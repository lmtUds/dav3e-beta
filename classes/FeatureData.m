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

classdef FeatureData < Descriptions
    properties
        featureDefinition
        featureDefinitionData
        rangeData
        cycleIdxs
        sensor
        sensorData
        data
        header
    end
    
    methods
        function obj = FeatureData(sensor,featDef,data,header,valueLabels,cycleIdxs)
            obj@Descriptions();
            if nargin == 0  % allow empty object creation
                return
            end
            obj.sensor = sensor;
            obj.sensorData = sensor.toStruct();
            obj.featureDefinition = featDef;
            obj.featureDefinitionData = featDef.toStruct();
            obj.rangeData = featDef.getRanges().toStruct();
            obj.cycleIdxs = cycleIdxs;
            
            obj.data = [];
            for i = 1:size(data,3)
                obj.data = [obj.data,data(:,:,i)];
            end
            obj.header = string(header);
            if ~isempty(valueLabels)
                obj.header = obj.header' + string('_') + string(valueLabels(:)');
                obj.header = obj.header(:)';
            end
        end
        
        function [val,reason] = isValid(objArray)
            reason = string('');
            val = false(0,1);
            
            for i = 1:numel(objArray)
                obj = objArray(i);
                
                if isempty(obj.sensor)
                    reason(i) = 'Empty object.';
                    val(i) = false;
                    continue
                end
                featDefs = obj.sensor.featureDefinitionSet.getFeatureDefinitions();

                % not valid if the sensor has changed (eg. abscissa)
                if obj.sensor.getModifiedDate() ~= obj.sensorData.modifiedDate
                    reason(i) = 'Sensor modified.';
                    val(i) = false;
                    continue
                end

                % not valid if the feature definition is not contained in the
                % sensor
                if ~ismember(obj.featureDefinition,featDefs)
                    reason(i) = 'FeatureDefinition invalid.';
                    val(i) = false;
                    continue
                end

                % not valid if the FeatureDefinition has been modified
                if obj.featureDefinition.getModifiedDate() ~= obj.featureDefinitionData.modifiedDate
                    reason(i) = 'FeatureDefinition modified.';
                    val(i) = false;
                    continue
                end                
                
                val(i) = true;
            end
        end
        
        function updateFeatures(objArray,cycleIdxs)
            for i = 1:numel(objArray)
                obj = objArray(i);
                [valid,reason] = obj.isValid();
                if ~valid
                    warning('FeatureData has become invalid and cannot be updated. %s',reason);
                    continue
                end
                if size(obj.data,2) == 0
                    obj.data = [];
                end
                [computed,loc] = ismember(obj.cycleIdxs,cycleIdxs);
                newData = nan(numel(obj.cycleIdxs),size(obj.data,2),size(obj.data,3));
                newData(loc(loc>0),:,:) = obj.data(computed,:,:);
                reducedCycleIdxs = cycleIdxs(~computed);
                rawData = obj.sensor.getCycleAt(reducedCycleIdxs,true);
                additionalData = obj.featureDefinition.computeRaw(rawData,obj.sensor);
                newDataMatIdxs = 1:numel(computed);
                newDataMatIdxs(computed) = [];
                newData(newDataMatIdxs,:,:) = additionalData;
                obj.data = newData;
            end
        end
    end
    
    methods(Static)
        function featDatas = computeForSensor(sensor,cycleIdxs,alreadyComputedFeatureDatas)
            if nargin < 3
                alreadyComputedFeatureDefs = FeatureDefinition.empty;
            else
                alreadyComputedFeatureDefs = [alreadyComputedFeatureDatas.featureDefinition];
            end
            featDatas = FeatureData.empty;
            featDefs = sensor.featureDefinitionSet.getFeatureDefinitions();
            % TODO: handle multi-part data (too large for RAM)
            rawData = sensor.getCycleAt(cycleIdxs,true);
            for i = 1:numel(featDefs)
                if ismember(featDefs(i),alreadyComputedFeatureDefs)
                    continue
                end
                [data,header,valueLabels] = featDefs(i).computeRawBatch(rawData,sensor);
                featDatas(i) = FeatureData(sensor,featDefs(i),data,header,valueLabels,cycleIdxs);
            end
        end
    end
end