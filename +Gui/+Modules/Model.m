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
        parametersDropdownPanel
        parameterPopups
        
        featurePreviewX
        featurePreviewY
        
        rangeTable
        propGrid
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
        
        function [panel,menu] = makeLayout(obj)
            %%
            panel = Gui.Modules.Panel();
            
            menu = uimenu('Label','Model');

            layout = uiextras.HBox('Parent',panel);
            leftLayout = uiextras.VBox('Parent',layout);
            obj.detailsLayout = uiextras.HBox('Parent',layout, 'Spacing',5, 'Padding',5);

            defsPanel = Gui.Modules.Panel('Parent',leftLayout, 'Title','model', 'Padding',5);
%             tablePanel = Gui.Modules.Panel('Parent',leftLayout, 'Title','feature ranges', 'Padding',5);
            
            propGridLayout = uiextras.VBox('Parent',defsPanel);
            
            % model dropdown
            obj.setDropdown = Gui.EditableDropdown(propGridLayout);
            obj.setDropdown.AppendClickCallback = @obj.dropdownNewModel;
            obj.setDropdown.RemoveClickCallback = @obj.dropdownRemoveModel;
            obj.setDropdown.EditCallback = @obj.dropdownModelRename;
            obj.setDropdown.SelectionChangedCallback = @obj.dropdownModelChange;            
            
            obj.propGrid = PropGrid(propGridLayout);
            obj.propGrid.setShowToolbar(false);
            propGridControlsLayout = uiextras.HBox('Parent',propGridLayout);
            uicontrol(propGridControlsLayout,'String','add', 'Callback',@(h,e)obj.addModelChainBlock);
            uicontrol(propGridControlsLayout,'String','delete', 'Callback',@(h,e)obj.removeModelChainBlock);
            uicontrol(propGridControlsLayout,'String','/\', 'Callback',@(h,e)obj.moveModelChainBlockUp);
            uicontrol(propGridControlsLayout,'String','\/', 'Callback',@(h,e)obj.moveModelChainBlockDown);
            
            modelControlsLayout = uiextras.HBox('Parent',propGridLayout);
            uicontrol(modelControlsLayout,'String','train', 'Callback',@(h,e)obj.trainModel);
%             uicontrol(modelControlsLayout,'String','show details', 'Callback',@(h,e)obj.showModelDetails);
            propGridLayout.Sizes = [30,-1,20,40];

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
            obj.tabLayout = uiextras.VBox('Parent',obj.detailsLayout);
            obj.parametersDropdownPanel = Gui.Modules.Panel('Parent',obj.detailsLayout, 'Title','parameters', 'Padding',2);
%             obj.parametersDropdownGrid = uiextras.Grid('Parent',obj.parametersDropdownPanel, 'Spacing',2, 'Padding',0);
            obj.parametersDropdownPanel.Visible = 'off';

            layout.Sizes = [-1,-3];
            leftLayout.Sizes = [-1];
        end
        
        function [moduleLayout,moduleMenu] = makeLayoutRework(obj,uiParent,mainFigure)
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
            
            %Create the grid to house the model definition section in the
            %leftmost column
            defsGrid = uigridlayout(moduleLayout, [5 4],...
                'ColumnWidth',{'2x','2x','1x','1x'},...
                'RowHeight',{'1x','1x','12x','1x','2x'},...
                'RowSpacing',4,...
                'Padding',[4 4 4 4]);
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

            obj.propGrid = Gui.uiParameterBlockGrid('Parent',defsGrid,...
                'ValueChangedFcn',@(src,event) obj.updatePropGrid());%,...
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
                'Text','Delete',...
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
            parameterPanel = uipanel(moduleLayout,...
                'Title','Adjust Parameters',...
                'BorderType','none',...
                'Visible','off');
            parameterPanel.Layout.Row = 1;
            parameterPanel.Layout.Column = 3;
            obj.parametersDropdownPanel = parameterPanel;
        end

        function addModelChainBlock(obj,desc)
            if nargin < 2
                methods = Model.getAvailableMethods(true);
%                 s = keys(fe);
                s = {};
                fields = fieldnames(methods);
                for i = 1:numel(fields)
                    if numel(keys(methods.(fields{i}))) == 0
                        continue
                    end
                    s{end+1} = sprintf('<html><b>%s</b></html>',fields{i});
                    s = horzcat(s,keys(methods.(fields{i})));
                    s{end+1} = '';
                end
                [sel,ok] = listdlg('ListString',s);
                if ~ok
                    return
                end
            else
                sel = {desc};
            end

            for i = 1:numel(sel)
                str = s{sel(i)};
                if isempty(str) || str(1) == '<'
                    continue
                end
                
                for j = sel(i):-1:1
                    field = s{j};
                    if ~isempty(field) && field(1) == '<'
                        map = methods.(field(10:end-11));
                        fcn = map(str);
                        break
                    end
                end
                
                obj.getModel().addToChain(DataProcessingBlock(fcn));
            end
            
            obj.updatePropGrid();
        end

        function removeModelChainBlock(obj)
            prop = obj.propGrid.getSelectedProperty().getHighestParent();
            if isempty(prop)
                return
            end
            idx = obj.propGrid.jPropList.indexOf(prop.jProperty);
            block = prop.getMatlabObj();
            obj.getModel().removeFromChain(block);
            obj.propGrid.removeProperty(prop);
            if obj.propGrid.jPropList.size() > 0
                nextSelProp = obj.propGrid.jPropList.get(max([0, idx-1]));
                obj.propGrid.grid.setSelectedProperty(nextSelProp);
            end
        end
        
        function moveModelChainBlockUp(obj)
            prop = obj.propGrid.getSelectedProperty().getHighestParent();
            if isempty(prop)
                return
            end
            block = prop.getMatlabObj();
            if block.canMoveUp()
                block.moveUp();
                obj.propGrid.movePropertyUp(prop);
            end
        end
        
        function moveModelChainBlockDown(obj)
            prop = obj.propGrid.getSelectedProperty().getHighestParent();
            if isempty(prop)
                return
            end
            block = prop.getMatlabObj();
            if block.canMoveDown()
                block.moveDown();
                obj.propGrid.movePropertyDown(prop);
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
%             pgf = obj.getModel().makePropGridFields();
%             obj.propGrid.addProperty(pgf);       
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
%               statusbar(obj.main.hFigure,'Changing model...'); 
                index = cellfun(@(x) strcmp(x,event.Value), src.Items);
                obj.currentModel = ...
                    obj.getProject().models(index);
                obj.updatePropGrid;
                obj.updateTabs();

                [~,caps,inds] = obj.currentModel.getCurrentIndexSet();
                obj.makeParameterDropdowns(caps,inds);
%               sb = statusbar(obj.main.hFigure,'Ready.');
%               set(sb.ProgressBar, 'Visible',false, 'Indeterminate',false); 
            end
        end
        
        function dropdownModelRename(obj,h,newName,index)
            newName = matlab.lang.makeUniqueStrings(newName,cellstr(obj.getProject().models.getCaption()));
            obj.getProject().models(index).setCaption(newName);
            h.renameItemAt(newName,h.getSelectedIndex());
        end
        
        function dropdownModelChange(obj,h,newItem,newIndex)
%             statusbar(obj.main.hFigure,'Changing model...'); 
            
            obj.currentModel = ...
                obj.getProject().models(newIndex);
            obj.updatePropGrid;
            obj.updateTabs();

            [~,caps,inds] = obj.currentModel.getCurrentIndexSet();
            obj.makeParameterDropdowns(caps,inds);
            
%             sb = statusbar(obj.main.hFigure,'Ready.');
%             set(sb.ProgressBar, 'Visible',false, 'Indeterminate',false); 
        end        
        
        function updateTabs(obj)
            obj.makeModelTabs();
        end
        
        function success = computeFeatures(obj)
            success = true;
%             sb = statusbar(obj.main.hFigure, 'Computing features...');
%             set(sb.ProgressBar, 'Visible',false, 'Indeterminate',true);
            try
                features = obj.getProject().computeFeatures();
            catch ME
                errordlg(sprintf('Could not compute features.\n %s', ME.message),'I''m afraid I can''t do that.','modal');
                success = false;
            end
            try
                features = obj.getProject().mergeFeatures();
            catch ME
                errordlg(sprintf('Could not merge features.\n %s', ME.message),'I''m afraid I can''t do that.','modal');
                success = false;
            end
%             features.featureCaptions'
%             sb = statusbar(obj.main.hFigure, 'Ready.');
%             set(sb.ProgressBar, 'Visible',false, 'Indeterminate',false);
        end
        
        function trainModel(obj)
            %obj.getProject().mergedFeatureData.groupingCaptions = obj.getProject().groupings.getCaption();

%             sb = statusbar(obj.main.hFigure,'Building model...');
%             set(sb.ProgressBar, 'Visible',true, 'Indeterminate',true);            
            
            % preparation, training, validation, testing
            data = obj.getProject().mergedFeatureData;
            
            try
                obj.getModel().train(data);
            catch ME
                f = gcf;
                errordlg(sprintf('Error during model training.\n %s', ME.message),'I''m afraid I can''t do that.');
                set(0, 'CurrentFigure', f)
            end

            [~,caps,inds] = obj.getModel().getLowestErrorData();
            obj.getModel().trainForParameterIndexSet(data,caps,inds);

%             sb = statusbar(obj.main.hFigure,'Plotting...');            
            
            obj.makeModelTabs();
            obj.makeParameterDropdowns(caps,inds);
            
            obj.updatePropGrid();
            
%             sb = statusbar(obj.main.hFigure,'Ready.');
%             set(sb.ProgressBar, 'Visible',false, 'Indeterminate',false);  
        end
        
        function makeParameterDropdowns(obj,caps,inds)
%             delete(obj.parametersDropdownGrid.Children);
            obj.parametersDropdownPanel.Children.delete();
            obj.parameterPopups = [];
            
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
                obj.parametersDropdownPanel.Parent.ColumnWidth{3} = '1x';
                obj.parametersDropdownPanel.Visible = 'on';
            else
                obj.parametersDropdownPanel.Parent.ColumnWidth{3} = 0;
                obj.parametersDropdownPanel.Visible = 'off';
            end
        end
        
        function parameterDropdownChanged(obj,varargin)
            caps = {}; inds = [];
            for i = 1:numel(obj.parameterPopups)
                caps{i} = obj.parameterPopups(i).UserData;
                inds(i) = ismember(obj.parameterPopups(i).Items,obj.parameterPopups(i).Value);
            end
            
            data = obj.getProject().mergedFeatureData.copy();
            data.setValidation('none');
            data.setTesting('none');
            obj.getModel().trainForParameterIndexSet(data,caps,inds);
            
            % update current details page
            obj.getCurrentDetailsPageTab().UserData();
        end
        
        function tab = getCurrentDetailsPageTab(obj)
            tab = obj.tabGroup.SelectedTab.Children.SelectedTab.Children.SelectedTab;
        end
        
        function updateChildrenTab(obj,h,varargin)
            selTab = h.SelectedTab.Children.SelectedTab;
            if isa(selTab.UserData,'function_handle')
                selTab.UserData();
            else
                selTab = selTab.Children.SelectedTab;
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
           
            % activate tab layout to create tabs
            obj.tabGroup.Visible = 'on';
            
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
            for i = numel(blocks):-1:1
                if isempty(blocks(i).detailsPages) %skip block with no output
                    continue;
                end
                %check block type and create a new tab under type's tab
                type = char(blocks(i).type);
                typeTab = obj.tabGroup.Children(ismember({obj.tabGroup.Children.Title},type));
                if isempty(typeTab.Children)
                    typeGroup = uitabgroup(typeTab,'SelectionChangedFcn',@obj.updateChildrenTab);
                else
                    typeGroup = typeTab.Children;
                end
                blockTab = uitab(typeGroup,'title',char(blocks(i).getCaption()));
                %create a new group and fill it with blocks output tabs
                tg = uitabgroup(blockTab,'SelectionChangedFcn',@obj.onTabChanged);
                for j = 1:numel(blocks(i).detailsPages)
                    t = uitab(tg,'title',blocks(i).detailsPages{j});
                    [~,updateFun] = blocks(i).createDetailsPage(blocks(i).detailsPages{j},t,obj.getProject());
                    t.UserData = updateFun;
                end
            end
            %set the final created tab as selected
            tg.SelectedTab = t;
            %delete empty tab groups
            for i = numel(obj.tabGroup.Children):-1:1
                if isempty(obj.tabGroup.Children(i).Children)
                    delete(obj.tabGroup.Children(i));
                end
            end
            obj.tabGroup.SelectedTab = obj.tabGroup.Children(end);
        end
        
        function allowed = canOpen(obj)
            p = obj.getProject();
            allowed = true;
            if isempty(p) || isempty(p.getCurrentCluster()) || isempty(p.getCurrentSensor())
                allowed = false;
                errordlg('Load at least one sensor.','I''m afraid I can''t do that.');
            elseif isempty(obj.getProject().groupings)
                allowed = false;
                errordlg('Make at least one grouping.','I''m afraid I can''t do that.');
            elseif isempty(obj.getProject().mergedFeatureData)
                q = questdlg('Must compute features first. Compute features now?','','Yes','No','Yes');
                allowed = false;
                if strcmp(q,'Yes')
                    try
                        allowed = obj.computeFeatures();
                        obj.currentModel.reset();
                        obj.makeModelTabs()
                    catch ME
                        errordlg(sprintf('Error during feature computation.\n %s', ME.message),'I''m afraid I can''t do that.');
                    end
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
            obj.getProject().mergedFeatureData = Data.empty;
        end     
    end
end
