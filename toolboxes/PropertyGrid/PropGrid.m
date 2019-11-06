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

classdef PropGrid < handle
   
properties
    grid
    model
    pane
    container
       
    jPropList
    
    UIContextMenuProp
    UIContextMenuPane
    
    props = PropGridField.empty
    clickedProp = PropGridField.empty
    propertyChangeFcn = '';
    
    locked = false
    tableUtils
    
    onMouseClickedCallback = []
    onPropertyChangedCallback = []
end

events
    onGridClick
    onPaneClick
end

methods
    function obj = PropGrid(container)
        if exist('container','var')
            obj.container = container;
        else
            f = figure;
            obj.container = uipanel('Parent',f,'Units','normalized','Position',[0 0 1 1]);
            obj.container.Units = 'pixels';
%             obj.parent = figure;
        end
        
        % Initialize JIDE's usage within Matlab
        com.mathworks.mwswing.MJUtilities.initJIDE;
        
        % empty list
        obj.jPropList = java.util.ArrayList();
        
        % Prepare a properties table containing the list
        obj.model = javaObjectEDT('com.jidesoft.grid.PropertyTableModel',obj.jPropList);
%         model.expandAll();
        obj.grid = javaObjectEDT('com.jidesoft.grid.PropertyTable',obj.model);
        obj.pane = javaObjectEDT('com.jidesoft.grid.PropertyPane',obj.grid);
        
        obj.grid.putClientProperty('terminateEditOnFocusLost', true);
        
        % The editor which has focus was sometimes not updated (eg. staying
        % with the old list of options), even when the whole PropGrid was 
        % newly built. This fixes it.
        obj.grid.setAlwaysRequestFocusForEditor(true);

        % Display the properties pane onscreen
        p = obj.container.Position;
        [~,obj.container] = javacomponent(obj.pane, [0 0 p(3) p(4)], obj.container);
        obj.container.Units = 'normalized';
        
        hModel = handle(obj.model, 'CallbackProperties');
        set(hModel, 'PropertyChangeCallback', @(h,e)propertyChangeCallback(obj,h,e));
        hGrid = handle(obj.grid,'CallbackProperties');
        set(hGrid,'MouseClickedCallback',@(h,e)onMouseClick(obj,h,e))
        hPane = handle(obj.pane.getScrollPane(),'CallbackProperties');
        set(hPane,'MouseClickedCallback',@(h,e)onMouseClickPane(obj,h,e))        
%         obj.list = base.List();

        % provides handy features for tables (by JIDE)
        obj.tableUtils = javaObjectEDT('com.jidesoft.grid.TableUtils');
        
        % fix row heights for high-res displays
        dpi = java.awt.Toolkit.getDefaultToolkit().getScreenResolution();
        obj.grid.setRowHeight(obj.grid.getRowHeight()*dpi/72);
        
        %
        com.jidesoft.converter.ObjectConverterManager.initDefaultConverter();
        
        %
        obj.pane.setShowDescription(false);
        obj.pane.setShowToolBar(false);
        
        % boolean checkbox editor/renderer
        editor = com.jidesoft.grid.BooleanCheckBoxCellEditor();
        com.jidesoft.grid.CellEditorManager.registerEditor(javaclass('logical'), editor); 
        renderer = com.jidesoft.grid.BooleanCheckBoxCellRenderer();
        com.jidesoft.grid.CellRendererManager.registerRenderer(javaclass('logical'),renderer)
    end
    
    function onMouseClickPane(obj,h,e)
        disp('pane clicked')
        x = e.getX;
        y = e.getY;        
        if e.isMetaDown %Right-click
            tPos = getpixelposition(obj.container,true);
            mPos = [x+tPos(1) tPos(2)+tPos(4)-y+obj.pane.getScrollPane().getVerticalScrollBar().getValue()];
            set(obj.UIContextMenuPane,'Position',mPos,'Visible','on');
            notify(obj,'onPaneClick',EventData([],[],'rightclick'));
        else
            notify(obj,'onPaneClick',EventData([],[],'leftclick'));
        end
    end
    
    function onMouseClick(obj,h,e)
        % Get the position clicked
        x = e.getX;
        y = e.getY;
        r = obj.grid.rowAtPoint(e.getPoint());
        c = obj.grid.columnAtPoint(e.getPoint());
        
%         if obj.model.isCategoryRow(r)
%             return;
%         end
        
        p = obj.model.getPropertyAt(r);
        idx = arrayfun(@(x)eq(x,p),obj.props.getJProperty());
        prop = obj.props(idx);
        
        if isempty(prop)
            return
        end
        
        if ~isempty(prop.onMouseClickedCallback)
            prop.onMouseClickedCallback(prop);
        else
            if ~isempty(obj.onMouseClickedCallback)
                obj.onMouseClickedCallback(prop);
            end
        end
        
%         obj.clickedProp = obj.getPropertyByName(p.getFullName());

%         if c == 1 && ~isempty(obj.clickedProp.onClick)
%             obj.clickedProp.onClick();
%         end
%         obj.model.isCategoryRow(r)
        
        if e.isMetaDown %Right-click
