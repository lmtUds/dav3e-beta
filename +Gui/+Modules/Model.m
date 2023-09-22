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

classdef Model < Gui.Modules.GuiModule
    properties
        caption = 'Model'
        
        currentFeatureDefinitionSet = FeatureDefinitionSet.empty;
        currentFeatureDefinitionTag
        ranges = GraphicsRange.empty;
        
        cycleLines
        previewLines
        
        tabGroup
        setDropdown
        detailsLayout
        tabLayout
        dynamicGrid
        parametersDropdownPanel
        errorPanel
        parameterPopups
        
        featurePreviewX
        featurePreviewY
        
        rangeTable
        propGrid
        
        addDataTipRowsMenu
    end
    
    properties (Dependent)
        currentModel
    end
    
    methods
        function obj = Model(main)
            %% constructor
            obj@Gui.Modules.GuiModule(main);
        end
        
        function val = get.currentModel(obj)
            val = obj.getProject().currentModel;
        end
        
        function set.currentModel(obj,val)
            obj.getProject().currentModel = val;
        end      
                       
        function [moduleLayout,moduleMenu] = makeLayout(obj,uiParent,mainFigure)
            %%
            %Define the main three column module layout
            moduleLayout = uigridlayout(uiParent,[1 3],...
                'Visible','off',...
                'Padding',[0 0 0 0],...
                'ColumnWidth',{'2x','5x',0},...
                'RowHeight',{'1x'},...
                'RowSpacing',7);
            
            %Add the menubar item for this module
            moduleMenu = uimenu(mainFigure,'Label','Model');
            obj.addDataTipRowsMenu = uimenu(moduleMenu,...
                'Label','scatter plots: add offset, cycle, and grouping info to data tips (time-consuming!)',...
                'Checked','off',...
                getMenuCallbackName(),@obj.addDataTipRowsMenuClicked);
            
            %Create the grid to house the model definition section in the
            %leftmost column
            defsGrid = uigridlayout(moduleLayout, [5 4],...
                'ColumnWidth',{'2x','2x','1x','1x'},...
                'RowHeight',{'fit','fit','15x','fit',40},...
                'RowSpacing',4,...
                'Padding',[0 0 0 0]);
            defsGrid.Layout.Row = 1;
            defsGrid.Layout.Column = 1;
            
            defsLabel = uilabel(defsGrid,...
                'Text','Model',...
                'FontWeight','bold');
            defsLabel.Layout.Row = 1;
            defsLabel.Layout.Column = [1 4];
            
            defsDropdown = uidropdown(defsGrid,...
                'Editable','on',...
                'ValueChangedFcn',@(src,event) obj.dropdownModelCallback(src,event));
            defsDropdown.Layout.Row = 2;
            defsDropdown.Layout.Column = [1 2];
            
            defsAdd = uibutton(defsGrid,...
                'Text','+',...
                'ButtonPushedFcn',@(src,event) obj.dropdownNewModel(src,event,defsDropdown));
            defsAdd.Layout.Row = 2;
            defsAdd.Layout.Column = 3;
            
            defsRem = uibutton(defsGrid,...
                'Text','-',...
                'ButtonPushedFcn',@(src,event) obj.dropdownRemoveModel(src,event,defsDropdown));
            defsRem.Layout.Row = 2;
            defsRem.Layout.Column = 4;
            
%             propGridPanel = uipanel(defsGrid);
%             propGridPanel.Layout.Row = 3;
%             propGridPanel.Layout.Column = [1 4];

            obj.propGrid = Gui.uiParameterBlockGrid('mainFigure',obj.main.hFigure,'Parent',defsGrid,...
                'ValueChangedFcn',@(src,event) obj.updatePropGrid(),...
                'SizeChangedFcn',@(src,event) obj.sizechangedCallback(src,event));%,...
%                 'SelectionChangedFcn',@(src,event) obj.changeCurrentPreprocessing(src,event));
            obj.propGrid.Layout.Row = 3;
            obj.propGrid.Layout.Column = [1 4];
            obj.propGrid.columnRatio = {'4x','2x'};
                        
            % model dropdown
            obj.setDropdown = defsDropdown;           
            
