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

classdef Cluster < Descriptions
    properties
        id
        offset = 0
        indexOffset = 0
        samplingPeriod = 1
        nCyclePoints
        nCycles
        track

        project
        sensors = Sensor.empty
        currentSensor
        featureData
        
        empty = false
    end

    methods
        function obj = Cluster(varargin)
            obj = obj@Descriptions();

            p = inputParser;
            addParameter(p,'samplingPeriod',nan,@isnumeric);
            addParameter(p,'nCyclePoints',nan,@isnumeric);
            addParameter(p,'nCycles',nan,@isnumeric);
            addParameter(p,'offset',0,@isnumeric);
            addParameter(p,'caption','cluster');
            addParameter(p,'track','default');
            parse(p,varargin{:});
            
            p = p.Results;
            if isnan(p.samplingPeriod) || isnan(p.nCyclePoints) || isnan(p.nCycles)
                obj.empty = true;
%                 warning('Required parameters: samplingPeriod, nCyclePoints, nCycles');
            end
            
            obj.samplingPeriod = p.samplingPeriod;
            obj.nCyclePoints = p.nCyclePoints;
            obj.nCycles = p.nCycles;
            obj.offset = p.offset;
            obj.setCaption(p.caption);
            obj.track = p.track;
        end
        
        function s = toStruct(objArray,asRef)
            if nargin <= 1
                asRef = true;
            end
            s = toStruct@Descriptions(objArray);
            for i = 1:numel(objArray)
                obj = objArray(i);
                s(i).id = obj.id;
                s(i).offset = obj.offset;
                s(i).indexOffset = obj.indexOffset;
                s(i).samplingPeriod = obj.samplingPeriod;
                s(i).sensors = obj.sensors.toStruct(asRef);
            end
        end
        
        function json = jsondump(objArray)
            s = objArray.toStruct();
            json = jsonencode(s);
        end

        function set.track(obj,track)
            obj.track = string(track);
        end
        
        function set.offset(obj,offset)
            obj.offset = offset;
            obj.modified();
        end
        
        function set.indexOffset(obj,indexOffset)
            cyclePoints = Point.empty;
            indexPoints = Point.empty;
            for i = 1:numel(obj.sensors)
                cyclePoints = [cyclePoints,obj.sensors(i).cyclePointSet.getPoints()];
                indexPoints = [indexPoints,obj.sensors(i).indexPointSet.getPoints()];
            end
            cyclePoints = unique(cyclePoints);
            indexPoints = unique(indexPoints);
            cyclePos = cyclePoints.getCyclePosition(obj);
            indexPos = indexPoints.getIndexPosition(obj);
            obj.indexOffset = indexOffset;
            cyclePoints.setCyclePosition(cyclePos,obj);
            indexPoints.setIndexPosition(indexPos,obj);
            obj.modified();
        end
        
        function set.samplingPeriod(obj,samplingPeriod)
            obj.samplingPeriod = samplingPeriod;
            obj.modified();
        end
        
        function iOffset = getAutoIndexOffset(obj,clusters)
            lcd = max(clusters.getCycleDuration());
            iOffset = -mod(obj.offset,lcd);
            if iOffset < -lcd/2
                iOffset = lcd + iOffset;
            end
        end
        
        function offsets = getCycleOffsets(obj)
            offsets = obj.offset + obj.nCyclePoints * obj.samplingPeriod * (0:obj.nCycles-1)';
        end
        
        function n = getTotalDataPoints(objArray)
            n = [objArray.nCycles] .* [objArray.nCyclePoints];
        end
        
        function d = getDuration(objArray)
            d = ([objArray.samplingPeriod] .* [objArray.nCyclePoints] .* [objArray.nCycles])';
        end
        
        function d = getCycleDuration(objArray)
            d = ([objArray.samplingPeriod] .* [objArray.nCyclePoints])';
        end
        
        function t = getClusterTimeRange(objArray)
            t = [[objArray.offset]',[objArray.offset]'+objArray.getDuration()];
        end
        
        function project = getProject(objArray)
            if isempty(objArray)
                project = Project.empty;
            end
            project = [objArray.project];
        end

        function setCurrent(obj)
            obj.getProject().setCurrentCluster(obj);
        end        
        
        function hasAS = hasActiveSensors(objArray)
            hasAS = false(0,1);
            for i = 1:numel(objArray)
                hasAS(i) = any(objArray(i).sensors.isActive());
            end
        end
        
        function r = makeIndexRange(obj,iPos,sensor)
            r(size(iPos,1)) = Range();
            if nargin < 3
                r.setIndexPosition(iPos,obj);
            else
                r.setAbscissaPosition(iPos,sensor);
            end
        end
        
        function r = makeCycleRange(obj,cPos)
            r(size(cPos,1)) = Range();
            r.setCyclePosition(cPos,obj);
        end
        
        function r = makeIndexPoint(obj,iPos,sensor)
            r = Point([0,0]);
            if nargin < 3
                r.setIndexPosition(iPos,obj);
            else
                r.setAbscissaPosition(iPos,sensor);
            end
        end
        
        function r = makeCyclePoint(obj,cPos)
            r = Point([0,0]);
            r.setCyclePosition(cPos,obj);
        end        
        
        function cnr = timeToCycleNumber(obj,tPos)
            cnr = Point.timeToCycleNumber(tPos,obj);
        end
        
        function cnr = timeRangeToCycleNumber(obj,tPos)
            cnr = Range.timeToCycleNumber(tPos,obj);
        end
        
        function r = getCycleRanges(obj)
            r = obj.project.ranges;
            cPos = r.getCyclePosition(obj);
            %keep = any(cPos >= 1) & any(cPos <= obj.nCycles);
            keep = ~any(isnan(cPos),2);
            r = r(keep);
        end
        
        function addSensor(obj,sensors)
            sensors = sensors(:);
            
            % ensure unique captions
            if ~isempty(obj.sensors)
                captions = cellstr(obj.sensors.getCaption());
                for i = 1:numel(sensors)
                    sensors(i).setCaption(matlab.lang.makeUniqueStrings(char(sensors(i).getCaption()),captions))
                end
            end
            captions = matlab.lang.makeUniqueStrings(cellstr(sensors.getCaption()));
            for i = 1:numel(captions)
                sensors(i).setCaption(captions{i});
            end            
            
            n = numel(sensors);
            if isempty(obj.sensors)
                obj.sensors = sensors;
                obj.currentSensor = sensors(end);
            else
                obj.sensors(end+1:end+n) = sensors;
            end
            
            for i = 1:numel(sensors)
                sensors(i).cluster = obj;
                sensors(i).init();
            end            
        end
        
        function setCurrentSensor(obj,sensor)
            if isnumeric(sensor)
                sensor = obj.sensors(sensor);
            elseif all(islogical(sensor))
                if sum(sensor) ~= 1
                    error('Exactly one cluster must be selected');
                else
                    sensor = obj.sensors(sensor);
                end
            end
            obj.currentSensor = sensor;
        end
        
        function sensor = getCurrentSensor(obj)
            if isempty(obj) || isempty(obj.currentSensor)
                sensor = Sensor.empty;
                return
            end
            sensor = obj.currentSensor;
        end
        
        function removeSensor(obj,sensors)
            if isa(sensors,'Sensor')
                found = ismember(obj.sensors,sensors);
            else
                found = ismember(obj.sensors.getCaption(),sensors);
            end
            found = find(found);
            
            for i = 1:numel(found)
                obj.sensors(found(i)).cluster = [];
            end            
            
            obj.sensors(found) = [];
        end
        
        function s = makeSensorFromData(obj,data)
            s = Sensor();
            dataLength = numel(data);
            clusterLength = obj.getTotalDataPoints();
            if dataLength > clusterLength
                data(clusterLength+1:end) = [];
            elseif dataLength < clusterLength
                data(end+1:clusterLength) = nan;
            end
            s.data = reshape(data,[obj.nCyclePoints,obj.nCycles])';
        end
        
        function [featData,header] = computeFeatures(obj,cycles)
            featData = [];
            featDataObjs = FeatureData.empty;
            header = string.empty;
            for i = 1:numel(obj.sensors)
                [fData,h] = obj.sensors(i).computeFeatures(cycles);
                featDataObjs = [featDataObjs,fData];
                featData = [featData,[fData.data]];
                header = [header, obj.sensors(i).getCaption() + string('/') + h];
            end
%             obj.featureData = featDataObjs;
%             header = obj.getCaption() + string('/') + header;
        end
        
        function p = getByCaption(objArray,caption)
            p = objArray(objArray.getCaption() == caption);
        end
    end
    
    methods(Static)
        function c = fromFile(path,type,varargin)
            ip = inputParser();
            ip.addParameter('samplingPeriod',1);
            ip.parse(varargin{:});
            ip = ip.Results;
            
            c = Cluster();
            c.samplingPeriod = ip.samplingPeriod;
            
            if ~iscell(path)
                path = {path};
            end
            for i = 1:numel(path)
                s = Sensor.fromFile(path{i},type);
                c.addSensor(s);
                if i == 1
                    c.nCyclePoints = size(s.data,2);
                    c.nCycles = size(s.data,1);
                end
            end
        end
    end
end