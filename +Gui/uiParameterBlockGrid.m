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
        grid
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
            % TODO finish and correct
            
            % empty the exixsting grid
            obj.panel.Children.delete();
            
            % compute the number of needed grid rows as dynamic adding to
            % the grid causes unwanted shrinking or stretching of elements
            rowCount = 0;
            for i = 1:numel(obj.blocks)
                for j = 1:numel(obj.blocks(i).parameters)
                    if obj.blocks(i).parameters(j).internal
                        continue
                    end
                    rowCount = rowCount + 1;
                end
                rowCount = rowCount + 1;
            end
            if rowCount == 0    % abort if there are no blocks/parameters
                return
            end
            % initialize a grid of proper size
            obj.grid = uigridlayout(obj.panel, [rowCount 2],...
                'Scrollable','on',...
                'ColumnWidth',{'1x'},...
                'RowHeight',{12},...
                'RowSpacing',2,...
                'Padding',[2 2 2 2]);
            % TODO group by category
            
            rowCount = 1;    %reuse the counter to fill grid rows correctly
            for i = 1:numel(obj.blocks) %loop through all blocks
                b = obj.blocks(i);
                
                % create a label for the block name
                blockName = uilabel(obj.grid,...
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
                    label = uilabel(obj.grid,...
                        'Text',p.shortCaption);
                    label.Layout.Row = rowCount;
                    label.Layout.Column = 1;
                    
                    %create the edit field for the parameter value
                    edit = uieditfield(obj.grid,...
                        'Editable','on',...
                        'Value',num2str(p.value));
                    edit.Layout.Row = rowCount;
                    edit.Layout.Column = 2;
                    
                    rowCount = rowCount + 1;   %advance to the next row
                end                
%                 uiParamBlock = Gui.uiParameterBlock('Parent',obj.grid,...
%                     'block',obj.blocks(i));
%                 uiParamBlock.Layout.Row = i;
%                 uiParamBlock.setBlock(obj.blocks(i));
            end
        end
    end
end