%             obj.propGrid = PropGrid(propGridLayout);
%             obj.propGrid.setShowToolbar(false);
%             propGridControlsLayout = uiextras.HBox('Parent',propGridLayout);
            
            defsElementAdd = uibutton(defsGrid,...
                'Text','Add',...
                'ButtonPushedFcn',@(h,e)obj.addModelChainBlock);
            defsElementAdd.Layout.Row = 4;
            defsElementAdd.Layout.Column = 1;
            
            defsElementDel = uibutton(defsGrid,...
                'Text','Delete...',...
                'ButtonPushedFcn',@(h,e)obj.removeModelChainBlock);
            defsElementDel.Layout.Row = 4;
            defsElementDel.Layout.Column = 2;
            
            defsElementUp = uibutton(defsGrid,...
                'Text','/\',...
                'ButtonPushedFcn',@(h,e)obj.moveModelChainBlockUp);
            defsElementUp.Layout.Row = 4;
            defsElementUp.Layout.Column = 3;
            
            defsElementDwn = uibutton(defsGrid,...
                'Text','\/',...
                'ButtonPushedFcn',@(h,e)obj.moveModelChainBlockDown);
            defsElementDwn.Layout.Row = 4;
            defsElementDwn.Layout.Column = 4;
            
            defsTrain = uibutton(defsGrid,...
                'Text','Train',...
                'ButtonpushedFcn',@(h,e)obj.trainModel);
            defsTrain.Layout.Row = 5;
            defsTrain.Layout.Column = [1 4];

            % This works fine for R2018a (and possibly lower), but causes a
            % fatal Java crash with R2016b (and possibly higher)
            % reason seems to be assigning the panel returned by this 
            % function (with uitabgroup inside) to a new parent after this
            % function has finished
            % if we do it later, all is fine
            % alternatively, MATLAB's native uipanel could be used
            % David Sampson (creater of GUI Layout Toolbox) could so far
            % not reproduce the issue
%             obj.tabGroup = uitabgroup(obj.detailsLayout);
            
            %Create the tabbed container to house the main module display
            tabGroup = uitabgroup(moduleLayout);
            tabGroup.Layout.Row = 1;
            tabGroup.Layout.Column = 2;
            
            obj.tabGroup = tabGroup;
            obj.tabLayout = moduleLayout;
            
            %Create the panel for the parameter adjusting section after
            %training
            
            dynamicGrid = uigridlayout(moduleLayout,[2 1],...
                'Visible','off',...
                'Padding',[0 0 0 0]);
            dynamicGrid.Layout.Row = 1;
            dynamicGrid.Layout.Column = 3;
            obj.dynamicGrid = dynamicGrid;
            
            parameterPanel = uipanel(dynamicGrid,...
                'Title','Adjust Parameters',...
                'BorderType','none',...
                'Visible','off');
            parameterPanel.Layout.Row = 1;
            obj.parametersDropdownPanel = parameterPanel;

            errorPanel = uipanel(dynamicGrid,...
                'Title','Errors',...
                'BorderType','none',...
                'Visible','off');
            errorPanel.Layout.Row = 2;
            obj.errorPanel = errorPanel;
        end
        
        function addDataTipRowsMenuClicked(obj,h,varargin)
            switch h.Checked
                case 'on', h.Checked = 'off';
                case 'off', h.Checked = 'on';
            end
        end
        
        function sizechangedCallback(obj, src, event)
            obj.propGrid.panel.Visible = 'off';
            pos_parent = obj.propGrid.Position;
            obj.propGrid.panel.Position = pos_parent - [0,65,0,11]; %values possibly subject to change 
            obj.propGrid.panel.Visible = 'on';                      % depending on screen resolution?
        end
        
        function addModelChainBlock(obj,desc)
            if nargin < 2
                methods = Model.getAvailableMethods(true);
%                 s = keys(fe);
                s = {};
                c = {};
                fields = fieldnames(methods);
                for i = 1:numel(fields)
                    if numel(keys(methods.(fields{i}))) == 0
                        continue
                    end
                    s = horzcat(s,keys(methods.(fields{i})));
                    c = horzcat(c,repmat(fields(i),1,size(keys(methods.(fields{i})),2)));
                end
                [sel,ext,cats] = Gui.Dialogs.SelectCategory('ListItems',s,'Categories',c);
                if ~ext
                    return
                end
            else
                sel = {desc};
            end

            for i = 1:numel(sel)
                str = sel{i};
                map = methods.(cats{i});
                fcn = map(str);
                
                obj.getModel().addToChain(DataProcessingBlock(fcn));
            end
            
            obj.updatePropGrid();
        end

