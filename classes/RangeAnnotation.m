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

classdef RangeAnnotation < Descriptions
    properties
        ranges
        vals
        colors
        defaultValue
        
        sorted = true
    end
    
    methods
        function obj = RangeAnnotation()
            obj@Descriptions();
            obj.ranges = [];
            obj.vals = [];
            obj.colors = containers.Map();
            obj.defaultValue = 0;
        end
        
        function s = toStruct(objArray)
            s = toStruct@Descriptions(objArray);
        end
        
        function addRange(obj,ranges)
            n = numel(ranges);
            
            r = obj.ranges;
            allContained = all(ismember(r,ranges));
            if allContained && (numel(r) == numel(ranges))
                allInOrder = all(r == ranges);
                if ~allInOrder
                    obj.sorted = false;
                end
                return
            end
            
%             obj.ranges(ismember()) = [];
            if isempty([obj.ranges])
%                 return;
                obj.ranges = ranges(1);
                obj.vals = categorical({obj.defaultValue});
                ranges(1) = [];
                n = n - 1;
            end
            obj.ranges = [obj.ranges; ranges(:)];
            obj.vals(end+1:end+n,1) = obj.defaultValue;
            
            obj.sorted = false;
            obj.modified();
        end
        
        function removeRange(obj,ranges)
            found = ismember(obj.ranges,ranges);
            obj.ranges(found) = [];
            obj.vals(found) = [];
            obj.modified();
        end
        
        function setValue(obj,group,range)
            mask = ismember(obj.ranges, range);
            if ischar(group)
                group = {group};
            end
            obj.vals(mask) = group;
            obj.vals = removecats(obj.vals);
            obj.modified();
        end
        
        function vals = getValues(objArray,ranges)
            if nargin < 2 || isempty(ranges)
                vals = vertcat(horzcat(objArray.vals));
                return
            end
            vals = repmat(objArray(1).vals(1),numel(ranges),numel(objArray));
            for i = 1:numel(objArray)
                [keep,idx] = ismember(objArray(i).ranges,ranges);
                idx(idx == 0) = [];
                v = objArray(i).vals(keep);
                vals(:,i) = v(idx);
            end
        end

        function setColor(obj,groupName,clr)
            if isa(clr,'java.awt.Color')
                clr = [clr.getRed(),clr.getGreen(),clr.getBlue()] / 255;
            end
            obj.colors(groupName) = clr;
            obj.modified();
        end
        
        function clr = getColorsInOrder(obj)
            clr = zeros(numel(obj.vals),3);
            v = cellstr(deStar(obj.vals));
            for i = 1:numel(obj.vals)
                clr(i,:) = obj.colors(v{i});
            end
        end
        
        function clr = getColorsForRanges(obj,ranges)
            clr = zeros(numel(ranges),3);
            v = cellstr(deStar(obj.getValues(ranges)));
            for i = 1:numel(v)
                clr(i,:) = obj.colors(v{i});
            end
        end
        
        function k = getSortedColorKeys(obj)
            k = categorical(keys(obj.colors));
            [~,idx] = sort(cat2num(k));
            k = cellstr(k(idx));
        end
        
        function updateColors(objArray)
            for i = 1:numel(objArray)
                obj = objArray(i);
                oldvals = keys(obj.colors);
                newvals = categories(deStar(obj.vals));
                deletedvals = setdiff(oldvals,newvals);
                addedvals = setdiff(newvals,oldvals);
                remove(obj.colors,deletedvals);
                for j = 1:numel(addedvals)
                    usedColors = cell2mat(values(obj.colors)');
                    if isempty(usedColors)
                        usedColors = [1 1 1];
                    end
                    obj.colors(addedvals{j}) = distinguishable_colors(1,usedColors);
                end
                obj.colors('<ignore>') = [.9 .9 .9];
            end
            objArray.modified();
        end
        
        function clr = getColors(obj)
            clr = obj.colors;
        end
        
        function jClr = getJavaColors(obj)
            k = keys(obj.colors);
            jClr = containers.Map();
            for i = 1:numel(k)
                c = obj.colors(k{i});
                jClr(k{i}) = java.awt.Color(c(1),c(2),c(3));
            end
        end
        
        function sortRanges(obj,ranges)
            if numel(ranges) ~= numel(obj.ranges)
                error('Number of ranges must match.');
            end
            [~,order] = ismember(ranges,obj.ranges);
            obj.ranges = ranges(:);
            obj.vals = obj.vals(order);
            obj.sorted = true;
            obj.modified();
        end
    end
    
    methods(Static)
        function fromStruct(s,objArray)
            fromStruct@Descriptions(s,objArray);
        end
    end
end