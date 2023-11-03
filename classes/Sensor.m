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

classdef Sensor < Descriptions
    properties
        data_
        abscissaType = 'time'
        cyclePointSet_
        indexPointSet_
        preprocessingChain_
        featureDefinitionSet_
        
        abscissaSensor
        abscissaSensorCycle = 1
        abscissaSensorPreprocessed = true
        
        cluster = Cluster.empty
        active = true
        virtual = false
        dataProcessingBlock = DataProcessingBlock.empty
        
        featureData = FeatureData.empty
    end
    
    properties (Transient)
        ppData = []
    end
    
    properties (Dependent)
        data
        abscissa
        cyclePointSet
        indexPointSet
        preprocessingChain
        featureDefinitionSet
    end
    
    methods
        function obj = Sensor(data,varargin)
            obj = obj@Descriptions();
            p = inputParser;
            p.addRequired('data');
            p.addParameter('caption','sensor');
            parse(p,data,varargin{:});
            if isa(p.Results.data,'DataProcessingBlock')
                obj.dataProcessingBlock = p.Results.data;
                obj.data_ = [];
                obj.virtual = true;
            else
                obj.data_ = p.Results.data;
            end
            obj.setCaption(p.Results.caption);
        end
        
        function val = get.cyclePointSet(obj)
            val = obj.cyclePointSet_;
        end
        
        function set.cyclePointSet(obj,val)
            obj.cyclePointSet_ = val;
            obj.modified();
        end        
        
        function val = get.indexPointSet(obj)
            val = obj.indexPointSet_;
        end
        
        function set.indexPointSet(obj,val)
            obj.indexPointSet_ = val;
            obj.modified();
        end 
        
        function val = get.preprocessingChain(obj)
            val = obj.preprocessingChain_;
        end
        
        function set.preprocessingChain(obj,val)
            obj.preprocessingChain_ = val;
            if ~isempty(obj.ppData)
                obj.deletePreprocessedData();
                obj.preComputePreprocessedData();
            end
            obj.modified();
        end 
        
        function val = get.featureDefinitionSet(obj)
            val = obj.featureDefinitionSet_;
        end
        
        function set.featureDefinitionSet(obj,val)
            obj.featureDefinitionSet_ = val;
            obj.modified();
        end         
        
        function data = get.data(obj)
            if obj.virtual
                data = obj.dataProcessingBlock.apply(obj);
            else
                data = obj.data_.data;
            end
        end
        
        function abscissa = get.abscissa(obj)
            switch obj.abscissaType
                case 'time'
                    abscissa = (1:size(obj.data,2)) * obj.getCluster().samplingPeriod;
                case 'data points'
                    abscissa = (1:size(obj.data,2));
                case 'sensor'
                    abscissa = obj.abscissaSensor.getCycleAt(obj.abscissaSensorCycle,obj.abscissaSensorPreprocessed);
                otherwise
                    error('Unknown abscissa.');
            end
        end
        
        function dates = getModifiedDate(objArray)
            if isempty(objArray)
                dates = datetime.empty;
                return
            end
            dates = [objArray.modifiedDate];
            for i = 1:numel(objArray)
                dates(i) = max([dates(i),...
                    objArray(i).cyclePointSet.getModifiedDate(),...
                    objArray(i).indexPointSet.getModifiedDate(),...
                    objArray(i).preprocessingChain.getModifiedDate(),...
                    objArray(i).featureDefinitionSet.getModifiedDate()]);
            end
        end         
        
