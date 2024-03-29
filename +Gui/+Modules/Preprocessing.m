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
        
        function [moduleLayout,moduleMenu] = makeLayout(obj,uiParent,mainFigure)
            %%
            % create a grid layout for the preprocessing panel
            moduleLayout = uigridlayout(uiParent,[1 2],...
                'Visible','off',...
                'Padding',[0 0 0 0],...
                'ColumnWidth',{'3x','8x'},...
                'RowHeight',{'1x'},...
                'RowSpacing',7);
            
            % create the menu bar dropdown
            moduleMenu = uimenu(mainFigure,'Label','Preprocessing');
            obj.globalYLimitsMenu = uimenu(moduleMenu,...
                'Label','global y-limits',...
                'Checked','off',...
                getMenuCallbackName(),@obj.globalYLimitsMenuClicked);
            
            ctrlGrid = uigridlayout(moduleLayout,[2 1],...
                'Padding',[0 0 0 0],...
                'ColumnWidth',{'1x'},...
                'RowHeight',{180,'1x'},'RowSpacing',7);
            ctrlGrid.Layout.Column = 1;
            
            axGrid = uigridlayout(moduleLayout,[2 1],...
                'Padding',[0 0 0 0],...
                'ColumnWidth',{'1x'},...
                'RowHeight',{'1x'}, 'RowSpacing',7);
            axGrid.Layout.Column = 2;
            
            % create and fill the grid layout of the 'compare with' section
            mainTabGp = uitabgroup(ctrlGrid);
            mainTabGp.Layout.Row = 1;
            %mainTabGp.Layout.Column = 1;
            
            cmpTab = uitab(mainTabGp,'Title','Cluster Timing / Compare');
            cmpTabGrid = uigridlayout(cmpTab,[2 1],...
                'Padding',[0 0 0 0],'RowHeight',{'1x','2x'});
            
            compareGrid = uigridlayout(cmpTabGrid,...moduleLayout,...
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
                'ValueChangedFcn',@(src,event)obj.compareWithSensorPopup(src,event));
            compareDropdown.Layout.Column = 2;
            
            obj.hCompareWith.hCompareWithCheckbox = compareCheckbox;
            obj.hCompareWith.hSensorPopup = compareDropdown;
            
            % create and fill the grid layout of the 'cluster' section
            clusterGrid = uigridlayout(cmpTabGrid, [4 2],...
                'ColumnWidth',{'1x','1x'},...
                'RowHeight',{'fit'},...
                'RowSpacing',4,...
                'Padding',[4 4 4 4]);
            clusterGrid.Layout.Row = 2;
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
                'ValueChangedFcn',@(src,event)obj.samplingPeriodEditCallback(src,event));
            periodEdit.Layout.Row = 2;
            periodEdit.Layout.Column = 2;
            
            offsetEdit = uieditfield(clusterGrid,'numeric',...
                'Value',100,...
                'ValueChangedFcn',@(src,event)obj.offsetEditCallback(src,event));
            offsetEdit.Layout.Row = 3;
            offsetEdit.Layout.Column = 2;
            
            virtOffsetEdit = uieditfield(clusterGrid,'numeric',...
                'Value',0,...
                'ValueChangedFcn',@(src,event)obj.virtualOffsetEditCallback(src,event));
            virtOffsetEdit.Layout.Row = 4;
            virtOffsetEdit.Layout.Column = 2;
                        
            obj.hCompareWith.hSamplingPeriodEdit = periodEdit;
            obj.hCompareWith.hOffsetEdit = offsetEdit;
            obj.hCompareWith.hVirtualOffsetEdit = virtOffsetEdit;
            
           % pointsTabGp = uitabgroup(main);
            cycleTab = uitab(mainTabGp,'Title','Cycles');
            % create and fill the grid layout of the 'cycle points' section
            cyclePointsGrid = uigridlayout(cycleTab, [2 4],...
                'ColumnWidth',{'2x','2x','1x','1x'},...
                'RowHeight',{'fit','6x'},...
                'RowSpacing',4,...
                'Padding',[4 4 4 4]);
%             cyclePointsGrid.Layout.Row = [7 14];
%             cyclePointsGrid.Layout.Column = 1;
            
%             cyclePointsLabel = uilabel(cyclePointsGrid,...
%                 'Text','Cycle points',...
%                 'FontWeight','bold');
%             cyclePointsLabel.Layout.Row = 1;
%             cyclePointsLabel.Layout.Column = [1 4];
            
            % cycle point set dropdown and buttons
            cyclePointsDropdown = uidropdown(cyclePointsGrid,...
                'Editable','on',...
                'ValueChangedFcn',@(src,event)obj.dropdownCyclePointSetCallback(src,event));
            cyclePointsDropdown.Layout.Row = 1;
            cyclePointsDropdown.Layout.Column = [1 2];
            
            cPointSetAdd = uibutton(cyclePointsGrid,...
                'Text','+',...
                'ButtonPushedFcn',@(src,event)obj.dropdownNewCyclePointSet(src,event,cyclePointsDropdown));
            cPointSetAdd.Layout.Row = 1;
            cPointSetAdd.Layout.Column = 3;
                       
            cPointSetRem = uibutton(cyclePointsGrid,...
                'Text','-',...
                'ButtonPushedFcn',@(src,event)obj.dropdownRemoveCyclePointSet(src,event,cyclePointsDropdown));
            cPointSetRem.Layout.Row = 1;
            cPointSetRem.Layout.Column = 4;
            
            cyclePointsTable = uitable(cyclePointsGrid);
            cyclePointsTable.Layout.Row = 2;
            cyclePointsTable.Layout.Column = [1 4];
                       
            obj.cyclePointSetDropdown = cyclePointsDropdown;
            obj.cyclePointTable = cyclePointsTable;
            
            qsTab = uitab(mainTabGp,'Title','Quasistatic Points');
            % create and fill the grid layout of the 'quasistatic points' section
            qsPointsGrid = uigridlayout(qsTab, [2 4],...
                'ColumnWidth',{'2x','2x','1x','1x'},...
                'RowHeight',{'fit','6x'},...
                'RowSpacing',4,...
                'Padding',[4 4 4 4]);
