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
%     end
%     properties (Access = private)
        blocks
        categories
        collapsedCategories
        columnRatio = {'3x','1x'};
        lineHeight = 22;
        panel
        selectedBlock
        skippedBlocks
    end
    
    events (HasCallbackProperty, NotifyAccess = protected)
        ValueChanged
        SelectionChanged
    end
    
    methods
        function addBlocks(obj, blocks)
            obj.blocks = [obj.blocks,blocks];
            if length(obj.blocks)>=1
                obj.selectedBlock = obj.blocks(1);
            end
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
            
            % TODO handle selected block deletion
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
        
        function selectedblock = getSelectedBlock(obj)
            selectedblock = obj.selectedBlock;
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
                
        function valueEditCallback(obj, src, event, param)
            param.value = event.Value;
            notify(obj,'ValueChanged');
        end
        
        function blockSelectCallback(obj, src, event)
            node = event.SelectedNodes;
            obj.selectedBlock = node.NodeData(1);
            notify(obj,'SelectionChanged');
        end
        
        function collapseCallback(obj, src, event)
            % get the data stored in the relevant tree node
            dat = event.Node.NodeData;
            if size(dat,2) > 1  %handle a category
                cmp = event.Node.Text == obj.categories;
                obj.collapsedCategories(cmp) = 1;
            else %handle a block
                dat.collapsed = 1;
            end
            obj.update();
        end
        
        function expandCallback(obj, src, event)
            % get the data stored in the relevant tree node
            dat = event.Node.NodeData;
            if size(dat,2) > 1  %handle a category
                cmp = event.Node.Text == obj.categories;
                obj.collapsedCategories(cmp) = 0;
            else %handle a block
                dat.collapsed = 0;
            end
            obj.update();
        end
        
        function multiSelParamCallback(obj, btn, event, parameter)
            %setup indexing of the enumerator and find already selected
            %values 
            prevSelectionInd = 1:max(size(parameter.enum));
            contained = strcmp(parameter.value,parameter.enum);
            %prompt the user to select from the whole enumerator space with
            %multiple selection allowed
            [selection,exitStatus] = listdlg('ListString',parameter.enum,...
                'InitialValue',prevSelectionInd(contained),...
                'Name','Multiple Selection',...
                'PromptString',['Select multiple ''', char(parameter.shortCaption),'''']);
            if exitStatus %a selection happened so we update
                %setup a fake event to pass to the valueEditCallback
                fakeEvent = struct();
                fakeEvent.Value = parameter.enum(selection);
                %process the value edit and update the ui element
                obj.valueEditCallback(btn,fakeEvent,parameter);
                obj.update();
            end
        end
    end
    methods (Access = protected)
        function setup(obj)
            % TODO
            obj.panel = uipanel(obj,'BorderType','none','BackgroundColor','white');
            obj.blocks = [];
        end
        
        function update(obj)
            % empty the exixsting grid
            obj.panel.Children.delete();
            % do nothing if we have no blocks
            if isempty(obj.blocks)
                return
            end
            
            % group all blocks into their respective categories
            groupedBlocks = {};
            for i = 1:numel(obj.blocks) %loop through all blocks
               c = obj.blocks(i).type; 
               cmp = c == obj.categories;   %check if category is known
               if sum(cmp) == 0 % append if not
                   obj.categories = [obj.categories c];
                   obj.collapsedCategories = [obj.collapsedCategories 0];
                   cmp = [cmp 1];
               end
               % append the current block to its appropriate category group
               if isempty(groupedBlocks)
                  groupedBlocks{cmp} = obj.blocks(i);
               elseif size(groupedBlocks,2) < size(cmp,2)%isempty(groupedBlocks{cmp})
                  groupedBlocks{cmp} = obj.blocks(i); 
               else
                  groupedBlocks{cmp} = [groupedBlocks{cmp} obj.blocks(i)];
               end
            end
            % eliminate empty(containing no blocks) categories
            delInd = [];
            for k = 1:numel(obj.categories)
               if isempty(groupedBlocks{k})
                   delInd = [delInd k];
               end
            end
            obj.categories(delInd) = [];
            % compute the number of needed grid rows as dynamic adding to
            % the grid causes unwanted shrinking or stretching of elements
            % also generate a mapping for all row heights to fit contents
            % properly into the grid
            rowCount = 0;
            heights = {};
            charHeight = {obj.lineHeight};
            for k = 1:numel(obj.categories)
                rowCount = rowCount + 1; %row per category header
                heights = [heights charHeight];
                if obj.collapsedCategories(k) %no lines for collapsed children
                    continue
                end
                for i = 1:numel(groupedBlocks{k})
                    rowCount = rowCount + 1;    %row per block in the category
                    heights = [heights charHeight];
                    if groupedBlocks{k}(i).collapsed %no lines for collapsed children
                        continue
                    end
                    for j = 1:numel(groupedBlocks{k}(i).parameters)
                        if groupedBlocks{k}(i).parameters(j).internal
                            continue
                        end
                        rowCount = rowCount + 1; %row per parameter in the block
                        heights = [heights charHeight];
                    end
                end
            end
            if rowCount == 0    % abort if there are no blocks/parameters
                return
            end
            rowCount = rowCount + 1; % append a blank row to fill space
            heights = [heights {'1x'}];
            
            % initialize a grid of proper size
            grid = uigridlayout(obj.panel, [rowCount 2],...                
                'Scrollable','on',...%'BackgroundColor','white',...
                'ColumnWidth',obj.columnRatio,...
                'ColumnSpacing',0,...
                'RowSpacing',0,...
                'RowHeight',heights,...
                'Padding',[0 0 0 0]);
            
            % fill the left column with the tree structure
            tree = uitree(grid,...%'BackgroundColor',[.94 .94 .94],...
                'SelectionChangedFcn',@(src, event) obj.blockSelectCallback(src, event),...
                'NodeExpandedFcn',@(src,event) obj.expandCallback(src,event),...
                'NodeCollapsedFcn',@(src,event) obj.collapseCallback(src,event));
            tree.Layout.Row = [1 rowCount];
            tree.Layout.Column = 1;
            
            rowCount = 1;    %reuse the counter to fill grid rows correctly
            for k = 1:numel(obj.categories) %loop through all categories
                category = uitreenode(tree,...
                        'Text',char(obj.categories(k)),...
                        'NodeData',groupedBlocks{k});
                
                rowCount = rowCount + 1;   %advance to the next row 
                for i = 1:numel(groupedBlocks{k}) %loop through all blocks
                    b = groupedBlocks{k}(i);

                    % create a label for the block name
                    block = uitreenode(category,...
                        'Text',b.shortCaption,...
                        'NodeData',b);
                    if ~obj.collapsedCategories(k)
                        rowCount = rowCount + 1;   %advance to the next row                
                    end
                    for j = 1:numel(b.parameters)   %loop through all parameters
                        p = b.parameters(j);

                        if p.internal   %skip internal parameters
                            continue
                        end

                        %create a label for the parameter
                        paramNode = uitreenode(block,...
                            'Text',p.shortCaption,...
                            'NodeData',b);
                        %create the matching right side entry for the 
                        %parameter value of non collapsed blocks
                        if ~b.collapsed && ~obj.collapsedCategories(k)
                            try 
                                if ~isempty(p.enum) %single or multi choice from a selection
                                    switch p.selectionType
                                        case 'single'
                                            if iscell(p.value)
                                                value = p.value{1};
                                            else
                                                value = p.value;
                                            end
                                            paramEntry = uidropdown(grid,...
                                                'Value',value,...
                                                'Items',p.enum,...
                                                'ValueChangedFcn',@(src,event) obj.valueEditCallback(src,event,p));
                                        case 'multiple'
                                            %gather how many of the allowed
                                            %multiples were selected
                                            selectRatioText = ...
                                                ['Sel. ',num2str(max(size(p.value))),...
                                                '/',num2str(max(size(p.enum)))];
                                            %create a button to invoke a
                                            %selection dialog
                                            paramEntry = uibutton(grid,...
                                                'Text',selectRatioText,...
                                                'ButtonPushedFcn',@(btn,event) obj.multiSelParamCallback(btn,event,p));
%                                             paramEntry = uilabel(grid,...
%                                                 'Text','TBD');
%                                             edit = uilabel(grid,...
%                                                 'Text',strjoin(p.value,';'));
                                    end
                                elseif islogical(p.value) %binary flag
                                    if ~p.editable
                                        if p.value
                                            labelText = 'true';
                                        else
                                            labelText = 'false';
                                        end
                                        paramEntry = uilabel(grid,...
                                            'Text',labelText,...
                                            'HorizontalAlignment','center');
                                    else
                                        paramEntry = uicheckbox(grid,...
                                            'Text','','Value',p.value,...
                                            'ValueChangedFcn',@(src,event) obj.valueEditCallback(src,event,p));
                                    end
                                elseif isnumeric(p.value) %numeric value
                                    if ~p.editable
                                        paramEntry = uilabel(grid,...
                                            'Text',num2str(p.value),...
                                            'HorizontalAlignment','center');
                                    else
                                        paramEntry = uieditfield(grid,...
                                            'numeric',...
                                            'Editable','on',...
                                            'HorizontalAlignment','left',...
                                            'Value',p.value,...
                                            'ValueChangedFcn',@(src,event) obj.valueEditCallback(src,event,p));
                                    end
                                else %text value
                                    if ~p.editable
                                        paramEntry = uilabel(grid,...
                                            'Text',p.value,...
                                            'HorizontalAlignment','center');
                                    else
                                        paramEntry = uieditfield(grid,...
                                            'Editable','on',...
                                            'HorizontalAlignment','left',...
                                            'Value',p.value,...
                                            'ValueChangedFcn',@(src,event) obj.valueEditCallback(src,event,p));
                                    end
                                end
                                paramEntry.Layout.Row = rowCount;
                                paramEntry.Layout.Column = 2;
                            catch ME
                               disp(ME) 
                               p.value
                               p.enum
                            end
                            rowCount = rowCount + 1;   %advance to the next row
                        end
                    end
                    if b.collapsed
                        collapse(block);
                    else
                        expand(block);
                    end
                end
                if obj.collapsedCategories(k)
                    collapse(category);
                else 
                    expand(category);
                end
            end
        end
    end
end

