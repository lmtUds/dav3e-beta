% This file is part of DAVE, a MATLAB toolbox for data evaluation.
% Copyright (C) 2018-2019 Saarland University, Author: Manuel Bastuck
% Website/Contact: www.lmt.uni-saarland.de, info@lmt.uni-saarland.de
% 
% The author thanks Tobias Baur, Tizian Schneider, and Jannis Morsch
% for their contributions.
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>. 

classdef ModelInputData < handle
    properties
        sensorCaptions
        measurements
        featureDataset
        featureMatrix
        
        grouping
        groupingVector
        target
        targetVector
        
        rngSeed = 'shuffle'
        holdoutPercentage = 0
        
        ignoreGroups
        validationGroups
        testingGroups
        ignoreMask
        validationMask
        testingMask
        trainingMask
        
        featureCaptions
        selectedFeatures
        featureMask
    end
    
    methods
        function obj = ModelInputData()
            obj.featureDataset =FeatureDataSet.empty;
            obj.measurements = Measurement.empty;
            obj.sensorCaptions = {};
            
            obj.ignoreGroups = {'<ignore>'};
            obj.validationGroups = {};
            obj.testingGroups = {};
        end
        
        function addFeatureDataSet(obj,featDataset)
            % find correct position in the meas/sensor matrix
            meas = featDataset.sensor.getMeasurement();
            [~,measPos] = ismember(obj.measurements,meas);
            if isempty(measPos)
                obj.measurements = [obj.measurements; meas];
                measPos = numel(obj.measurements);
            end
            sCap = featDataset.sensor.getCaption('cluster');
            [~,sensorPos] = ismember(obj.sensorCaptions,sCap);
            if isempty(sensorPos)
                obj.sensorCaptions = [obj.sensorCaptions,sCap];
                sensorPos = numel(obj.sensorCaptions);
            end
            
            % check if FeatureDefinitionSets in already present
            % FeatureDataSets is the same as the new one
            if measPos <= size(obj.featureDataset)
                temp = obj.featureDataset(measPos,:);
                if ~all([temp.featureDefinitionSet] == featDataset.featureDefinitionSet)
                    error('Serial fusion of sensors requires same feature definition set for all those sensors.');
                end
            end
            obj.featureDataset(measPos,sensorPos) = featDataset;
        end
        
        function fm = buildFeatureMatrix(obj)
            nCycles = arrayfun(@(x)x.getNCycles(),obj.featureDataset);
            nFeatures = arrayfun(@(x)x.getNFeatures(),obj.featureDataset);
            fm = nan(sum(nCycles),sum(nFeatures));
            header = strings(1,sum(nFeatures));
            cycleStarts = [1, 1 + cumsum(nCycles(1:end-1))];
            featureStarts = [1, 1 + cumsum(nFeatures(1:end-1))];
            cycleEnds = nCycles + cycleStarts - 1;
            featureEnds = nFeatures + cycleStarts - 1;
            for idxc = 1:numel(cycleStarts)
                for idxf = 1:numel(featureStarts)
                    [m,h] = obj.featureDataset(idxc,idxf).getFeatureMatrix();
                    fm(cycleStarts(idxc):cycleEnds(idxc),...
                        featureStarts(idxf):featureEnds(idxf)) = m;
                    header(featureStarts(idxf):featureEnds(idxf)) = h;
                end
            end
            obj.featureMatrix = fm;
            obj.featureCaptions = header;
        end
        

        function addIgnoreGroup(obj,group)
            group = string(group);
            obj.ignoreGroups = union(obj.ignoreGroups, group);
        end
        
        function removeIgnoreGroup(obj,group)
            group = string(group);
            pos = ismember(group,'<ignore>');
            group(pos) = [];
            pos = ismember(obj.ignoreGroups,group);
            obj.ignoreGroups(pos) = [];
        end
        
        function addValidationGroup(obj,group)
            group = string(group);
            pos = ismember(group,'<ignore>');
            group(pos) = [];            
            obj.validationGroups = union(obj.validationGroups, group);
        end
        
        function removeValidationGroup(obj,group)
            group = string(group);
            pos = ismember(obj.validationGroups,group);
            obj.validationGroups(pos) = [];
        end
        
        function addTestingGroup(obj,group)
            group = string(group);
            pos = ismember(group,'<ignore>');
            group(pos) = [];            
            obj.testingGroups = union(obj.testingGroups, group);
        end
        
        function removeTestingGroup(obj,group)
            group = string(group);
            pos = ismember(obj.testingGroups,group);
            obj.testingGroups(pos) = [];
        end
        
        function selectFeature(obj,feature)
            feature = string(feature);          
            obj.selectedFeatures = union(obj.selectedFeatures, feature);
            obj.featureMask = ismember(obj.featureCaptions,obj.selectedFeatures);
        end
        
        function deselectFeature(obj,feature)
            feature = string(feature);
            pos = ismember(obj.selectedFeatures,feature);
            obj.selectedFeatures(pos) = [];
            obj.featureMask = ismember(obj.featureCaptions,obj.selectedFeatures);
        end        
        
        function updateCycleMasks(obj)
            t = obj.targetVector;
            obj.ignoreMask = ismember(t,categorical(obj.ignoreGroups));
            obj.validationMask = ismember(t,categorical(obj.validationGroups));
            obj.testingMask = ismember(t,categorical(obj.testingGroups));
            obj.trainingMask = ~(obj.ignoreMask | obj.testingMask);
            
            % transfer holdout data from training to testing data
            if obj.holdoutPercentage > 0
                rng(obj.rngSeed);
                c = cvpartition(t(obj.trainingMask),'HoldOut',obj.holdoutPercentage/100);
                obj.testingMask(obj.trainingMask) = c.test;
                obj.trainingMask(obj.trainingMask) = c.training;
            end
            
            % check to be sure that no cycle is used twice
            if any(sum([obj.ignoreMask, obj.validationMask,...
                   obj.testingMask, obj.trainingMask],2) > 1)
                error('Datasets must be mutually exclusive.');
            end
        end
        
        function data = getTrainingData(obj)
            data = obj.featureMatrix(obj.trainingMask,:);
        end
        
        function data = getValidationData(obj)
            data = obj.featureMatrix(obj.validationMask,:);
        end
        
        function data = getTestingData(obj)
            data = obj.featureMatrix(obj.testingMask,:);
        end
        
        function nFeat = getNSelectedFeatures(obj)
            nFeat = sum(obj.featureMask);
        end
        
        function [train, val, test] = getNSelectedCycles(obj)
            train = sum(obj.trainingMask);
            val = sum(obj.validationMask);
            test = sum(obj.testingMask);
        end
    end
end