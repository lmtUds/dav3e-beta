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

classdef JavaTable < handle
    properties
        jTable
        baseModel
        header
        container
        columnClasses = {}

        callbackRowsCols = zeros(0,2)
        callbackValues = {}
        ignoreDataChangesFrom = zeros(0,2)
        ignoreNextDataChange = false
        
        onDataChangedCallback = []
        onMouseClickedCallback = [];
        onMouseReleasedCallback = [];
        onRowSelectionChangedCallback = [];
        onColumnSelectionChangedCallback = [];
        onIndexChangedCallback = [];
        onHeaderTextChangedCallback = [];
        onColumnMovedCallback = [];
        
        callbackTimer
        callbacksActive = true
        
        rowObjects
        columnObjects
    end
    
    methods
        function obj = JavaTable(parent,headerType)
            if ~exist('parent','var')
                parent = figure;
            end
            if ~exist('headerType','var')
                headerType = 'sortable'; % editable
            end

            % general setup
            try
                jTable = MyTable();
            catch
                obj.initialSetup();
                jTable = MyTable();
            end
            switch headerType
                case 'sortable'
                    theader = com.jidesoft.grid.AutoFilterTableHeader(jTable);
                case 'editable'
                    theader = com.jidesoft.grid.EditableTableHeader(jTable.getColumnModel());
                    hheader = handle(theader,'CallbackProperties');
            end
            if strcmp(headerType,'default')
                theader = jTable.getTableHeader();
            else
                jTable.setTableHeader(theader)
            end
            jscroll = javax.swing.JScrollPane(jTable);
            [~,container] = javacomponent(jscroll,[5,5,500,400],parent);
            set(container,'Units','norm');
            jTable.putClientProperty('terminateEditOnFocusLost', true);
%             jTable.setAutoCreateColumnsFromModel(false);
%             jTable.setClickCountToStart(1); % double-click to start editing
            
            % fake row header (first column)
            cr0 = javax.swing.table.DefaultTableCellRenderer();
            cr0.setHorizontalAlignment(0) % 0 for CENTER, 2 for LEFT and 4 for RIGHT
            cr0.setBackground(java.awt.Color(15790320)); % grey backgroundt
            jTable.getColumnModel.getColumn(0).setCellRenderer(cr0);
            jTable.getColumnModel.getColumn(0).setResizable(false);
            jTable.getColumnModel.getColumn(0).setMaxWidth(32);     
            
            % scrollbars
            jscroll.setVerticalScrollBarPolicy(jscroll.VERTICAL_SCROLLBAR_AS_NEEDED);
            jscroll.setHorizontalScrollBarPolicy(jscroll.HORIZONTAL_SCROLLBAR_AS_NEEDED);
            jTable.setSelectionMode(javax.swing.ListSelectionModel.SINGLE_INTERVAL_SELECTION);
            jTable.setColumnSelectionAllowed(true);
            jTable.setRowSelectionAllowed(true);
            
            % fix row heights for high-res displays
            dpi = java.awt.Toolkit.getDefaultToolkit().getScreenResolution();
            jTable.setRowHeight(jTable.getRowHeight()*dpi/72);

            % disable sorting and filtering
            if strcmp(headerType,'sortable')
                theader.setUseNativeHeaderRenderer(true)
                jTable.setSortingEnabled(false);
                theader.setAutoFilterEnabled(true);
                theader.setShowFilterName(true);
                theader.setShowFilterIcon(true);
            end
            jTable.setSortingEnabled(false);
            theader.setReorderingAllowed(false);
            
            % callbacks
            obj.callbackTimer = timer;
            obj.callbackTimer.StartDelay = 0.01;
            obj.callbackTimer.TimerFcn = @obj.applyTableChanges;
            
            htable = handle(jTable.getSelectionModel(),'CallbackProperties');
            set(htable, 'ValueChangedCallback', @obj.rowSelectionChangedCallback);
            htable = handle(jTable.getColumnModel().getSelectionModel(),'CallbackProperties');
            set(htable, 'ValueChangedCallback', @obj.columnSelectionChangedCallback);
            htable = handle(jTable.getColumnModel(),'CallbackProperties');
            set(htable, 'ColumnMovedCallback', @obj.columnMovedCallback);
            htable = handle(jTable.getModel,'CallbackProperties');
            set(htable, 'TableChangedCallback', @obj.dataChangedCallback); 
            set(jTable,'MousePressedCallback', @obj.mouseClickedCallback); % seems to work better than MouseClickedCallback
            set(jTable,'MouseReleasedCallback', @obj.mouseReleasedCallback) 
            set(htable,'IndexChangedCallback',@obj.indexChangedCallback);
            
