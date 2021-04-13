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

classdef Preprocessing < Gui.Modules.GuiModule
    properties
        caption = 'Preprocessing'
        
%         currentCyclePointSet = PointSet.empty;
%         currentIndexPointSet = PointSet.empty;
        cyclePoints = GraphicsPoint.empty;
        indexPoints = GraphicsPoint.empty;
        
        hCompareWith
        propGrid
        setDropdown
        cyclePointSetDropdown
        indexPointSetDropdown
        
        hAxQuasistatic
        hAxCycle
        
        cyclePointTable
        indexPointTable
        
        currentPreprocessing
        compareSensor
        
        rawColorShade = 3
        hLines
        
        globalYLimitsMenu
    end
    
    properties (Dependent)
        currentPreprocessingChain
        currentCyclePointSet
        currentIndexPointSet
    end
    
    methods
        function obj = Preprocessing(main)
            %% constructor
            obj@Gui.Modules.GuiModule(main);
            
            obj.hLines = struct();
            types = {'current','compare'};
            pp = {'raw','pp'};
            views = {'cycle','quasistatic'};
            for t = 1:numel(types)
                for p = 1:numel(pp)
                    for v = 1:numel(views)
                        obj.hLines.(types{t}).(pp{p}).(views{v}) = [];
                    end
                end
            end
        end
        
        function reset(obj)
            reset@Gui.Modules.GuiModule(obj);
            obj.compareSensor = [];
        end        
        
        function delete(obj)
            delete(obj.cyclePointTable);
            delete(obj.indexPointTable);
        end        
        
        function [panel,menu] = makeLayout(obj)
            %%
            panel = Gui.Modules.Panel();%Replaced from the uiextras package
            
            menu = uimenu('Label','Preprocessing');
            obj.globalYLimitsMenu = uimenu(menu,'Label','global y-limits', 'Checked','off', getMenuCallbackName(),@obj.globalYLimitsMenuClicked);
            
            layout = uiextras.HBox('Parent',panel);
            leftLayout = uiextras.VBox('Parent',layout);
%             leftInnerLayout1 = uiextras.VBox('Parent',leftLayout);
%             leftInnerLayout2 = uiextras.VBox('Parent',leftLayout);
            axesLayout = uiextras.VBox('Parent',layout, 'Spacing',5, 'Padding',5);
            
            comparePanel = Gui.Modules.Panel('Parent',leftLayout, 'Title','compare with', 'Padding',5);
            clusterPanel = Gui.Modules.Panel('Parent',leftLayout, 'Title','cluster', 'Padding',5);
            cTablePanel = Gui.Modules.Panel('Parent',leftLayout, 'Title','cycle points', 'Padding',5);
            cTablePanelLayout = uiextras.VBox('Parent',cTablePanel);
            qsTablePanel = Gui.Modules.Panel('Parent',leftLayout, 'Title','quasistatic points', 'Padding',5);
            qsTablePanelLayout = uiextras.VBox('Parent',qsTablePanel);
            chainPanel = Gui.Modules.Panel('Parent',leftLayout, 'Title','preprocessing chain', 'Padding',5);
            
            l = uiextras.HBox('Parent',comparePanel);
            hCompareWithCheckbox = uicontrol('Parent',l, 'Style','checkbox',...
                'Callback',@obj.compareWithCheckboxCallback);
            hSensorPopup = uicontrol('Parent',l, 'Style','popup', 'String',{'1','2'},...
                'Callback',@obj.compareWithSensorPopup);
            l.Sizes = [30,-1];
            
            l = uiextras.Grid('Parent',clusterPanel, 'Spacing',2);
%             l = uiextras.VBox('Parent',clusterPanel);
%             uicontrol('Parent',l, 'Style','checkbox');
            uicontrol('Parent',l, 'Style','text', 'String','sampling period / s', 'HorizontalAlignment','left');
            uicontrol('Parent',l, 'Style','text', 'String','offset / s', 'HorizontalAlignment','left');
            uicontrol('Parent',l, 'Style','text', 'String','virtual offset / s', 'HorizontalAlignment','left');
%             uicontrol('Parent',l, 'Style','popup', 'String',{'1','2'});
            hSamplingPeriodEdit = uicontrol('Parent',l, 'Style','edit', 'String','0.1','Callback',@obj.samplingPeriodEditCallback);
            hOffsetEdit = uicontrol('Parent',l, 'Style','edit', 'String','100','Callback',@obj.offsetEditCallback);
            hVirtualOffsetEdit = uicontrol('Parent',l, 'Style','edit', 'String','0','Callback',@obj.virtualOffsetEditCallback);

            set(l,'ColumnSizes',[100,-1], 'RowSizes',[-1,-1,-1],...
                'MinimumRowSizes',[20,20,20]);