%         function removeModelChainBlock(obj)
%             block = obj.propGrid.getSelectedBlock();
%             if isempty(block)
%                 return
%             end
%             obj.getModel().removeFromChain(block);
%             obj.updatePropGrid();
%         end
        
        function removeModelChainBlock(obj, src, event)
            mod = obj.currentModel.processingChain.blocks;
            captions = mod.getCaption();
            types = mod.getType();

            % Sort to make it the same order as in the "Add" dialog
            methods = string(fieldnames(Model.getAvailableMethods(true)))';  %all method blocks
            methods = intersect(methods,types,'stable'); %only used blocks
            [~,methodidx] = ismember(methods, types); %find (first) index of method blocks in used methods
            methodidx = unique([methodidx,[1:numel(types)]],'stable'); %add missing entries at the end (rest is handled by for loop in SelectCategory)
            mod = mod(methodidx); %sort accordingly
            captions = captions(methodidx); %sort accordingly
            types = types(methodidx); %sort accordingly

%             [sel,ok] = Gui.Dialogs.Select('ListItems',captions,'MultiSelect',false);
            [sel,ok,cat] = Gui.Dialogs.SelectCategory('ListItems',captions,'Categories',types,'MultiSelect',false);
            if ~ok
                return
            end

            rem = mod(ismember(captions,sel) & ismember(types,cat));
            %TODO: Better prevent model chain blocks from being added if already in model chain (instead of handling a delete conflict as follows).
            if numel(rem)>1
                rem = rem(1,end);
                warning('Backtrace','off')
                warning('More than one model chain block fits the deletion selection. The last one added has been removed, the other remain(s).')
                warning('Backtrace','on')
            end
            obj.currentModel.removeFromChain(rem);
            obj.updatePropGrid();
            obj.getCurrentSensor().preComputePreprocessedData();