%             hheader = handle(theader,'CallbackProperties');
%             hheader.ComponentMovedCallback = @obj.columnMovedCallback;
            
            if strcmp(headerType,'editable')
                hheader = handle(theader.getDefaultEditor(),'CallbackProperties');
                set(hheader, 'EditingStoppedCallback', @obj.headerTextChangedCallback); 
            end
            
            obj.jTable = jTable;
            obj.baseModel = jTable.getModel().getActualModel().getActualModel();
            obj.header = theader;
            obj.container = container;
           
%             obj.baseModel.setColumnEditable(1,true);
%             obj.baseModel.setColumnClass(1,java.lang.Integer.TYPE);
%             
%             obj.baseModel.setColumnEditable(2,true);
%             obj.baseModel.setColumnClass(2,java.lang.Double.TYPE);
%             
%             obj.baseModel.setColumnEditable(3,true);
%             obj.baseModel.setColumnClass(3,java.lang.Boolean.TYPE);
%             
%             obj.baseModel.setColumnEditable(4,true);
%             obj.jTable.getColumnModel().getColumn(4).setCellEditor(com.jidesoft.grid.ListComboBoxCellEditor({'1','2','3'}));
        end
        
        function delete(obj)
            delete(obj.callbackTimer);
        end
        
        function initialSetup(obj)
            javaaddpath([pwd '\toolboxes\table\MyTable.jar']);
            
            % register JIDE's default converters/renderers/editors
            com.jidesoft.converter.ObjectConverterManager.initDefaultConverter();
            com.jidesoft.grid.CellEditorManager.initDefaultEditor();
            com.jidesoft.grid.CellRendererManager.initDefaultRenderer();

            % change converter locale to US in order to use point, not
            % comma, as decimal separator
            cm = com.jidesoft.converter.ObjectConverterManager;
            numberFormat = java.text.NumberFormat.getInstance(java.util.Locale.US);
            c = cm.getConverter(java.lang.Integer.TYPE);
            c.setNumberFormat(numberFormat);
            c = cm.getConverter(java.lang.Double.TYPE);
            c.setNumberFormat(numberFormat);
            c = cm.getConverter(java.lang.Float.TYPE);
            c.setNumberFormat(numberFormat);
            c = cm.getConverter(java.lang.Short.TYPE);
            c.setNumberFormat(numberFormat);
        end
        
        function clear(obj)
            obj.columnClasses = {};

            obj.callbackRowsCols = zeros(0,2);
            obj.callbackValues = {};
            obj.ignoreDataChangesFrom = zeros(0,2);
            obj.ignoreNextDataChange = false;

            obj.onDataChangedCallback = [];
            obj.onMouseClickedCallback = [];
            obj.onMouseReleasedCallback = [];
            obj.onRowSelectionChangedCallback = [];
            obj.onColumnSelectionChangedCallback = [];
            obj.onIndexChangedCallback = [];
            obj.onHeaderTextChangedCallback = [];
            obj.onColumnMovedCallback = [];

            obj.callbacksActive = true

            obj.rowObjects = [];
            obj.columnObjects = [];         
        end
        
        function setRowObjects(obj,o)
            obj.rowObjects = o;
        end
        
        function setColumnObjects(obj,o)
            obj.columnObjects = o;
        end
        
        function [r,actualR] = getRowObjectRow(obj,o)
            actualR = find(ismember(obj.rowObjects,o));
            r = obj.getRowsAt(actualR);
        end
        
        function [c,actualC] = getColumnObjectColumn(obj,o)
            actualC = find(ismember(obj.columnObjects,o));
            c = obj.getColumnsAt(actualC);
        end
        
        function o = getRowObjectsAt(obj,visR)
            idx = obj.getActualRowsAt(visR);
            o = obj.rowObjects(idx);
        end
        
        function o = getColumnObjectsAt(obj,visC)
            idx = obj.getActualColumnsAt(visC);
            o = obj.columnObjects(idx);
        end
        
        function setSortingEnabled(obj,state)
            obj.jTable.setSortingEnabled(state);
        end
        
        function setFilteringEnabled(obj,state)
            theader = obj.jTable.getTableHeader();
            theader.setAutoFilterEnabled(state);
            theader.setShowFilterName(state);
            theader.setShowFilterIcon(state);            
        end
        
        function setColumnReorderingAllowed(obj,state)
            obj.jTable.getTableHeader().setReorderingAllowed(state);
        end
        
        function setRowHeader(obj,header)
            if ~exist('header','var')
                rowNum = com.jidesoft.grid.TableModelWrapperUtils.getActualRowsAt(...
                    obj.jTable.getModel(),0:obj.getRowCount(),false);
                header = rowNum + 1;
            end
            for i = 1:numel(header)
                if iscell(header)
                    val = header{i};
                    if isnumeric(val)
                        val = num2str(val);
                    end                    
                else
                    val = num2str(header(i));
                end
                obj.jTable.setValueAt(val,i-1,0);
            end
            
            % fake row header (first column)
            cr0 = javax.swing.table.DefaultTableCellRenderer();
            cr0.setHorizontalAlignment(0) % 0 for CENTER, 2 for LEFT and 4 for RIGHT
            cr0.setBackground(java.awt.Color(15790320)); % grey backgroundt
            obj.jTable.getColumnModel.getColumn(0).setCellRenderer(cr0);
            obj.jTable.getColumnModel.getColumn(0).setResizable(false);
            obj.jTable.getColumnModel.getColumn(0).setMaxWidth(32);              
        end
        
