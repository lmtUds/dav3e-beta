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

classdef Grouping < RangeAnnotation
    properties
        %
    end
    
    methods
        function obj = Grouping()
            obj = obj@RangeAnnotation();
            obj.setCaption('grouping');
            obj.defaultValue = '<ignore>';
            obj.vals = categorical();
            obj.updateColors();
        end
        
        function s = toStruct(objArray)
            s = toStruct@RangeAnnotation(objArray);
            for i = 1:numel(objArray)
                obj = objArray(i);
                s(i).categories = categories(removecats(obj.vals));
                s(i).order = double(removecats(obj.vals));
                colors = cell(numel(s(i).categories),1);
                for j = 1:numel(s(i).categories)
                    colors{j} = obj.colors(s(i).categories{j});
                end
                s(i).colors = colors;
            end
        end
        
        function json = jsondump(objArray)
            s = objArray.toStruct();
            json = jsonencode(s);
        end     
        
        function setGroup(obj,group,range)
            mask = ismember(obj.ranges, range);
            if ischar(group)
                group = {group};
            end
            obj.vals(mask) = group;
        end
        
        function vals = getValues(objArray,ranges)
            if nargin < 2
                ranges = [];
            end
            vals = objArray.getValues@RangeAnnotation(ranges);
            if ~iscategorical(vals)
                vals = categorical(vals);
            end
            vals = removecats(vals);
        end        
        
        function groups = getGroups(objArray) % TODO: rename, groups is already reserved for the "categories"
            groups = objArray.getValues();
        end
        
        function cats = getCategories(objArray)
            cats = categories(removecats(objArray.getValues()));
            cats(ismember(cats,'<ignore>')) = [];
        end
        
        function cats = getDestarredCategories(objArray)
            cats = objArray.getCategories();
            cats = cellstr(unique(deStar(cats)));
        end
        
        function makeColorGradient(obj,baseColor,ignore)
            if nargin < 3
                ignore = {};
            end
            cats = obj.getDestarredCategories();
            cats(ismember(cats,ignore)) = [];
            [~,idx] = sort(cellfun(@str2double,cats));
            cats = cats(idx);
            clrs = colorGradient((baseColor+1)/2,baseColor/2,numel(cats));
            for i = 1:numel(cats)
                obj.setColor(cats{i},clrs(i,:));
            end
            obj.updateColors();
        end
        
        function makeColorGradientHSV(obj,baseColor,baseColor2,ignore)
            if nargin < 4
                ignore = {};
            end
            cats = obj.getDestarredCategories();
            cats(ismember(cats,ignore)) = [];
            [~,idx] = sort(cellfun(@str2double,cats));
            cats = cats(idx);
            clrs = colorGradientHSV(baseColor,baseColor2,numel(cats));
            for i = 1:numel(cats)
                obj.setColor(cats{i},clrs(i,:));
            end
            obj.updateColors();
        end           
        
        function replaceGroup(obj,oldGroup,newGroup)
            obj.vals(obj.vals==oldGroup) = newGroup;
            obj.vals = removecats(obj.vals);
            obj.colors(newGroup) = obj.colors(oldGroup);
            obj.updateColors();
        end
        
        function target = getTargetVector(obj,ranges,cluster)
            if ~exist('ranges','var') || isempty(ranges)
                ranges = obj.ranges;
            else
                if ~obj.sorted
                    error('Grouping must be sorted first. Proceed to module "FeatureDefinition", or use menu:Grouping:"set current grouping". Then retry.');
                end
            end
            pos = ranges.getCyclePosition(cluster);
%             lengths = ranges.getNCycles(cluster);
            groups = obj.getValues(cluster.getCycleRanges());
%             target = repelem(groups,lengths);
            target = categorical(nan(cluster.nCycles,1));
            for i = 1:numel(groups)
                target(pos(i,1):pos(i,2)) = groups(i);
            end
        end
    end
    
    methods(Static)
        function groupings = fromStruct(s,ranges)
            groupings = Grouping.empty;
            for i = 1:numel(s)
                g = Grouping();
                g.ranges = ranges;
                g.vals = categorical(s(i).categories(s(i).order));
                for j = 1:numel(s(i).categories)
                    if iscell(s(i).colors)
                        g.colors(s(i).categories{j}) = s(i).colors{j};
                    else
                        g.colors(s(i).categories{j}) = s(i).colors(j,:);
                    end
                end
                groupings(end+1) = g; %#ok<AGROW>
            end
            fromStruct@RangeAnnotation(s,groupings)
        end
        
        function ranges = jsonload(json)
            data = jsondecode(json);
            ranges = Grouping.fromStruct(data);
        end
    end
end