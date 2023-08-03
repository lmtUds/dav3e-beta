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
                
        oldPath
    end
    
    properties (Dependent)
        currentGrouping
    end
    
    methods
        function obj = Grouping(main)
            obj@Gui.Modules.GuiModule(main);
        end
        
        function delete(obj)
            delete(obj.groupingTable);
            delete(obj.groupsTable);
        end
        
        function reset(obj)
            reset@Gui.Modules.GuiModule(obj);
%             obj.groupingTable.clear();
            obj.groupingTable.Data = {};
            obj.groupingTable.UserData = {};
%             obj.groupsTable.clear();
            obj.groupsTable.Data = {};
            obj.groupsTable.UserData = {};
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
            [sel,ok] = Gui.Dialogs.Select('ListItems',s,'MultiSelect',false);
            if ~ok
                return
            end
            obj.main.getActiveModule().onClose();
            obj.getProject().currentGrouping = obj.getProject().groupings(ismember(s,sel));
            obj.main.getActiveModule().onOpen();
        end
                
        function [moduleLayout,moduleMenu] = makeLayout(obj,uiParent,mainFigure)
            moduleLayout = uigridlayout(uiParent,[3 2],...
                'Visible','off',...
                'Padding',[0 0 0 0],...
                'ColumnWidth',{'4x','1x'},...
                'RowHeight',{'2x','1x','3x'},...
                'RowSpacing',7);
            
            moduleMenu = uimenu(mainFigure,'Label','Grouping');
            uimenu(moduleMenu,'Label', 'set current grouping',...
                getMenuCallbackName(), @(varargin)obj.onClickMenuSetCurrentGrouping);
            uimenu(moduleMenu,'Label', 'make color gradient',...
                getMenuCallbackName(), @(varargin)Gui.Dialogs.GroupingColorGradient(obj.main, obj));
            uimenu(moduleMenu,'Label', 'import groupings',...
                getMenuCallbackName(), @(varargin)obj.onClickImport);
            uimenu(moduleMenu,'Label', 'export groupings',...
                getMenuCallbackName(), @(varargin)obj.onClickExport);
                        
            groupAx = uiaxes(moduleLayout);
            groupAx.XLabel.String = 'Cycle number';
            groupAx.YLabel.String = 'Prepro. data / a.u.';
            
            groupAx.Layout.Row = 1;
            groupAx.Layout.Column = [1 2];
           
            obj.hAx = groupAx;
            
            groupingTable = uitable(moduleLayout,'ColumnRearrangeable','on');
            groupingTable.Layout.Row = [2 3];
            groupingTable.Layout.Column = 1;
            
            groupingCM = uicontextmenu(mainFigure);
            renameMenu = uimenu(groupingCM,...
                'Text','Rename Groupings',...
                'MenuSelectedFcn',@(src,event) obj.renameGroupings(src,event));
            groupingTable.ContextMenu = groupingCM;

            obj.groupingTable = groupingTable;
            
            buttonGrid = uigridlayout(moduleLayout,[3 1],...
                'Padding' ,[0 0 0 0],...
                'RowSpacing',4,...
                'RowHeight',{'1x','1x','1x'});
            buttonGrid.Layout.Row = 2;
            buttonGrid.Layout.Column = 2;
            
            addButton = uibutton(buttonGrid,...
                'Text','Add new grouping',...
                'ButtonPushedFcn',@obj.addGroupingButtonCallback);
            addButton.Layout.Row = 1;
            
            createButton = uibutton(buttonGrid,...
                'Text','Create new grouping',...
                'ButtonPushedFcn',@(varargin)...
                            Gui.Dialogs.GroupingCreation(obj.main,obj));
            createButton.Layout.Row = 2;
            
            deleteButton = uibutton(buttonGrid,...
                'Text','Delete grouping',...
                'ButtonPushedFcn',@obj.deleteGroupingButtonCallback);
            deleteButton.Layout.Row = 3;
            
            obj.deleteButton = deleteButton;
            
            groupsTable = uitable(moduleLayout);
            groupsTable.Layout.Row = 3;
            groupsTable.Layout.Column = 2;
            
            obj.groupsTable = groupsTable;
        end

        function onClickImport(obj)
            options = {'*.json','JSON file';'*.csv','CSV (human readable)'};
            [file,path] = uigetfile(options,'Choose groupings file',obj.oldPath);
            % swap invisible shortly to regain window focus after
            % uigetfile
            obj.main.hFigure.Visible = 'off';
            obj.main.hFigure.Visible = 'on';
            if file == 0
                return
            end
            obj.oldPath = path;
            
            selection = uiconfirm(obj.main.hFigure,...
                                'This will delete the current groupings. Proceed?',...
                                'Confirm grouping import','Icon','warning',...
                                'Options',{'Yes, Import','No, Cancel'},...
                                'DefaultOption',2,'CancelOption',2);
            switch selection
                case 'No, Cancel'
                    return
            end
            
            splitFile = strsplit(file,'.');
            extension = splitFile{end};
            groupingJson = fileread(fullfile(path,file));
            switch extension
                case 'json'
                    groupingStruct = jsondecode(groupingJson);
                case 'csv'
                    groupingStruct = groupingCsvDecode(groupingJson);
            end
            
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
            options = {'*.json','JSON file';'*.csv','CSV (human readable)'};
            [file,path] = uiputfile(options,'Choose groupings file',obj.oldPath);
            % swap invisible shortly to regain window focus after
            % uiputfile
            obj.main.hFigure.Visible = 'off';
            obj.main.hFigure.Visible = 'on';
            if file == 0
                return
            end
            obj.oldPath = path;
            
            splitFile = strsplit(file,'.');
            extension = splitFile{end};
            
            groupingJson.groupings = obj.getProject().groupings.toStruct();
            switch extension
                case 'json'
                    groupingJson = jsonencode(groupingJson);
                case 'csv'
                    groupingJson = groupingCsvEncode(groupingJson);
            end
            fid = fopen(fullfile(path,file), 'w+');
            fwrite(fid, groupingJson, 'char');
            fclose(fid);
        end        
        
        function allowed = canOpen(obj)
            p = obj.getProject();
            if isempty(p) || isempty(p.getCurrentCluster()) || isempty(p.getCurrentSensor())
                allowed = false;
                uialert(obj.main.hFigure,'Load at least one sensor.','Data required');
            elseif numel(p.ranges) == 0
                allowed = false;
                uialert(obj.main.hFigure,'Define at least one cycle range.','Cycle ranges required');
            else
                allowed = true;
            end
        end
        
        function onOpen(obj)
            % temporarily, should check for changes