%         function makeReal(objArray)
%             for i = 1:numel(objArray)
%                 objArray(i).data = objArray(i).data;
%                 objArray(i).virtual = false;
%             end
%         end
%             
%         function makeVirtual(objArray)
%             for i = 1:numel(objArray)
%                 objArray(i).virtual = true;
%                 objArray(i).data = [];
%             end
%         end
        
        function s = toStruct(objArray,asRef)
            if nargin <= 1
                asRef = true;
            end
            s = toStruct@Descriptions(objArray);
            for i = 1:numel(objArray)
                obj = objArray(i);
                if asRef
                    s(i).cyclePointSet = makeUUIDRef(obj.cyclePointSet);
                    s(i).indexPointSet = makeUUIDRef(obj.indexPointSet);
                    s(i).preprocessingChain = makeUUIDRef(obj.preprocessingChain);
                    s(i).featureDefinitionSet = makeUUIDRef(obj.featureDefinitionSet);
                else
                    s(i).cyclePointSet = obj.cyclePointSet;
                    s(i).indexPointSet = obj.indexPointSet;
                    s(i).preprocessingChain = obj.preprocessingChain;
                    s(i).featureDefinitionSet = obj.featureDefinitionSet;
                end
                s(i).active = obj.active;
            end
        end
        
        function json = jsondump(objArray)
            s = objArray.toStruct();
            json = jsonencode(s);
        end
        
        function writeDataToFile(obj,projectPath)
            varName = obj.getUUID();
            eval(varName + string('=obj.data;')); %#ok<*STRQUOT>
            if ~exist(fullfile(projectPath,'sensorData.mat'),'file')
                save(fullfile(projectPath,'sensorData.mat'),varName);
            else
                save(fullfile(projectPath,'sensorData.mat'),varName,'-append');
            end
        end
        
        function readDataFromFile(obj,projectPath)
            varName = obj.getUUID();
            d = load(fullfile(projectPath,'sensorData.mat'),varName);
            obj.data = d.(char(varName));
        end
        
        function captions = getCaption(objArray,varargin)
            captions = getCaption@Descriptions(objArray);
            if ismember('cluster',varargin)
                cCap = objArray.getCluster().getCaption();
                captions = cCap + '/' + captions;
            end
        end
        
        function project = getProject(objArray)
            project = objArray.getCluster().getProject();
        end
        
        function cluster = getCluster(objArray)
            cluster = [objArray.cluster];
        end
        
        function setCurrent(obj)
            obj.getCluster().setCurrentSensor(obj);
        end          
        
        function setActive(objArray,state)
            if numel(state) == 1
                [objArray.active] = deal(state);
            else
                for i = 1:numel(objArray)
                    objArray(i).active = state(i);
                end
            end
            objArray.modified();
        end
        
        function active = isActive(objArray)
            active = [objArray.active];
        end
        
        function p = getIndexPoints(obj)
            p = obj.indexPointSet.getPoints();
            if isempty(p)
                return
            end
            pos = p.getIndexPosition(obj.cluster);
            p((pos < 1) | (pos > obj.cluster.nCyclePoints)) = [];
        end
        
        function p = getCyclePoints(obj)
            p = obj.cyclePointSet.getPoints();
            if isempty(p)
                return
            end
            pos = p.getCyclePosition(obj.cluster);
            p((pos < 1) | (pos > obj.cluster.nCycles)) = [];
        end
        
        function d = getPPData(obj)
            if ~isempty(obj.ppData)
                d = obj.ppData;
            else
                obj.preprocessingChain.train(obj.data);
                d = obj.preprocessingChain.apply(obj.data);
            end
        end
        
        function d = getSelectedQuasistaticSignals(obj,pp)
            if nargin < 2
                pp = false;
            end
            p = obj.getIndexPoints().getIndexPosition(obj.cluster);
            invalid = isnan(p);
            p(invalid) = 1;
            if pp
                if ~isempty(obj.ppData)
                    d = obj.ppData;
                else
                    obj.preprocessingChain.train(obj.data);
                    d = obj.preprocessingChain.apply(obj.data);
                end
            else
                d = obj.data;
            end
            d = d(:,p);
            d(:,invalid) = nan;
        end
        
        function d = getSelectedCycles(obj,pp)
            if nargin < 2
                pp = false;
            end
            p = obj.getCyclePoints().getCyclePosition(obj.cluster);
            invalid = isnan(p);
            p(invalid) = 1;
            d = obj.data(p,:);
            if pp
                if ~isempty(obj.ppData)
                    d = obj.ppData(p,:);
                else
                    obj.preprocessingChain.train(d);
                    d = obj.preprocessingChain.apply(d);
                end
            end
            d(invalid,:) = nan;
        end
        
        function d = getQuasistaticSignalAtIndex(obj,iPos,pp)
            if nargin < 3
                pp = false;
            end
            if pp
                if ~isempty(obj.ppData)
                    d = obj.ppData;
                else
                    obj.preprocessingChain.train(obj.data);
                    d = obj.preprocessingChain.apply(obj.data);
                end
            else
                d = obj.data;
            end            
            d = d(:,iPos);
        end
        
        function d = getCycleAt(obj,cPos,pp)
            if nargin < 3
                pp = false;
            end   
            d = obj.data(cPos,:);
            if pp
                if ~isempty(obj.ppData)
                    d = obj.ppData(cPos,:);
                else
                    try
                        obj.preprocessingChain.train(d);
                        d = obj.preprocessingChain.apply(d);
                    catch
                        % temporary solution to catch quasistatic
                        % preprocessings that need all cycles, like
                        % baseline correction
                        obj.preprocessingChain.train(obj.data);
                        d = obj.preprocessingChain.apply(obj.data);
                        d = d(cPos,:);
                    end
                end
            end            
        end
        
        function mm = getDataMinMax(obj,pp)
            if nargin < 2
                pp = false;
            end
            if pp
                if ~isempty(obj.ppData)
                    d = obj.ppData;
                else
                    obj.preprocessingChain.train(obj.data);
                    d = obj.preprocessingChain.apply(obj.data);
                end
            else
                d = obj.data;
            end
            if size(d,1) > 10
                d(1,:) = 0;
            end
            mm = [min(min(d)), max(max(d))];
        end
        
        function p = addIndexPoint(obj,iPos)
            p = obj.cluster.makeIndexPoint(iPos);
            obj.indexPointSet.addPoint(p);
        end
        
        function p = addCyclePoint(obj,iPos)
            p = obj.cluster.makeCyclePoint(iPos);
            obj.cyclePointSet.addPoint(p);
        end
        
        function preComputePreprocessedData(obj)
            obj.preprocessingChain.train(obj.data);
            obj.ppData = obj.preprocessingChain.apply(obj.data);
        end
        
        function deletePreprocessedData(obj)
            obj.ppData = [];
        end
        
        function init(objArray)
            if isempty(objArray) || isempty(objArray.getProject())
                return
            end
            p = objArray(1).getProject();
            for i = 1:numel(objArray)
                obj = objArray(i);
                obj.cyclePointSet = p.poolCyclePointSets(1);
                obj.indexPointSet = p.poolIndexPointSets(1);
                obj.preprocessingChain = p.poolPreprocessingChains(1);
                obj.featureDefinitionSet = p.poolFeatureDefinitionSets(1);
                
                if isempty(obj.getCyclePoints())
                    obj.cyclePointSet.addPoint(obj.cluster.makeCyclePoint(0));
                end
                if isempty(obj.getIndexPoints())
                    obj.indexPointSet.addPoint(obj.cluster.makeIndexPoint(0));
                end
            end
        end
        
        function o = getDataObject(obj,grouping)
            o = Data(obj.getPPData(),obj.cluster.getCycleOffsets());
            o.groupingObj = grouping;
            o.groupings = grouping.getTargetVector(obj.cluster.getCycleRanges(),obj.cluster);
