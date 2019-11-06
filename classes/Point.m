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

classdef Point < DataSelector
    properties(Constant)
        nPos = 1
    end
    
    methods
        function obj = Point(tPos)
            if nargin == 0
                tPos = 0;
            end
            obj = obj@DataSelector(tPos);
            obj.timePosition = tPos;
            obj.clr = [0 0 0];
        end

        function s = toStruct(objArray)
            s = toStruct@DataSelector(objArray);
        end
        
        function json = jsondump(objArray)
            s = objArray.toStruct();
            json = jsonencode(s);
        end
        
        function gr = makeGraphicsObject(objArray,mode,dragEnabled)
            gr = GraphicsPoint.empty;
            for i = 1:numel(objArray)
                gr(i) = GraphicsPoint(objArray(i),mode,dragEnabled);
            end
        end
    end
    
    methods(Static)
        function iPos = timeToIndex(tPos,cluster)
            iPos = mod((tPos-cluster.offset-cluster.indexOffset) / cluster.samplingPeriod, cluster.nCyclePoints);
            iPos = floor(iPos) + 1;
        end
        
        function cPos = timeToCycleNumber(tPos,cluster)
            cPos = (tPos-cluster.offset-cluster.indexOffset) / (cluster.samplingPeriod * cluster.nCyclePoints);
            cPos = floor(cPos) + 1;
            cPos(cPos < 1) = nan;
            cPos(cPos > cluster.nCycles) = nan;
        end
        
        function tPos = indexToTime(iPos,cluster)
            iPos(iPos<1) = 1;
            iPos(iPos>cluster.nCyclePoints) = cluster.nCyclePoints;
            tPos = (iPos - 0.5) * cluster.samplingPeriod + cluster.offset + cluster.indexOffset;   
        end
        
        function tPos = cycleNumberToTime(cPos,cluster)
            cPos(cPos<1) = 1;
            cPos(cPos>cluster.nCycles) = cluster.nCycles;         
            cLength = cluster.samplingPeriod * cluster.nCyclePoints;
            tPos = (cPos - 0.5) * cLength + cluster.offset;            
        end
        
        function points = fromStruct(s)
            points = Point.empty;
            for i = 1:numel(s)
                p = Point(0);
                points(end+1) = p;
            end
            fromStruct@DataSelector(s,points)
        end
        
        function points = jsonload(json)
            data = jsondecode(json);
            points = Point.fromStruct(data);
        end
    end
end