%             obj.updatePlotsInPlace();
%             obj.setGlobalYLimits();
        end

    
        function moveModelChainBlockUp(obj)
            block = obj.propGrid.getSelectedBlock();
            if isempty(block)
                return
            end
            if block.canMoveUp()
                block.moveUp();
                obj.updatePropGrid();
            end
        end
        
        function moveModelChainBlockDown(obj)
            block = obj.propGrid.getSelectedBlock();
            if isempty(block)
                return
            end
            if block.canMoveDown()
                block.moveDown();
                obj.updatePropGrid();
            end
        end
        
        function model = getModel(obj)
            %model = obj.getProject().models;
            model = obj.currentModel;
        end
        
        function updatePropGrid(obj)
            obj.propGrid.clear();
            obj.getModel().processingChain.updateChainParameters(obj.getProject());
            obj.propGrid.addBlocks(obj.getModel().processingChain.getAllBlocksInChain());     
        end
        
        function dropdownNewModel(obj,src,event,dropdown)
            model = obj.getProject().addModel();
            obj.currentModel = model;
            dropdown.Items{end+1} = char(model.getCaption());
            dropdown.Value = char(model.getCaption());
        end
        
        function dropdownRemoveModel(obj,src,event,dropdown)
            %get selected item and index it via number
            selItem = ismember(dropdown.Items,dropdown.Value);
            idx = 1:size(dropdown.Items,2);
            idx = idx(selItem);
            
            % if there is only one model, it will now be deleted
            % so we have to add a new one
            if numel(obj.getProject().models) == 1
                newModel = obj.getProject().addModel();
                dropdown.Items{end+1} = char(newModel.getCaption());
            else %if we had more models remove accordingly
                if idx == 1
                    newModel = obj.getProject().models(2);
                else
                    newModel = obj.getProject().models(idx-1);
                end
            end                

            obj.currentModel = newModel;
            obj.getProject().removeModelAt(idx);
            
            dropdown.Items(idx) = [];
            dropdown.Value = char(obj.currentModel.getCaption());
        end
        
        function dropdownModelCallback(obj,src,event)
            if event.Edited                
                index = cellfun(@(x) strcmp(x,event.PreviousValue), src.Items);
                newName = matlab.lang.makeUniqueStrings(event.Value,...
                   cellstr(obj.getProject().models.getCaption()));
                obj.getProject().models(index).setCaption(newName);
                src.Items{index} = newName;
            else
                prog = uiprogressdlg(obj.main.hFigure,...
                    'Title','Changing model',...
                    'Indeterminate','on');
                drawnow
                index = cellfun(@(x) strcmp(x,event.Value), src.Items);
                obj.currentModel = ...
                    obj.getProject().models(index);
                obj.updatePropGrid;
                obj.updateTabs();

                [~,caps,inds] = obj.currentModel.getCurrentIndexSet();
                obj.makeParameterDropdowns(caps,inds);
                close(prog)
            end
        end
        
        function dropdownModelRename(obj,h,newName,index)
            newName = matlab.lang.makeUniqueStrings(newName,cellstr(obj.getProject().models.getCaption()));
            obj.getProject().models(index).setCaption(newName);
            h.renameItemAt(newName,h.getSelectedIndex());
        end
        
        function dropdownModelChange(obj,h,newItem,newIndex)
            prog = uiprogressdlg(obj.main.hFigure,'Title','Changing model',...
                'Indeterminate','on');
            drawnow
            obj.currentModel = ...
                obj.getProject().models(newIndex);
            obj.updatePropGrid;
            obj.updateTabs();

            [~,caps,inds] = obj.currentModel.getCurrentIndexSet();
            obj.makeParameterDropdowns(caps,inds);
            
            close(prog)
        end        
        
        function updateTabs(obj)
            obj.makeModelTabs();
        end
        
        function success = computeFeatures(obj)
            success = true;
            prog = uiprogressdlg(obj.main.hFigure,'Title','Computing features',...
                'Indeterminate','on');
            drawnow
            try
                features = obj.getProject().computeFeatures();
            catch ME
                uialert(obj.main.hFigure,...
                    sprintf('Could not compute features.\n %s', ME.message),...
                    'Feature computation error');
                success = false;
            end
            try
                features = obj.getProject().mergeFeatures();
            catch ME
                uialert(obj.main.hFigure,...
                    sprintf('Could not merge features.\n %s', ME.message),...
                    'Feature merge error');
                success = false;
            end
%             features.featureCaptions'
            close(prog)
        end
        
        function trainModel(obj)
            %obj.getProject().mergedFeatureData.groupingCaptions = obj.getProject().groupings.getCaption();
            prog = uiprogressdlg(obj.main.hFigure,'Title','Building model',...
                'Indeterminate','on');
            drawnow
            % preparation, training, validation, testing
            data = obj.getProject().mergedFeatureData;
            
            try
                obj.getModel().train(data);
            catch ME
                f = gcf;
                uialert(obj.main.hFigure,...
                    sprintf('Error during model training.\n %s', ME.message),...
                    'Model training error');
                set(0, 'CurrentFigure', f)
            end

            [~,caps,inds] = obj.getModel().getLowestErrorData();
            obj.getModel().trainForParameterIndexSet(data,caps,inds);
                      
            prog.Title = 'Plotting';
            
            obj.makeModelTabs();
            obj.makeParameterDropdowns(caps,inds);
            obj.makeErrorPanel();

            obj.updatePropGrid();
            
            close(prog)
        end
        
        function makeParameterDropdowns(obj,caps,inds)