%             c = uicontextmenu;
%             uimenu(c,'Label','test');
%             uimenu(c,'Label','test2');
            
%             fPos = obj.container.Position;
            tPos = getpixelposition(obj.container,true);
            mPos = [x+tPos(1) tPos(2)+tPos(4)-y+obj.pane.getScrollPane().getVerticalScrollBar().getValue()];
%             mousePos = java.awt.MouseInfo.getPointerInfo().getLocation()
%             screenHeight = java.awt.Toolkit.getDefaultToolkit().getScreenSize().getHeight();
%             mPos = [mousePos.x-fPos(1) mousePos.y];
            set(obj.UIContextMenuProp,'Position',mPos,'Visible','on');
%             notify(obj,'onGridClick',EventData([],obj.clickedProp,'rightclick'))
        else
            notify(obj,'onGridClick',EventData([],obj.clickedProp,'leftclick'))
        end
    end
    
    function setFontSize(obj, value)
        % get the current font
        jFont = obj.grid.getFont();
        
        % convert value from points to pixels
        dpi = java.awt.Toolkit.getDefaultToolkit.getScreenResolution();
        %value = round(value * dpi / 72);
        value = round(value * dpi / 96);
        
        % create a new Java font
        jFont = javax.swing.plaf.FontUIResource(jFont.getName(),...
            jFont.getStyle(), value);
        
        % set the font size (in pixels)
        obj.grid.setFont(jFont);
        obj.grid.setRowHeight(value*1.5);
    end % setFontSize
    
    function adjustRowHeights(obj)
        obj.expandAll();
        drawnow
        rowHeights = obj.tableUtils.autoResizeAllRows(obj.grid);
        for i = 1:numel(rowHeights)
            obj.grid.setRowHeight(i-1,rowHeights(i));
        end
        obj.applyDefaultFoldStates();
    end
    
    function addProperty(obj,prop)
        obj.props = [obj.props,prop];
        [prop.parentProp] = deal(obj);
        addList = java.util.ArrayList();
        jprops = prop.getJProperty();
        for i = 1:numel(prop)
            addList.add(jprops(i));
        end
        obj.jPropList.addAll(addList);
        
        if ~obj.locked
            prop.applyDefaultFoldState(obj);
            obj.model.reloadProperties();
            cat = obj.model.getCategories();
            for i = 1:numel(cat)
                cat(i).setExpanded(true)
            end
            obj.refresh();
        end
        
%         obj.generateShortName(prop);
%         obj.grid.getColumnModel().getSelectionModel().setSelection(0,0)
        
%         if obj.count() == 1
%             obj.model.expandAll();
%         end

    end
    
    function p = getSelectedProperty(obj)
        p = obj.grid.getSelectedProperty();
        try
            p = obj.getPropertyByName(p.getName());
        catch
            p = PropGridField.empty;
        end
    end
    
    function applyDefaultFoldStates(obj,prop)
        if ~exist('prop','var') || isempty(prop)
            prop = obj.getPropertiesAndChildren();
        end
        prop.applyDefaultFoldState(obj);  
    end
    
%     function replaceProperty(obj,oldProp,prop)
%         obj.addProperty(prop);
%         prop.moveAfter(prop,oldProp);
%         obj.removeProperty(oldProp);
%     end
    
    function lock(obj)
        obj.locked = true;
    end
    
    function unlock(obj)
        obj.locked = false;
        obj.model.reloadProperties(); 
        obj.adjustRowHeights();
        cat = obj.model.getCategories();
        for i = 1:numel(cat)
            cat(i).setExpanded(true)
        end
        obj.refresh();
    end

    function movePropertyDown(obj,prop)
        toMove = prop.jProperty;
        idx = obj.jPropList.indexOf(toMove);
        if (idx == -1) || (idx == obj.jPropList.size() - 1)
            return
        end
        obj.jPropList.set(idx, obj.jPropList.get(idx+1));
        obj.jPropList.set(idx+1, toMove);
        obj.model.reloadProperties();
    end
    
    function movePropertyUp(obj,prop)
        toMove = prop.jProperty;
        idx = obj.jPropList.indexOf(toMove);
        if idx <= 0
            return
        end
        obj.jPropList.set(idx, obj.jPropList.get(idx-1));
        obj.jPropList.set(idx-1, toMove);
        obj.model.reloadProperties();
    end    
    
    function removeProperty(obj,prop)
        pos = ismember(obj.props,prop);
        obj.props(pos) = [];
        obj.jPropList.remove(prop.getJProperty);
        obj.model.reloadProperties();
    end
    
    function clear(obj)
        obj.props = PropGridField.empty;
        obj.jPropList = java.util.ArrayList();
        obj.model.setOriginalProperties(obj.jPropList);
        obj.model.reloadProperties();
%         for e = obj.props
%             obj.removeProperty(e);
%         end
%         com.jidesoft.grid.CellEditorManager.unregisterAllEditors();
    end
    
    function prop = getProperty(obj,index)
        prop = obj.props(index);
    end
    
    function p = getPropertyByName(obj,shortName)
        if ~ischar(shortName)
            shortName = char(shortName);
        end
        s = strsplit(shortName,'.');
        p = obj.getPropertiesAndChildren().findByName(shortName);