%             qsPointsGrid.Layout.Row = [15 22];
%             qsPointsGrid.Layout.Column = 1;
            
%             qsPointsLabel = uilabel(qsPointsGrid,...
%                 'Text','Quasistatic points',...
%                 'FontWeight','bold');
%             qsPointsLabel.Layout.Row = 1;
%             qsPointsLabel.Layout.Column = [1 4];
            
            % cycle point set dropdown and buttons
            qsPointsDropdown = uidropdown(qsPointsGrid,...
                'Editable','on',...
                'ValueChangedFcn',@(src,event)obj.dropdownIndexPointSetCallback(src,event));
            qsPointsDropdown.Layout.Row = 1;
            qsPointsDropdown.Layout.Column = [1 2];
            
            qsPointSetAdd = uibutton(qsPointsGrid,...
                'Text','+',...
                'ButtonPushedFcn',@(src,event)obj.dropdownNewIndexPointSet(src,event,qsPointsDropdown));
            qsPointSetAdd.Layout.Row = 1;
            qsPointSetAdd.Layout.Column = 3;
                       
            qsPointSetRem = uibutton(qsPointsGrid,...
                'Text','-',...
                'ButtonPushedFcn',@(src,event)obj.dropdownRemoveIndexPointSet(src,event,qsPointsDropdown));
            qsPointSetRem.Layout.Row = 1;
            qsPointSetRem.Layout.Column = 4;
            
            qsPointsTable = uitable(qsPointsGrid);
            qsPointsTable.Layout.Row = 2;
            qsPointsTable.Layout.Column = [1 4];
                        
            % index point set dropdown
            obj.indexPointSetDropdown = qsPointsDropdown;
            obj.indexPointTable = qsPointsTable;
            
            chainTabGP = uitabgroup(ctrlGrid,'AutoResizeChildren','off');
            chainTabGP.Layout.Row = 2;
            %chainTabGP.Layout.Column = 1;
            % create and fill the grid layout of the 'preprocessing chain' section
            chainTab = uitab(chainTabGP,'Title','Preprocessing Chain','AutoResizeChildren','off');
            chainGrid = uigridlayout(chainTab, [3 4],...
                'ColumnWidth',{'2x','2x','1x','1x'},...
                'RowHeight',{'fit','6x','fit'},...
                'RowSpacing',4,...
                'Padding',[4 4 4 4]);
%             chainGrid.Layout.Row = [1 22];
%             chainGrid.Layout.Column = 2;
            
%             chainLabel = uilabel(chainGrid,...
%                 'Text','Preprocessing Chain',...
%                 'FontWeight','bold');
%             chainLabel.Layout.Row = 1;
%             chainLabel.Layout.Column = [1 4];
            
            chainDropdown = uidropdown(chainGrid,...
                'Editable','on',...
                'ValueChangedFcn',@(src,event)obj.dropdownPreprocessingChainCallback(src,event));
            chainDropdown.Layout.Row = 1;
            chainDropdown.Layout.Column = [1 2];
            
            chainAdd = uibutton(chainGrid,...
                'Text','+',...
                'ButtonPushedFcn',@(src,event)obj.dropdownNewPreprocessingChain(src,event,chainDropdown));
            chainAdd.Layout.Row = 1;
            chainAdd.Layout.Column = 3;
            
            chainRem = uibutton(chainGrid,...
                'Text','-',...
                'ButtonPushedFcn',@(src,event)obj.dropdownRemovePreprocessingChain(src,event,chainDropdown));
            chainRem.Layout.Row = 1;
            chainRem.Layout.Column = 4;
            
%             propGridPanel = uipanel(chainGrid,'Scrollable','on');
%             propGridPanel.Layout.Row = 3;
%             propGridPanel.Layout.Column = [1 4];
            % preprocessing chain set dropdown
            obj.setDropdown = chainDropdown;
            
            % preprocessing chain propgrid
%             obj.propGrid = PropGrid(propGridPanel);
            obj.propGrid = Gui.uiParameterBlockGrid('Parent',chainGrid,...
                'ValueChangedFcn',@(src,event) obj.onParameterChangedCallback(src,event),...
                'SelectionChangedFcn',@(src,event) obj.changeCurrentPreprocessing(src,event),...
                'SizeChangedFcn',@(src,event) obj.sizechangedCallback(src,event));%,...
                %);
            obj.propGrid.Layout.Row = 2;
            obj.propGrid.Layout.Column = [1 4];