%             delete(obj.parametersDropdownGrid.Children);
            obj.parametersDropdownPanel.Children.delete();
            obj.parameterPopups = [];
            
            obj.parametersDropdownPanel.Parent.RowHeight = {'1x','1x'};
            %get the hyper parameters that are varied with caption and
            %values available for variation
            [cap,~,val] = obj.getModel().getVariedHyperParameters();
            
            %check if any parameters have varied selection
            if numel(cap) > 0
                %setup the grid to arrange the parameter variation dropdowns
                parametersDropdownGrid = uigridlayout(obj.parametersDropdownPanel,...
                    [2*numel(cap) 1],'RowHeight',repmat(32,1,2*numel(cap)),...
                    'Padding',[0 0 0 0],'RowSpacing',5,'ColumnWidth',{'1x'});

                %loop through the changed hyper parameters
                for i = 1:numel(cap)
                    %add a label for each varied parameter
                    uilabel(parametersDropdownGrid,'Text',cap{i},'WordWrap','on');
                    %select the last variation value by default
                    ind = inds(ismember(caps,cap{i}));
                    %add a dropdown to select the variable value
                    popup = uidropdown(parametersDropdownGrid,...
                        'Items',string(val{i}),...
                        'UserData',cap{i},...
                        'Value',string(val{i}{ind}),...
                        'ValueChangedFcn',@(src,event) obj.parameterDropdownChanged());
                    %append to all parameterDropdowns
                    if isempty(obj.parameterPopups)
                        obj.parameterPopups = popup;
                    else
                        obj.parameterPopups(i) = popup;
                    end
                end
                obj.parametersDropdownPanel.Parent.Parent.ColumnWidth{3} = '1x';
                obj.dynamicGrid.Visible = 'on';
                obj.parametersDropdownPanel.Visible = 'on';

            else
%                 obj.parametersDropdownPanel.Parent.Parent.ColumnWidth{3} = 0; 
                obj.parametersDropdownPanel.Visible = 'off';
                obj.parametersDropdownPanel.Parent.RowHeight = {0 '1x'};
            end
        end
        
        function makeErrorPanel(obj)
            
            obj.errorPanel.Children.delete();
            obj.parameterPopups = [];

            errorGrid = uigridlayout(obj.errorPanel,[5 2],...
                'ColumnWidth',{'2x','1x'},'RowHeight',repmat(32,5,1),...
                'Padding',[0 0 0 0],'RowSpacing',5);
            
            trainErrorCap = uilabel(errorGrid,'Text','trainingError','WordWrap','on');
            trainErrorCap.Layout.Row = 1;
            trainErrorCap.Layout.Column = 1;

            valErrorCap = uilabel(errorGrid,'Text','validationError','WordWrap','on');
            valErrorCap.Layout.Row = 2;
            valErrorCap.Layout.Column = 1;

            testErrorCap = uilabel(errorGrid,'Text','testingError','WordWrap','on');
            testErrorCap.Layout.Row = 3;
            testErrorCap.Layout.Column = 1;
              
            fullModelTrainErrorCap = uilabel(errorGrid,'Text','fullModelTrainingError','WordWrap','on');
            fullModelTrainErrorCap.Layout.Row = 4;
            fullModelTrainErrorCap.Layout.Column = 1;

            fullModelTestErrorCap = uilabel(errorGrid,'Text','fullModelTestingError','WordWrap','on');
            fullModelTestErrorCap.Layout.Row = 5;
            fullModelTestErrorCap.Layout.Column = 1;

            caps = {}; inds = [];
            for i = 1:numel(obj.parameterPopups)
                caps{i} = obj.parameterPopups(i).UserData;
                logInd = ismember(obj.parameterPopups(i).Items,obj.parameterPopups(i).Value);
                proxArray = 1:size(obj.parameterPopups(i).Items,2);
                inds(i) = proxArray(logInd);
            end
            if isempty(inds)
                inds = 1;
            end

            trainErrorVal = uilabel(errorGrid,'Text',num2str(obj.currentModel.trainingErrors(inds)));
            trainErrorVal.Layout.Row = 1;
            trainErrorVal.Layout.Column = 2;

            valErrorVal = uilabel(errorGrid,'Text',num2str(obj.currentModel.validationErrors(inds)));
            valErrorVal.Layout.Row = 2;
            valErrorVal.Layout.Column = 2;

            testErrorVal = uilabel(errorGrid,'Text',num2str(obj.currentModel.testingErrors(inds)));
            testErrorVal.Layout.Row = 3;
            testErrorVal.Layout.Column = 2;

            testErrorVal = uilabel(errorGrid,'Text',num2str(obj.currentModel.fullModelTrainingError));
            testErrorVal.Layout.Row = 4;
            testErrorVal.Layout.Column = 2;

            testErrorVal = uilabel(errorGrid,'Text',num2str(obj.currentModel.fullModelTestingError));
            testErrorVal.Layout.Row = 5;
            testErrorVal.Layout.Column = 2;

            obj.errorPanel.Parent.Parent.ColumnWidth{3} = '1x';
            obj.dynamicGrid.Visible = 'on';
            obj.errorPanel.Visible = 'on';
        end


        function parameterDropdownChanged(obj,varargin)
            caps = {}; inds = [];
            for i = 1:numel(obj.parameterPopups)
                caps{i} = obj.parameterPopups(i).UserData;
                logInd = ismember(obj.parameterPopups(i).Items,obj.parameterPopups(i).Value);
                proxArray = 1:size(obj.parameterPopups(i).Items,2);
                inds(i) = proxArray(logInd);
            end

            data = obj.getProject().mergedFeatureData.copy();
            data.setValidation('none');
            data.setTesting('none');
            obj.getModel().trainForParameterIndexSet(data,caps,inds);
            
            % update current details page
            obj.getCurrentDetailsPageTab().UserData();
            obj.updatePropGrid();

            % update errors
            obj.makeErrorPanel();
        end
        
        function tab = getCurrentDetailsPageTab(obj)
            %double children bc. a grid is inbetween
            tab = obj.tabGroup.SelectedTab.Children.Children.SelectedTab.Children.Children.SelectedTab;
        end
        
        function updateChildrenTab(obj,h,varargin)
            %double children bc. a grid is inbetween
            selTab = h.SelectedTab.Children.Children.SelectedTab;
            if isa(selTab.UserData,'function_handle')
                selTab.UserData();
            else
                selTab = selTab.Children.Children.SelectedTab;
                selTab.UserData();
            end
        end
        
        function onTabChanged(~,~,event,varargin)
            updateFun = event.NewValue.UserData;
            updateFun();
        end
        
        function makeModelTabs(obj)
            %%
            % delete old tabs
            if isempty(obj.tabGroup)
                obj.tabGroup = uitabgroup('Parent',obj.tabLayout,...
                    'SelectionChangedFcn',@obj.updateChildrenTab);
                obj.tabGroup.Layout.Row = 1;
                obj.tabGroup.Layout.Column = 2;
            else
                tabs = obj.tabGroup.Children;
                obj.tabGroup.Visible = 'off';
                delete(tabs);
                obj.parameterPopups = [];
