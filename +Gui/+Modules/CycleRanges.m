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
        
        function [panel,menu] = makeLayout(obj)
            %%
            panel = uiextras.Panel();
            
            menu = uimenu('Label','CycleRanges');
            uimenu(menu,'Label','import cycle ranges', getMenuCallbackName(),@(varargin)obj.onClickImport);
            uimenu(menu,'Label','export cycle ranges', getMenuCallbackName(),@(varargin)obj.onClickExport);
            uimenu(menu,'Label','change range length (batch)', getMenuCallbackName(),@(varargin)obj.onClickChangeRangeLength);
            
            layout = uiextras.VBox('Parent',panel);
            
            obj.hAx = axes(layout); title('quasistatic signal');
            obj.hAx.ButtonDownFcn = @obj.axesButtonDownCallback;
            xlabel('cycle number'); ylabel('data / a.u.');% yyaxis right, ylabel('raw data / a.u.');
            box on, 
            set(gca,'LooseInset',get(gca,'TightInset')) % https://undocumentedmatlab.com/blog/axes-looseinset-property
            
            obj.rangeTable = JavaTable(layout);
            
            layout.Sizes = [-3,-1];
        end
        
        function onClickChangeRangeLength(obj,onlyCluster)
            answer = inputdlg({'start','end'},'Change range size',[1 10],{'0','0'});
            startVal = str2double(answer{1});
            endVal = str2double(answer{2});
            r = obj.getProject().ranges;
            cPos = r.getCyclePosition(obj.getCurrentCluster());
            r.setCyclePosition(cPos + [startVal -endVal],obj.getCurrentCluster());
            obj.handleClusterChange(obj.getProject().getCurrentCluster(),obj.lastCluster);
        end
        
        function onClickImport(obj)
            [file,path] = uigetfile({'*.json','JSON file'},'Choose cycle range file',obj.oldPath);
            if file == 0
                return
            end
            obj.oldPath = path;
            
            if ~isempty(obj.ranges)
                re = questdlg('This will delete the current cycle ranges. Proceed?','Proceed?','Yes','No','No');
                if ~strcmp(re,'Yes')
                    return
                end
            end
            
            rangeJson = fileread(fullfile(path,file));
            rangeStruct = jsondecode(rangeJson);
            if ~isfield(rangeStruct,'cycleRanges')
                error('Field cycleRanges not found.');
            end
            
            r = Range.fromStruct(rangeStruct.cycleRanges);
            obj.deleteRangeCallback(obj.ranges);
            obj.addRange([],r);
        end
        
        function onClickExport(obj)
            [file,path] = uiputfile({'*.json','JSON file'},'Choose cycle range file',obj.oldPath);
            if file == 0
                return
            end
            obj.oldPath = path;
            
            rangeJson.cycleRanges = obj.ranges.getObject().toStruct();
            rangeJson = jsonencode(rangeJson);
            fid = fopen(fullfile(path,file), 'w+');
            fwrite(fid, rangeJson, 'char');
            fclose(fid);
        end
        
        function allowed = canOpen(obj)
            %% Validates whether the module can open.
            % The module can open only when a project, a cluster, and a
            % sensor exist.
            p = obj.getProject();
            if isempty(p) || isempty(p.getCurrentCluster()) || isempty(p.getCurrentSensor())
                allowed = false;
                errordlg('Load at least one sensor.');
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
            set(gcf,'WindowScrollWheelFcn',@obj.scrollWheelCallback);
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
                uistack(obj.quasistaticLines,'bottom');
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
                colors = num2cell(gRanges.getRange().getJavaColor());
                data = [captions, positions, time_positions, colors];
            else
                data = {};
            end

            t = obj.rangeTable;
            t.setData(data,{'caption','begin','end','time begin in s','time end in s','color'});
            t.setRowObjects(gRanges);
            t.setColumnClasses({'str','int','int','double','double','clr'});
            t.setColumnsEditable([true true true true true true]);
            t.setSortingEnabled(false)
            t.setFilteringEnabled(false);
            t.setColumnReorderingAllowed(false);
            t.jTable.sortColumn(4);
            t.jTable.setAutoResort(false)
            obj.rangeTable.onDataChangedCallback = @obj.rangeTableDataChangeCallback;
            obj.rangeTable.onMouseClickedCallback = @obj.rangeTableMouseClickedCallback;
        end
        
        function cycleRangeDraggedCallback(obj,gRange)
            %%
            % update the position in the table when the point is dragged
            row = obj.rangeTable.getRowObjectRow(gRange);
            pos = gRange.getPosition();
            time_pos = gRange.getTimePosition();
            obj.rangeTable.setValue(pos(1),row,2);
            obj.rangeTable.setValue(pos(2),row,3);
            obj.rangeTable.setValue(time_pos(1),row,4);
            obj.rangeTable.setValue(time_pos(2),row,5);
        end
        
        function cycleRangeDragStartCallback(obj,gObj)
            %% Called when the user starts to drag range.
            % disable table callbacks (to omit "wrong" data changed events),
            % move the current selection to the corresponding row, and make
            % the corresponding cycle line bold
            obj.rangeTable.setCallbacksActive(false);
            objRow = obj.rangeTable.getRowObjectRow(gObj);
            obj.rangeTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
        end
        
        function cycleRangeDragStopCallback(obj,gObj)
            %% Called when a range drag is finished.
            % re-enable table callbacks and set selection again (can get
            % messed up, probably due to dynamic sorting in the table?),
            % set cycle line width back to normal
            pause(0.01); % to make sure all callbacks have been processed
            objRow = obj.rangeTable.getRowObjectRow(gObj);
            obj.rangeTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
            obj.rangeTable.setCallbacksActive(true);
            obj.rangeTable.jTable.sortColumn(4);
        end
        
        function rangeTableDataChangeCallback(obj,rc,v)
            %% Called when any data in the table changes.
            % write changes from the table to the point object
            for i = 1:size(rc,1)
                o = obj.rangeTable.getRowObjectsAt(rc(i,1));
                switch rc(i,2)
                    case 1
                        o.getObject().setCaption(v{i});
                    case 2
                        o.setPosition([v{i} nan],obj.getProject().getCurrentSensor());
                    case 3
                        o.setPosition([nan v{i}],obj.getProject().getCurrentSensor());
                    case 4
                        o.setTimePosition([v{i} nan]);
                    case 5
                        o.setTimePosition([nan v{i}]);
                    case 6
                        o.setColor(v{i});
                end
                pos = o.getPosition();
                time_pos = o.getTimePosition();
                obj.rangeTable.setValue(pos(1),rc(i,1),2);
                obj.rangeTable.setValue(pos(2),rc(i,1),3);
                obj.rangeTable.setValue(time_pos(1),rc(i,1),4);
                obj.rangeTable.setValue(time_pos(2),rc(i,1),5);
            end
            obj.rangeTable.jTable.sortColumn(4);
        end
                
        function rangeTableMouseClickedCallback(obj,visRC,actRC)
            %% Called when the mouse is clicked in the table.
            % highlight the corresponding graphics object when the mouse
            % button is pressed on a table row
            o = obj.rangeTable.getRowObjectsAt(visRC(1));
            o.setHighlight(true);
            obj.rangeTable.onMouseReleasedCallback = @()obj.rangeTableMouseReleasedCallback(o);
        end
        
        function rangeTableMouseReleasedCallback(obj,gObject)
            %% Called when the mouse is released in the table.
            % un-highlight the previously highlighted graphics object when
            % the mouse button is released again
            gObject.setHighlight(false);
            obj.rangeTable.onMouseReleasedCallback = [];
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
                nCycles = obj.getCurrentCluster().nCycles;
                r = obj.getCurrentCluster().makeCycleRange([pos,pos+nCycles*0.1]);
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
            dir = e.VerticalScrollCount;
            p = get(gca,'CurrentPoint');
            x = p(1,1); y = p(1,2); ylimits = ylim;
            pos = obj.ranges.getPosition();
            onRange = (x >= pos(:,1)) & (x <= pos(:,2));
            inYLimits = (y >= ylimits(1)) && (y <= ylimits(2));
            if ~inYLimits || ~any(onRange)
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