% get actual row that corresponds to row in view
% com.jidesoft.grid.TableModelWrapperUtils.getActualRowAt(jtable.getModel,0)
% com.jidesoft.grid.TableModelWrapperUtils.getActualRowsAt(jtable.getModel,0:4,false)

% columns add/remove
% jtable.getColumnModel.addColumn(javax.swing.table.TableColumn)
% jtable.getColumnModel.removeColumn(jtable.getColumnModel.getColumn(3))

% rows add/remove
% jtable.getModel.getActualModel.getActualModel.addRow(1:3)
% jtable.getModel.getActualModel.getActualModel.removeRow(10)

        function n = getRowCount(obj)
            n = obj.jTable.getRowCount();
        end

        function n = getColumnCount(obj)
            n = obj.jTable.getColumnCount();
        end
        
%         function addColumn(obj,caption,type,editable,content,columnObject)
%             obj.setCallbacksActive(false);
%             if ~exist('content','var')
%                 content = cell(obj.getRowCount(),1);
%             end
%             c = javax.swing.table.TableColumn();
%             obj.baseModel.addColumn(caption,content);
%             n = obj.getColumnCount()-1;
%             obj.setColumnEditable(n,editable);
%             obj.setColumnClass(n,type);
%             c.setHeaderValue(caption);
%             obj.setRowHeader();
%             if exist('columnObject','var')
%                 obj.columnObjects = [obj.columnObjects, columnObject];
%             end
%             obj.setCallbacksActive(true);
%         end
%         
%         function removeColumn(obj,idx)
%             obj.setCallbacksActive(false);
%             if idx > 0
% %                 obj.jTable.removeColumn(...
% %                     obj.jTable.getColumnModel.getColumn(idx))
%                 idx = obj.getRowsAt(idx);
%                 obj.baseModel.removeColumn(idx);
%                 try
%                     obj.columnObjects(idx) = [];
%                 catch %
%                 end
%             end
%             obj.setCallbacksActive(true);
%             
%         end
        
        function addRow(obj)
            obj.baseModel.addRow(cell(1,obj.getColumnCount()));
            obj.setRowHeader();
        end
        
        function removeRow(obj,idx)
            obj.baseModel.removeRow(idx-1);
            obj.setRowHeader();
        end
        
        function setData(obj,data,header)
            obj.setCallbacksActive(false);
            obj.ignoreNextDataChange = true;
