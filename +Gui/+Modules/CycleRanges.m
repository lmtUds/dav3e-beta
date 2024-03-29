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

classdef CycleRanges < Gui.Modules.GuiModule
    properties
        caption = 'CycleRanges'
        
        ranges = GraphicsRange.empty;
        quasistaticLines

        hAx
        rangeTable
        
        oldPath = ''
    end
    
    methods
        function obj = CycleRanges(main)
            %% constructor
            obj@Gui.Modules.GuiModule(main);
        end
        
        function delete(obj)
            delete(obj.rangeTable);
        end  
        
        function [moduleLayout,moduleMenu] = makeLayout(obj,uiParent,mainFigure)
            %%
            moduleLayout = uigridlayout(uiParent,[2 1],...
                'Visible','off',...
                'Padding',[0 0 0 0],...
                'RowHeight',{'3x','2x'},...
                'RowSpacing',7);
            
            moduleMenu = uimenu(mainFigure,'Label','CycleRanges');
            uimenu(moduleMenu,'Label','export cycle ranges', getMenuCallbackName(),@(varargin)obj.onClickExport);
            uimenu(moduleMenu,'Label','import cycle ranges', getMenuCallbackName(),@(varargin)obj.onClickImport);
            uimenu(moduleMenu,'Label','change range length (batch)','Separator','on', getMenuCallbackName(),@(varargin)obj.onClickChangeRangeLength);
            uimenu(moduleMenu,'Label','make cycle ranges and grouping from selected sensor', getMenuCallbackName(),@(varargin)obj.onClickMakeCycleRangesAndGroupingFromSelectedSensor);

            rangeAx = uiaxes(moduleLayout);
            rangeAx.Title.String = 'Quasistatic signal';
            rangeAx.ButtonDownFcn = @obj.axesButtonDownCallback;
            rangeAx.XLabel.String = 'Cycle number';
            rangeAx.YLabel.String = 'Data / a.u.';
            
            rangeAx.Layout.Row = 1;
           
            obj.hAx = rangeAx;
            
            rangeTable = uitable(moduleLayout);
            rangeTable.Layout.Row = 2;
            
            obj.rangeTable = rangeTable;            
        end
        
        function onClickChangeRangeLength(obj,onlyCluster)
            [answer,ext] = Gui.Dialogs.Input('FieldNames',{'start','end'},...
                'DefaultValues',{'0','0'},'Name','Change range size');
            if ~ext
                return
            end
            startVal = str2double(answer{1});
            endVal = str2double(answer{2});
            r = obj.getProject().ranges;
