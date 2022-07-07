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

classdef Parameter < Descriptions
    properties
        value
        editable
        bounds
        enum
        nValuesBounds
        hidden
        selectionType
        internal
    end
    
    properties (Transient)
        onChangedCallback
    end
    
    methods
        function obj = Parameter(varargin)
            p = inputParser();
            p.addParameter('shortCaption','');
            p.addParameter('caption','');
            p.addParameter('description','');
            p.addParameter('value',[]);
            p.addParameter('editable',true);
            p.addParameter('bounds',[]);
            p.addParameter('enum',{});
            p.addParameter('nValuesBounds',[]);
            p.addParameter('hidden',false);
            p.addParameter('selectionType','single');
            p.addParameter('internal',false);
            p.parse(varargin{:});
            
            obj@Descriptions();
            obj.setShortCaption(p.Results.shortCaption);
            obj.setCaption(p.Results.caption);
            obj.setDescription(p.Results.description);
            obj.value = p.Results.value;
            obj.editable = p.Results.editable;
            obj.bounds = p.Results.bounds;
            obj.enum = p.Results.enum;
            obj.nValuesBounds = p.Results.nValuesBounds;
            obj.hidden = p.Results.hidden;
            obj.selectionType = p.Results.selectionType;
            obj.internal = p.Results.internal;
            
            if isempty(obj.caption) || (obj.caption == string(''))
                obj.setCaption(obj.shortCaption);
            end
        end
        
        function cap = getValueCaptions(obj)
            if ~iscell(obj.value)
                try
                    cap = char(obj.value.getCaption());
                catch
                    cap = obj.value;
                end
            else
                cap = cell(size(obj.value));
                for i = 1:numel(obj.value)
                    v = obj.value{i};
                    try
                        cap{i} = char(v.getCaption());
                    catch
                        cap{i} = v;
                    end
                end
            end
        end
        
        function cap = getEnumCaptions(obj)
            cap = cell(size(obj.enum));
            for i = 1:numel(obj.enum)
                e = obj.enum{i};
                try
                    cap{i} = char(e.getCaption());
                catch
                    cap{i} = e;
                end
            end
        end
        
        function setValue(obj,value)
            function out = allpurpose_cmp(in1,in2)
                if ischar(in1) || ischar(in2)
                    out = strcmp(in1,in2);
                else
                    out = in1 == in2;
                end
            end
        
%             if ~isempty(obj.enum)% && ~any(ismember(value,obj.enum))
%                 enumCaptions = string(obj.getEnumCaptions());
%                 isContained = false(size(obj.enum));
%                 if iscell(value)
%                     for i = 1:numel(value)
%                         for j = 1:numel(obj.enum)
%                             if allpurpose_cmp(value{i},obj.enum{j}) || allpurpose_cmp(value{i},enumCaptions{j})
%                                 isContained(j) = true;
%                                 break
%                             end
%                         end
%                     end
%                 else
%                     if ischar(value)
%                         value = string(value);
%                     end
%                     for j = 1:numel(obj.enum)
%                         if (value == obj.enum{j}) || (value == enumCaptions{j})
%                             isContained(j) = true;
%                             break
%                         end
%                     end
%                 end
%                 sameCaption = find(isContained);
%                 if sameCaption
%                     if iscell(value)
%                         obj.value = obj.enum(sameCaption);
%                     else
%                         obj.value = obj.enum{sameCaption};
%                     end
%                 end
%             elseif isnumeric(value) && ~isempty(obj.bounds)
%                 if (value >= obj.bounds(1)) && (value <= obj.bounds(2))
%                     obj.value = value;
%                 end
%             else
%                 obj.value = value;
%             end
            obj.value = value;
            obj.modified()
        end
        
        function setValueSilent(obj,value)
            % TODO
        end
        
        function value = getValue(obj)
            value = obj.value;
        end
        
        function p = getByCaption(objArray,caption)
            p = objArray(objArray.getCaption() == caption);
        end
        
        function s = getStruct(objArray)
            if isempty(objArray)
                s = struct();
                return
            end
            s = cell2struct({objArray.value},cellstr(objArray.getShortCaption()),2);
        end
        
        function updateFromStruct(objArray,s)
            shortCaptions = cellstr(objArray.getShortCaption());
            fields = fieldnames(s);
            [~,idx] = ismember(fields,shortCaptions);
            for i = 1:numel(fields)
                if idx(i) > 0
                    objArray(idx(i)).setValue(s.(fields{i}));
                end
            end
%             for i = 1:numel(fields)
%                 idx = ismember(shortCaptions,fields{i});
%                 if ~any(idx)
% %                     error('Parameter with short caption not found.');
%                     continue
%                 end
%                 objArray(idx).setValue(s.(fields{i}));
%             end
        end
        
        function m = getMap(objArray)
            m = containers.Map(cellstr(objArray.getCaption()),...
                {objArray.value});
%             m = containers.Map();
%             for i = 1:numel(objArray)
%                 m(char(objArray(i).getCaption())) = objArray(i).value;
%             end
        end
        
        function m = getMapWithUUIDRefs(objArray)
            m = objArray.getMap();
            k = keys(m);
            for i = 1:numel(k)
                try
                    % regex: ^([0-9a-zA-Z]+)::(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})$
                    m(k{i}) = string(class(m(k{i}))) + '::' + m(k{i}).getUUID();
                catch
                    % never mind, value is hopefully okay
                end
            end
        end
        
        function resolveUUIDRefs(objArray,project)
            for i = 1:numel(objArray)
                objArray(i).value = project.resolveUUIDRefs(objArray(i).value);
            end
        end
    end
end