%             obj.handleSensorChange(obj.getProject().getCurrentSensor(),obj.lastSensor);
%             obj.populateGroupingTable();

            % TODO: needs to check for any change in cycle ranges
%             if obj.clusterHasChanged()
                obj.handleClusterChange(obj.getProject().getCurrentCluster(),obj.lastCluster);
%             end
%             if obj.sensorHasChanged()
                obj.handleSensorChange(obj.getProject().getCurrentSensor(),obj.lastSensor);
%             end
            obj.populateGroupsTable(obj.currentGrouping);
            obj.deleteButton.Text = sprintf('Delete "%s"',obj.currentGrouping.getCaption());    

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
            gps = obj.getProject().groupings;
            header = gps.getCaption();
            r = obj.getCurrentCluster().getCycleRanges();
            data = cellstr(gps.getValues(r));
            
            t = obj.groupingTable;
            t.Data = data;
%             t.UserData = r;
            t.UserData = gps;
            
            t.ColumnName = header;
            t.ColumnEditable = true;
            
%             t.setColumnObjects(gps);
%             t.setColumnClasses({'str','int','clr'});
            
            t.CellSelectionCallback = @(src,event) obj.groupingTableColumnSelectionChanged(src,event);
            t.CellEditCallback = @(src,event) obj.groupingTableDataChanged(src,event);
%             t.ButtonDownFcn = @(src,event) obj.groupingTableMouseClickedCallback(src,event);
            
%             t.onColumnMovedCallback = @obj.groupingTableColumnMoved;
%             t.onHeaderTextChangedCallback = @obj.groupingTableHeaderTextChanged;