%             uicontrol('Parent',l, 'Style','text', 'String','sampling period / s', 'HorizontalAlignment','left');
%             hSamplingPeriodEdit = uicontrol('Parent',l, 'Style','edit', 'String','0.1', ...
%                 'Callback',@obj.samplingPeriodEditCallback);
%             uicontrol('Parent',l, 'Style','text', 'String','offset / s', 'HorizontalAlignment','left');
%             hOffsetEdit = uicontrol('Parent',l, 'Style','edit', 'String','100', ...
%                 'Callback',@obj.offsetEditCallback);
%             uicontrol('Parent',l, 'Style','text', 'String','virtual offset / s', 'HorizontalAlignment','left');
%             hVirtualOffsetEdit = uicontrol('Parent',l, 'Style','edit', 'String','0', ...
%                 'Callback',@obj.virtualOffsetEditCallback);

            obj.hCompareWith.hCompareWithCheckbox = hCompareWithCheckbox;
            obj.hCompareWith.hSensorPopup = hSensorPopup;
            obj.hCompareWith.hSamplingPeriodEdit = hSamplingPeriodEdit;
            obj.hCompareWith.hOffsetEdit = hOffsetEdit;
            obj.hCompareWith.hVirtualOffsetEdit = hVirtualOffsetEdit;
            
            propGridLayout = uiextras.VBox('Parent',chainPanel);
            
            % preprocessing chain set dropdown
            obj.setDropdown = Gui.EditableDropdown(propGridLayout);
            obj.setDropdown.AppendClickCallback = @obj.dropdownNewPreprocessingChain;
            obj.setDropdown.RemoveClickCallback = @obj.dropdownRemovePreprocessingChain;
            obj.setDropdown.EditCallback = @obj.dropdownPreprocessingChainRename;
            obj.setDropdown.SelectionChangedCallback = @obj.dropdownPreprocessingChainChange;
            
            % preprocessing chain propgrid
            obj.propGrid = PropGrid(propGridLayout);
            obj.propGrid.onPropertyChangedCallback = @obj.onParameterChangedCallback;
            obj.propGrid.setShowToolbar(false);
            propGridControlsLayout = uiextras.HBox('Parent',propGridLayout);
            uicontrol(propGridControlsLayout,'String','add', 'Callback',@(h,e)obj.addPreprocessing);
            uicontrol(propGridControlsLayout,'String','delete', 'Callback',@(h,e)obj.removePreprocessing);
            uicontrol(propGridControlsLayout,'String','/\', 'Callback',@(h,e)obj.movePreprocessingUp);
            uicontrol(propGridControlsLayout,'String','\/', 'Callback',@(h,e)obj.movePreprocessingDown);
            propGridLayout.Sizes = [30,-1,20];
            
%             propGrid.grid.setDragEnabled(true);
%             propGrid.grid.setDropMode(javax.swing.DropMode.INSERT_ROWS);
%             propGrid.grid.setTransferHandler(javax.swing.TransferHandler())

%             propGrid.addProperty(PropGridField('test1','test1'));
%             propGrid.addProperty(PropGridField('test2','test2'));
            
            obj.hAxQuasistatic = axes(axesLayout); title('quasistatic signal');
            obj.hAxQuasistatic.ButtonDownFcn = @obj.quasistaticAxesButtonDownCallback;
            xlabel('cycle number'); ylabel('data / a.u.');% yyaxis right, ylabel('data / a.u.');
            box on, 
            set(gca,'LooseInset',get(gca,'TightInset')) % https://undocumentedmatlab.com/blog/axes-looseinset-property
            obj.hAxCycle = axes(axesLayout); title('selected cycles');
            obj.hAxCycle.ButtonDownFcn = @obj.cycleAxesButtonDownCallback;
            xlabel('time / s'); ylabel('data / a.u.');% yyaxis right, ylabel('data / a.u.');
            box on
            set(gca,'LooseInset',get(gca,'TightInset'))
            
            % cycle point set dropdown
            obj.cyclePointSetDropdown = Gui.EditableDropdown(cTablePanelLayout);
            obj.cyclePointSetDropdown.AppendClickCallback = @obj.dropdownNewCyclePointSet;
            obj.cyclePointSetDropdown.RemoveClickCallback = @obj.dropdownRemoveCyclePointSet;
            obj.cyclePointSetDropdown.EditCallback = @obj.dropdownCyclePointSetRename;
            obj.cyclePointSetDropdown.SelectionChangedCallback = @obj.dropdownCyclePointSetChange;
            obj.cyclePointTable = JavaTable(cTablePanelLayout);
            cTablePanelLayout.Sizes = [30,-1];
            
            % index point set dropdown
            obj.indexPointSetDropdown = Gui.EditableDropdown(qsTablePanelLayout);
            obj.indexPointSetDropdown.AppendClickCallback = @obj.dropdownNewIndexPointSet;
            obj.indexPointSetDropdown.RemoveClickCallback = @obj.dropdownRemoveIndexPointSet;
            obj.indexPointSetDropdown.EditCallback = @obj.dropdownIndexPointSetRename;
            obj.indexPointSetDropdown.SelectionChangedCallback = @obj.dropdownIndexPointSetChange;
            obj.indexPointTable = JavaTable(qsTablePanelLayout);
            qsTablePanelLayout.Sizes = [30,-1];
            
            leftLayout.Sizes = [50,-1,-2,-2,-4];
            leftLayout.MinimumSizes = [50,100,100,100,150];
            layout.Sizes = [-1,-4];
%             leftLayout.Sizes = [-1,-1,120,-2];
            
        end
        
        function [moduleLayout,moduleMenu] = makeLayoutRework(obj,uiParent,mainFigure)
            %%
            % create a grid layout for the preprocessing panel
            moduleLayout = uigridlayout(uiParent,[12 2],...
                'Visible','off',...
                'Padding',[0 0 0 0],...
                'ColumnWidth',{'1x','3x'},...
                'RowHeight',{'fit'},...
                'RowSpacing',7);
            
            % create the menu bar dropdown
            moduleMenu = uimenu(mainFigure,'Label','Preprocessing');
            obj.globalYLimitsMenu = uimenu(moduleMenu,...
                'Label','global y-limits',...
                'Checked','off',...
                getMenuCallbackName(),@obj.globalYLimitsMenuClicked);
                        
            % create and fill the grid layout of the 'compare with' section
            compareGrid = uigridlayout(moduleLayout,...
                'ColumnWidth',{'1x','4x'},...
                'RowHeight',{'fit'},...
                'RowSpacing',4,...
                'Padding',[4 4 4 4]);
            compareGrid.Layout.Row = 1;
            compareGrid.Layout.Column = 1;
            
            compareLabel = uilabel(compareGrid,...
                'Text','Compare with',...
                'FontWeight','bold');
            compareLabel.Layout.Row = 1;
            compareLabel.Layout.Column = [1 2];
            
            compareCheckbox = uicheckbox(compareGrid,...
                'Text','',...
                'ValueChangedFcn',@obj.compareWithCheckboxCallback);
            compareCheckbox.Layout.Column = 1;
            
            compareDropdown = uidropdown(compareGrid,...
                'Items',{'1','2'},...
                'ValueChangedFcn',@obj.compareWithSensorPopup);
            compareDropdown.Layout.Column = 2;
            
            obj.hCompareWith.hCompareWithCheckbox = compareCheckbox;
            obj.hCompareWith.hSensorPopup = compareDropdown;
            
            % create and fill the grid layout of the 'cluster' section
            clusterGrid = uigridlayout(moduleLayout, [4 2],...
                'ColumnWidth',{'1x','1x'},...
                'RowHeight',{'fit'},...
                'RowSpacing',4,...
                'Padding',[4 4 4 4]);
            clusterGrid.Layout.Row = [2 3];
            clusterGrid.Layout.Column = 1;
            
            clusterLabel = uilabel(clusterGrid,...
                'Text','Cluster',...
                'FontWeight','bold');
            clusterLabel.Layout.Row = 1;
            clusterLabel.Layout.Column = [1 2];
            
            periodLabel = uilabel(clusterGrid,'Text','sampling period / s');
            periodLabel.Layout.Row = 2;
            periodLabel.Layout.Column = 1;
            
            offsetLabel = uilabel(clusterGrid,'Text','offset / s');
            offsetLabel.Layout.Row = 3;
            offsetLabel.Layout.Column = 1;
            
            virtOffsetLabel = uilabel(clusterGrid,'Text','virtual offset / s');
            virtOffsetLabel.Layout.Row = 4;
            virtOffsetLabel.Layout.Column = 1;
            
            periodEdit = uieditfield(clusterGrid,'numeric',...
                'Value',0.1,...
                'ValueChangedFcn',@obj.samplingPeriodEditCallback);
            periodEdit.Layout.Row = 2;
            periodEdit.Layout.Column = 2;
            
            offsetEdit = uieditfield(clusterGrid,'numeric',...
                'Value',100,...
                'ValueChangedFcn',@obj.offsetEditCallback);
            offsetEdit.Layout.Row = 3;
            offsetEdit.Layout.Column = 2;
            
            virtOffsetEdit = uieditfield(clusterGrid,'numeric',...
                'Value',0,...
                'ValueChangedFcn',@obj.virtualOffsetEditCallback);
            virtOffsetEdit.Layout.Row = 4;
            virtOffsetEdit.Layout.Column = 2;
                        
            obj.hCompareWith.hSamplingPeriodEdit = periodEdit;
            obj.hCompareWith.hOffsetEdit = offsetEdit;
            obj.hCompareWith.hVirtualOffsetEdit = virtOffsetEdit;
            
            % create and fill the grid layout of the 'cycle points' section
            cyclePointsGrid = uigridlayout(moduleLayout, [4 4],...
                'ColumnWidth',{'2x','2x','1x','1x'},...
                'RowHeight',{'1x','1x','4x','1x'},...
                'RowSpacing',4,...
                'Padding',[4 4 4 4]);
            cyclePointsGrid.Layout.Row = [4 6];
            cyclePointsGrid.Layout.Column = 1;
            
            cyclePointsLabel = uilabel(cyclePointsGrid,...
                'Text','Cycle points',...
                'FontWeight','bold');
            cyclePointsLabel.Layout.Row = 1;
            cyclePointsLabel.Layout.Column = [1 4];
            
            % cycle point set dropdown and buttons
            cyclePointsDropdown = uidropdown(cyclePointsGrid,...
                'Editable','on',...
                'ValueChangedFcn',@obj.dropdowCyclePointSetCallback);
            cyclePointsDropdown.Layout.Row = 2;
            cyclePointsDropdown.Layout.Column = [1 2];
            
            cPointSetAdd = uibutton(cyclePointsGrid,...
                'Text','+',...
                'ButtonPushedFcn',@obj.dropdownNewCyclePointSet);
            cPointSetAdd.Layout.Row = 2;
            cPointSetAdd.Layout.Column = 3;
                       
            cPointSetRem = uibutton(cyclePointsGrid,...
                'Text','-',...
                'ButtonPushedFcn',@obj.dropdownRemoveCyclePointSet);
            cPointSetRem.Layout.Row = 2;
            cPointSetRem.Layout.Column = 4;
            
            cyclePointsTable = uitable(cyclePointsGrid);
            cyclePointsTable.Layout.Row = [3 4];
            cyclePointsTable.Layout.Column = [1 4];
                       
            obj.cyclePointSetDropdown = cyclePointsDropdown;
            obj.cyclePointTable = cyclePointsTable;
            
            
            % create and fill the grid layout of the 'quasistatic points' section
            qsPointsGrid = uigridlayout(moduleLayout, [4 4],...
                'ColumnWidth',{'2x','2x','1x','1x'},...
                'RowHeight',{'1x','1x','4x','1x'},...
                'RowSpacing',4,...
                'Padding',[4 4 4 4]);
            qsPointsGrid.Layout.Row = [7 9];
            qsPointsGrid.Layout.Column = 1;
            
            qsPointsLabel = uilabel(qsPointsGrid,...
                'Text','Quasistatic points',...
                'FontWeight','bold');
            qsPointsLabel.Layout.Row = 1;
            qsPointsLabel.Layout.Column = [1 4];
            
            % cycle point set dropdown and buttons
            qsPointsDropdown = uidropdown(qsPointsGrid,...
                'Editable','on',...
                'ValueChangedFcn',@obj.dropdowIndexPointSetCallback);
            qsPointsDropdown.Layout.Row = 2;
            qsPointsDropdown.Layout.Column = [1 2];
            
            qsPointSetAdd = uibutton(qsPointsGrid,...
                'Text','+',...
                'ButtonPushedFcn',@obj.dropdownNewIndexPointSet);
            qsPointSetAdd.Layout.Row = 2;
            qsPointSetAdd.Layout.Column = 3;
                       
            qsPointSetRem = uibutton(qsPointsGrid,...
                'Text','-',...
                'ButtonPushedFcn',@obj.dropdownRemoveIndexPointSet);
            qsPointSetRem.Layout.Row = 2;
            qsPointSetRem.Layout.Column = 4;
            
            qsPointsTable = uitable(qsPointsGrid);
            qsPointsTable.Layout.Row = [3 4];
            qsPointsTable.Layout.Column = [1 4];
                        
            % index point set dropdown
            obj.indexPointSetDropdown = qsPointsDropdown;
            obj.indexPointTable = qsPointsTable;
            
            
            % create and fill the grid layout of the 'preprocessing chain' section
            chainGrid = uigridlayout(moduleLayout, [4 4],...
                'ColumnWidth',{'2x','2x','1x','1x'},...
                'RowHeight',{'1x','1x','4x','1x'},...
                'RowSpacing',4,...
                'Padding',[4 4 4 4]);
            chainGrid.Layout.Row = [10 12];
            chainGrid.Layout.Column = 1;
            
            chainLabel = uilabel(chainGrid,...
                'Text','Preprocessing Chain',...
                'FontWeight','bold');
            chainLabel.Layout.Row = 1;
            chainLabel.Layout.Column = [1 4];
            
            chainDropdown = uidropdown(chainGrid,...
                'Editable','on',...
                'ValueChangedFcn',@obj.dropdownPreprocessingChainCallback);
            chainDropdown.Layout.Row = 2;
            chainDropdown.Layout.Column = [1 2];
            
            chainAdd = uibutton(chainGrid,...
                'Text','+',...
                'ButtonPushedFcn',@obj.dropdownNewPreprocessingChain);
            chainAdd.Layout.Row = 2;
            chainAdd.Layout.Column = 3;
            
            chainRem = uibutton(chainGrid,...
                'Text','-',...
                'ButtonPushedFcn',@obj.dropdownRemovePreprocessingChain);
            chainRem.Layout.Row = 2;
            chainRem.Layout.Column = 4;
            
            propGridPanel = uipanel(chainGrid);
            propGridPanel.Layout.Row = 3;
            propGridPanel.Layout.Column = [1 4];
            % preprocessing chain set dropdown
            obj.setDropdown = chainDropdown;
            
            % preprocessing chain propgrid
%             obj.propGrid = PropGrid(propGridPanel);
%             obj.propGrid.onPropertyChangedCallback = @obj.onParameterChangedCallback;
%             obj.propGrid.setShowToolbar(false);
            chainElementAdd = uibutton(chainGrid,...
                'Text','Add',...
                'ButtonPushedFcn',@(h,e)obj.addPreprocessing);
            chainElementAdd.Layout.Row = 4;
            chainElementAdd.Layout.Column = 1;
            
            chainElementDel = uibutton(chainGrid,...
                'Text','Delete',...
                'ButtonPushedFcn',@(h,e)obj.removePreprocessing);
            chainElementDel.Layout.Row = 4;
            chainElementDel.Layout.Column = 2;
            
            chainElementUp = uibutton(chainGrid,...
                'Text','/\',...
                'ButtonPushedFcn',@(h,e)obj.movePreprocessingUp);
            chainElementUp.Layout.Row = 4;
            chainElementUp.Layout.Column = 3;
            
            chainElementDwn = uibutton(chainGrid,...
                'Text','\/',...
                'ButtonPushedFcn',@(h,e)obj.movePreprocessingDown);
            chainElementDwn.Layout.Row = 4;
            chainElementDwn.Layout.Column = 4;
            
            qsAx = uiaxes(moduleLayout);
            qsAx.Title.String = 'Quasistatic signal';
            qsAx.ButtonDownFcn = @obj.quasistaticAxesButtonDownCallback;
            qsAx.XLabel.String = 'Cycle number';
            qsAx.YLabel.String = 'Data / a.u.';
            qsAx.Layout.Row = [1 6];
            qsAx.Layout.Column = 2;
            
            obj.hAxQuasistatic = qsAx;
            
            cyAx = uiaxes(moduleLayout);
            cyAx.Title.String = 'Selected cycles';
            cyAx.ButtonDownFcn = @obj.cycleAxesButtonDownCallback;
            cyAx.XLabel.String = 'Time /s';
            cyAx.YLabel.String = 'Data / a.u.';
            cyAx.Layout.Row = [7 12];
            cyAx.Layout.Column = 2;
            
            obj.hAxCycle = cyAx;
        end
        
        function globalYLimitsMenuClicked(obj,h,varargin)
            switch h.Checked
                case 'on', h.Checked = 'off';
                case 'off', h.Checked = 'on';
            end
            obj.setGlobalYLimits();
        end
        
        function setGlobalYLimits(obj,val)
            if nargin < 2
                switch obj.globalYLimitsMenu.Checked
                    case 'on', val = true;
                    case 'off', val = false;
                end
            end
            if val
                minmax = obj.getProject().getCurrentSensor().getDataMinMax(true);
                if diff(minmax) == 0
                    minmax = minmax + [-1 1];
                end
                ylim(obj.hAxCycle,minmax)
                ylim(obj.hAxQuasistatic,minmax);
            else
                ylim(obj.hAxCycle,'auto');
                ylim(obj.hAxQuasistatic,'auto');
            end
        end
        
        function allowed = canOpen(obj)
            p = obj.getProject();
            if isempty(p) || isempty(p.getCurrentCluster()) || isempty(p.getCurrentSensor())
                allowed = false;
                errordlg('Load at least one sensor.');
            else
                allowed = true;
            end
        end
        
        function onOpen(obj)
%             obj.setDropdown.setCallbacksActive(false);
%             obj.setDropdown.setItems(obj.getProject().poolPreprocessingChains.getCaption());
%             obj.setDropdown.setSelectedItem(obj.currentPreprocessingChain.getCaption());
%             obj.setDropdown.setCallbacksActive(false);
            
            obj.setDropdown.Items = ...
                cellfun(@(x) x,obj.getProject().poolPreprocessingChains.getCaption(),...
                'UniformOutput',false);
            obj.setDropdown.Value = obj.currentPreprocessingChain.getCaption();
            
%             obj.cyclePointSetDropdown.setCallbacksActive(false);
%             obj.cyclePointSetDropdown.setItems(obj.getProject().poolCyclePointSets.getCaption());
%             obj.cyclePointSetDropdown.setSelectedItem(obj.currentCyclePointSet.getCaption());
%             obj.cyclePointSetDropdown.setCallbacksActive(true);
            
            obj.cyclePointSetDropdown.Items = ...
                cellfun(@(x) x,obj.getProject().poolCyclePointSets.getCaption(),...
                'UniformOutput',false);
            obj.cyclePointSetDropdown.Value = obj.currentCyclePointSet.getCaption();
            
%             obj.indexPointSetDropdown.setCallbacksActive(false);
%             obj.indexPointSetDropdown.setItems(obj.getProject().poolIndexPointSets.getCaption());
%             obj.indexPointSetDropdown.setSelectedItem(obj.currentIndexPointSet.getCaption());
%             obj.indexPointSetDropdown.setCallbacksActive(true);
            
            obj.indexPointSetDropdown.Items = ...
                cellfun(@(x) x,obj.getProject().poolIndexPointSets.getCaption(),...
                'UniformOutput',false);
            obj.indexPointSetDropdown.Value = obj.currentIndexPointSet.getCaption();
            
            if obj.clusterHasChanged()
                obj.handleClusterChange(obj.getProject().getCurrentCluster(),obj.lastCluster);
            end
            if obj.sensorHasChanged()
                obj.handleSensorChange(obj.getProject().getCurrentSensor(),obj.lastSensor);
            end
            if obj.cyclePointSetHasChanged()
                obj.handleCyclePointSetChange();
            end
            if obj.indexPointSetHasChanged()
                obj.handleIndexPointSetChange();
            end
            
%             cSensors = obj.getProject().getSensors().getCaption('cluster');
%             cSensors = cellfun(@(x) char(x), cSensors, 'UniformOutput', false);
%             obj.hCompareWith.hSensorPopup.Items = cSensors;
%             obj.hCompareWith.hSensorPopup.Value = cSensors{1};
            obj.hCompareWith.hSensorPopup.String = obj.getProject().getSensors().getCaption('cluster');

            if isempty(obj.compareSensor)
                sensors = obj.getProject().getSensors();
                obj.compareSensor = sensors(1);
            end
        end

        function handleCyclePointSetChange(obj,ylimits)
            delete(obj.cyclePoints);
            sensor = obj.getProject().getCurrentSensor();
            if nargin < 2
                ylimits = sensor.getDataMinMax(true);
                ylimits = ylimits + [-.1 .1] * diff(ylimits);
            end
            p = sensor.getCyclePoints();
            axis(obj.hAxQuasistatic);
%             yyaxis(obj.hAxQuasistatic,'left');
            obj.cyclePoints = p.makeGraphicsObject('cycle',true);
            obj.cyclePoints.draw(obj.hAxQuasistatic,sensor,ylimits);
            [obj.cyclePoints.getPoint().onPositionChanged] = deal(@obj.cyclePointPositionChangedCallback);
            [obj.cyclePoints.onDraggedCallback] = deal(@obj.cyclePointDraggedCallback);
            [obj.cyclePoints.onDragStartCallback] = deal(@obj.cyclePointDragStartCallback);
            [obj.cyclePoints.onDragStopCallback] = deal(@obj.cyclePointDragStopCallback);
            [obj.cyclePoints.onDeleteRequestCallback] = deal(@obj.deletePointCallback);
            obj.populateCyclePointsTable();
            obj.updateSensorPlots();
        end
        
        function handleIndexPointSetChange(obj,ylimits)
            delete(obj.indexPoints);
            sensor = obj.getProject().getCurrentSensor();
            if nargin < 2
                ylimits = sensor.getDataMinMax(true);
                ylimits = ylimits + [-.1 .1] * diff(ylimits);
            end
            p = sensor.getIndexPoints();
            axis(obj.hAxCycle);
%             yyaxis(obj.hAxCycle,'left');
            axis(obj.hAxCycle);
            obj.indexPoints = p.makeGraphicsObject('index',true);
            obj.indexPoints.draw(obj.hAxCycle,sensor,ylimits);
            [obj.indexPoints.getPoint().onPositionChanged] = deal(@obj.indexPointPositionChangedCallback);
            [obj.indexPoints.onDraggedCallback] = deal(@obj.indexPointDraggedCallback);
            [obj.indexPoints.onDragStartCallback] = deal(@obj.indexPointDragStartCallback);
            [obj.indexPoints.onDragStopCallback] = deal(@obj.indexPointDragStopCallback);
            [obj.indexPoints.onDeleteRequestCallback] = deal(@obj.deletePointCallback);
            obj.populateIndexPointsTable();
            obj.updateSensorPlots();
        end
        
        function handleClusterChange(obj,newCluster,oldCluster)
            obj.deleteAllPlots();
%             obj.hCompareWith.hSamplingPeriodEdit.String = num2str(newCluster.samplingPeriod);
%             obj.hCompareWith.hOffsetEdit.String = num2str(newCluster.offset);
%             obj.hCompareWith.hVirtualOffsetEdit.String = num2str(newCluster.indexOffset);
            
            obj.hCompareWith.hSamplingPeriodEdit.Value = newCluster.samplingPeriod;
            obj.hCompareWith.hOffsetEdit.Value = newCluster.offset;
            obj.hCompareWith.hVirtualOffsetEdit.Value = newCluster.indexOffset;   
        end
        
        function handleSensorChange(obj,newSensor,oldSensor)
            newSensor.getCaption()
            newSensor.preComputePreprocessedData();
            
%             obj.plotSensor('current','raw');
            obj.plotSensor('current','pp');
            
            ylimits = newSensor.getDataMinMax(true);
            ylimits = ylimits + [-.1 .1] * diff(ylimits);

            if ~obj.cyclePointSetHasChanged(newSensor.cyclePointSet)
                obj.cyclePoints.updatePosition(newSensor);
                obj.cyclePoints.setYLimits(ylimits);
            else
%                 obj.cyclePointSetDropdown.setCallbacksActive(false);
%                 obj.cyclePointSetDropdown.setSelectedItem(obj.currentCyclePointSet.getCaption());
%                 obj.cyclePointSetDropdown.setCallbacksActive(true);
                
                obj.cyclePointSetDropdown.Value = obj.currentCyclePointSet.getCaption();
                obj.handleCyclePointSetChange(ylimits);
            end
            
            if ~obj.indexPointSetHasChanged(newSensor.indexPointSet)
                obj.indexPoints.updatePosition(newSensor);
                obj.indexPoints.setYLimits(ylimits);
            else
%                 obj.indexPointSetDropdown.setCallbacksActive(false);
%                 obj.indexPointSetDropdown.setSelectedItem(obj.currentIndexPointSet.getCaption());
%                 obj.indexPointSetDropdown.setCallbacksActive(true);
                
                obj.indexPointSetDropdown.Value = obj.currentIndexPointSet.getCaption();
                obj.handleIndexPointSetChange(ylimits);
            end
            
%             obj.setDropdown.setCallbacksActive(false);
%             obj.setDropdown.setSelectedItem(obj.currentPreprocessingChain.getCaption());
%             obj.setDropdown.setCallbacksActive(true);
            
            obj.setDropdown.Value = obj.currentPreprocessingChain.getCaption();
            
            obj.refreshPropGrid();
            
%             obj.cyclePointSetDropdown.setCallbacksActive(false);
%             obj.cyclePointSetDropdown.setSelectedItem(obj.currentCyclePointSet.getCaption());
%             obj.populateCyclePointsTable();
%             obj.cyclePointSetDropdown.setCallbacksActive(true);
%             
%             obj.indexPointSetDropdown.setCallbacksActive(false);
%             obj.indexPointSetDropdown.setSelectedItem(obj.currentIndexPointSet.getCaption());
%             obj.populateCyclePointsTable();
%             obj.indexPointSetDropdown.setCallbacksActive(true);
            
            if ~isempty(oldSensor)
                oldSensor.deletePreprocessedData();
            end
        end
        
        function onCurrentClusterChanged(obj,cluster,oldCluster)
            obj.handleClusterChange(cluster,oldCluster);
        end
        
        function onCurrentSensorChanged(obj,sensor,oldSensor)
            obj.handleSensorChange(sensor,oldSensor);
        end
        
        function onCurrentCyclePointSetChanged(obj,cps)
            obj.cyclePointSetDropdown.setSelectedItem(cps.getCaption());
        end
        
        function onCurrentIndexPointSetChanged(obj,ips)
            obj.indexPointSetDropdown.setSelectedItem(ips.getCaption());
        end
        
        function onCurrentPreprocessingChainChanged(obj,ppc)
            obj.setDropdown.setSelectedItem(ppc.getCaption());
        end
        
        function val = get.currentPreprocessingChain(obj)
            val = obj.getProject().currentPreprocessingChain;
        end
        
        function set.currentPreprocessingChain(obj,val)
            obj.getProject().currentPreprocessingChain = val;
        end

        %% dropdown callbacks for preprocessing chains
        function dropdownNewPreprocessingChain(obj,h)
            ppc = obj.getProject().addPreprocessingChain();
            obj.currentPreprocessingChain = ppc;
            h.appendItem(ppc.getCaption());
            h.selectLastItem();
            obj.main.populateSensorSetTable();
        end
        
        function dropdownRemovePreprocessingChain(obj,h)
            idx = h.getSelectedIndex();
            ppcs = obj.getProject().poolPreprocessingChains;
            ppc = ppcs(idx);
            sensorsWithPPC = obj.getProject().checkForSensorsWithPreprocessingChain(ppc);
            
            if numel(sensorsWithPPC) > 1  % the current sensor always has the PPC to delete
                choices = {};
                if numel(ppcs) > 1
                    choices{1} = 'Choose a replacement';
                end
                choices{end+1} = 'Replace with new';
                choices{end+1} = 'Cancel';
                answer = questdlg('The preprocessing chain is used in other sensors. What would you like to do?', ...
                    'Conflict', ...
                    choices{:},'Cancel');
                switch answer
                    case 'Choose a replacement'
                        ppcs(idx) = [];
                        [sel,ok] = listdlg('ListString',ppcs.getCaption(), 'SelectionMode','single');
                        if ~ok
                            return
                        end
                        obj.getProject().replacePreprocessingChainInSensors(ppc,ppcs(sel));
                        newPPC = ppcs(sel);
                    case 'Replace with new'
                        newPPC = obj.getProject().addPreprocessingChain();
                        h.appendItem(newPPC.getCaption());
                        obj.getProject().replacePreprocessingChainInSensors(ppc,newPPC);
                    case 'Cancel'
                        return
                end
            else
                % if there is only one PPC, it will now be deleted
                % so we have to add a new one
                if numel(obj.getProject().poolPreprocessingChains) == 1
                    newPPC = obj.getProject().addPreprocessingChain();
                    h.appendItem(newPPC.getCaption());
                else
                    if idx == 1
                        newPPC = obj.getProject().poolPreprocessingChains(2);
                    else
                        newPPC = obj.getProject().poolPreprocessingChains(idx-1);
                    end
                end
            end

            obj.currentPreprocessingChain = newPPC;
            obj.getProject().removePreprocessingChain(ppc);
                
            h.removeItemAt(idx);
            h.setSelectedItem(obj.currentPreprocessingChain.getCaption());
            obj.main.populateSensorSetTable();
%             obj.refreshPropGrid();
%             obj.getCurrentSensor().preComputePreprocessedData();
%             obj.updatePlotsInPlace();
        end
        
        function dropdownPreprocessingChainCallback(obj, event)
            if event.Edited
                dropdownPreprocessingChainRename(obj,h,newName,index)
            else
                dropdownPreprocessingChainChange(obj,h,newItem,newIndex)
            end
        end
        
        function dropdownPreprocessingChainRename(obj,h,newName,index)
            newName = matlab.lang.makeUniqueStrings(newName,cellstr(obj.getProject().poolPreprocessingChains.getCaption()));
            obj.getProject().poolPreprocessingChains(index).setCaption(newName);
            h.renameItemAt(newName,h.getSelectedIndex());
            obj.main.populateSensorSetTable();
        end
        
        function dropdownPreprocessingChainChange(obj,h,newItem,newIndex)
            obj.currentPreprocessingChain = ...
                obj.getProject().poolPreprocessingChains(newIndex);
            disp('callback')
            obj.refreshPropGrid();
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.updatePlotsInPlace();
            obj.main.populateSensorSetTable();
        end
        
        %% dropdown callbacks for cycle point sets
        function dropdownNewCyclePointSet(obj,h)
            cps = obj.getProject().addCyclePointSet();
            obj.currentCyclePointSet = cps;
%             obj.addCyclePoint(0);
            h.appendItem(cps.getCaption());
            h.selectLastItem();
%             obj.handleCyclePointSetChange();
%             obj.main.populateSensorSetTable();
        end
        
        function dropdownRemoveCyclePointSet(obj,h)
            idx = h.getSelectedIndex();
            cpss = obj.getProject().poolCyclePointSets;
            cps = cpss(idx);
            sensorsWithFds = obj.getProject().checkForSensorsWithCyclePointSet(cps);
            
            if numel(sensorsWithFds) > 1  % the current sensor always has the FDS to delete
                choices = {};
                if numel(cpss) > 1
                    choices{1} = 'Choose a replacement';
                end
                choices{end+1} = 'Replace with new';
                choices{end+1} = 'Cancel';
                answer = questdlg('The feature definition set is used in other sensors. What would you like to do?', ...
                    'Conflict', ...
                    choices{:},'Cancel');
                switch answer
                    case 'Choose a replacement'
                        cpss(idx) = [];
                        [sel,ok] = listdlg('ListString',cpss.getCaption(), 'SelectionMode','single');
                        if ~ok
                            return
                        end
                        obj.getProject().replaceCyclePointSetInSensors(cps,cpss(sel));
                        newCps = cpss(sel);
                    case 'Replace with new'
                        newCps = obj.getProject().addCyclePointSet();
                        h.appendItem(newCps.getCaption());
                        obj.getProject().replaceCyclePointSetInSensors(cps,newCps);
                    case 'Cancel'
                        return
                end
            else
                % if there is only one CPS, it will now be deleted
                % so we have to add a new one
                if numel(obj.getProject().poolCyclePointSets) == 1
                    newCps = obj.getProject().addCyclePointSet();
                    h.appendItem(newCps.getCaption());
                else
                    if idx == 1
                        newCps = obj.getProject().poolCyclePointSets(2);
                    else
                        newCps = obj.getProject().poolCyclePointSets(idx-1);
                    end
                end
            end

            obj.currentCyclePointSet = newCps;
            obj.getProject().removeCyclePointSet(cps);
                
            h.removeItemAt(idx);
            h.setSelectedItem(obj.currentCyclePointSet.getCaption());
            obj.handleCyclePointSetChange();
            obj.main.populateSensorSetTable();
        end
        function dropdownCyclePointSetCallback(obj,event)
           if event.Edited
               dropdownCyclePointSetRename(obj,h,newName,index)
           else 
               dropdownCyclePointSetChange(obj,h,newItem,newIndex)
           end
        end
        function dropdownCyclePointSetRename(obj,h,newName,index)
            newName = matlab.lang.makeUniqueStrings(newName,cellstr(obj.getProject().poolCyclePointSets.getCaption()));
            obj.getProject().poolCyclePointSets(index).setCaption(newName);
            h.renameItemAt(newName,h.getSelectedIndex());
            obj.handleCyclePointSetChange();
            obj.main.populateSensorSetTable();
        end
        
        function dropdownCyclePointSetChange(obj,h,newItem,newIndex)
            obj.currentCyclePointSet = ...
                obj.getProject().poolCyclePointSets(newIndex);
            obj.handleCyclePointSetChange();
            obj.main.populateSensorSetTable();
        end        
        
        %% dropdown callbacks for index point sets
        function dropdownNewIndexPointSet(obj,h)
            ips = obj.getProject().addIndexPointSet();
            obj.currentIndexPointSet = ips;
%             obj.addIndexPoint(0);
            h.appendItem(ips.getCaption());
            h.selectLastItem();
%             obj.handleIndexPointSetChange();
%             obj.main.populateSensorSetTable();
        end
        
        function dropdownRemoveIndexPointSet(obj,h)
            idx = h.getSelectedIndex();
            ipss = obj.getProject().poolIndexPointSets;
            ips = ipss(idx);
            sensorsWithFds = obj.getProject().checkForSensorsWithIndexPointSet(ips);
            
            if numel(sensorsWithFds) > 1  % the current sensor always has the IPS to delete
                choices = {};
                if numel(ipss) > 1
                    choices{1} = 'Choose a replacement';
                end
                choices{end+1} = 'Replace with new';
                choices{end+1} = 'Cancel';
                answer = questdlg('The feature definition set is used in other sensors. What would you like to do?', ...
                    'Conflict', ...
                    choices{:},'Cancel');
                switch answer
                    case 'Choose a replacement'
                        ipss(idx) = [];
                        [sel,ok] = listdlg('ListString',ipss.getCaption(), 'SelectionMode','single');
                        if ~ok
                            return
                        end
                        obj.getProject().replaceIndexPointSetInSensors(ips,ipss(sel));
                        newIps = ipss(sel);
                    case 'Replace with new'
                        newIps = obj.getProject().addIndexPointSet();
                        h.appendItem(newIps.getCaption());
                        obj.getProject().replaceIndexPointSetInSensors(ips,newIps);
                    case 'Cancel'
                        return
                end
            else
                % if there is only one FDS, it will now be deleted
                % so we have to add a new one
                if numel(obj.getProject().poolIndexPointSets) == 1
                    newIps = obj.getProject().addIndexPointSet();
                    h.appendItem(newIps.getCaption());
                else
                    if idx == 1
                        newIps = obj.getProject().poolIndexPointSets(2);
                    else
                        newIps = obj.getProject().poolIndexPointSets(idx-1);
                    end
                end
            end

            obj.currentIndexPointSet = newIps;
            obj.getProject().removeIndexPointSet(ips);
                
            h.removeItemAt(idx);
            h.setSelectedItem(obj.currentIndexPointSet.getCaption());
            obj.handleIndexPointSetChange();
            obj.main.populateSensorSetTable();
        end
        
        function dropdownIndexPointSetCallback(obj,event)
           if event.Edited
               dropdownIndexPointSetRename(obj,h,newName,index)
           else
               dropdownIndexPointSetChange(obj,h,newItem,newIndex)
           end
        end
        function dropdownIndexPointSetRename(obj,h,newName,index)
            newName = matlab.lang.makeUniqueStrings(newName,cellstr(obj.getProject().poolIndexPointSets.getCaption()));
            obj.getProject().poolIndexPointSets(index).setCaption(newName);
            h.renameItemAt(newName,h.getSelectedIndex());
            obj.handleIndexPointSetChange();
            obj.main.populateSensorSetTable();
        end
        
        function dropdownIndexPointSetChange(obj,h,newItem,newIndex)
            obj.currentIndexPointSet = ...
                obj.getProject().poolIndexPointSets(newIndex);
            obj.handleIndexPointSetChange();
            obj.main.populateSensorSetTable();
        end
        
        %%
        function val = get.currentCyclePointSet(obj)
            val = obj.getProject().currentCyclePointSet;
        end
        
        function set.currentCyclePointSet(obj,val)
            obj.getProject().currentCyclePointSet = val;
        end
        
        function val = get.currentIndexPointSet(obj)
            val = obj.getProject().currentIndexPointSet;
        end
        
        function set.currentIndexPointSet(obj,val)
            obj.getProject().currentIndexPointSet = val;
        end
        
        function populateCyclePointsTable(obj)
            %%
            % write data to the table, style and configure it, activate callbacks
            gPoints = obj.cyclePoints;
            captions = cellstr(gPoints.getPoint().getCaption()');
            positions = num2cell(gPoints.getPosition());
            time_positions = num2cell(gPoints.getTimePosition());
            % TODO re-add the colour functionality
%             colors = num2cell(gPoints.getPoint().getJavaColor());
%             data = [captions, positions, time_positions, colors];
            data = [captions, positions, time_positions];

            t = obj.cyclePointTable;
            t.ColumnName = {'caption','cycle','time in s'};
%             t.setData(data,{'caption','cycle','time in s','color'});
%             t.setRowObjects(gPoints);
            t.ColumnFormat({'char','numeric','numeric'});
            t.ColumnEditable = [true true true true];
            t.Data = data;
            
%             t.setSortingEnabled(false)
%             t.setFilteringEnabled(false);
%             t.setColumnReorderingAllowed(false);
%             t.jTable.sortColumn(3);
%             t.jTable.setAutoResort(false)
            obj.cyclePointTable.CellEditCallback = ...
                @(src, event) obj.cyclePointTableEditCallback(src, event);
            obj.cyclePointTable.onDataChangedCallback = @obj.cyclePointTableDataChangeCallback;
            obj.cyclePointTable.onMouseClickedCallback = @obj.cyclePointTableMouseClickedCallback;
        end
        
        function populateIndexPointsTable(obj)
            %%
            % write data to the table, style and configure it, activate callbacks
            gPoints = obj.indexPoints;
            captions = cellstr(gPoints.getPoint().getCaption()');
            positions = num2cell(gPoints.getPosition());
            colors = num2cell(gPoints.getPoint().getJavaColor());
            data = [captions, positions, colors];
            
            t = obj.indexPointTable;
            t.setData(data,{'caption','point','color'});
            t.setRowObjects(gPoints);
            t.setColumnClasses({'str','double','clr'});
            t.setColumnsEditable([true true true]);
            t.setSortingEnabled(false)
            t.setFilteringEnabled(false);
            t.setColumnReorderingAllowed(false);
            t.jTable.sortColumn(2);
            t.jTable.setAutoResort(false)
            obj.indexPointTable.onDataChangedCallback = @obj.indexPointTableDataChange;
            obj.indexPointTable.onMouseClickedCallback = @obj.indexPointTableMouseClickedCallback;
        end
        
        function cyclePointDraggedCallback(obj,gPoint)
            %%
            % update the position in the table when the point is dragged
            row = obj.cyclePointTable.getRowObjectRow(gPoint);
            obj.cyclePointTable.setValue(gPoint.getPosition(),row,2);
            obj.cyclePointTable.setValue(gPoint.getTimePosition(),row,3);
        end
        
        function indexPointDraggedCallback(obj,gPoint)
            %%
            % update the position in the table when the point is dragged
            row = obj.indexPointTable.getRowObjectRow(gPoint);
            obj.indexPointTable.setValue(gPoint.getPosition(),row,2);
        end

        function cyclePointDragStartCallback(obj,gObj)
            %%
            % disable table callbacks (to omit "wrong" data changed events),
            % move the current selection to the corresponding row, and make
            % the corresponding cycle line bold
            obj.cyclePointTable.setCallbacksActive(false);
            objRow = obj.cyclePointTable.getRowObjectRow(gObj);
            obj.cyclePointTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
            idx = ismember(obj.cyclePoints,gObj);
            obj.hLines.current.raw.cycle(idx).LineWidth = 2;
            obj.hLines.current.pp.cycle(idx).LineWidth = 2;
            if obj.compareSensorDrawn()
                obj.hLines.compare.raw.cycle(idx).LineWidth = 2;
                obj.hLines.compare.pp.cycle(idx).LineWidth = 2;
            end
        end
        
        function cyclePointDragStopCallback(obj,gObj)
            %%
            % re-enable table callbacks and set selection again (can get
            % messed up, probably due to dynamic sorting in the table?),
            % set cycle line width back to normal
            pause(0.01); % to make sure all callbacks have been processed
            idx = ismember(obj.cyclePoints,gObj);
            obj.hLines.current.raw.cycle(idx).LineWidth = 1;
            obj.hLines.current.pp.cycle(idx).LineWidth = 1;
            if obj.compareSensorDrawn()
                obj.hLines.compare.raw.cycle(idx).LineWidth = 1;
                obj.hLines.compare.pp.cycle(idx).LineWidth = 1;
            end
            objRow = obj.cyclePointTable.getRowObjectRow(gObj);
            obj.cyclePointTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
%             obj.cyclePointTable.setRowHeader();
            obj.cyclePointTable.setCallbacksActive(true);
        end
        
        function indexPointDragStartCallback(obj,gObj)
            %%
            % disable table callbacks (to omit "wrong" data changed events),
            % move the current selection to the corresponding row, and make
            % the corresponding quasistatic line bold
            obj.indexPointTable.setCallbacksActive(false);
            objRow = obj.indexPointTable.getRowObjectRow(gObj);
            obj.indexPointTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
            idx = ismember(obj.indexPoints,gObj);
            obj.hLines.current.raw.quasistatic(idx).LineWidth = 2;
            obj.hLines.current.pp.quasistatic(idx).LineWidth = 2;
            if obj.compareSensorDrawn()
                obj.hLines.compare.raw.quasistatic(idx).LineWidth = 2;
                obj.hLines.compare.pp.quasistatic(idx).LineWidth = 2;
            end
        end
        
        function indexPointDragStopCallback(obj,gObj)
            %%
            % re-enable table callbacks and set selection again (can get
            % messed up, probably due to dynamic sorting in the table?),
            % set quasistatic line width back to normal
            pause(0.01); % to make sure all callbacks have been processed
            idx = ismember(obj.indexPoints,gObj);
            obj.hLines.current.raw.quasistatic(idx).LineWidth = 1;
            obj.hLines.current.pp.quasistatic(idx).LineWidth = 1;
            if obj.compareSensorDrawn()
                obj.hLines.compare.raw.quasistatic(idx).LineWidth = 1;
                obj.hLines.compare.pp.quasistatic(idx).LineWidth = 1;
            end
            objRow = obj.indexPointTable.getRowObjectRow(gObj);
            obj.indexPointTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
%             obj.indexPointTable.setRowHeader();
            obj.indexPointTable.setCallbacksActive(true);
        end
        
        function cyclePointTableDataChangeCallback(obj,rc,v)
            %%
            % write changes from the table to the point object
            for i = 1:size(rc,1)
                o = obj.cyclePointTable.getRowObjectsAt(rc(i,1));
                switch rc(i,2)
                    case 1
                        o.getObject().setCaption(v{i});
                    case 2
                        o.setPosition(v{i},obj.getProject().getCurrentSensor());
                        obj.cyclePointTable.setValue(o.getTimePosition(),rc(i,1),3);
                    case 3
                        o.setTimePosition(v{i});
                        obj.cyclePointTable.setValue(o.getPosition(),rc(i,1),2);
                    case 4
                        o.setColor(v{i});
                        idx = ismember(obj.cyclePoints,o);
                        obj.hLines.current.raw.cycle(idx).Color = changeColorShade(obj.cyclePoints(idx).getPoint().getColor(),obj.rawColorShade);
                        obj.hLines.current.pp.cycle(idx).Color = obj.cyclePoints(idx).getPoint().getColor();
                end
            end
            obj.cyclePointTable.jTable.sortColumn(3);
        end
        
        function indexPointTableDataChange(obj,rc,v)
            %%
            % write changes from the table to the point object
            for i = 1:size(rc,1)
                o = obj.indexPointTable.getRowObjectsAt(rc(i,1));
                switch rc(i,2)
                    case 1
                        o.getObject().setCaption(v{i});
                    case 2
                        o.setPosition(v{i},obj.getProject().getCurrentSensor());
                    case 3
                        o.setColor(v{i});
                        idx = ismember(obj.indexPoints,o);
                        obj.hLines.current.raw.quasistatic(idx).Color = changeColorShade(obj.indexPoints(idx).getPoint().getColor(),obj.rawColorShade);
                        obj.hLines.current.pp.quasistatic(idx).Color = obj.indexPoints(idx).getPoint().getColor();
                end
            end
        end
        
        function cyclePointPositionChangedCallback(obj,point,~)
            %%
            % update the corresponding lines in cyclic plot when a
            % point selector in the quasistatic plot has moved
            idx = ismember(obj.cyclePoints.getPoint(),point);
            cycle_point = point.getCyclePosition(point.currentCluster);
            if ~isnan(cycle_point)
                d = obj.getProject().getCurrentSensor().getCycleAt(point.getCyclePosition(point.currentCluster));
                obj.hLines.current.raw.cycle(idx).YData = d;
                d = obj.getProject().getCurrentSensor().getCycleAt(point.getCyclePosition(point.currentCluster),true);
                obj.hLines.current.pp.cycle(idx).YData = d;
            end
%             d = obj.compareSensor.getCycleAt(point.getCyclePosition(point.currentCluster));
%             obj.hLines.compare.raw.cycle(idx).YData = d;
%             d = obj.compareSensor.getCycleAt(point.getCyclePosition(point.currentCluster),true);
%             obj.hLines.compare.pp.cycle(idx).YData = d;            
        end
        
        function indexPointPositionChangedCallback(obj,point,~)
            %%
            % update the corresponding lines in quasistatic plot when a
            % point selector in the cycle plot has moved
            idx = ismember(obj.indexPoints.getPoint(),point);
            d = obj.getProject().getCurrentSensor().getQuasistaticSignalAtIndex(point.getIndexPosition(point.currentCluster));
            obj.hLines.current.raw.quasistatic(idx).YData = d;
            d = obj.getProject().getCurrentSensor().getQuasistaticSignalAtIndex(point.getIndexPosition(point.currentCluster),true);
            obj.hLines.current.pp.quasistatic(idx).YData = d;
%             d = obj.compareSensor.getQuasistaticSignalAtIndex(point.getIndexPosition(point.currentCluster));
%             obj.hLines.compare.raw.quasistatic(idx).YData = d;
%             d = obj.compareSensor.getQuasistaticSignalAtIndex(point.getIndexPosition(point.currentCluster),true);
%             obj.hLines.compare.pp.quasistatic(idx).YData = d;            
        end
        
        function cyclePointTableMouseClickedCallback(obj,visRC,actRC)
            %%
            % highlight the corresponding graphics object when the mouse
            % button is pressed on a table row
            o = obj.cyclePointTable.getRowObjectsAt(visRC(1));
            o.setHighlight(true);
            obj.cyclePointTable.onMouseReleasedCallback = @()obj.cyclePointTableMouseReleasedCallback(o);
        end
        
        function indexPointTableMouseClickedCallback(obj,visRC,actRC)
            %%
            % highlight the corresponding graphics object when the mouse
            % button is pressed on a table row
            o = obj.indexPointTable.getRowObjectsAt(visRC(1));
            o.setHighlight(true);
            obj.indexPointTable.onMouseReleasedCallback = @()obj.indexPointTableMouseReleasedCallback(o);
        end
        
        function cyclePointTableMouseReleasedCallback(obj,gObject)
            %%
            % un-highlight the previously highlighted graphics object when
            % the mouse button is released again
            gObject.setHighlight(false);
            obj.cyclePointTable.onMouseReleasedCallback = [];
        end
        
        function indexPointTableMouseReleasedCallback(obj,gObject)
            %%
            % un-highlight the previously highlighted graphics object when
            % the mouse button is released again
            gObject.setHighlight(false);
            obj.indexPointTable.onMouseReleasedCallback = [];
        end
        
        function compareWithCheckboxCallback(obj,~,~)
            checked = obj.hCompareWith.hCompareWithCheckbox.Value;
            if checked
%                 obj.plotSensor('compare','raw');
                obj.plotSensor('compare','pp');
            else
%                 obj.deleteSensorPlot('compare','raw');
                obj.deleteSensorPlot('compare','pp');
            end
%             obj.compareSensor.preComputePreprocessedData();
            disp(checked)
        end
        
        function compareWithSensorPopup(obj,~,~)
            value = obj.hCompareWith.hSensorPopup.Value;
            if obj.compareSensor ~= obj.getCurrentSensor()
                obj.compareSensor.deletePreprocessedData();
            end
            sensors = obj.getProject().getSensors();
            obj.compareSensor = sensors(value);
            obj.compareSensor.preComputePreprocessedData();
            disp(value)
            if obj.hCompareWith.hCompareWithCheckbox.Value
%                 obj.deleteSensorPlot('compare','raw');
                obj.deleteSensorPlot('compare','pp');
%                 obj.plotSensor('compare','raw');
                obj.plotSensor('compare','pp');
            end            
        end        
        
        function samplingPeriodEditCallback(obj,~,~)
            newNum = str2double(obj.hCompareWith.hSamplingPeriodEdit.String);
            if (~isnumeric(newNum)) || isnan(newNum)
                obj.hCompareWith.hSamplingPeriodEdit.String = ...
                    num2str(obj.getProject().getCurrentCluster().samplingPeriod);
                return
            end
            obj.getCurrentCluster().samplingPeriod = newNum;
            obj.cyclePoints.updatePosition(obj.getProject().getCurrentSensor());
            obj.updatePlotsInPlace();
            obj.populateCyclePointsTable();
            obj.populateIndexPointsTable();
        end
        
        function offsetEditCallback(obj,~,~)
            newNum = str2double(obj.hCompareWith.hOffsetEdit.String);
            if ~isnumeric(newNum) || isnan(newNum)
                obj.hCompareWith.hOffsetEdit.String = ...
                    num2str(obj.getProject().getCurrentCluster().offset);
                return
            end
            obj.getProject().getCurrentCluster().offset = newNum;
            iOffset = obj.getProject().getCurrentCluster().getAutoIndexOffset(obj.getProject().clusters);
            obj.getProject().getCurrentCluster().indexOffset = iOffset;
            obj.hCompareWith.hVirtualOffsetEdit.String = num2str(iOffset);
            obj.updatePlotsInPlace();
            obj.cyclePoints.updatePosition(obj.getProject().getCurrentSensor());
            for i = 1:numel(obj.cyclePoints)
                id = obj.cyclePointTable.getRowObjectRow(obj.cyclePoints(i));
                gPoint = obj.cyclePoints(i);
                obj.cyclePointTable.setValue(gPoint.getTimePosition(),id,3);
                obj.cyclePointTable.setValue(gPoint.getPosition(),id,2);
            end
        end
        
        function virtualOffsetEditCallback(obj,~,~)
            newNum = str2double(obj.hCompareWith.hVirtualOffsetEdit.String);
            if ~isnumeric(newNum) || isnan(newNum)
                obj.hCompareWith.hVirtualOffsetEdit.String = ...
                    num2str(obj.getProject().getCurrentCluster().indexOffset);
                return
            end
            obj.getProject().getCurrentCluster().indexOffset = newNum;
            obj.updatePlotsInPlace();
        end
        
        function deleteSensorPlot(obj,type,pp)
            delete(obj.hLines.(type).(pp).cycle);
            delete(obj.hLines.(type).(pp).quasistatic);
            obj.hLines.(type).(pp).cycle = [];
            obj.hLines.(type).(pp).quasistatic = [];
            xlim(obj.hAxCycle,'auto');
            xlim(obj.hAxQuasistatic,'auto');
        end
        
        function deleteAllPlots(obj)
            types = {'current','compare'};
            pp = {'raw','pp'};
            views = {'cycle','quasistatic'};
            for t = 1:numel(types)
                for p = 1:numel(pp)
                    for v = 1:numel(views)
                        if ~isempty(obj.hLines.(types{t}).(pp{p}).(views{v}))
                            try
                                delete(obj.hLines.(types{t}).(pp{p}).(views{v}));
                            catch
                            end
                            obj.hLines.(types{t}).(pp{p}).(views{v}) = [];
                        end
                    end
                end
            end
        end
        
        function updateSensorPlots(obj)
%             obj.plotSensor('current','raw');
            obj.plotSensor('current','pp');
            if obj.hCompareWith.hCompareWithCheckbox.Value
%                 obj.plotSensor('compare','raw');
                obj.plotSensor('compare','pp');                
            end
        end
        
        function plotSensor(obj,type,pp)
            switch type
                case 'current'
                    sensor = obj.getCurrentSensor();
                    style = '-k';
                case 'compare'
                    sensor = obj.compareSensor;
                    style = '--k';
            end
            switch pp
                case 'raw'
%                     ppBool = false;
%                     side = 'left';
%                     colorShade = obj.rawColorShade;
                    return
                case 'pp'
                    ppBool = true;
                    side = 'left';
                    colorShade = 0;
            end
            
            qsSignals = sensor.getSelectedQuasistaticSignals(ppBool);
            cSignals = sensor.getSelectedCycles(ppBool);

            numQsSignalsEqualsPoints = numel(obj.hLines.(type).(pp).quasistatic) == size(qsSignals,2);
            numCycleSignalsEqualsPoints = numel(obj.hLines.(type).(pp).cycle) == size(cSignals,1);
            if ~(numQsSignalsEqualsPoints && numCycleSignalsEqualsPoints)
                obj.deleteSensorPlot(type,pp);
                minmax = obj.getCurrentSensor().getDataMinMax(true);
                if obj.compareSensorDrawn()
                    minmax = [minmax,obj.compareSensor.getDataMinMax(true)];
                end
                minData = min(minmax);
                maxData = max(minmax);
            end
            
            if isempty(obj.hLines.(type).(pp).quasistatic)
                x = repmat((1:size(qsSignals,1))',1,size(qsSignals,2));
                axis(obj.hAxQuasistatic);
%                 yyaxis(obj.hAxQuasistatic,side);
                hold(obj.hAxQuasistatic,'on');
                obj.hLines.(type).(pp).quasistatic = plot(obj.hAxQuasistatic,x,qsSignals,style);
                hold(obj.hAxQuasistatic,'off');
            else
                for i = 1:numel(obj.hLines.(type).(pp).quasistatic)
                    obj.hLines.(type).(pp).quasistatic(i).YData = qsSignals(:,i);
                end
            end
            
            if isempty(obj.hLines.(type).(pp).cycle)
                x = repmat(sensor.abscissa,size(cSignals,1),1);
                axis(obj.hAxCycle);
%                 yyaxis(obj.hAxCycle,side);
                hold(obj.hAxCycle,'on');
                if size(sensor.abscissa,2) > 1
                    obj.hLines.(type).(pp).cycle = plot(obj.hAxCycle,x',cSignals',style);
                else   %if there is no cycle, the one cycle point is replicated, so that plot() still creates one Line for each selected cycle
                    obj.hLines.(type).(pp).cycle = plot(obj.hAxCycle,repmat(x',2,1),repmat(cSignals',2,1),style);
                end
                hold(obj.hAxCycle,'off');
            else
                for i = 1:numel(obj.hLines.(type).(pp).cycle)
                    obj.hLines.(type).(pp).cycle(i).XData = sensor.abscissa;
                    obj.hLines.(type).(pp).cycle(i).YData = cSignals(i,:);
                end
            end
            
            cClr = sensor.getCyclePoints().getColorCell();
            cClr = changeColorShade(cClr,colorShade);
            [obj.hLines.(type).(pp).cycle.Color] = deal(cClr{:});
            cClr = sensor.getIndexPoints().getColorCell();
            cClr = changeColorShade(cClr,colorShade);
            [obj.hLines.(type).(pp).quasistatic.Color] = deal(cClr{:});
            
            if exist('minData','var')
                obj.cyclePoints.setYLimits([minData,maxData]);
                obj.indexPoints.setYLimits([minData,maxData]);
            end
            
            obj.setGlobalYLimits();
%             xlim(obj.hAxCycle,'auto');
            set(obj.hAxCycle, 'XLimSpec', 'Tight');
            set(obj.hAxQuasistatic, 'XLimSpec', 'Tight');

            if ~isempty(sensor.abscissaSensor)
                xlabel(obj.hAxCycle,sensor.abscissaSensor.getCaption());
            else
                xlabel(obj.hAxCycle,sensor.abscissaType);
            end
        end
        
        function updatePlotsInPlace(obj)
            sensor = obj.getProject().getCurrentSensor();
            
%             d = sensor.getSelectedQuasistaticSignals();
%             for i = 1:numel(obj.hLines.current.raw.quasistatic)
%                 obj.hLines.current.raw.quasistatic(i).YData = d(:,i);
%             end
% 
%             d = sensor.getSelectedCycles()';
%             for i = 1:numel(obj.hLines.current.raw.cycle)
%                 obj.hLines.current.raw.cycle(i).YData = d(:,i);
%                 obj.hLines.current.raw.cycle(i).XData = sensor.abscissa;
%             end

            d = sensor.getSelectedQuasistaticSignals(true);
            for i = 1:numel(obj.hLines.current.pp.quasistatic)
                obj.hLines.current.pp.quasistatic(i).YData = d(:,i);
            end

            d = sensor.getSelectedCycles(true)';
            for i = 1:numel(obj.hLines.current.pp.cycle)
                obj.hLines.current.pp.cycle(i).YData = d(:,i);
                obj.hLines.current.pp.cycle(i).XData = sensor.abscissa;
            end
            xlim(obj.hAxCycle,[min(sensor.abscissa),max(sensor.abscissa)]);
            
            minmax = obj.getCurrentSensor().getDataMinMax(true);
            if obj.compareSensorDrawn()
                minmax = [minmax,obj.compareSensor.getDataMinMax(true)];
            end
            minData = min(minmax);
            maxData = max(minmax);
            obj.cyclePoints.setYLimits([minData,maxData]);
            obj.indexPoints.setYLimits([minData,maxData]);
            
            xlim(obj.hAxCycle,'auto');
            xlim(obj.hAxQuasistatic,'auto');            
        end

        function addPreprocessing(obj)
            pp = PreprocessingChain.getAvailableMethods(true)
            s = keys(pp)
            [sel,ok] = listdlg('ListString',s);
            if ~ok
                return
            end
            obj.currentPreprocessingChain.appendPreprocessing(s(sel));
            obj.refreshPropGrid();
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.updatePlotsInPlace();
            obj.setGlobalYLimits();
        end
        
        function removePreprocessing(obj)
            pp = obj.currentPreprocessingChain.preprocessings;
            captions = pp.getCaption();
            %uniqueTags = unique(captions);
            [sel,ok] = listdlg('ListString',captions);
            if ~ok
                return
            end
            rem = pp(sel);
            obj.currentPreprocessingChain.removePreprocessing(rem);
            obj.refreshPropGrid();
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.updatePlotsInPlace();
            obj.setGlobalYLimits();
        end
        
        function movePreprocessingUp(obj)
            obj.currentPreprocessing.moveUp();
            obj.refreshPropGrid();
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.updatePlotsInPlace();
        end
        
        function movePreprocessingDown(obj)
            obj.currentPreprocessing.moveDown();
            obj.refreshPropGrid();
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.updatePlotsInPlace();
        end
        
        function changeCurrentPreprocessing(obj,prop)
            prop.userData
            obj.currentPreprocessing = prop.userData;
        end
        
        function refreshPropGrid(obj)
            obj.propGrid.clear();
            pgf = obj.currentPreprocessingChain.makePropGridFields();
            obj.propGrid.addProperty(pgf);
            [pgf.onMouseClickedCallback] = deal(@obj.changeCurrentPreprocessing);
        end
        
        function quasistaticAxesButtonDownCallback(obj,varargin)
            switch get(gcf,'SelectionType')
                case 'open' % double-click
                    coord = get(gca,'Currentpoint');
                    x = coord(1,1);
                    obj.addCyclePoint(x);
            end
        end
        
        function [p,pg] = addCyclePoint(obj,pos)
            p = obj.getCurrentCluster().makeCyclePoint(pos);
            axis(obj.hAxQuasistatic);
%             yyaxis(obj.hAxQuasistatic,'left');
            pg = p.makeGraphicsObject('cycle',true);
            pg.draw(obj.hAxQuasistatic,obj.getCurrentSensor(),obj.cyclePoints(1).getYLimits());
            p.onPositionChanged = @obj.cyclePointPositionChangedCallback;
            pg.onDraggedCallback = @obj.cyclePointDraggedCallback;
            pg.onDragStartCallback = @obj.cyclePointDragStartCallback;
            pg.onDragStopCallback = @obj.cyclePointDragStopCallback;
            pg.onDeleteRequestCallback = @obj.deletePointCallback;
            obj.cyclePoints(end+1) = pg;
            obj.getCurrentSensor().cyclePointSet.addPoint(p);
            obj.populateCyclePointsTable();
            obj.updateSensorPlots();
        end
        
        function [p,pg] = addIndexPoint(obj,pos)
            p = obj.getCurrentCluster().makeIndexPoint(pos,obj.getCurrentSensor());
            axis(obj.hAxCycle);
%             yyaxis(obj.hAxCycle,'left');
            pg = p.makeGraphicsObject('index',true);
            pg.draw(obj.hAxCycle,obj.getCurrentSensor(),obj.indexPoints(1).getYLimits());
            p.onPositionChanged = @obj.indexPointPositionChangedCallback;
            pg.onDraggedCallback = @obj.indexPointDraggedCallback;
            pg.onDragStartCallback = @obj.indexPointDragStartCallback;
            pg.onDragStopCallback = @obj.indexPointDragStopCallback;
            pg.onDeleteRequestCallback = @obj.deletePointCallback;
            obj.indexPoints(end+1) = pg;
            obj.getCurrentSensor().indexPointSet.addPoint(p);
            obj.populateIndexPointsTable();
            obj.updateSensorPlots();
        end
        
        function deletePointCallback(obj,gObject)
            inCyclePoints = obj.cyclePoints == gObject;
            if any(inCyclePoints) && (numel(obj.cyclePoints) > 1)
                obj.getCurrentSensor().cyclePointSet.removePoint(gObject.getObject());
                obj.cyclePoints(inCyclePoints) = [];
                delete(gObject);
                obj.populateCyclePointsTable();
            end
            inIndexPoints = obj.indexPoints == gObject;
            if any(inIndexPoints) && numel(obj.indexPoints) > 1
                obj.getCurrentSensor().indexPointSet.removePoint(gObject.getObject());
                obj.indexPoints(inIndexPoints) = [];
                delete(gObject);
                obj.populateIndexPointsTable();
            end
            obj.updateSensorPlots();
        end
        
        function cycleAxesButtonDownCallback(obj,varargin)
            switch get(gcf,'SelectionType')
                case 'open' % double-click
                    coord = get(gca,'Currentpoint');
                    x = coord(1,1);
                    obj.addIndexPoint(x);
            end
        end
        
        function val = compareSensorDrawn(obj)
            val = logical(obj.hCompareWith.hCompareWithCheckbox.Value);
        end
        
        function onParameterChangedCallback(obj,prop,param)
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.compareSensor.preComputePreprocessedData();
            obj.updatePlotsInPlace();
        end
    end
end