%             obj.propGrid.onPropertyChangedCallback = @obj.onParameterChangedCallback;

            chainElementAdd = uibutton(chainGrid,...
                'Text','Add',...
                'ButtonPushedFcn',@(src,event)obj.addPreprocessing(src,event));
            chainElementAdd.Layout.Row = 3;
            chainElementAdd.Layout.Column = 1;
            
            chainElementDel = uibutton(chainGrid,...
                'Text','Delete...',...
                'ButtonPushedFcn',@(src,event)obj.removePreprocessing(src,event));
            chainElementDel.Layout.Row = 3;
            chainElementDel.Layout.Column = 2;
            
            chainElementUp = uibutton(chainGrid,...
                'Text','/\',...
                'ButtonPushedFcn',@(src,event)obj.movePreprocessingUp(src,event));
            chainElementUp.Layout.Row = 3;
            chainElementUp.Layout.Column = 3;
            
            chainElementDwn = uibutton(chainGrid,...
                'Text','\/',...
                'ButtonPushedFcn',@(src,event)obj.movePreprocessingDown(src,event));
            chainElementDwn.Layout.Row = 3;
            chainElementDwn.Layout.Column = 4;
            
            % fill out right side of PP-Module with quasistatic and cycle
            % plots 
            qsAx = uiaxes(axGrid);
            qsAx.Layout.Row = 1;
            qsAx.Layout.Column = 1;
            qsAx.Title.String = 'Quasistatic signal';
            qsAx.XLabel.String = 'Cycle number';
            qsAx.YLabel.String = 'Data / a.u.';
            qsAx.ButtonDownFcn = @obj.quasistaticAxesButtonDownCallback;
            
            obj.hAxQuasistatic = qsAx;
            
            cyAx = uiaxes(axGrid);
            cyAx.Layout.Row = 2;
            cyAx.Layout.Column = 1;
            cyAx.Title.String = 'Selected cycles';
            cyAx.XLabel.String = 'Time /s';
            cyAx.YLabel.String = 'Data / a.u.';
            cyAx.ButtonDownFcn = @obj.cycleAxesButtonDownCallback;
            
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
                uialert(obj.main.hFigure,'Load at least one sensor.','Data required');
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
            obj.hCompareWith.hSensorPopup.Items = obj.getProject().getSensors().getCaption('cluster');

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
            newSensor.getCaption();
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
            obj.cyclePointSetDropdown.Valus = char(cps.getCaption());
        end
        
        function onCurrentIndexPointSetChanged(obj,ips)
            obj.indexPointSetDropdown.Value = char(ips.getCaption());
        end
        
        function onCurrentPreprocessingChainChanged(obj,ppc)
            obj.setDropdown.Value = char(ppc.getCaption());
        end
        
        function val = get.currentPreprocessingChain(obj)
            val = obj.getProject().currentPreprocessingChain;
        end
        
        function set.currentPreprocessingChain(obj,val)
            obj.getProject().currentPreprocessingChain = val;
        end

        %% dropdown callbacks for preprocessing chains
        function dropdownNewPreprocessingChain(obj,src,event,dropdown)
            ppc = obj.getProject().addPreprocessingChain();
            obj.currentPreprocessingChain = ppc;
            dropdown.Items{end+1} = char(ppc.getCaption());
            dropdown.Value = char(ppc.getCaption());
            
            obj.main.populateSensorSetTable();
            obj.refreshPropGrid();
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.updatePlotsInPlace();
        end
        
        function dropdownRemovePreprocessingChain(obj,src,event,dropdown)
            prepChains = obj.getProject().poolPreprocessingChains;
            idx = arrayfun(@(chain) strcmp(chain.caption,dropdown.Value),prepChains);
            ppc = prepChains(idx);
            sensorsWithPPC = obj.getProject().checkForSensorsWithPreprocessingChain(ppc);
            
            if numel(sensorsWithPPC) > 1  % the current sensor always has the PPC to delete
                choices = {};
                if numel(prepChains) > 1
                    choices{1} = 'Choose a replacement';
                end
                choices{end+1} = 'Replace with new';
                choices{end+1} = 'Cancel';
                
                answer = uiconfirm(obj.main.hFigure,...
                    ['The preprocessing chain "' char(ppc.caption) '" is used in other sensors. What would you like to do?'],...
                    'Preprocessing chain usage conflict',...
                    'Icon','warning',...
                    'Options',choices,...
                    'DefaultOption',numel(choices),'CancelOption',numel(choices));
                
                switch answer
                    case 'Choose a replacement'
                        prepChains(idx) = [];
                        [sel,ok] = Gui.Dialogs.Select('MultiSelect',false,...
                            'ListItems',prepChains.getCaption(),...
                            'Message','Please select a replacement preprocessing chain.');
                        if ~ok
                            return
                        end
                        selInd = ismember(prepChains.getCaption(),sel);
                        obj.getProject().replacePreprocessingChainInSensors(ppc,prepChains(selInd));
                        newPPC = prepChains(selInd);
                    case 'Replace with new'
                        newPPC = obj.getProject().addPreprocessingChain();
                        dropdown.Items = [dropdown.Items char(newPPC.getCaption())];
                        obj.getProject().replacePreprocessingChainInSensors(ppc,newPPC);
                    case 'Cancel'
                        return
                end
            else
                % if there is only one PPC, it will now be deleted
                % so we have to add a new one
                if numel(obj.getProject().poolPreprocessingChains) == 1
                    newPPC = obj.getProject().addPreprocessingChain();
                    dropdown.Items = [dropdown.Items char(newPPC.getCaption())];
                else    %select a PPC we already have
                    if idx(1)     %the first logical index had the true
                        newPPC = obj.getProject().poolPreprocessingChains(2);
                    else
                        %shift the logical index one position to the front (left)
                        newPPC = obj.getProject().poolPreprocessingChains(circshift(idx,-1));
                    end
                end
            end

            obj.currentPreprocessingChain = newPPC;
            obj.getProject().removePreprocessingChain(ppc);
                
            dropdown.Items = dropdown.Items(~idx);  %drop the old option
            dropdown.Value = char(newPPC.caption);  %set the new one
            
            obj.main.populateSensorSetTable();
            obj.refreshPropGrid();
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.updatePlotsInPlace();
        end
        
        function dropdownPreprocessingChainCallback(obj, src, event)
            if event.Edited                
                index = cellfun(@(x) strcmp(x,event.PreviousValue), src.Items);
                newName = matlab.lang.makeUniqueStrings(event.Value,...
                   cellstr(obj.getProject().poolCyclePointSets.getCaption()));
                obj.getProject().poolPreprocessingChains(index).setCaption(newName);
                src.Items{index} = newName;
                obj.main.populateSensorSetTable();
            else
                index = cellfun(@(x) strcmp(x,event.Value), src.Items);
                obj.currentPreprocessingChain = ...
                    obj.getProject().poolPreprocessingChains(index);
                obj.refreshPropGrid();
                obj.getCurrentSensor().preComputePreprocessedData();
                obj.updatePlotsInPlace();
                obj.main.populateSensorSetTable();
            end
        end        
        %% sizeChanged Callback
        function sizechangedCallback(obj, src, event)
            obj.propGrid.panel.Visible = 'off';
            pos_parent = obj.propGrid.Position;
            obj.propGrid.panel.Position = pos_parent - [0,25,9,12]; %values possibly subject to change 
            obj.propGrid.panel.Visible = 'on';                      % depending on screen resolution?
            %disp('Resized')
        end
        %% dropdown callbacks for cycle point sets
        function dropdownNewCyclePointSet(obj,src,event,dropdown)
            cps = obj.getProject().addCyclePointSet();
            obj.currentCyclePointSet = cps;
            dropdown.Items{end+1} = char(cps.getCaption());
            dropdown.Value = char(cps.getCaption());
        end
        
        function dropdownRemoveCyclePointSet(obj,src,event,dropdown)
            cPointSets = obj.getProject().poolCyclePointSets;
            idx = arrayfun(@(set) strcmp(set.caption,dropdown.Value),cPointSets);
            cps = cPointSets(idx);
            sensorsWithCps = obj.getProject().checkForSensorsWithCyclePointSet(cps);
            
            if numel(sensorsWithCps) > 1  % the current sensor always has the Cps to delete
                choices = {};
                if numel(cPointSets) > 1
                    choices{1} = 'Choose a replacement';
                end
                choices{end+1} = 'Replace with new';
                choices{end+1} = 'Cancel';
                
                answer = uiconfirm(obj.main.hFigure,...
                    ['The cycle point set "' char(cps.caption) '" is used in other sensors. What would you like to do?'],...
                    'Cycle point set usage conflict',...
                    'Icon','warning',...
                    'Options',choices,...
                    'DefaultOption',numel(choices),'CancelOption',numel(choices));
                
                switch answer
                    case 'Choose a replacement'
                        cPointSets(idx) = [];
                        [sel,ok] = Gui.Dialogs.Select('MultiSelect',false,...
                            'ListItems',cPointSets.getCaption(),...
                            'Message','Please select a replacement cycle point set.');
                        if ~ok
                            return
                        end
                        selInd = ismember(cPointSets.getCaption(),sel);
                        obj.getProject().replaceCyclePointSetInSensors(cps,cPointSets(selInd));
                        newCps = cPointSets(selInd);
                    case 'Replace with new'
                        newCps = obj.getProject().addCyclePointSet();
                        dropdown.Items = [dropdown.Items char(newCps.getCaption())];
                        obj.getProject().replaceCyclePointSetInSensors(cps,newCps);
                    case 'Cancel'
                        return
                end
            else
                % if there is only one CPS, it will now be deleted
                % so we have to add a new one
                if numel(obj.getProject().poolCyclePointSets) == 1
                    newCps = obj.getProject().addCyclePointSet();
                    dropdown.Items = [dropdown.Items char(newCps.getCaption())];
                else    %select a CPS we already have
                    if idx(1)   %the first logical index had the true
                        newCps = obj.getProject().poolCyclePointSets(2);
                    else
                        %shift the logical index one position to the front (left)
                        newCps = obj.getProject().poolCyclePointSets(circshift(idx,-1));
                    end
                end
            end

            obj.currentCyclePointSet = newCps;
            obj.getProject().removeCyclePointSet(cps);
                
            dropdown.Items = dropdown.Items(~idx);  %drop the old option
            dropdown.Value = char(newCps.caption);  %set the new one
            obj.handleCyclePointSetChange();
            obj.main.populateSensorSetTable();
        end
        function dropdownCyclePointSetCallback(obj, src, event)
           if event.Edited
               index = cellfun(@(x) strcmp(x,event.PreviousValue), src.Items);
               newName = matlab.lang.makeUniqueStrings(event.Value,...
                   cellstr(obj.getProject().poolCyclePointSets.getCaption()));
               obj.getProject().poolCyclePointSets(index).setCaption(newName);
               src.Items{index} = newName;
               obj.handleCyclePointSetChange();
               obj.main.populateSensorSetTable();
           else 
               index = cellfun(@(x) strcmp(x,event.Value), src.Items);
               obj.currentCyclePointSet = ...
                   obj.getProject().poolCyclePointSets(index);
               obj.handleCyclePointSetChange();
               obj.main.populateSensorSetTable();
           end
        end       
        
        %% dropdown callbacks for index point sets
        function dropdownNewIndexPointSet(obj,src,event,dropdown)
            ips = obj.getProject().addIndexPointSet();
            obj.currentIndexPointSet = ips;
            dropdown.Items{end+1} = char(ips.getCaption());
            dropdown.Value = char(ips.getCaption());
        end
        
        function dropdownRemoveIndexPointSet(obj,src,event,dropdown)
            iPointSets = obj.getProject().poolIndexPointSets;
            idx = arrayfun(@(set) strcmp(set.caption,dropdown.Value),iPointSets);
            ips = iPointSets(idx);
            sensorsWithIps = obj.getProject().checkForSensorsWithIndexPointSet(ips);
            
            if numel(sensorsWithIps) > 1  % the current sensor always has the IPS to delete
                choices = {};
                if numel(iPointSets) > 1
                    choices{1} = 'Choose a replacement';
                end
                choices{end+1} = 'Replace with new';
                choices{end+1} = 'Cancel';
                
                answer = uiconfirm(obj.main.hFigure,...
                    ['The index point set "' char(ips.caption) '" is used in other sensors. What would you like to do?'],...
                    'Index point set usage conflict',...
                    'Icon','warning',...
                    'Options',choices,...
                    'DefaultOption',numel(choices),'CancelOption',numel(choices));
                
                switch answer
                    case 'Choose a replacement'
                        iPointSets(idx) = [];
                        [sel,ok] = Gui.Dialogs.Select('MultiSelect',false,...
                            'ListItems',iPointSets.getCaption(),...
                            'Message','Please select a replacement index point set.');
                        if ~ok
                            return
                        end
                        selInd = ismember(iPointSets.getCaption(),sel);
                        obj.getProject().replaceIndexPointSetInSensors(ips,iPointSets(selInd));
                        newIps = iPointSets(selInd);
                    case 'Replace with new'
                        newIps = obj.getProject().addIndexPointSet();
                        dropdown.Items = [dropdown.Items char(newIps.getCaption())];
                        obj.getProject().replaceIndexPointSetInSensors(ips,newIps);
                    case 'Cancel'
                        return
                end
            else
                % if there is only one IPS, it will now be deleted
                % so we have to add a new one
                if numel(obj.getProject().poolIndexPointSets) == 1
                    newIps = obj.getProject().addIndexPointSet();
                    dropdown.Items = [dropdown.Items char(newIps.getCaption())];
                else    %select an IPS we already have
                    if idx(1)   %the first logical index had the true
                        newIps = obj.getProject().poolIndexPointSets(2);
                    else
                        %shift the logical index one position to the front (left)
                        newIps = obj.getProject().poolIndexPointSets(circshift(idx,-1));
                    end
                end
            end

            obj.currentIndexPointSet = newIps;
            obj.getProject().removeIndexPointSet(ips);
                
            dropdown.Items = dropdown.Items(~idx);  %drop the old option
            dropdown.Value = char(newIps.caption);  %set the new one
            obj.handleIndexPointSetChange();
            obj.main.populateSensorSetTable();
        end
        
        function dropdownIndexPointSetCallback(obj, src, event)
           if event.Edited
               index = cellfun(@(x) strcmp(x,event.PreviousValue), src.Items);
               newName = matlab.lang.makeUniqueStrings(event.Value,...
                   cellstr(obj.getProject().poolIndexPointSets.getCaption()));
               obj.getProject().poolIndexPointSets(index).setCaption(newName);
               src.Items{index} = newName;
               obj.handleIndexPointSetChange();
               obj.main.populateSensorSetTable();
           else 
               index = cellfun(@(x) strcmp(x,event.Value), src.Items);
               obj.currentIndexPointSet = ...
                   obj.getProject().poolIndexPointSets(index);
               obj.handleIndexPointSetChange();
               obj.main.populateSensorSetTable();
           end
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
            
            clrArray = gPoints.getObject.getColor();
            colors = cell(size(clrArray,1),1);
            for i = 1:size(clrArray,1)
                colors{i} = clr2str(clrArray(i,:));
            end
            data = [captions, positions, time_positions, colors];