%         for i = 2:numel(s)
% %             p = p.getChildren().findByName(strjoin(s(1:i),'.'));
%             p = p.getChildren().findByName(s{i});
%         end
    end
    
%     function p = getPropertyByDisplayName(obj,displayName)
%         if ~ischar(displayName)
%             displayName = char(displayName);
%         end
%         s = strsplit(displayName,'.');
%         p = obj.getProperties().findByName(s{1});
%         for i = 2:numel(s)
% %             p = p.getChildren().findByName(strjoin(s(1:i),'.'));
%             p = p.getChildren().findByName(s{i});
%         end
%     end    
    
    function p = getPropertyByTag(obj,tag,allowIncomplete)
        if ~exist('allowIncomplete','var') || isempty(allowIncomplete)
            allowIncomplete = false;
        end        
        p = obj.getPropertiesAndChildren().findByTag(tag,allowIncomplete);
    end

    function props = getProperties(obj)
        props = obj.props;
    end
    
    function setPropertyChangeFcn(obj,propChangeFcnHandle)
        obj.propertyChangeFcn = propChangeFcnHandle;
    end
    
    function grid = getGrid(obj)
        grid = obj.grid;
    end
    
    function expandAll(obj)
        obj.model.expandAll();
    end
    
    function setShowDescription(obj,boolVal)
        obj.pane.setShowDescription(boolVal);
    end
    
    function setShowToolbar(obj,boolVal)
        obj.pane.setShowToolBar(boolVal);
    end

    function setOrder(obj,val)
        obj.pane.setOrder(val);
    end    
    
    function propertyChangeCallback(obj,~,e)
        e.getNewValue()
        class(e.getNewValue())
        shortName = char(e.getPropertyName());
        
        prop = obj.getPropertyByName(shortName);
%         jProp = obj.model.getProperty(shortName);
%         newVal = prop.castToType(e.getNewValue());
        oldVal = prop.getValue();
        prop.setValue(e.getNewValue());
        
        obj.getPropertiesAndChildren().checkShowCondition();

        param = prop.getMatlabObj();
        if ~isempty(param) && isa(param,'Parameter')
            param.setValue(prop.getValue());
            prop.setValue(param.getValueCaptions()); % in case the Parameter rejects or changes the set value
        end
        
        if ~isempty(obj.propertyChangeFcn)
            obj.propertyChangeFcn(prop,oldVal);
        elseif isa(prop.setFcn,'function_handle')
            prop.setFcn(oldVal);
        end        
        
        if ~isempty(prop.onChangedCallback)
            prop.onChangedCallback();
        end
        if ~isempty(param.onChangedCallback)
            param.onChangedCallback();
        end
        
        if ~isempty(obj.onPropertyChangedCallback)
            obj.onPropertyChangedCallback(prop,param);
        end

        obj.model.refresh();  % refresh value onscreen
    end
    
    function propOut = getPropertiesAndChildren(obj,props)
        propOut = PropGridField.empty;
        if ~exist('props','var')
            props = obj.getProperties();
        end
        for i = 1:numel(props)
            propOut = [propOut props(i) obj.getPropertiesAndChildren(props(i).getChildren())];
        end
    end
    
    function refresh(obj)
        obj.model.refresh();
    end
    
    function generateShortName(obj,propArray)
        
%         if ~exist('propArray','var')
%             propArray = obj.getPropertiesAndChildren();
%             shortNames = regexprep({propArray.displayName},'[^\w'']','');
%             shortNames = matlab.lang.makeUniqueStrings(shortNames);
%         else
%             existingProps = obj.getPropertiesAndChildren();
%             exclude = {existingProps.shortName};
%             shortNames = regexprep({propArray.displayName},'[^\w'']','');
%             shortNames = matlab.lang.makeUniqueStrings(shortNames,exclude); 
%         end
        
        for i = 1:numel(propArray)
%             propArray(i).setShortName(shortNames{i});
            propArray(i).setShortName(propArray(i).jProperty.getFullName())
        end
        % TODO
%         propArray.generateChildrenShortName();
        
%         propArray = obj.getPropertiesAndChildren();
%         shortNames = regexprep({propArray.displayName},'[^\w'']','');
%         shortNames = matlab.lang.makeUniqueStrings(shortNames,exclude);
%         for i = 1:numel(propArray)
%             propArray(i).setShortName(shortNames{i});
%         end
%         
%         for i = 1:numel(propArray)
%             prop = propArray(i);
%             shortName = regexprep(prop.displayName,'[^\w'']','');
% %             if ~isempty(prop.parentProp)
% %                 shortName = strcat(prop.parentProp.getShortName(),'.',shortName);
% %             end
%             exclude = propArray.getShortName();
%             if ~isempty(exclude)
%                 shortName = matlab.lang.makeUniqueStrings(shortName,exclude);
%             end
%             prop.setShortName(shortName);
%             
% %             if prop.hasChildren()
% %                 obj.generateShortName(prop.getChildren());
% %             end
%         end
    end    
end

end