%             obj.jTable.setAutoCreateColumnsFromModel(true);
            
            data = cellfun(@str2char,data,'uni',false);  % <=2016b
            function s = str2char(s)
                if isstring(s)
                    s = char(s);
                end
            end

            data = [cell(size(data,1),1) data];
            header = [{' '} header];
            header = cellstr(header);  % <=2016b
            obj.baseModel.setDataVector(data,header);
            obj.setRowHeader();
            
            % fake row header (first column)
            cr0 = javax.swing.table.DefaultTableCellRenderer();
            cr0.setHorizontalAlignment(0) % 0 for CENTER, 2 for LEFT and 4 for RIGHT
            cr0.setBackground(java.awt.Color(15790320)); % grey backgroundt
            obj.jTable.getColumnModel.getColumn(0).setCellRenderer(cr0);
            obj.jTable.getColumnModel.getColumn(0).setResizable(false);
            obj.jTable.getColumnModel.getColumn(0).setMaxWidth(32);
            
%             obj.jTable.setAutoCreateColumnsFromModel(false);
            obj.setCallbacksActive(true);
        end
        
        function setValue(obj,value,row,column)
            if isstring(value)  % <=2016b
                value = char(value);
            end
            row = row - 1;
            obj.ignoreDataChangesFrom(end+1,:) = [row,column];
            obj.jTable.setValueAt(value,row,column);
        end
        
        function v = getValue(obj,row,column)
            row = row - 1;
            v = obj.jTable.getValueAt(row,column);
        end
        
        function setColumnEditable(obj,idx,state)
            obj.baseModel.setColumnEditable(idx,state);
        end
        
        function setColumnsEditable(obj,states)
            for i = 1:numel(states)
                obj.baseModel.setColumnEditable(i,states(i));
            end
        end
        
        function setColumnClass(obj,idx,type)
            if iscell(type) || (isstring(type) && ~isscalar(type))
                obj.jTable.getColumnModel().getColumn(idx).setCellEditor(...
                    com.jidesoft.grid.ListComboBoxCellEditor(type));
            elseif any(strcmp(type,{'clr','color'}))
                obj.jTable.getColumnModel().getColumn(idx).setCellRenderer(...
                    com.jidesoft.grid.ColorCellRenderer());
                obj.jTable.getColumnModel().getColumn(idx).setCellEditor(...
                    com.jidesoft.grid.ColorCellEditor());                
            else
                c = obj.getJavaClass(type);
                if ~isempty(c)
                    obj.baseModel.setColumnClass(idx,c);
                end
            end
        end
        
        function setColumnClasses(obj,types)
            for i = 1:numel(types)
                obj.setColumnClass(i,types{i});
            end            
        end
        
        function aRows = getActualRowsAt(obj,rows)
            rows = rows - 1;
            aRows = com.jidesoft.grid.TableModelWrapperUtils.getActualRowsAt(...
                obj.jTable.getModel(),rows,false);
            aRows = aRows + 1;
        end
        
        function aColumns = getActualColumnsAt(obj,columns)
            aColumns = com.jidesoft.grid.TableModelWrapperUtils.getActualColumnsAt(...
                obj.jTable.getModel(),columns,false);            
        end
        
        function rows = getRowsAt(obj,aRows)
            aRows = aRows - 1;
            rows = com.jidesoft.grid.TableModelWrapperUtils.getRowsAt(...
                obj.jTable.getModel(),aRows,false);
            rows = rows + 1;
        end
        
        function aColumns = getColumnsAt(obj,aColumns)
            aColumns = com.jidesoft.grid.TableModelWrapperUtils.getColumnsAt(...
                obj.jTable.getModel(),aColumns,false);            
        end
        
        function setCallbacksActive(obj,state)
            obj.callbacksActive = state;
            if state
                pause(0.05);
                obj.callbackRowsCols = zeros(0,2);
                obj.callbackValues = {};
                obj.ignoreDataChangesFrom = zeros(0,2);
                obj.ignoreNextDataChange = false;
            end
        end
        
        function indexChangedCallback(obj,varargin)
            if ~obj.callbacksActive
                return
            end
            if ~isempty(obj.onIndexChangedCallback)
                obj.onIndexChangedCallback();
            end
        end
        
        function mouseClickedCallback(obj,varargin)
            if ~obj.callbacksActive
                return
            end
            visR = obj.jTable.rowAtPoint(varargin{2}.getPoint()) + 1;
            visC = obj.jTable.columnAtPoint(varargin{2}.getPoint());
            actR = com.jidesoft.grid.TableModelWrapperUtils.getActualRowsAt(obj.jTable.getModel(),visR - 1,false) + 1;
            actC = com.jidesoft.grid.TableModelWrapperUtils.getActualColumnsAt(obj.jTable.getModel(),visC,false);
            if ~isempty(obj.onMouseClickedCallback)
                obj.onMouseClickedCallback([visR visC],[actR actC]);
            end
        end
        
        function mouseReleasedCallback(obj,varargin)
            if ~isempty(obj.onMouseReleasedCallback)
                obj.onMouseReleasedCallback();
            end
        end
        
        function rowSelectionChangedCallback(obj,~,event)
            if ~obj.callbacksActive
                return
            end
            if ~event.getValueIsAdjusting()
                fromRowVis = event.getLastIndex() + 1;
                toRowVis = event.getFirstIndex() + 1;
                actR = com.jidesoft.grid.TableModelWrapperUtils.getActualRowsAt(obj.jTable.getModel(),[fromRowVis,toRowVis],false) + 1;
                if ~isempty(obj.onRowSelectionChangedCallback)
                    obj.onRowSelectionChangedCallback([fromRowVis,toRowVis],actR);
                end
            end
        end
        
        function columnSelectionChangedCallback(obj,~,event)
            if ~obj.callbacksActive
                return
            end
            
            if ~event.getValueIsAdjusting()
                fromColumnVis = event.getLastIndex();
                toColumnVis = event.getFirstIndex();
                if fromColumnVis == obj.jTable.getSelectedColumn()
                    fromColumnVis = event.getFirstIndex();
                    toColumnVis = event.getLastIndex();
                end
                actC = com.jidesoft.grid.TableModelWrapperUtils.getActualColumnsAt(obj.jTable.getModel(),[fromColumnVis,toColumnVis],false);
                if ~isempty(obj.onColumnSelectionChangedCallback)
                    obj.onColumnSelectionChangedCallback([fromColumnVis,toColumnVis],actC);
                end
            end
        end
        
        function dataChangedCallback(obj,~,event)
            if ~obj.callbacksActive
                return
            end
            % Everytime the callback is called we start a single-shot timer
            % which calls the actual handling function after 10 ms. If the
            % callback is called again within in this timespan, the timer
            % is reset. This prevents many single calls, especially when
            % pasting many data, and, instead, allows for much better
            % vectorization in applyTableChanges.
            stop(obj.callbackTimer);
            start(obj.callbackTimer);
            obj.callbackRowsCols(end+1,1) = event.getFirstRow;
            obj.callbackRowsCols(end,2) = event.getColumn;
            obj.callbackValues{end+1} = obj.jTable.getValueAt(event.getFirstRow(),event.getColumn());
        end

        function applyTableChanges(obj,~,~)
            if ~obj.callbacksActive
                return
            end
            
            if obj.ignoreNextDataChange
                obj.callbackRowsCols = zeros(0,2);
                obj.callbackValues = {};