%             cPos = r.getCyclePosition(obj.getCurrentCluster());
%             r.setCyclePosition(cPos + [startVal -endVal],obj.getCurrentCluster());
            cycLen = obj.getCurrentCluster().getCycleDuration();
            tPos = r.getTimePosition();
            r.setTimePosition(tPos + [startVal -endVal]*cycLen);
            obj.handleClusterChange(obj.getProject().getCurrentCluster(),obj.lastCluster);
        end
        
        function onClickImport(obj)
            options = {'*.json','JSON file';'*.csv','CSV (human readable)'};
            [file,path] = uigetfile(options,'Choose cycle range file',obj.oldPath);
            % swap invisible shortly to regain window focus after
            % uigetfile
            obj.main.hFigure.Visible = 'off';
            obj.main.hFigure.Visible = 'on';
            if file == 0
                return
            end
            obj.oldPath = path;
            
            if ~isempty(obj.ranges)
                selection = uiconfirm(obj.main.hFigure,...
                                'This will delete the current cycle ranges. Proceed?',...
                                'Confirm cycle range import','Icon','warning',...
                                'Options',{'Yes, Import','No, Cancel'},...
                                'DefaultOption',2,'CancelOption',2);
                switch selection
                    case 'No, Cancel'
                        return
                end
            end
            splitFile = strsplit(file,'.');
            extension = splitFile{end};
            
            rangeJson = fileread(fullfile(path,file));
            switch extension
                case 'json'
                    rangeStruct = jsondecode(rangeJson);
                case 'csv'
                    rangeStruct = rangeCsvDecode(rangeJson);
            end
            if ~isfield(rangeStruct,'cycleRanges')
                error('Field cycleRanges not found.');
            end
            
            r = Range.fromStruct(rangeStruct.cycleRanges);
            obj.deleteRangeCallback(obj.ranges);
            obj.addRange([],r);
        end
        
        function onClickExport(obj)
            options = {'*.json','JSON file';'*.csv','CSV (human readable)'};
            [file,path] = uiputfile(options,'Choose cycle range file',obj.oldPath);
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
            rangeJson.cycleRanges = obj.ranges.getObject().toStruct();
            switch extension
                case 'json'
                    rangeJson = jsonencode(rangeJson);
                case 'csv'
                    rangeJson = rangeCsvEncode(rangeJson);
            end
            fid = fopen(fullfile(path,file), 'w+');
            fwrite(fid, rangeJson, 'char');
            fclose(fid);
        end
        
        function onClickMakeCycleRangesAndGroupingFromSelectedSensor(obj)
            sensor = obj.getCurrentSensor();
            
            offset=sensor.getCluster().offset;
            samplingPeriod=sensor.getCluster().samplingPeriod;
            
            data = sensor.data;
            data = data';
            data = data(:);

%             if numel(unique(data))>2
%                 warning('This function is limited to a sensor that only has the values 0 and 1.')
%                 return;
%             end
            
%             lastOff = find(diff(data) == 1);
%             lastOn = find(diff(data) == -1);
%             changes = sort([[lastOff,lastOn],[lastOff,lastOn]+1]);

            change = find(diff(data) ~= 0)';
            changes = sort([change,change+1]);
            changes = [1,changes,size(data,1)];
%             nRanges = numel(changes)/2;
            
            times = offset+changes*samplingPeriod; %v1
%             times = offset+([0,sort([change,change]),size(data,1)])*samplingPeriod; %v2
            caps = data(changes);

            ncaps = numel(unique(caps));
            if isempty(change) || ncaps < 2 %should mean the same, but to be sure...
                errordlg('There are no changes in the sensor data, so no ranges detected.','No cycle ranges made')
                return
            end
            
            if (ncaps > 2 || (~any(ismember(caps,1)) || ~any(ismember(caps,0)))) %&& isempty(binSelIn)...
                msg = sprintf([ 'The sensor data seem to be non-binary\n', ...
                                '(%d different values detected).\n',...
                                'This might also be a result of data aquisition/processing.\n',...
                                'Do you actually expect binary data (only 0 and 1)?'],...
                                ncaps); 
                binSel = uiconfirm(obj.main.hFigure,...
                    msg,'Non-binary data detected',...
                    'Options',{'Yes, should be binary','No, clearly non-binary','I dont know, cancel'},...
                    'DefaultOption', 1,...
                    'CancelOption', 3,...
                    'Icon','question');
                if strcmp(binSel,'I dont know, cancel')
                    return
                end
                isbinary = strcmp(binSel,'Yes, should be binary');
            else %...
                isbinary = 1; %...
            end
            if isbinary  %&& isempty(onSelIn)...
                msg = sprintf([ 'Do you want to make cycle ranges \n',...
                                'only for the value 1 ("ON")\n',...
                                'or also for data parts with the value 0 ("OFF")?']...
                                ); 
                onSel = uiconfirm(obj.main.hFigure,...
                    msg,'Binary choice',...
                    'Options',{'Yes, only 1','No, both 0 and 1','I dont know, cancel'},...
                    'DefaultOption', 1,...
                    'CancelOption', 3,...
                    'Icon','question');
                if strcmp(onSel,'I dont know, cancel')
                    return
                end
                onlyOn = strcmp(onSel,'Yes, only 1');
            end %...
            
