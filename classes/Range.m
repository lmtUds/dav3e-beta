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

classdef Range < DataSelector
    properties
        subRangeNum = 1
        subRangeForm = 'lin'
        subRangeDivs = [];
    end
    
    properties(Constant)
        nPos = 1
    end
    
    methods
        function obj = Range(tPos)
            if nargin == 0
                tPos = [0,0];
            end    
            obj = obj@DataSelector(tPos); 
            obj.timePosition = tPos;
            obj.clr = [.5 .5 .5];
        end
        
        function s = toStruct(objArray)
            s = toStruct@DataSelector(objArray);
            for i = 1:numel(objArray)
                obj = objArray(i);
                s(i).subRangeNum = obj.subRangeNum;
                s(i).subRangeForm = obj.subRangeForm;
            end
        end
        
        function json = jsondump(objArray)
            s = objArray.toStruct();
            json = jsonencode(s);
        end
        
        function tPos = getTimePosition(objArray)
            if isempty(objArray)
                tPos = [];
                return
            end
            tPos = objArray.getTimePosition@DataSelector();
            switched = tPos(:,1) > tPos(:,2);
            tPos(switched,:) = tPos(switched,[2 1]);
        end        
        
        function setTimePosition(objArray,tPos)
            setTimePosition@DataSelector(objArray,tPos);
            objArray.updateSubRanges();
        end
        
        function tPos = getAllTimePositions(obj)
            tPos = [obj.timePosition(1) obj.subRangeDivs obj.timePosition(2)]';
            tPos = [tPos(1:end-1), tPos(2:end)];
        end
        
        function iPos = getAllIndexPositions(obj,sensor)
%             if isa(sensor,'Cluster')
%                 cluster = sensor;
%             else
%                 cluster = sensor.cluster;
%             end
            tPos = obj.getTimePosition();
            tPos = [tPos(1) obj.subRangeDivs tPos(2)]';
            tPos = [tPos(1:end-1), tPos(2:end)];
            iPos = Range.timeToIndex(tPos,sensor.cluster);
            
            % if a sensor was given and its abscissa is not monotonically
            % increasing, the range might refer to multiple limits at once
%             if isa(sensor,'Sensor')
%                 sensor = sensor;
                if all(diff(sensor.abscissa) > 0)
                    return
                end
                tempiPos = nan(0,2);
                for i = 1:size(iPos,1)
                    left = findCrossingIndices(sensor.abscissa,iPos(i,1));
                    right = findCrossingIndices(sensor.abscissa,iPos(i,2));
                    tempiPos = [tempiPos; [left',right']];
                end
                % make sure the lower number is left
                swap = tempiPos(:,1) > tempiPos(:,2);
                tempiPos(swap,:) = tempiPos(swap,[2 1]);
                iPos = tempiPos;