%                 obj.ignoreDataChangesFrom = zeros(0,2);
                obj.ignoreNextDataChange = false;
                
                if ~isempty(obj.ignoreDataChangesFrom)
                    match1 = ismember(obj.ignoreDataChangesFrom(:,1),obj.callbackRowsCols(:,1));
                    match2 = ismember(obj.ignoreDataChangesFrom(:,2),obj.callbackRowsCols(:,2));
                    obj.ignoreDataChangesFrom(match1&match2,:) = [];
                end
                
                return
            end
            
            rc = obj.callbackRowsCols;
            v = obj.callbackValues;

            if ~isempty(obj.ignoreDataChangesFrom)
                % check which events can be ignored because they were fired
                % by a programmatic setValueAt
                match1 = ismember(rc(:,1),obj.ignoreDataChangesFrom(:,1));
                match2 = ismember(rc(:,2),obj.ignoreDataChangesFrom(:,2));
                ignored = match1 & match2;
                
                % delete these from the ignore list
                match1 = ismember(obj.ignoreDataChangesFrom(:,1),rc(:,1));
                match2 = ismember(obj.ignoreDataChangesFrom(:,2),rc(:,2));
                obj.ignoreDataChangesFrom(match1&match2,:) = [];
                
                rc(ignored,:) = [];
                v(ignored) = [];
            end            
            
            % any event with a row or column number < 0 is invalid
            invalid = any(rc<0,2);
            rc(invalid,:) = [];
            v(invalid) = [];

            % reverse so that the latest changes are first found by unique
            rc = rc(end:-1:1,:);
            v = v(end:-1:1);
            [rc,idx] = unique(rc,'rows');
            v = v(idx);
            
            if ~isempty(v) && all(rc(:,1)>=0) && all(rc(:,2)>0)
                disp('data changed')
                if ~isempty(obj.onDataChangedCallback)
                    obj.onDataChangedCallback(rc + [1 0],v);
                end
            end
            
            obj.callbackRowsCols = zeros(0,2);
            obj.callbackValues = {};