%             o.groupings
        end
        
        function [featData,header] = computeFeatures(obj,cycles)
            if ~obj.isActive()
                featData = FeatureData.empty;
                header = string.empty;
                return
            end
            
            % remove invalid features and update still valid features
            obj.featureData(~obj.featureData.isValid()) = [];
            obj.featureData.updateFeatures(cycles);
            
            % compute new features
            featData = FeatureData.computeForSensor(obj,cycles,obj.featureData);
            featData = [obj.featureData,featData];
            header = horzcat(featData.header);
            obj.featureData = featData;
            
%             featDefSet = obj.featureDefinitionSet;
%             d = obj.getCycleAt(cycles,true); % preprocessed cycles
%             [featData,header,featUUIDs] = featDefSet.compute(d,obj);
%             header = string(header);
%             header = obj.getCaption() + string('/') + header;
%             obj.featureData = featData;
%             obj.featureHeader = header;
%             obj.featureRangeUUIDs = featUUIDs;
        end
    end
    
    methods(Static)
        function sensors = fromStruct(s)
            sensors = Sensor.empty;
            for i = 1:numel(s)
                sn = Sensor();
                sn.cyclePointSet = s(i).cyclePointSet;
                sn.indexPointSet = s(i).indexPointSet;
                sn.preprocessingChain = s(i).preprocessingChain;
                sn.featureDefinitionSet = s(i).featureDefinitionSet;
                sn.active = s(i).active;
                sensors(end+1) = sn; %#ok<AGROW>
            end
            fromStruct@Descriptions(s,sensors)
        end
        
        function ranges = jsonload(json)
            data = jsondecode(json);
            ranges = Sensor.fromStruct(data);
        end
        
        function s = fromFile(path,type,varargin)
            s = Sensor();
            switch type
                case 'csv'
                    s.data = csvread(path);
                case 'tsv'
                    s.data = dlmread(path,'\t');
            end
        end
    end
    
    methods (Static)
        function out = getAvailableMethods(force)
            persistent fe
            if ~exist('force','var')
                force = false;
            end
            if ~isempty(fe) && ~force
                out = fe;
                return
            end
            fe = parsePlugin('VirtualSensor');
            out = fe;
        end
    end    
end