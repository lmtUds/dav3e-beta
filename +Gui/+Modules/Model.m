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
        parametersDropdownGrid
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
            obj.parametersDropdownGrid = uiextras.Grid('Parent',obj.parametersDropdownPanel, 'Spacing',2, 'Padding',0);
            obj.parametersDropdownPanel.Visible = 'off';

            layout.Sizes = [-1,-3];
            leftLayout.Sizes = [-1];
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
            pgf = obj.getModel().makePropGridFields();
            obj.propGrid.addProperty(pgf);       
        end
        
        function dropdownNewModel(obj,h)
            model = obj.getProject().addModel();
            obj.currentModel = model;
            h.appendItem(model.getCaption());
            h.selectLastItem();
        end
        
        function dropdownRemoveModel(obj,h)
            idx = h.getSelectedIndex();
%             models = obj.getProject().removeModelAt(idx);
            
            % if there is only one model, it will now be deleted
            % so we have to add a new one
            if numel(obj.getProject().models) == 1
                newModel = obj.getProject().addModel();
                h.appendItem(newModel.getCaption());
            else
                if idx == 1
                    newModel = obj.getProject().models(2);
                else
                    newModel = obj.getProject().models(idx-1);
                end
            end                

            obj.currentModel = newModel;
            obj.getProject().removeModelAt(idx);
                
            h.removeItemAt(idx);
            h.setSelectedItem(obj.currentModel.getCaption());
        end
        
        function dropdownModelRename(obj,h,newName,index)
            newName = matlab.lang.makeUniqueStrings(newName,cellstr(obj.getProject().models.getCaption()));
            obj.getProject().models(index).setCaption(newName);
            h.renameItemAt(newName,h.getSelectedIndex());
        end
        
        function dropdownModelChange(obj,h,newItem,newIndex)
            statusbar(obj.main.hFigure,'Changing model...'); 
            
            obj.currentModel = ...
                obj.getProject().models(newIndex);
            obj.updatePropGrid;
            obj.updateTabs();

            [~,caps,inds] = obj.currentModel.getCurrentIndexSet();
            obj.makeParameterDropdowns(caps,inds);
            
            sb = statusbar(obj.main.hFigure,'Ready.');
            set(sb.ProgressBar, 'Visible',false, 'Indeterminate',false); 
        end        
        
        function updateTabs(obj)
            obj.makeModelTabs();
        end
        
        function success = computeFeatures(obj)
            success = true;
            sb = statusbar(obj.main.hFigure, 'Computing features...');
            set(sb.ProgressBar, 'Visible',false, 'Indeterminate',true);
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
                disp('''Could not merge features'' help (most obvious cases):');
                disp('''Cluster collision'' means that you have to check the timing (offset and length) of your clusters, as there are unexpected overlaps of clusters in one track.');
                disp('''Index in position 1 exceeds array bounds'' might either originate from a mislabeled track, which leads to unintended parallel tracks and deletion of clusters during merging process (no clusters in both tracks at the same time).');
                disp('Or ''Index in position 1 exceeds array bounds'' might originate from inconsistently used feature sets for at least one sensor (a sensor has to use the same feature set in every (used) cluster).');
                disp('''Dimensions of arrays being concatenated are not consistent'' might originate from a non-checked sensor (table column ''use'') in one cluster, while in other clusters in the same track that sensor is checked.');
                success = false;
            end
%             features.featureCaptions'
            sb = statusbar(obj.main.hFigure, 'Ready.');
            set(sb.ProgressBar, 'Visible',false, 'Indeterminate',false);
        end
        
        function trainModel(obj)
            %obj.getProject().mergedFeatureData.groupingCaptions = obj.getProject().groupings.getCaption();

            sb = statusbar(obj.main.hFigure,'Building model...');
            set(sb.ProgressBar, 'Visible',true, 'Indeterminate',true);            
            
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

            sb = statusbar(obj.main.hFigure,'Plotting...');            
            
            obj.makeModelTabs();
            obj.makeParameterDropdowns(caps,inds);
            
            sb = statusbar(obj.main.hFigure,'Ready.');
            set(sb.ProgressBar, 'Visible',false, 'Indeterminate',false);  
        end
        
        function makeParameterDropdowns(obj,caps,inds)
            delete(obj.parametersDropdownGrid.Children);
            obj.parameterPopups = [];

            [cap,~,val] = obj.getModel().getVariedHyperParameters();
            
            for i = 1:numel(cap)
                uicontrol(obj.parametersDropdownGrid,'Style','text', 'String',cap{i});
                ind = inds(ismember(caps,cap{i}));
                popup = uicontrol(obj.parametersDropdownGrid,...
                    'Style','popupmenu', 'String',val{i},...
                    'UserData',cap{i},...
                    'Value',ind,...
                    'Callback',@obj.parameterDropdownChanged);
                if isempty(obj.parameterPopups)
                    obj.parameterPopups = popup;
                else
                    obj.parameterPopups(i) = popup;
                end
            end
            if numel(cap) > 0
                set(obj.parametersDropdownGrid, 'ColumnSizes', [100], 'RowSizes', repmat([30 30],1,numel(cap)));
                obj.detailsLayout.Sizes = [-1,110];
                obj.parametersDropdownPanel.Visible = 'on';
            else
                obj.detailsLayout.Sizes = [-1,0];
                obj.parametersDropdownPanel.Visible = 'off';
            end
        end
        
        function parameterDropdownChanged(obj,varargin)
            caps = {}; inds = [];
            for i = 1:numel(obj.parameterPopups)
                caps{i} = obj.parameterPopups(i).UserData;
                inds(i) = obj.parameterPopups(i).Value;
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
            % delete old tabs
            if isempty(obj.tabGroup)
                obj.tabGroup = uitabgroup(obj.tabLayout,'SelectionChangedFcn',@obj.updateChildrenTab);
            else
                tabs = obj.tabGroup.Children;
                obj.tabLayout.Visible = 'off';
                delete(tabs);
                delete(obj.parametersDropdownGrid.Children);
                obj.parameterPopups = [];
                obj.parametersDropdownPanel.Visible = 'off';
            end
            
            % if model not trained -> return
            if ~obj.getModel().trained
               return 
            end
           
            % activate tab layout to create tabs
            obj.tabLayout.Visible = 'on';
            
            % create tabs
            blocks = obj.getModel().processingChain.getBlocksInOrder();
            if isempty(blocks)
                return
            end
            types = cellfun(@char,{blocks.type},'uni',false);
            uniqueTypes = unique(types,'stable');
            for i = 1:numel(uniqueTypes)
                uitab(obj.tabGroup,'title',uniqueTypes{i});
            end

            for i = numel(blocks):-1:1
                if isempty(blocks(i).detailsPages)
                    continue;
                end
                type = char(blocks(i).type);
                typeTab = obj.tabGroup.Children(ismember({obj.tabGroup.Children.Title},type));
                if isempty(typeTab.Children)
                    t = uitabgroup(typeTab,'SelectionChangedFcn',@obj.updateChildrenTab);
                else
                    t = typeTab.Children;
                end
                t = uitab(t,'title',char(blocks(i).getCaption()));
                tg = uitabgroup(t,'SelectionChangedFcn',@obj.onTabChanged);
                for j = 1:numel(blocks(i).detailsPages)
                    t = uitab(tg,'title',blocks(i).detailsPages{j});
                    [~,updateFun] = blocks(i).createDetailsPage(blocks(i).detailsPages{j},t,obj.getProject());
                    t.UserData = updateFun;
                end
            end
            
            tg.SelectedTab = t;
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
            obj.setDropdown.setItems(cellstr(obj.getProject().models.getCaption()));
            obj.setDropdown.setSelectedItem(char(obj.currentModel.getCaption()));
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