%             obj.ignoreDataChangesFrom = zeros(0,2);
        end
        
        function headerTextChangedCallback(obj,varargin)
            if ~obj.callbacksActive
                return
            end
            s = strings(1,obj.getColumnCount()-1);
            for i = 1:obj.getColumnCount()-1
                s(i) = obj.jTable.getColumnModel().getColumn(i).getHeaderValue();
            end
            if ~isempty(obj.onHeaderTextChangedCallback)
                obj.onHeaderTextChangedCallback(s);
            end
        end
        
        function columnMovedCallback(obj,varargin)
            if ~obj.callbacksActive
                return
            end
            event = varargin{2};
            fromIndex = event.getFromIndex();
            toIndex = event.getToIndex();
            actC = obj.getActualColumnsAt([fromIndex,toIndex]);
            if fromIndex ~= toIndex
                if toIndex == 0
                    obj.jTable.moveColumn(0,1);
                    return
                elseif fromIndex == 0
                    return
                end
                if ~isempty(obj.onColumnMovedCallback)
                    obj.onColumnMovedCallback([fromIndex,toIndex],actC);
                end
            end
        end
    end
    
    methods(Static)
        function c = getJavaClass(type)
            switch(type)
                case {'int','integer','int32'}
                    c = java.lang.Integer.TYPE;
                case {'dbl','double'}
                    c = java.lang.Double.TYPE;
                case {'bool','boolean','logical'}
                    c = java.lang.Boolean.TYPE;
                otherwise
                    c = [];
            end
        end
    end
end