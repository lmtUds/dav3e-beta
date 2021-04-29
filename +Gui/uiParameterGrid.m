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

classdef uiParameterGrid < matlab.ui.componentcontainer.ComponentContainer
    %PARAMETERGRID A grid style ui container to display and edit program
    %runtime parameters
    
    properties
        grid
        parameters
        selectedParameter
        uiParent
    end
    
    events
        parameterEdit
        parameterSelect
    end
    
    methods
        function obj = uiParameterGrid(uiParent)
            %PARAMETERGRID Construct an instance of a parameter grid
            obj.grid = uigridlayout(uiParent);
            obj.parameters = [];
        end
        
        function addParameter(obj, param)
            obj.parameters = [obj.parameters,param];
            obj.refresh();
        end
        
        function clear(obj)
            obj.grid.delete();
            obj.parameters = [];
            obj.grid = uigridlayout(obj.uiParent);
        end
        
        function deleteParameter(obj, param)
            ind = obj.getParameterIndex(param);
            obj.parameters = ...
                [obj.parameters(1:ind-1),obj.parameters(ind+1:end)];
            obj.refresh();
        end
        
        function parameters = getAllParameters(obj)
            parameters = obj.parameters;
        end
        
        function param = getParameter(obj, identifier)
            if isnumeric(identifier)
               param = obj.parameters(identifier);
            else
               % TODO
               param = 'foo'; 
            end
        end
        
        function index = getParameterIndex(obj, param)
            index = [];
            for i = 1:numel(obj.parameters)
                % TODO how to compare parameters properly
                if param == obj.parameters(i)
                    index = i;
                    return
                end
            end
            if isempty(index)
                warning('parameter could not be found');
                index = 1;
            end
        end
        
        function moveParameter(obj, param, direction)
            ind = obj.getParameterIndex(param);
            switch direction
                case 'up'
                    if ind == 1
                        warning('Top parameter cannot move further up.')
                        return
                    end
                    obj.parameters(ind) = obj.parameters(ind-1);
                    obj.parameters(ind-1) = param;
                case 'down'
                    if ind == numel(obj.parameters)
                        warning('Bottom parameter cannot move further down.')
                        return
                    end
                    obj.parameters(ind) = obj.parameters(ind+1);
                    obj.parameters(ind+1) = param;
            end
            obj.refresh();
        end
        
        function parameterEditCallback(obj, src, event)
            % TODO
        end
        
        function parameterSelectCallback(obj, src, event)
            % TODO
        end
        
        function refresh(obj)
            % TODO
        end
    end
end

