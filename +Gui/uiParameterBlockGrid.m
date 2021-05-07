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

classdef uiParameterBlockGrid < matlab.ui.componentcontainer.ComponentContainer
    %PARAMETERGRID A grid style ui container for uiParameterBlock instances
    
    properties
    end
    properties (Access = private)
        blocks
        panel
        selectedBlock
    end
    
    events (HasCallbackProperty, NotifyAccess = protected)
        blockEdit %might not be needed
        blockSelect
    end
    
    methods
        function addBlocks(obj, blocks)
            obj.blocks = [obj.blocks,blocks];
            obj.update();
        end
        
        function clear(obj)
            obj.panel.Children.delete();
            obj.blocks = [];
        end
        
        function deleteBlock(obj, block)
            ind = obj.getBlockIndex(block);
            obj.blocks = ...
                [obj.blocks(1:ind-1),obj.blocks(ind+1:end)];
            obj.update();
        end
        
        function blocks = getAllBlocks(obj)
            blocks = obj.blocks;
        end
        
        function block = getBlock(obj, identifier)
            if isnumeric(identifier)
               block = obj.blocks(identifier);
            else
               % TODO
               block = 'foo'; 
            end
        end
        
        function index = getBlockIndex(obj, block)
            index = [];
            for i = 1:numel(obj.blocks)
                % TODO how to compare parameters properly
                if block == obj.blocks(i)
                    index = i;
                    return
                end
            end
            if isempty(index)
                warning('parameter block could not be found');
                index = 1;
            end
        end
                
        function blockEditCallback(obj, src, event, block)
            % TODO
        end
        
        function blockSelectCallback(obj, src, event, block)
            % TODO
        end
    end
    methods (Access = protected)
        function setup(obj)
            % TODO
            obj.panel = uipanel(obj);
            obj.blocks = [];
        end
        
        function update(obj)
            % empty the exixsting grid
            obj.panel.Children.delete();
            
            % compute the number of needed grid rows as dynamic adding to
            % the grid causes unwanted shrinking or stretching of elements
            % also generate a mapping for all row heights to fit contents
            % properly into the grid
            rowCount = 0;
            heights = {};
            for i = 1:numel(obj.blocks)
                rowCount = rowCount + 1;
                heights = [heights {15}];
                for j = 1:numel(obj.blocks(i).parameters)
                    if obj.blocks(i).parameters(j).internal
                        continue
                    end
                    rowCount = rowCount + 1;
                    heights = [heights {13}];
                end
                rowCount = rowCount + 1;
                heights = [heights {3}];
            end
            
            if rowCount == 0    % abort if there are no blocks/parameters
                return
            end
            % initialize a grid of proper size
            grid = uigridlayout(obj.panel, [rowCount 2],...                
                'Scrollable','on',...
                'ColumnWidth',{'2x','1x'},...
                'RowHeight',heights,...
                'RowSpacing',2,...
                'Padding',[2 2 2 2]);
            % TODO group by category
            
            rowCount = 1;    %reuse the counter to fill grid rows correctly
            for i = 1:numel(obj.blocks) %loop through all blocks
                b = obj.blocks(i);
                
                % create a label for the block name
                blockName = uilabel(grid,...
                    'Text',b.shortCaption,...
                    'FontWeight','bold');
                blockName.Layout.Row = rowCount;
                blockName.Layout.Column = [1 2];
                
                rowCount = rowCount + 1;   %advance to the next row                
                for j = 1:numel(b.parameters)   %loop through all parameters
                    p = b.parameters(j);
                    
                    if p.internal   %skip internal parameters
                        continue
                    end
                    
                    %create a label for the parameter
                    label = uilabel(grid,...
                        'Text',p.shortCaption);
                    label.Layout.Row = rowCount;
                    label.Layout.Column = 1;
                    
                    %create the edit field for the parameter value
                    if isnumeric(p.value)
                        edit = uieditfield(grid,...
                            'numeric',...
                            'Editable','on',...
                            'Value',p.value);
                    else
                        edit = uieditfield(grid,...
                            'Editable','on',...
                            'Value',p.value);
                    end
                    edit.Layout.Row = rowCount;
                    edit.Layout.Column = 2;
                    
                    rowCount = rowCount + 1;   %advance to the next row
                end
                % draw a divider line for better visual separation
                divLine = repmat('-',1,240);
                divider = uilabel(grid,...
                    'Text',divLine,...
                    'FontSize',2,...
                    'HorizontalAlignment','center');
                divider.Layout.Row = rowCount;
                divider.Layout.Column = [1 2];
                
                rowCount = rowCount + 1;   %advance to the next row
            end
        end
    end
end

