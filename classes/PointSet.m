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

classdef PointSet < Descriptions
    properties
        points = Point.empty;
    end
    
    methods
        function obj = PointSet()
            obj.setCaption('point set');
        end
        
        function s = toStruct(objArray)
            s = toStruct@Descriptions(objArray);
            for i = 1:numel(objArray)
                obj = objArray(i);
                s(i).points = obj.points.toStruct();
            end
        end
        
        function json = jsondump(objArray)
            s = objArray.toStruct();
            json = jsonencode(s);
        end
        
        function dates = getModifiedDate(objArray)
            if isempty(objArray)
                dates = datetime.empty;
                return
            end
            dates = [objArray.modifiedDate];
            for i = 1:numel(objArray)
                dates(i) = max([dates(i),objArray(i).points.getModifiedDate()]);
            end
        end         
        
        function addPoint(obj,point)
            obj.points = [obj.points, point];
            obj.modified();
        end
        
        function p = getPoints(obj)
            p = obj.points;
        end
        
        function removePoint(obj,point)
            obj.points(obj.points==point) = [];
        end
    end
    
    methods(Static)
        function sets = fromStruct(s)
            sets = PointSet.empty;
            for i = 1:numel(s)
                ps = PointSet();
                ps.points = Point.fromStruct(s(i).points);
                sets(end+1) = ps;
            end
            fromStruct@Descriptions(s,sets)
        end
        
        function sets = jsonload(json)
            data = jsondecode(json);
            sets = PointSet.fromStruct(data);
        end
    end
end