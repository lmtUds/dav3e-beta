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

classdef Grouping < Gui.Modules.GuiModule
    properties
        caption = 'Grouping'
        
        groupingTable
        groupsTable
        hAx
        deleteButton

        ranges
        quasistaticLines
        
        colorGradientDialog
        createGroupingDialog
        
        oldPath
    end
    
    properties (Dependent)
        currentGrouping
    end
    
    methods
        function obj = Grouping(main)
            obj@Gui.Modules.GuiModule(main);
            obj.colorGradientDialog = Gui.Dialogs.GroupingColorGradient(main,obj);
            obj.createGroupingDialog = Gui.Dialogs.GroupingCreation(main,obj);
        end
        
        function delete(obj)
            delete(obj.groupingTable);
            delete(obj.groupsTable);
            delete(obj.colorGradientDialog.f);
            delete(obj.createGroupingDialog.f);
        end
        
        function reset(obj)
            reset@Gui.Modules.GuiModule(obj);
            obj.groupingTable.clear();
            obj.groupsTable.clear();
            delete(obj.ranges);
            obj.ranges = GraphicsRange.empty;
        end
        
        function val = get.currentGrouping(obj)
            val = obj.getProject().currentGrouping;
        end
        
        function set.currentGrouping(obj,val)
            obj.getProject().currentGrouping = val;
        end        
        
        function onClickMenuSetCurrentGrouping(obj)
            s = cellstr(obj.getProject().groupings.getCaption());
            [sel,ok] = listdlg('ListString',s, 'SelectionMode','single');
            if ~ok
                return
            end
            obj.main.getActiveModule().onClose();
            obj.getProject().currentGrouping = obj.getProject().groupings(sel);
            obj.main.getActiveModule().onOpen();
        end
        
        function [panel,menu] = makeLayout(obj)
            panel = Gui.Modules.Panel();
            
            menu = uimenu('Label','Grouping');
            uimenu(menu,'Label','set current grouping', getMenuCallbackName(),@(varargin)obj.onClickMenuSetCurrentGrouping);
            uimenu(menu,'Label','make color gradient', getMenuCallbackName(),@(varargin)obj.colorGradientDialog.show());
            uimenu(menu,'Label','import groupings', getMenuCallbackName(),@(varargin)obj.onClickImport);
            uimenu(menu,'Label','export groupings', getMenuCallbackName(),@(varargin)obj.onClickExport);
            
            layout = uiextras.VBox('Parent',panel);
            obj.hAx = axes(layout);
            xlabel('cycle number'); ylabel('prepro. data / a.u.');
            box on
            set(gca,'LooseInset',get(gca,'TightInset'))
            
            tablePropLayout = uiextras.HBox('Parent',layout);

            obj.groupingTable = JavaTable(tablePropLayout,'editable');
            
            configLayout = uiextras.VBox('Parent',tablePropLayout);
            uicontrol('Parent',configLayout, 'String','add new grouping',...
                'Callback',@obj.addGroupingButtonCallback);
            uicontrol('Parent',configLayout, 'String','create new grouping',...
                'Callback',@(varargin)obj.createGroupingDialog.show());
            obj.deleteButton = uicontrol('Parent',configLayout, 'String','delete grouping',...
                'Callback',@obj.deleteGroupingButtonCallback);
            obj.groupsTable = JavaTable(configLayout);

            layout.Sizes = [-1,-3];
            tablePropLayout.Sizes = [-4,-1];
            configLayout.Sizes = [25,25,25,-1];
        end

        function onClickImport(obj)
            [file,path] = uigetfile({'*.json','JSON file'},'Choose groupings file',obj.oldPath);
            if file == 0
                return
            end
            obj.oldPath = path;
            
            re = questdlg('This will delete the current groupings. Proceed?','Proceed?','Yes','No','No');
            if ~strcmp(re,'Yes')
                return
            end
            
            groupingJson = fileread(fullfile(path,file));
            groupingStruct = jsondecode(groupingJson);
            if ~isfield(groupingStruct,'groupings')
                error('Field groupings not found.');
            end
            
            g = Grouping.fromStruct(groupingStruct.groupings,obj.getProject().ranges);
            obj.getProject().removeGrouping(obj.getProject().groupings);
            obj.getProject().addGrouping(g);
            obj.populateGroupingTable();
            obj.populateGroupsTable();
        end
        
        function onClickExport(obj)
            [file,path] = uiputfile({'*.json','JSON file'},'Choose groupings file',obj.oldPath);
            if file == 0
                return
            end
            obj.oldPath = path;
            
            groupingJson.groupings = obj.getProject().groupings.toStruct();
            groupingJson = jsonencode(groupingJson);
            fid = fopen(fullfile(path,file), 'w+');
            fwrite(fid, groupingJson, 'char');
            fclose(fid);
        end        
        
        function allowed = canOpen(obj)
            p = obj.getProject();
            if isempty(p) || isempty(p.getCurrentCluster()) || isempty(p.getCurrentSensor())
                allowed = false;
                errordlg('Load at least one sensor.');
            elseif numel(p.ranges) == 0
                allowed = false;
                errordlg('Define at least one cycle range.');
            else
                allowed = true;
            end
        end
        
        function onOpen(obj)
            % temporarily, should check for changes