%             data = [captions, positions, time_positions];

            t = obj.cyclePointTable;
%             t.ColumnName = {'caption','cycle','time in s'};
            t.ColumnName = {'caption','cycle','time in s','color'};
%             t.setRowObjects(gPoints);
%             t.ColumnFormat = {'char' 'numeric' 'numeric'};
            t.ColumnFormat = {'char' 'numeric' 'numeric' 'char'};
%             t.ColumnSortable = [false false true];
%             t.ColumnEditable = [true true true];
            t.ColumnEditable = [true true true true];
            t.ColumnWidth = {'auto' 'fit' 'fit' 'fit'};
            t.Data = data;
            t.UserData = gPoints;

            ind = tableColSort(t,3,'a');
%             obj.cyclePoints = obj.cyclePoints(ind);
%             disabled due to unwanted behaviour involving two or more
%             cusors
                        
            if ~isempty(data)
                clrArray = clrArray(ind,:); %sort colors, then style
                if size(clrArray,1) > 1
                    for i = 1:size(clrArray,1)
                        s = uistyle('BackgroundColor',clrArray(i,:));
                        addStyle(t,s,'cell',[i 4])
                    end
                else
                    s = uistyle('BackgroundColor',clrArray);
                    addStyle(t,s,'column',4)
                end
            end