%             isbinary = 1; onlyOn = 1;
% With isbinary = 1, only data with the values 0 and 1 are used to make cycle 
% ranges ("binary" approach); with onlyOn = 1, only the 1 is used to make 
% ranges; set to 0 to also use 0; set isbinary = 0 to create cycle ranges of
% non-binary data; however, note that these should contain a very limited
% number of (stable) values (best: integers), as every change/new value is 
% assigned to a new cycle range (i.e., takes long if there are, e.g., a lot 
% of different floats)
            if isbinary
                changes = changes(caps==1 | caps==0);
                times = times(caps==1 | caps==0);
                caps = caps(caps==1 | caps==0);
            end
            
            nRanges = numel(changes)/2;
            
            rLimit = 1000;
            if nRanges > rLimit %&& isempty(limSelIn)...
                msg = sprintf([ 'Detected %d ranges to create.\n',...
                                'This exceedes the limit of %d.\n',...
                                'Processing this many ranges may lock up DAVE.'],...
                                nRanges,rLimit); 
                sel = uiconfirm(obj.main.hFigure,...
                    msg,'Large range count',...
                    'Options',{'Compute Anyway','Cancel'},...
                    'Icon','warning');
                if strcmp(sel,'Cancel')
                    return
                end
            end %...
            
            cr = Range.empty;
            groupColors=[];

            progDlg = uiprogressdlg(obj.main.hFigure,...
                'Title','Ranges are being created...',...
                'Message',sprintf('Creating range 1 of %d',nRanges));
            try
            
                for ridx = 1:1:nRanges
                    if (caps(1+2*(ridx-1))==1 && caps(2+2*(ridx-1))==1) || ~onlyOn || ~isbinary
                        cr(ridx) = Range([times(1+2*(ridx-1)), times(2+2*(ridx-1))]);
                        cr(ridx).setCaption(caps(1+2*(ridx-1)));
                        
                        groupCaptions=strsplit(sensor.getCaption, ' ');
                        groupCaptions=groupCaptions(1,1);
        
                        groupColors{ridx,1}=rand(1,3);
                    end