%             end
        end
        
        function cPos = getAllCyclePositions(obj,cluster)
            tPos = obj.getTimePosition();
            tPos = [tPos(1) obj.subRangeDivs tPos(2)]';
            tPos = [tPos(1:end-1), tPos(2:end)];
            cPos = Range.timeToCycleNumber(tPos,cluster);
        end
        
        function cIdx = getCycleIndices(objArray,cluster)
            cIdx = [];
            cPos = objArray.getCyclePosition(cluster);
            for i = 1:size(cPos,1)
                cIdx = [cIdx,cPos(i,1):cPos(i,2)];
            end
        end
        
        function setSubRangeNum(objArray,n)
            for i = 1:numel(objArray)
                objArray(i).subRangeNum = n;
            end
            objArray.updateSubRanges();
            objArray.modified();
        end
        
        function setSubRangeForm(objArray,f)
            for i = 1:numel(objArray)
                objArray(i).subRangeForm = f;
            end
            objArray.updateSubRanges();
            objArray.modified();
        end
        
        function dur = getDuration(objArray)
            dur = diff(objArray.getTimePosition(),[],2);
        end
        
        function points = getNPoints(objArray,cluster)
            points = diff(objArray.getIndexPosition(cluster),[],2) + 1;
        end
        
        function cycles = getNCycles(objArray,cluster)
            cycles = diff(objArray.getCyclePosition(cluster),[],2) + 1;
        end
        
        function n = getSubRangeNum(objArray)
            n = [objArray.subRangeNum];
        end
        
        function f = getSubRangeForm(objArray)
            f = {objArray.subRangeForm};
        end
        
        function subRanges = getSubRanges(obj)
            if obj.subRangeNum == 1
                subRanges = obj;
                return
            end
            
            subRanges = Range.empty;
            tPos = obj.getAllTimePositions();
            for i = 1:obj.subRangeNum
                subRanges(i) = Range(tPos(i,:));
            end
        end
        
        function updateSubRanges(objArray)
            tPos = objArray.getTimePosition();
            for i = 1:numel(objArray)
                obj = objArray(i);
                if obj.subRangeNum > 1
                    switch obj.subRangeForm
                        case 'lin'
                            divs = linspace(tPos(i,1),tPos(i,2),obj.subRangeNum+1);
                        case 'log'
                            divs = logspace(0,1.30103,obj.subRangeNum+1);
                            divs = (divs - 1) / 19 * (tPos(i,2) - tPos(i,1)) + tPos(i,1);
                        case 'invlog'
                            divs = logspace(1.30103,0,obj.subRangeNum+1);
                            divs = (divs - 1) / 19 * (tPos(i,1) - tPos(i,2)) + tPos(i,2);
                    end
                    obj.subRangeDivs = divs(2:end-1);
                else
                    obj.subRangeDivs = [];
                end
            end
        end
        
        function gr = makeGraphicsObject(objArray,mode,dragEnabled)
            gr = GraphicsRange.empty;
            for i = 1:numel(objArray)
                gr(i) = GraphicsRange(objArray(i),mode,dragEnabled);
            end
        end
    end
    
    methods(Static)
        function iPos = timeToIndex(tPos,cluster)
            if size(tPos,2) ~= 2
                error('Size of tPos must be n x 2.');
            end
            iPos = mod((tPos-cluster.offset-cluster.indexOffset) / cluster.samplingPeriod, cluster.nCyclePoints);
            iPos = round(iPos) + 1;
            iPos(iPos > cluster.nCyclePoints) = cluster.nCyclePoints;
        end
            
        function cPos = timeToCycleNumber(tPos,cluster)
            if size(tPos,2) ~= 2
                error('Size of tPos must be n x 2.');
            end
            cPos = (tPos-cluster.offset) / (cluster.samplingPeriod * cluster.nCyclePoints);
%             cPos = [ceil(cPos(:,1)) + 1, floor(cPos(:,2))];
%             cPos = [floor(cPos(:,1)) + 1, ceil(cPos(:,2))];
            cPos = [ceil(cPos(:,1))+1, floor(cPos(:,2))];
%             cPos = [ceil(cPos(:,1)), 1+floor(cPos(:,2))];
            cPos(cPos < 1) = nan;
            cPos(cPos > cluster.nCycles) = nan;
%             cPos = [floor(cPos(:,1)) + 1, floor(cPos(:,2 - 1) + 1)];
        end
        
        function tPos = indexToTime(iPos,cluster)
            if size(iPos,2) ~= 2
                error('Size of tPos must be n x 2.');
            end
            iPos(iPos<1) = 1;
            iPos(iPos>cluster.nCyclePoints) = cluster.nCyclePoints;
            tPos = (iPos - 1) * cluster.samplingPeriod ...
                + cluster.offset + cluster.indexOffset;         
        end
        
        function tPos = cycleNumberToTime(cPos,cluster)
            if size(cPos,2) ~= 2
                error('Size of tPos must be n x 2.');
            end
            cPos = ceil(cPos);
            cPos(cPos<1) = 1;
            cPos(cPos>cluster.nCycles) = cluster.nCycles;
            cLength = cluster.samplingPeriod * cluster.nCyclePoints;
            tPos = [(cPos(:,1) - 1) * cLength + cluster.offset, ...
                cPos(:,2) * cLength + cluster.offset];         
        end
        
        function ranges = fromStruct(s)
            ranges = Range.empty;
            for i = 1:numel(s)
                r = Range([0,0]);
                r.subRangeNum = s(i).subRangeNum;
                r.subRangeForm = s(i).subRangeForm;
                ranges(end+1) = r;
            end
            fromStruct@DataSelector(s,ranges)
        end
        
        function ranges = jsonload(json)
            data = jsondecode(json);
            ranges = Range.fromStruct(data);
        end
    end
end