%             obj.cyclePointTable.onDataChangedCallback = @obj.cyclePointTableDataChangeCallback;
%             obj.cyclePointTable.onMouseClickedCallback = @obj.cyclePointTableMouseClickedCallback;
        end
        
        function populateGroupsTable(obj,grouping)
            if nargin < 2
                grouping = obj.currentGrouping;
            end
            
            c = grouping.colors;
            keys = grouping.getSortedColorKeys();
            clrArray = values(c,keys);
            clrArray = vertcat(clrArray{:});
            colors = cell(size(clrArray,1),1);
            for i = 1:size(clrArray,1)
                colors{i} = clr2str(clrArray(i,:));
            end
            
            data = [keys' colors];
            
            t = obj.groupsTable;
            t.Data = data;
            t.UserData = keys;
            
            t.ColumnName = {'group','color'};
            t.ColumnFormat = {'char','char'};
            t.ColumnEditable = [true true];
            
            if size(clrArray,1) > 1
                for i = 1:size(clrArray,1)
                    s = uistyle('BackgroundColor',clrArray(i,:));
                    addStyle(t,s,'cell',[i 2])
                end
            else
                s = uistyle('BackgroundColor',clrArray);
                addStyle(t,s,'column',2)
            end
            
            t.CellEditCallback = @(src,event) obj.groupsTableDataChanged(src,event);
            t.CellSelectionCallback = @(src,event) obj.groupsTableClicked(src,event);
            
            if ~isempty(obj.ranges)
                obj.ranges.setColor(grouping.getColorsForRanges(obj.getCurrentCluster().getCycleRanges()));
            end
            
            obj.deleteButton.Text = sprintf('Delete "%s"',grouping.getCaption());
        end
        
        function groupingTableMouseClickedCallback(obj,src,event)
            %%
            % highlight the corresponding graphics object when the mouse
            % button is pressed on a table row
%             o = obj.groupingTable.getRowObjectsAt(visRC(1));
            o = obj.ranges(src(1));
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
        
        function groupingTableColumnSelectionChanged(obj,src,event)
            if isempty(event.Indices)
                return
            else
                row = event.Indices(1,1);
                column = event.Indices(1,2);
                g = src.UserData(column);
            end
            obj.currentGrouping = g;
            obj.populateGroupsTable(g);
            obj.updateRangeColors();
            removeStyle(obj.groupingTable);
            style = uistyle("BackgroundColor",[221,240,255]./256);
            addStyle(src,style,"Column",column);
            
            % if a double click on the whole column happended
            % rename the grouping
            if strcmp(get(gcf,'SelectionType'),'open') ...
                    && size(event.Indices,1) == size(src.Data,1)
                
                [answer,ext] = Gui.Dialogs.Input('FieldNames',{g.caption},...
                    'DefaultValues',{g.caption},...
                    'Message','Enter new grouping names:',...
                    'Name','Rename Grouping');
                if ~ext
                    return
                end
                g.setCaption(answer);
            end
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
            
            % choose the first grouping as the new active grouping
            p.currentGrouping = p.groupings(1);
            
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
        
        function groupingTableDataChanged(obj,src,event)
            row = event.Indices(1);
            column = event.Indices(2);
            grouping = src.UserData(column);
            range = grouping.ranges(row);
            
            grouping.setValue(event.EditData,range);
            grouping.updateColors();
            obj.populateGroupsTable(grouping);
        end
        
        function groupsTableDataChanged(obj,src,event)
            row = event.Indices(1);
            column = event.Indices(2);
            key = src.UserData(row);
            key = key{1};
            switch column
                case 1
                    obj.currentGrouping.replaceGroup(key,event.NewData);
                case 2
                    try %to convert the edited string to a color triplet
                        rgbClr = str2clr(event.EditData);
                    catch ME %revert back to the previous string and colour
                        disp(ME)
                        rgbClr = str2clr(event.PreviousData);
                        src.Data{row,col} = event.PreviousData;
                    end
                    s = uistyle('BackgroundColor',rgbClr);
                    addStyle(src,s,'cell',[row column]);
                    obj.currentGrouping.setColor(key,rgbClr);
                    obj.currentGrouping.updateColors();
                    obj.updateRangeColors();
            end
            obj.populateGroupingTable();
        end
        
        function groupsTableClicked(obj,src,event)
            % catch interaction with the colour column to show a colour
            % picker, we dont need anything else
            if size(event.Indices,1) == 1 && event.Indices(2) == 2
                row = event.Indices(1);
                col = event.Indices(2);
                key = src.UserData(row);
%                 key = key{1};
                clrArray = values(obj.currentGrouping.colors,key);
                origClr = clrArray{:};
                try
                    rgbClr = uisetcolor(origClr,'Select a color');
                    movegui(gcf,'center');
                    obj.main.hFigure.Visible = 'off';
                    obj.main.hFigure.Visible = 'on';
                    src.Data{row,col} = clr2str(rgbClr);
                catch ME
                    disp(ME)
                    rgbClr = origClr;
                end
                s = uistyle('BackgroundColor',rgbClr);
                addStyle(src,s,'cell',[row col]);
                obj.currentGrouping.setColor(key{:},rgbClr);                
                obj.updateRangeColors();
            end
        end
        
        function updateRangeColors(obj)
            if ~isempty(obj.ranges)
%                 r = obj.getCurrentCluster().getCycleRanges();
                obj.ranges.setColor(obj.currentGrouping.getColorsForRanges(obj.ranges.getObject()));
            end
        end
        
        function renameGroupings(obj,src,event)
            gps = obj.getProject().groupings;
            caps = gps.getCaption();
            [answer,ext] = Gui.Dialogs.Input('FieldNames',caps,...
                    'DefaultValues',caps,...
                    'Message','Enter new grouping names:',...
                    'Name','Rename Grouping');
            if ~ext
                return
            end
            gps.setCaption(answer);
            
            %check for renamed groupings 
            %then choose the first renamed one as active
            idx = ~strcmp(answer,caps);
            if any(idx)
                [~,ind] = max(idx);
                obj.populateGroupsTable(gps(ind));
                obj.currentGrouping = gps(ind);
            end
            obj.populateGroupingTable();
        end
    end
end