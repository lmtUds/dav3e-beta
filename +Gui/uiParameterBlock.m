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

classdef uiParameterBlock < matlab.ui.componentcontainer.ComponentContainer
    %UIPARAMETER A ui container for displaying and editing parameters of a 
    %dataprocessingblock
    
    properties
        block
    end
    
    properties (Access = private)
        category
        displayName
        grid
        shortName = '';
    end
    
    events (HasCallbackProperty, NotifyAccess = protected)
        edit
        select
    end
    
    methods
    end
    
    methods (Access = protected)
        function setup(obj)
            %TODO compute value count from paramObj
            valueCount = 5;
            obj.grid = uigridlayout(obj,...
                [valueCount 2],...
                'RowSpacing',2,...
                'Padding',[0 0 0 0]);
            obj.populateUi();
        end
        function update(obj)
            
        end
    end
    methods (Access = private)
        function populateUi(obj)
            %TODO proper call to parameter values and names
            for i = 1:numel(obj.block.values)
                label = uilabel(obj.grid,'Text',obj.block.names(i));
                label.Layout.Row = i;
                label.Layout.Column = 1;
                
                edit = uieditfield(obj.grid,'Editable','on',...
                    'Value',obj.paramObj.values(i));
                edit.Layout.Row = i;
                edit.Layout.Column = 2;
            end
        end
    end
end

