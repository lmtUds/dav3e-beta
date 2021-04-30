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
        grid
        blocks
        selectedBlock
    end
    
    events (HasCallbackProperty, NotifyAccess = protected)
        blockEdit %might not be needed
        blockSelect
    end
    
    methods
        function addBlock(obj, block)
            obj.blocks = [obj.blocks,block];
            obj.update();
        end
        
        function clear(obj)
            obj.grid.Children.delete();
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
        
        function moveBlock(obj, block, direction)
            ind = obj.getBlockIndex(block);
            switch direction
                case 'up'
                    if ind == 1
                        warning('Top parameter block cannot move further up.')
                        return
                    end
                    obj.blocks(ind) = obj.blocks(ind-1);
                    obj.blocks(ind-1) = block;
                case 'down'
                    if ind == numel(obj.blocks)
                        warning('Bottom parameter block cannot move further down.')
                        return
                    end
                    obj.blocks(ind) = obj.blocks(ind+1);
                    obj.blocks(ind+1) = block;
            end
            obj.update();
        end
        
        function blockEditCallback(obj, src, event)
            % TODO
        end
        
        function blockSelectCallback(obj, src, event)
            % TODO
        end
    end
    methods (Access = protected)
        function setup(obj)
            % TODO
            obj.grid = uigridlayout(obj, [1 1],...
                'RowSpacing',4,...
                'Padding',[0 0 0 0]);
            obj.blocks = [];
        end
        
        function update(obj)
            % TODO finish and correct
            for i = 1:numel(obj.blocks)
                uiParam = Gui.uiParameterBlock('Parent',obj.grid,...
                    'blockObject',obj.blocks(i));
                uiParam.Layout.Row = i;
            end
        end
    end
end