%             obj.handleSensorChange(obj.getProject().getCurrentSensor(),obj.lastSensor);
%             obj.populateGroupingTable();
            
            obj.populateGroupsTable(obj.currentGrouping);
            obj.deleteButton.String = sprintf('delete "%s"',obj.currentGrouping.getCaption());
            
            % TODO: needs to check for any change in cycle ranges
%             if obj.clusterHasChanged()
                obj.handleClusterChange(obj.getProject().getCurrentCluster(),obj.lastCluster);
%             end
%             if obj.sensorHasChanged()
                obj.handleSensorChange(obj.getProject().getCurrentSensor(),obj.lastSensor);
%             end

%             obj.getProject().createGroupingFrom(...
%                 obj.getProject().getGroupingByCaption('valve V10'),...
%                 obj.getProject().getGroupingByCaption('cooler C1'),...
%                 {'3','100'},...
%                 '*');
%             obj.populateGroupingTable();
%             obj.populateGroupsTable();
        end
        
        function onClose(obj)
            onClose@Gui.Modules.GuiModule(obj);
            obj.getProject().sortGroupings();
        end
        
        function handleClusterChange(obj,newCluster,oldCluster)
            % change ranges in plot
            % populate table with corresponding groups
%             delete(obj.quasistaticLines);
%             obj.quasistaticLines = [];
            obj.populateGroupingTable();
            
            delete(obj.ranges);
            obj.ranges = [];
            r = obj.getCurrentCluster().getCycleRanges();
            obj.ranges = r.makeGraphicsObject('cycle',false);
            hold(obj.hAx,'on');
            obj.ranges.draw(obj.hAx,newCluster.sensors(1),[0 1]);
            hold(obj.hAx,'off');
            obj.updateRangeColors();
        end
        
        function handleSensorChange(obj,newSensor,oldSensor)