%             t.setSortingEnabled(false)
%             t.setFilteringEnabled(false);
%             t.setColumnReorderingAllowed(false);
%             t.jTable.sortColumn(3);
%             t.jTable.setAutoResort(false)
            obj.cyclePointTable.CellEditCallback = ...
                @(src, event) obj.cyclePointTableEditCallback(src, event);
            obj.cyclePointTable.CellSelectionCallback = ...
                @(src, event) obj.cyclePointTableClickCallback(src, event);
%             obj.cyclePointTable.onDataChangedCallback = @obj.cyclePointTableDataChangeCallback;
%             obj.cyclePointTable.onMouseClickedCallback = @obj.cyclePointTableMouseClickedCallback;
        end
        
        function populateIndexPointsTable(obj)
            %%
            % write data to the table, style and configure it, activate callbacks
            gPoints = obj.indexPoints;
            captions = cellstr(gPoints.getPoint().getCaption()');
            positions = num2cell(gPoints.getPosition());
            
            clrArray = gPoints.getObject.getColor();
            colors = cell(size(clrArray,1),1);
            for i = 1:size(clrArray,1)
                colors{i} = clr2str(clrArray(i,:));
            end
            data = [captions, positions, colors];
%             data = [captions, positions];
            
            t = obj.indexPointTable;
            
            t.ColumnName = {'caption','cycle point','color'};
            t.ColumnFormat = {'char' 'numeric' 'char'};
            t.ColumnEditable = [true true true];
            t.Data = data;
            t.UserData = gPoints;
            
             ind = tableColSort(t,2,'a');
%             obj.indexPoints = obj.indexPoints(ind);
            
            if ~isempty(data)
                clrArray = clrArray(ind,:); %sort colors, then style
                if size(clrArray,1) > 1
                    for i = 1:size(clrArray,1)
                        s = uistyle('BackgroundColor',clrArray(i,:));
                        addStyle(t,s,'cell',[i 3])
                    end
                else
                    s = uistyle('BackgroundColor',clrArray);
                    addStyle(t,s,'column',3)
                end
            end
%             t.setData(data,{'caption','point','color'});
%             t.setRowObjects(gPoints);
%             t.setColumnClasses({'str','double','clr'});
%             t.setColumnsEditable([true true true]);
%             t.setSortingEnabled(false)
%             t.setFilteringEnabled(false);
%             t.setColumnReorderingAllowed(false);
%             t.jTable.sortColumn(2);
%             t.jTable.setAutoResort(false)
            obj.indexPointTable.CellEditCallback = ...
                @(src, event) obj.indexPointTableEditCallback(src, event);
            obj.indexPointTable.CellSelectionCallback = ...
                @(src, event) obj.indexPointTableClickCallback(src, event);
%             obj.indexPointTable.DisplayDataChangedFcn = ...
%                 @(src, event) obj.indexPointTableDataChange(src,event);
%             obj.indexPointTable.onMouseClickedCallback = @obj.indexPointTableMouseClickedCallback;
        end
        
        function cyclePointDraggedCallback(obj,gPoint)
            %%
            % update the position in the table when the point is dragged
%             row = obj.cyclePointTable.getRowObjectRow(gPoint);
%             obj.cyclePointTable.setValue(gPoint.getPosition(),row,2);
%             obj.cyclePointTable.setValue(gPoint.getTimePosition(),row,3);
            idx = ismember(obj.cyclePoints,gPoint);
            obj.cyclePointTable.Data{idx,2} = gPoint.getPosition();
            obj.cyclePointTable.Data{idx,3} = gPoint.getTimePosition();
%             ind = tableColSort(obj.cyclePointTable,3,'a');
%             obj.cyclePoints = obj.cyclePoints(ind);
            obj.populateCyclePointsTable();
        end
        
        function indexPointDraggedCallback(obj,gPoint)
            %%
            % update the position in the table when the point is dragged
%             row = obj.indexPointTable.getRowObjectRow(gPoint);
%             obj.indexPointTable.setValue(gPoint.getPosition(),row,2);
            idx = ismember(obj.indexPoints,gPoint);
            obj.indexPointTable.Data{idx,2} = gPoint.getPosition();
%             ind = tableColSort(obj.indexPointTable,2,'a');
%             obj.indexPoints = obj.indexPoints(ind);
            obj.populateIndexPointsTable();
        end

        function cyclePointDragStartCallback(obj,gObj)
            %%
            % disable table callbacks (to omit "wrong" data changed events),
            % move the current selection to the corresponding row, and make
            % the corresponding cycle line bold
%             obj.cyclePointTable.setCallbacksActive(false);
%             objRow = obj.cyclePointTable.getRowObjectRow(gObj);
            obj.cyclePointTable.Enable = 'off';
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
            obj.cyclePointTable.Enable = 'on';
%             objRow = obj.cyclePointTable.getRowObjectRow(gObj);
%             obj.cyclePointTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
% %             obj.cyclePointTable.setRowHeader();
%             obj.cyclePointTable.setCallbacksActive(true);
        end
        
        function indexPointDragStartCallback(obj,gObj)
            %%
            % disable table callbacks (to omit "wrong" data changed events),
            % move the current selection to the corresponding row, and make
            % the corresponding quasistatic line bold
%             obj.indexPointTable.setCallbacksActive(false);
%             objRow = obj.indexPointTable.getRowObjectRow(gObj);
            obj.indexPointTable.Enable = 'off';
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
            obj.indexPointTable.Enable = 'on';
%             objRow = obj.indexPointTable.getRowObjectRow(gObj);
%             obj.indexPointTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
% %             obj.indexPointTable.setRowHeader();
%             obj.indexPointTable.setCallbacksActive(true);
        end
        
        function cyclePointTableEditCallback(obj, src, event)
            row = event.Indices(1);
            col = event.Indices(2);
            cPoint = src.UserData(row);
            switch col
                case 1
                    cPoint.getObject().setCaption(event.EditData);
                case 2
                    cPoint.setPosition(event.NewData,...
                        obj.getProject().getCurrentSensor());
                    src.Data{row,3} = cPoint.getTimePosition();
                case 3
                    cPoint.setTimePosition(event.NewData);
                    src.Data{row,2} = cPoint.getPosition();
                case 4
                    try %to convert the edited string to a color triplet
                        rgbClr = str2clr(event.EditData);
                    catch ME %revert back to the previous string and colour
                        disp(ME)
                        rgbClr = str2clr(event.PreviousData);
                        src.Data{row,col} = event.PreviousData;
                    end
                    s = uistyle('BackgroundColor',rgbClr);
                    addStyle(src,s,'cell',[row col]);
                    cPoint.setColor(rgbClr);
                    idx = ismember(obj.cyclePoints,cPoint);
                    obj.hLines.current.raw.cycle(idx).Color = changeColorShade(rgbClr,obj.rawColorShade);
                    obj.hLines.current.pp.cycle(idx).Color = rgbClr;
            end
            ind = tableColSort(obj.cyclePointTable,3,'a');
            obj.cyclePoints = obj.cyclePoints(ind);
        end
        
        function cyclePointTableClickCallback(obj,src,event)
            % check if a single color picker was selected
            if size(event.Indices,1) == 1 && event.Indices(2) == 4
                row = event.Indices(1);
                col = event.Indices(2);
                cPoint = src.UserData(row);
                origClr = cPoint.getObject.getColor();
                try
                    rgbClr = uisetcolor(origClr,'Select a color');
                    obj.main.hFigure.Visible = 'off';
                    obj.main.hFigure.Visible = 'on';
                    src.Data{row,col} = clr2str(rgbClr);
                catch ME
                    disp(ME)
                    rgbClr = origClr;
                end
                s = uistyle('BackgroundColor',rgbClr);
                addStyle(src,s,'cell',[row col]);
                
                cPoint.setColor(rgbClr);
                idx = ismember(obj.cyclePoints,cPoint);
                obj.hLines.current.raw.cycle(idx).Color = changeColorShade(rgbClr,obj.rawColorShade);
                obj.hLines.current.pp.cycle(idx).Color = rgbClr;
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
        
        function indexPointTableEditCallback(obj, src, event)
            row = event.Indices(1);
            col = event.Indices(2);
            iPoint = src.UserData(row);
            switch col
                case 1
                    iPoint.getObject().setCaption(event.EditData);
                case 2
                    iPoint.setPosition(event.NewData,...
                        obj.getProject().getCurrentSensor());
                case 3
                    try %to convert the edited string to a color triplet
                        rgbClr = str2clr(event.EditData);
                    catch ME %revert back to the previous string and colour
                        disp(ME)
                        rgbClr = str2clr(event.PreviousData);
                        src.Data{row,col} = event.PreviousData;
                    end
                    s = uistyle('BackgroundColor',rgbClr);
                    addStyle(src,s,'cell',[row col]);
                    iPoint.setColor(rgbClr);
                    idx = ismember(obj.indexPoints,iPoint);
                    obj.hLines.current.raw.quasistatic(idx).Color = changeColorShade(rgbClr,obj.rawColorShade);
                    obj.hLines.current.pp.quasistatic(idx).Color = rgbClr;
            end
            ind = tableColSort(obj.indexPointTable,2,'a');
            obj.indexPoints = obj.indexPoints(ind);
        end
        
        function indexPointTableClickCallback(obj, src, event)
            % check if a single color picker was selected
            if size(event.Indices,1) == 1 && event.Indices(2) == 3
                row = event.Indices(1);
                col = event.Indices(2);
                iPoint = src.UserData(row);
                origClr = iPoint.getObject.getColor();
                try
                    rgbClr = uisetcolor(origClr,'Select a color');
                    obj.main.hFigure.Visible = 'off';
                    obj.main.hFigure.Visible = 'on';
                    src.Data{row,col} = clr2str(rgbClr);
                catch ME
                    disp(ME)
                    rgbClr = origClr;
                end
                s = uistyle('BackgroundColor',rgbClr);
                addStyle(src,s,'cell',[row col]);
                iPoint.setColor(rgbClr);
                idx = ismember(obj.indexPoints,iPoint);
                obj.hLines.current.raw.quasistatic(idx).Color = changeColorShade(rgbClr,obj.rawColorShade);
                obj.hLines.current.pp.quasistatic(idx).Color = rgbClr;
            end
        end
        
        function indexPointTableDataChange(obj,src,event)
            %%
            % write changes from the table to the point object
            foo = 5;
            for i = 1:size(src,1)
                o = obj.indexPointTable.getRowObjectsAt(src(i,1));
                switch src(i,2)
                    case 1
                        o.getObject().setCaption(event{i});
                    case 2
                        o.setPosition(event{i},obj.getProject().getCurrentSensor());
                    case 3
                        o.setColor(event{i});
                        idx = ismember(obj.indexPoints,o);
                        obj.hLines.current.raw.quasistatic(idx).Color = changeColorShade(obj.indexPoints(idx).getPoint().getColor(),obj.rawColorShade);
                        obj.hLines.current.pp.quasistatic(idx).Color = obj.indexPoints(idx).getPoint().getColor();
                end
            end
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
%             disp(checked)
        end
        
        function compareWithSensorPopup(obj, src, event)
            sensorInd = cellfun(@(x) strcmp(x,event.Value), src.Items);
            if obj.compareSensor ~= obj.getCurrentSensor()
                obj.compareSensor.deletePreprocessedData();
            end
            sensors = obj.getProject().getSensors();
            obj.compareSensor = sensors(sensorInd);
            obj.compareSensor.preComputePreprocessedData();
%             disp(value)
            if obj.hCompareWith.hCompareWithCheckbox.Value
%                 obj.deleteSensorPlot('compare','raw');
                obj.deleteSensorPlot('compare','pp');
%                 obj.plotSensor('compare','raw');
                obj.plotSensor('compare','pp');
            end            
        end        
        
        function samplingPeriodEditCallback(obj,src,event)
            obj.getCurrentCluster().samplingPeriod = event.Value;
            obj.cyclePoints.updatePosition(obj.getProject().getCurrentSensor());
            obj.updatePlotsInPlace();
            obj.populateCyclePointsTable();
            obj.populateIndexPointsTable();
        end
        
        function offsetEditCallback(obj,src,event)
            obj.getProject().getCurrentCluster().offset = event.Value;
            iOffset = obj.getProject().getCurrentCluster().getAutoIndexOffset(obj.getProject().clusters);
            obj.getProject().getCurrentCluster().indexOffset = iOffset;
            obj.hCompareWith.hVirtualOffsetEdit.Value = iOffset;
            obj.updatePlotsInPlace();
            obj.cyclePoints.updatePosition(obj.getProject().getCurrentSensor());
            obj.populateCyclePointsTable();
        end
        
        function virtualOffsetEditCallback(obj,src,event)
            obj.getProject().getCurrentCluster().indexOffset = event.Value;
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

        function addPreprocessing(obj, src, event)
            pp = PreprocessingChain.getAvailableMethods(true);
            s = keys(pp);
            [sel,ok] = Gui.Dialogs.Select('ListItems',s);
            if ~ok
                return
            end
            obj.currentPreprocessingChain.appendPreprocessing(sel);
            obj.refreshPropGrid();
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.updatePlotsInPlace();
            obj.setGlobalYLimits();
        end
        
        function removePreprocessing(obj, src, event)
            pp = obj.currentPreprocessingChain.preprocessings;
            captions = pp.getCaption();
            %uniqueTags = unique(captions);
            [sel,ok] = Gui.Dialogs.Select('ListItems',captions);
            if ~ok
                return
            end
            rem = pp(ismember(captions,sel));
            obj.currentPreprocessingChain.removePreprocessing(rem);
            obj.refreshPropGrid();
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.updatePlotsInPlace();
            obj.setGlobalYLimits();
        end
        
        function movePreprocessingUp(obj, src, event)
            obj.currentPreprocessing.moveUp();
            obj.refreshPropGrid();
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.updatePlotsInPlace();
        end
        
        function movePreprocessingDown(obj, src, event)
            obj.currentPreprocessing.moveDown();
            obj.refreshPropGrid();
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.updatePlotsInPlace();
        end
        
        function changeCurrentPreprocessing(obj,src,event)
            obj.currentPreprocessing = src.getSelectedBlock;
        end
        
        function refreshPropGrid(obj)
            obj.propGrid.clear();
            obj.propGrid.addBlocks(obj.currentPreprocessingChain.preprocessings);
%             pgf = obj.currentPreprocessingChain.makePropGridFields();
%             obj.propGrid.addProperty(pgf);
%             [pgf.onMouseClickedCallback] = deal(@obj.changeCurrentPreprocessing);
        end
        
        function quasistaticAxesButtonDownCallback(obj,src, event)
            switch get(gcf,'SelectionType')
                case 'open' % double-click
                    obj.addCyclePoint(event.IntersectionPoint(1));
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
        
        function cycleAxesButtonDownCallback(obj,src,event)
            switch get(gcf,'SelectionType')
                case 'open' % double-click
                    obj.addIndexPoint(event.IntersectionPoint(1));
            end
        end
        
        function val = compareSensorDrawn(obj)
            val = logical(obj.hCompareWith.hCompareWithCheckbox.Value);
        end
        
        function onParameterChangedCallback(obj,src,event)
            obj.getCurrentSensor().preComputePreprocessedData();
            obj.compareSensor.preComputePreprocessedData();
            obj.updatePlotsInPlace();
        end
    end
end