%                 delete(obj.parametersDropdownGrid.Children);
                obj.parametersDropdownPanel.Children.delete();
                obj.parametersDropdownPanel.Visible = 'off';
            end
            
            % if model not trained, no ouput tabs -> return
            if ~obj.getModel().trained
               return 
            end
            
            % create tabs for each processing block type
            blocks = obj.getModel().processingChain.getBlocksInOrder();
            if isempty(blocks) %no blocks, no tabs
                return
            end
            types = cellfun(@char,{blocks.type},'uni',false);
            uniqueTypes = unique(types,'stable');
            for i = 1:numel(uniqueTypes)
                uitab(obj.tabGroup,'title',uniqueTypes{i});
            end
            % loop through individual blocks to fill their specific tabs
%             for i = numel(blocks):-1:1
            for i = 1:numel(blocks)
                if isempty(blocks(i).detailsPages) %skip block with no output
                    continue;
                end
                %check block type and create a new tab under type's tab
                type = char(blocks(i).type);
                typeTab = obj.tabGroup.Children(ismember({obj.tabGroup.Children.Title},type));
                if isempty(typeTab.Children)
                    typeGrid = uigridlayout(typeTab,[1 1],'Padding',[0 0 0 0]);
                    typeGroup = uitabgroup(typeGrid,'SelectionChangedFcn',@obj.updateChildrenTab);
                else
                    typeGrid = typeTab.Children;
                    typeGroup = typeGrid.Children;
                end
                blockTab = uitab(typeGroup,'title',char(blocks(i).getCaption()));
                blockGrid = uigridlayout(blockTab,[1 1],'Padding',[0 0 0 0]);
                %create a new group and fill it with blocks output tabs
                blockGroup = uitabgroup(blockGrid,...
                    'SelectionChangedFcn',@obj.onTabChanged);
                for j = 1:numel(blocks(i).detailsPages)
                    detailTab = uitab(blockGroup,'title',blocks(i).detailsPages{j});
                    detailGrid = uigridlayout(detailTab,[1 1],'Padding',[7 7 7 7]);
                    updateFun = blocks(i).createDetailsPage(blocks(i).detailsPages{j},detailGrid,obj.getProject());
                    detailTab.UserData = updateFun;
                    %Select the tab  created once
                    blockGroup.SelectedTab = detailTab;
                end
                %Select the tab  created once
                typeGroup.SelectedTab = blockTab;
            end
            
            %delete empty tab groups
            for i = numel(obj.tabGroup.Children):-1:1
                if isempty(obj.tabGroup.Children(i).Children)
                    delete(obj.tabGroup.Children(i));
                end
            end
                        
            % set all created tabs visible
            obj.tabGroup.Visible = 'on';
            % set the last tab in each group as active
            % selection appears to be bugged as of now
            %https://mathworks.com/matlabcentral/answers/545120-bug-in-tabgroup-appearance-in-appdesigner-r2019b
            if ~isempty(obj.tabGroup.Children)
                %Set the last type tab as active
                obj.tabGroup.SelectedTab = obj.tabGroup.Children(end);
                %Set the last block in that type as active
                typeTab = obj.tabGroup.Children(end);
                blockGroup = typeTab.Children.Children;
                blockGroup.SelectedTab = blockGroup.Children(end);
                %Set the last details page for the active bloack as active
                blockTab = blockGroup.Children(end);
                detailsGroup = blockTab.Children.Children;
                detailsGroup.SelectedTab = detailsGroup.Children(end);
            end
            
        end
        
        function allowed = canOpen(obj)
            p = obj.getProject();
            allowed = true;
            if isempty(p) || isempty(p.getCurrentCluster()) || isempty(p.getCurrentSensor())
                allowed = false;
                uialert(obj.main.hFigure,...
                    'Load at least one sensor.',...
                    'Data required');
            elseif isempty(obj.getProject().groupings)
                allowed = false;
                uialert(obj.main.hFigure,...
                    'Create at least one grouping.',...
                    'Grouping required');
            elseif isempty(obj.getProject().mergedFeatureData)
                selection = uiconfirm(obj.main.hFigure,...
                                {'No features available.','Features must be computed first.','Compute features now?'},...
                                'Confirm feature computation','Icon','warning',...
                                'Options',{'Yes, compute now','No, cancel'},...
                                'DefaultOption',2,'CancelOption',2);
                switch selection
                    case 'No, cancel'
                        allowed = false;
                        return
                end
                try
                    allowed = obj.computeFeatures();
                    obj.currentModel.reset();
                    obj.makeModelTabs()
                catch ME
                    uialert(obj.main.hFigure,...
                        sprintf('Could not compute features.\n %s', ME.message),...
                        'Feature computation error');
                end
            else
                selection = uiconfirm(obj.main.hFigure,...
                                {'Merged features available.','Compute features again or use existing features?','Note: Features should be computed again after any significant changes!'},...
                                'Confirm feature (re-)computation','Icon','warning',...
                                'Options',{'Yes, compute now','No, keep existing features','Cancel'},...
                                'DefaultOption',1,'CancelOption',3);
                switch selection
                    case 'Cancel'
                        allowed = false;
                        return
                end
                try
                    allowed = obj.computeFeatures();
                    obj.currentModel.reset();
                    obj.makeModelTabs()
                catch ME
                    uialert(obj.main.hFigure,...
                        sprintf('Could not compute features.\n %s', ME.message),...
                        'Feature computation error');
                end
            end
        end
        
        function onOpen(obj)
            obj.updatePropGrid();
            
            obj.setDropdown.Items = ...
                cellfun(@(x) x,obj.getProject().models.getCaption(),...
                'UniformOutput',false);
            obj.setDropdown.Value = obj.currentModel.getCaption();
            
%             obj.setDropdown.setItems(cellstr(obj.getProject().models.getCaption()));
%             obj.setDropdown.setSelectedItem(char(obj.currentModel.getCaption()));
        end
        
        function onClose(obj)
            onClose@Gui.Modules.GuiModule(obj);
            % this deletes the computed features when leaving the Model
            % module, which makes sure that the features are always up to
            % date, but is quite inefficient
            % TODO
            % Edit: was removed/commented, as there is a new dialog asking
            % if features should be calculated even though there already
            % are mergedFeatures.
%             obj.getProject().mergedFeatureData = Data.empty;
        end     
    end
end