%                 end
                    
                    progDlg.Value = ridx / nRanges;
                    progDlg.Message = sprintf('Creating range %d of %d',ridx,nRanges);
                end
                close(progDlg)
            catch %make sure progDlg is closed
                close(progDlg)
            end
            
            if numel(obj.main.project.groupings)==1
                if strcmp(obj.main.project.groupings.caption,'grouping')
                    if isempty(obj.main.project.groupings.ranges)
                        obj.main.project.removeGrouping(obj.main.project.groupings)
                    end
                end
            end
            
            for cridx=numel(cr):-1:1
                if sum(cr(1,cridx).timePosition)==0
                    cr(cridx)=[];
                    groupColors(cridx)=[];
                end
            end
            
            obj.addRange([],cr);
            
             for i = 1:numel(groupCaptions)
                if ~strcmp(groupCaptions(i),'')
                    gCaption = groupCaptions(i);
                    g = obj.main.project.getGroupingByCaption(gCaption);
                    if isempty(g)
                        g = Grouping();
                        g.setCaption(gCaption);
                        obj.main.project.addGrouping(g);
                    end
                    vals = string(vertcat(cr.getCaption'));
                    g.setGroup(categorical(vals),cr);
                    
                    color = groupColors;
                    for j=1:numel(color)
                        if ~isnan(color{j,i})
                            g.setColor(vals{j,1}, color{j,1});
                        end
                    end
                    g.updateColors();
                end
             end
        end
        
        function allowed = canOpen(obj)
            %% Validates whether the module can open.
            % The module can open only when a project, a cluster, and a
            % sensor exist.
            p = obj.getProject();
            if isempty(p) || isempty(p.getCurrentCluster()) || isempty(p.getCurrentSensor())
                allowed = false;
                uialert(obj.main.hFigure,'Load at least one sensor.','Data required');
            else
                allowed = true;
            end
        end
        
        function onOpen(obj)
            %% Called right before the module opens.
            if obj.clusterHasChanged()
                obj.handleClusterChange(obj.getProject().getCurrentCluster(),obj.lastCluster);
            end
            if obj.sensorHasChanged()
                obj.handleSensorChange(obj.getProject().getCurrentSensor(),obj.lastSensor);
            end
            if ~isequal(obj.getProject().ranges, obj.ranges)
                obj.handleClusterChange(obj.getProject().getCurrentCluster(),obj.lastCluster);
            end
            obj.ranges.updateYLimits();
%             set(obj.main.hFigure,'WindowScrollWheelFcn',@obj.scrollWheelCallback);
        end
        
        function onClose(obj)
            %% Called right before the module closes.
            onClose@Gui.Modules.GuiModule(obj);
            obj.getProject().sortGroupings();
            set(gcf,'WindowScrollWheelFcn',[]);
        end

        function handleClusterChange(obj,newCluster,oldCluster)
            delete(obj.ranges);
            r = newCluster.getCycleRanges();
            obj.ranges = r.makeGraphicsObject('cycle',true);
            obj.ranges.draw(obj.hAx,obj.getCurrentSensor(),ylim(obj.hAx));
            [obj.ranges.onDraggedCallback] = deal(@obj.cycleRangeDraggedCallback);
            [obj.ranges.onDragStartCallback] = deal(@obj.cycleRangeDragStartCallback);
            [obj.ranges.onDragStopCallback] = deal(@obj.cycleRangeDragStopCallback);
            [obj.ranges.onDeleteRequestCallback] = deal(@obj.deleteRangeCallback);
            obj.populateRangeTable(obj.ranges);
        end
        
        function handleSensorChange(obj,newSensor,oldSensor)
            delete(obj.quasistaticLines);
            obj.quasistaticLines = [];
            
            d = newSensor.getSelectedQuasistaticSignals(true);
            if isempty(obj.quasistaticLines)
                x = repmat((1:size(d,1))',1,size(d,2));
                hold(obj.hAx,'on');
                obj.quasistaticLines = plot(obj.hAx,x,d,'-k');
                hold(obj.hAx,'off');
%                 uistack(obj.quasistaticLines,'bottom');
                cClr = newSensor.getIndexPoints().getColorCell();
                l = [obj.quasistaticLines];
                [l.Color] = deal(cClr{:});
            else
                for i = 1:numel(obj.quasistaticLines)
                    obj.quasistaticLines(i).YData = d(:,i);
                end
            end
            
%             ylimits = newSensor.getDataMinMax();
%             ylimits = ylimits + [-.1 .1] * diff(ylimits);
%             obj.ranges.setYLimits(ylimits);
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
        
        function populateRangeTable(obj,gRanges)
            %% Styles table, writes range data to it and activates callbacks.
            if ~isempty(gRanges)
                captions = cellstr(gRanges.getRange().getCaption()');
                positions = num2cell(gRanges.getPosition());
                time_positions = num2cell(gRanges.getTimePosition());

                clrArray = gRanges.getRange().getColor();
                colors = cell(size(clrArray,1),1);
                for i = 1:size(clrArray,1)
                    colors{i} = clr2str(clrArray(i,:));
                end
                data = [captions, positions, time_positions, colors];
%                 data = [captions, positions, time_positions];
            else
                data = {};
            end
            
            t = obj.rangeTable;
            t.Data = data;
            t.UserData = gRanges;
            
            t.ColumnName = {'caption','begin','end','time begin in s','time end in s','color'};
            t.ColumnFormat = {'char','numeric','numeric','numeric','numeric','char'};
            t.ColumnEditable = [true true true true true true];
            
%             t.ColumnName = {'caption','begin','end','time begin in s','time end in s'};
%             t.ColumnFormat = {'char','numeric','numeric','numeric','numeric'};
%             t.ColumnEditable = [true true true true true];
            
            if ~isempty(gRanges) %only sort if there is a range
                ind = tableColSort(t,4,'a');
                gRanges = gRanges(ind);
            end
            if ~isempty(data)
                clrArray = clrArray(ind,:); %sort colors, then style
                if size(clrArray,1) > 1
                    for i = 1:size(clrArray,1)
                        s = uistyle('BackgroundColor',clrArray(i,:));
                        addStyle(t,s,'cell',[i 6])
                    end
                else
                    s = uistyle('BackgroundColor',clrArray);
                    addStyle(t,s,'column',6)
                end
            end
            obj.rangeTable.CellEditCallback = @(src,event) obj.rangeTableDataChangeCallback(src,event);
            obj.rangeTable.CellSelectionCallback = @(src,event) obj.rangeTableMouseClickedCallback(src,event);
        end
        
        function cycleRangeDraggedCallback(obj,gRange)
            %%
            % update the position in the table when the point is dragged
%             row = obj.rangeTable.getRowObjectRow(gRange);
            row = ismember(obj.rangeTable.UserData,gRange);
            pos = gRange.getPosition();
            time_pos = gRange.getTimePosition();
            clr = gRange.getObject().getColorCell();
            obj.rangeTable.Data{row,2} = pos(1);
            obj.rangeTable.Data{row,3} = pos(2);
            obj.rangeTable.Data{row,4} = time_pos(1);
            obj.rangeTable.Data{row,5} = time_pos(2);
            obj.rangeTable.Data{row,6} = clr2str(clr{:});
            tableColSort(obj.rangeTable,4,'a');
            obj.populateRangeTable(obj.ranges);
        end
        
        function cycleRangeDragStartCallback(obj,gObj)
            %% Called when the user starts to drag range.
            % disable table callbacks (to omit "wrong" data changed events),
            % move the current selection to the corresponding row, and make
            % the corresponding cycle line bold
            obj.rangeTable.Enable = 'off';
%             obj.rangeTable.setCallbacksActive(false);
%             idx = ismember(gObj,obj.rangeTable.UserData);
%             objRow = obj.rangeTable.getRowObjectRow(gObj);
%             obj.rangeTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
        end
        
        function cycleRangeDragStopCallback(obj,gObj)
            %% Called when a range drag is finished.
            % re-enable table callbacks and set selection again (can get
            % messed up, probably due to dynamic sorting in the table?),
            % set cycle line width back to normal
            pause(0.01); % to make sure all callbacks have been processed
%             objRow = obj.rangeTable.getRowObjectRow(gObj);
%             obj.rangeTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
%             obj.rangeTable.setCallbacksActive(true);
            tableColSort(obj.rangeTable,4,'a');
            obj.populateRangeTable(obj.ranges);
            obj.rangeTable.Enable = 'on';
%             obj.rangeTable.jTable.sortColumn(4);
        end
        
        function rangeTableDataChangeCallback(obj,src,event)
            %% Called when any data in the table changes.
            % write changes from the table to the point object
            row = event.Indices(1);
            column = event.Indices(2);
            rangeObj = src.UserData(row);
            switch column
                case 1
                    rangeObj.getObject().setCaption(event.NewData);
                case 2
                    rangeObj.setPosition([event.NewData nan],obj.getProject().getCurrentSensor());
                    time_pos = rangeObj.getTimePosition();
                    src.Data{row,4} = time_pos(1);
                case 3
                    rangeObj.setPosition([nan event.NewData],obj.getProject().getCurrentSensor());
                    time_pos = rangeObj.getTimePosition();
                    src.Data{row,5} = time_pos(2);
                case 4
                    rangeObj.setTimePosition([event.NewData nan]);
                    pos = rangeObj.getPosition();
                    src.Data{row,2} = pos(1);
                case 5
                    rangeObj.setTimePosition([nan event.NewData]);
                    pos = rangeObj.getPosition();
                    src.Data{row,3} = pos(2);
                case 6
                    try %to convert the edited string to a color triplet
                        rgbClr = str2clr(event.EditData);
                    catch ME %revert back to the previous string and colour
                        disp(ME)
                        rgbClr = str2clr(event.PreviousData);
                        src.Data{row,col} = event.PreviousData;
                    end
                    s = uistyle('BackgroundColor',rgbClr);
                    addStyle(src,s,'cell',[row column]);
                    rangeObj.setColor(rgbClr);
            end
            tableColSort(src,4,'a');
        end
                
        function rangeTableMouseClickedCallback(obj,src,event)
            %% Called when the mouse is clicked in the table.
            % catch interaction with the colour column to show a colour
            % picker, we dont need anything else
            if size(event.Indices,1) == 1 && event.Indices(2) == 6
                row = event.Indices(1);
                col = event.Indices(2);
                rangeObj = src.UserData(row);
                origClr = rangeObj.getRange().getColor();
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
                
                rangeObj.setColor(rgbClr);
            end
        end
        
        function axesButtonDownCallback(obj,varargin)
            %% Called when the mouse is clicked in the axes.
            % Adds a new range upon double-click.
            switch get(gcf,'SelectionType')
                case 'open' % double-click
                    coord = get(gca,'Currentpoint');
                    x = coord(1,1);
                    obj.addRange(x);
            end
        end
        
        function addRange(obj,pos,ranges)
            %% Adds a new range (graphical and in the project).
            % in: pos (start cycle number)
            if nargin >= 3
                r = ranges;
            else
%                 nCycles = obj.getCurrentCluster().nCycles;
                r = obj.getCurrentCluster().makeCycleRange([pos,pos+10]); % Length of Range: 10 cycles %[pos,pos+nCycles*0.02]);
            end
            obj.getProject().addCycleRange(r);
            rg = r.makeGraphicsObject('cycle',true);
            obj.ranges = [obj.ranges, rg];
            rg.draw(obj.hAx,obj.getCurrentSensor(),ylim(obj.hAx));
            [rg.onDraggedCallback] = deal(@obj.cycleRangeDraggedCallback);
            [rg.onDragStartCallback] = deal(@obj.cycleRangeDragStartCallback);
            [rg.onDragStopCallback] = deal(@obj.cycleRangeDragStopCallback);
            [rg.onDeleteRequestCallback] = deal(@obj.deleteRangeCallback);
            obj.populateRangeTable(obj.ranges);
        end
        
        function deleteRangeCallback(obj,gObject)
            %% Called upon right-click on a range to delete it.
            % in: gObject (graphical range)
            obj.getProject().removeCycleRange(gObject.getObject());
            obj.ranges(ismember(obj.ranges,gObject)) = [];
            delete(gObject);
            obj.populateRangeTable(obj.ranges);  
        end

        function scrollWheelCallback(obj,~,e)
            %%
            if isempty(obj.ranges)  %stop if there are no ranges
                return;
            end
            dir = e.VerticalScrollCount;
            p = get(gca,'CurrentPoint');
            x = p(1,1); y = p(1,2); ylimits = ylim;
            pos = obj.ranges.getPosition();
            onRange = (x >= pos(:,1)) & (x <= pos(:,2));
            inYLimits = (y >= ylimits(1)) && (y <= ylimits(2));
            if ~inYLimits || ~any(onRange)  %stop if we hit no range
                return
            end
            affectedRanges = obj.ranges(onRange);
            for i = 1:numel(affectedRanges)
                r = affectedRanges(i);
                obj.cycleRangeDragStartCallback(r);
                oldPos = r.getObject().getCyclePosition(obj.getCurrentCluster());
                r.getObject().setCyclePosition(oldPos - dir*[-1 1],obj.getCurrentCluster());
                r.updatePosition(obj.getCurrentSensor());
                obj.cycleRangeDraggedCallback(r);
                obj.cycleRangeDragStopCallback(r);
            end
        end
    end
end