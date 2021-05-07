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
%         block
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
        function setBlock(obj, block)
            obj.block = block;
            obj.update();
        end
        function block = getBlock(obj)
            block = obj.block;
        end
    end
    
    methods (Access = protected)
        function setup(obj)
            %TODO compute value count from paramObj
            obj.grid = uigridlayout(obj,...
                'RowSpacing',2,...
                'Padding',[0 0 0 0]);
        end
        function update(obj)
            %TODO proper call to parameter values and names
            blockName = uilabel(obj.grid,...
                'Text',obj.block.shortCaption,...
                'FontWeight','bold',...
                'FontSize',8);
            blockName.Layout.Row = 1;
            blockName.Layout.Column = [1 2];
            for i = 1:numel(obj.block.parameters)
                p = obj.block.parameters(i);
                label = uilabel(obj.grid,...
                    'Text',p.shortCaption,...
                    'FontSize',8);
                label.Layout.Row = i+1;
                label.Layout.Column = 1;
                
                edit = uieditfield(obj.grid,...
                    'Editable','on',...
                    'Value',num2str(p.value),...
                    'FontSize',8);
                edit.Layout.Row = i+1;
                edit.Layout.Column = 2;
                drawnow;
            end
        end
    end
    methods (Access = private)
    end
end