%             newSensor.getCaption()
            delete(obj.quasistaticLines);
            obj.quasistaticLines = [];
            
            ylimits = newSensor.getDataMinMax(true);
            ylimits = ylimits + [-.1 .1] * diff(ylimits);
            
            d = newSensor.getSelectedQuasistaticSignals(true);
            if isempty(obj.quasistaticLines)
                x = repmat((1:size(d,1))',1,size(d,2));
                hold(obj.hAx,'on');
                obj.quasistaticLines = plot(obj.hAx,x,d,'-k');
                hold(obj.hAx,'off');
            else
                for i = 1:numel(obj.quasistaticLines)
                    obj.quasistaticLines(i).YData = d(:,i);
                end
            end

            cClr = newSensor.indexPointSet.getPoints().getColorCell();
            l = [obj.quasistaticLines];
            [l.Color] = deal(cClr{:});

            obj.ranges.updateYLimits();
        end
        
        function onCurrentClusterChanged(obj,cluster,oldCluster)
            obj.handleClusterChange(cluster,oldCluster);
        end
        
        function onCurrentSensorChanged(obj,sensor,oldSensor)
            obj.handleSensorChange(sensor,oldSensor);
        end

        function onCurrentIndexPointSetChanged(obj,ips)
            obj.handleSensorChange(obj.getProject().getCurrentSensor());
        end
        
        function onCurrentPreprocessingChainChanged(obj,ppc)
            obj.handleSensorChange(obj.getProject().getCurrentSensor());
        end
        
        function populateGroupingTable(obj)
            t = obj.groupingTable;
            g = obj.getProject().groupings;
            header = g.getCaption();
            r = obj.getCurrentCluster().getCycleRanges();
            data = cellstr(g.getValues(r));
            t.setData(data,header);
            t.setColumnObjects(g);
            t.setRowObjects(r);
%             t.setColumnClasses({'str','int','clr'});
            t.setColumnsEditable(true(1,numel(g)));
            t.setColumnReorderingAllowed(true);
            t.jTable.setAutoResizeMode(t.jTable.AUTO_RESIZE_OFF);
            
            t.onColumnSelectionChangedCallback = @obj.groupingTableColumnSelectionChanged;
            t.onColumnMovedCallback = @obj.groupingTableColumnMoved;
            t.onHeaderTextChangedCallback = @obj.groupingTableHeaderTextChanged;
            t.onDataChangedCallback = @obj.groupingTableDataChanged;
            t.onMouseClickedCallback = @obj.groupingTableMouseClickedCallback;

%             obj.cyclePointTable.onDataChangedCallback = @obj.cyclePointTableDataChangeCallback;
%             obj.cyclePointTable.onMouseClickedCallback = @obj.cyclePointTableMouseClickedCallback;
        end
        
        function populateGroupsTable(obj,grouping)
            if nargin < 2
                grouping = obj.currentGrouping;
            end
            t = obj.groupsTable;
            c = grouping.getJavaColors();
            header = {'group','color'};
            keys = grouping.getSortedColorKeys();
            data = [keys' values(c,keys)'];
            %data = [keys(c)' values(c)'];
            t.setData(data,header);
            t.setRowObjects(keys);
            t.setColumnClasses({'str','clr'});
            t.setColumnsEditable([true true]);
            t.setSortingEnabled(true)
            t.setFilteringEnabled(false);
            t.setColumnReorderingAllowed(false);
            t.jTable.repaint();
            
            t.onDataChangedCallback = @obj.groupsTableDataChanged;
            
%             if ~isempty(obj.ranges)
%                 obj.ranges.setColor(grouping.getColorsForRanges(obj.getCurrentCluster().getCycleRanges()));
%             end
            
            obj.deleteButton.String = sprintf('delete "%s"',grouping.getCaption());
        end
        
        function groupingTableMouseClickedCallback(obj,visRC,actRC)
            %%
            % highlight the corresponding graphics object when the mouse
            % button is pressed on a table row
%             o = obj.groupingTable.getRowObjectsAt(visRC(1));
            o = obj.ranges(visRC(1));
            o.setHighlight(true);
%             obj.ranges(visRC(1)).setHighlight(true);
            obj.groupingTable.onMouseReleasedCallback = @()obj.groupingTableMouseReleasedCallback(o);
        end
        
        function groupingTableMouseReleasedCallback(obj,gObject)
            %%
            % un-highlight the previously highlighted graphics object when
            % the mouse button is released again
            gObject.setHighlight(false);
            obj.groupingTable.onMouseReleasedCallback = [];
        end
        
        function groupingTableColumnSelectionChanged(obj,visC,actC)
            if visC(2) == 0
                obj.groupingTable.jTable.getColumnModel().getSelectionModel().setSelectionInterval(visC(1),visC(1));
                return
            end
            g = obj.groupingTable.getColumnObjectsAt(actC(2));
            obj.currentGrouping = g;
            obj.populateGroupsTable(g);
            obj.updateRangeColors();
            obj.colorGradientDialog.update(deStar(g.getDestarredCategories()));
        end
        
        function addGroupingButtonCallback(obj,varargin)
            obj.getProject().addGrouping();
            obj.populateGroupingTable();
        end
        
        function deleteGroupingButtonCallback(obj,varargin)
            p = obj.getProject();
            p.removeGrouping(obj.currentGrouping);
            if isempty(p.groupings)
                p.addGrouping();
            end
            obj.populateGroupingTable();
            obj.populateGroupsTable(obj.currentGrouping);
        end
        
        function groupingTableColumnMoved(obj,col,actCol)
            p = obj.getProject();
            p.groupings(col([2 1])) = p.groupings(col);
            %obj.groupingTable.columnObjects(actCol([2 1])) = obj.groupingTable.columnObjects(actCol);
            p.groupings.getCaption()
        end
        
        function groupingTableHeaderTextChanged(obj,header)
            p = obj.getProject();
            p.groupings.setCaption(header);
            p.groupings.getCaption()
        end
        
        function groupingTableDataChanged(obj,rc,v)
            for i = 1:size(rc)
                g = obj.groupingTable.getColumnObjectsAt(rc(i,2));
                r = obj.groupingTable.getRowObjectsAt(rc(i,1));
                g.setValue(v{i},r);
                g.updateColors();
                obj.populateGroupsTable(g);
            end
        end
        
        function groupsTableDataChanged(obj,rc,v)
            for i = 1:size(rc,1)
                g = obj.groupsTable.getRowObjectsAt(rc(i,1));
                g = g{1};
                switch rc(i,2)
                    case 1
                        obj.currentGrouping.replaceGroup(g,v{i});
                    case 2
                        obj.currentGrouping.setColor(g,v{i});
                        obj.currentGrouping.updateColors();
                        obj.updateRangeColors();
                end
            end
            obj.populateGroupingTable();
        end
        
        function updateRangeColors(obj)
            if ~isempty(obj.ranges)
%                 r = obj.getCurrentCluster().getCycleRanges();
                obj.ranges.setColor(obj.currentGrouping.getColorsForRanges(obj.ranges.getObject()));
            end
        end
    end
end