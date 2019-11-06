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

classdef PropGridField < Descriptions

properties
    shortName = ''
    value
    enum
    type
    selectionType
    displayName
    category
    editable
    visible
    onClick
    defaultFoldState
    
    jProperty
    mObject
    parameter
    getFcn
    setFcn
    showCondition
    
    parentProp
    childrenProp
    
    context_
    
    onMouseClickedCallback = []
    onChangedCallback = []
end

methods
    function obj = PropGridField(displayName,value,varargin)
        
        obj@Descriptions();
        
        if nargin == 0
            return
        end
        
        if ~exist('displayName','var')
            % empty object
            return
        end
        
        p = inputParser;
        defaultType = '';
        expectedTypes = {'char','double','int32','logical',...
            'clickable','color','tristate','?'};
        defaultSelectionType = 'single';
        expectedSelectionTypes = {'single','multiple'};
        defaultCategory = [];
        defaultEnum = {};
        defaultDescription = [];
        defaultEditable = true;
        defaultVisible = true;
        defaultOnClick = [];
        defaultFoldState = 'expanded';
        validFoldStates = {'expanded','collapsed'};
        defaultUserData = [];
        defaultTag = '';
        
        addRequired(p,'DisplayName',@ischar);
        addRequired(p,'Value');
        addParameter(p,'Type',defaultType,...
            @(x) any(validatestring(x,expectedTypes)));
        addParameter(p,'SelectionType',defaultSelectionType);
        addParameter(p,'Category',defaultCategory);
        addParameter(p,'Enum',defaultEnum);
        addParameter(p,'Description',defaultDescription);
        addParameter(p,'Editable',defaultEditable);
        addParameter(p,'Visible',defaultVisible);
        addParameter(p,'onClick',defaultOnClick);
        addParameter(p,'DefaultFoldState',defaultFoldState,...
            @(x) any(validatestring(x,validFoldStates)));
        addParameter(p,'UserData',defaultUserData);
        addParameter(p,'Tag',defaultTag);
        
        parse(p,displayName,value,varargin{:});
        
        if isempty(p.Results.Type) || strcmp(p.Results.Type,'?')
            [obj.type, obj.selectionType] = obj.autoDiscover(p.Results.Value, p.Results.Enum);
        else
            obj.type = p.Results.Type;
        end
        if isempty(obj.selectionType)
            obj.selectionType = p.Results.SelectionType;
        end
        
        obj.setDisplayName(p.Results.DisplayName);
        obj.value = obj.castToType(p.Results.Value);
%         obj.type = p.Results.Type;
        obj.category = p.Results.Category;
        obj.enum = p.Results.Enum;
        obj.description = char(p.Results.Description);
        obj.editable = p.Results.Editable;
        obj.visible = p.Results.Visible;
        obj.onClick = p.Results.onClick;
        obj.defaultFoldState = p.Results.DefaultFoldState;
        obj.userData = p.Results.UserData;
        obj.tag = p.Results.Tag;
        
        obj.parentProp = [];%PropGridField.empty;
        
        obj.childrenProp = PropGridField.empty;
        
        obj.updateJProperty();
    end
    
%     function tag = getTag(objArray)
%         tag = {objArray.tag};
%     end
    
    function p = getHighestParent(obj)
        p = obj;
        if isempty(obj)
            return
        end
        while true
            if isempty(p.parentProp) || isa(p.parentProp,'PropGrid')
                return
            else
                p = obj.parentProp.getHighestParent();
            end
        end
    end

    function p = getParent(obj)
        p = obj.parentProp;
    end
    
    function userData = getUserData(objArray)
        userData = [objArray.userData];
    end
    
    function jProp = getJProperty(objArray)
        jProp = [objArray.jProperty];
    end

    function mObj = getMatlabObj(obj)
        mObj = obj.mObject;
    end
    
    function setMatlabObj(obj,mObj)
        obj.mObject = mObj;
    end    
    
    function setParameter(obj,prm)
        obj.parameter = prm;
    end
    
%     function shortName = getShortName(obj)
%         shortName = {obj.shortName};
%         if isscalar(obj)
%             shortName = shortName{1};
%         end
%     end
% 
%     function setShortName(obj,shortName)
%         obj.shortName = shortName;
%         obj.jProperty.setName(shortName);
%     end
    
    function setCategory(objArray,category)
        for i = 1:numel(objArray)
            objArray(i).category = category;
            objArray(i).jProperty.setCategory(category);    
        end
    end
    
    function displayName = getDisplayName(obj)
        displayName = {obj.displayName};
        if isscalar(obj)
            displayName = displayName{1};
        end
    end    
    
    function setDisplayName(objArray,displayName)
        for i = 1:numel(objArray)
            objArray(i).displayName = displayName;
%             objArray(i).jProperty.setDisplayName(displayName);
            
        end
    end
    
    function val = hasChildren(obj)
        val = false;
        if count(obj.childrenProp) > 0
            val = true;
        end
    end
    
    function val = castToType(obj,val)
        switch obj.type
            case 'double'
                val = double(val);
            case 'int32'
                val = int32(val);
            case 'logical'
                val = logical(val);
            case 'char'
                if obj.isMultiSelection()
                    val = cell(val);
                else
                    val = char(val);
                end
            case 'color'
                %
            otherwise
                val = val;
                warning('Type was not casted.');
        end
    end
    
    function setValue(obj,val)
%         if strcmp(obj.type,'list')
%             if isa(val,'class.datatype.SingleChoiceArray')
%                 obj.value = val;
%                 obj.jProperty.setValue(val.getElement());
%             else
%                 obj.value.setChoice(val);
%                 obj.jProperty.setValue(val);
%             end
%         elseif strcmp(obj.type,'checkboxList')
%             if isa(val,'class.datatype.MultipleChoiceArray')
%                 obj.value = val;
%                 obj.jProperty.setValue(val.getElement());
%             else
%                 obj.value.setChoice(val);
%                 obj.jProperty.setValue(val);
%             end
        val = obj.castToType(val);

        if strcmp(obj.type,'class.datatype.CheckboxTree')
            obj.value = val;
            obj.jProperty.setValue(val.getSelectedPaths());
        elseif strcmp(obj.type,'color')
            try
                obj.value = double(val.getRGBColorComponents([1 1 1]))';
                obj.jProperty.setValue(val);
            catch
                if isempty(val) || all(isnan(val))
                    obj.value = nan(1,3);
                    obj.jProperty.setValue([]);
                elseif numel(val) == 3
                    obj.value = val;
                    obj.jProperty.setValue(java.awt.Color(val(1),val(2),val(3)));
                end
            end
%             obj.jProperty.setValue
        else
            obj.value = val;
            obj.jProperty.setValue(val);
        end
    end
    
    function val = getValue(objArray)
        val = [objArray.value];
    end
    
    function val = getString(obj)
        val = char(obj.getJProperty.getValue());
    end
    
    function val = getSelection(obj)
        if isa(obj.value,'class.datatype.SingleChoiceArray') || isa(obj.value,'class.datatype.MultipleChoiceArray')
            val = obj.value.getChoice();
        else
            val = true;
        end
    end
    
    function childProps = getChildren(obj)
        childProps = obj.childrenProp;
    end
    
    function addChild(obj,prop)
        if isempty(prop)
            return;
        end
        
        obj.generateChildrenShortName(prop);
        for p = prop
            obj.jProperty.addChild(p.getJProperty());
        end
        
        obj.childrenProp(end+1) = prop;
        [prop.parentProp] = deal(obj);
        
        prop.applyDefaultFoldState();
    end
    
    function applyDefaultFoldState(objArray,propGrid)
        for i = 1:numel(objArray)
            if strcmp(objArray(i).defaultFoldState,'expanded')
                objArray(i).getJProperty().setExpanded(true);
            else
                objArray(i).getJProperty().setExpanded(false);
            end
        end
        if ~exist('propGrid','var') || isempty(propGrid) || ~isa(propGrid,'PropGrid')
            propGrid = PropGrid.empty;
            for i = objArray
                propGrid = i.getPropGrid();
                if isa(propGrid,'PropGrid') && ~isempty(propGrid)
                    break;
                end
            end
        end
        if ~isempty(propGrid) && ~propGrid.locked
            propGrid.refresh();
        end
    end    
    
    function obj = getPropGrid(obj)
        while ~isa(obj,'PropGrid')
            try
                o = obj.parentProp;
%                 if isempty(o)
%                     o = obj.getParent();
%                 end
                obj = o;
            catch
%                 obj = obj.getParent();
            end
            if isempty(obj) || (isa(obj,'class.datatype.List') && obj.null)
                obj = PropGrid.empty;
                return
            end
        end
    end
    
    function setShowCondition(objArray,val1,operator,val2)
        for i = 1:numel(objArray)
            obj = objArray(i);
            obj.showCondition.val1 = val1;
            obj.showCondition.val2 = val2;
            obj.showCondition.operator = operator;
        end
        objArray.checkShowCondition();
    end
    
    function val = castStringToType(obj,val)
        if strcmp(obj.type,'char') && strcmp(obj.selectionType,'multiple')
            
        end
        switch obj.type
            case 'char'
%                 val = char(val);
                val = num2str(val);
            case 'double'
                val = str2double(val);
            case 'int32'
                val = int32(str2double(val));             
            case 'logical'
                val = logical(val);
            case 'list'
                %
            case 'checkboxList'
                val = cell(val);
%             case 'checkboxTree'
%                 multChoiceTree = copy(obj.getValue());
%                 multChoiceTree.selectPath(val);
%                 val = multChoiceTree;
%             case 'clickable'
% %                 val = char(val);
%                 val = num2str(val);
            case 'color'
%                 val = double(val.getRGBColorComponents([1 1 1]))';
        end
    end

    function prop = findByName(objArray,fullName)
        if ~ischar(fullName)
            fullName = char(fullName);
        end
        for i = 1:numel(objArray)
            prop = objArray(i);
            fn = char(prop.jProperty.getFullName());
            if strcmp(fullName,fn)
                return
            end
        end
%         shortNames = {objArray.shortName};
%         prop = objArray(strcmp(shortNames,fullName));
    end
    
    function prop = findByDisplayName(objArray,displayName)
        displayNames = {objArray.displayName};
        prop = objArray(strcmp(displayNames,displayName));
    end    
    
    function prop = findByTag(objArray,tag,allowIncomplete)
        tags = {objArray.tag};
        if ~exist('allowIncomplete','var') || isempty(allowIncomplete)
            allowIncomplete = false;
        end
        if allowIncomplete
            prop = objArray(strncmp(tags,tag,length(tag)));
        else
            prop = objArray(strcmp(tags,tag));
        end
    end       
    
    function checkShowCondition(objArray)
        for i = 1:numel(objArray)
            obj = objArray(i);
            
            if isempty(obj.showCondition)
                continue;
            end

            val1 = obj.showCondition.val1;
            val2 = obj.showCondition.val2;
            operator = obj.showCondition.operator;

            if isa(val1,'function_handle')
                val1 = val1();
            end
            if isa(val2,'function_handle')
                val2 = val2();
            end

            if ischar(val1) && ischar(val2)
                strCmp = true;
            elseif ischar(val1) && iscell(val2) && ischar(val2{1})
                strCmp = true;
            else
                strCmp = false;
            end

            switch operator
                case '=='
                    if strCmp
                        vis = strcmp(val1,val2);
                    else
                        vis = val1 == val2;
                    end
                case '~='
                    if strCmp
                        vis = ~strcmp(val1,val2);
                    else
                        vis = ~(val1 == val2);
                    end
                case '<'
                    vis = val1 < val2;
                case '<='
                    vis = val1 <= val2;
                case '>'
                    vis = val1 > val2;
                case '>='
                    vis = val1 >= val2;
            end

            obj.setVisible(any(vis));
        end
    end
    
    function setVisible(obj,boolVal)
        obj.visible = boolVal;
        vis = java.lang.Boolean(~obj.visible);
        obj.jProperty.setHidden(vis.booleanValue);        
    end
    
    function update(obj)
        obj.updateJProperty();
        obj.getPropGrid().model.reloadProperties();
        obj.getPropGrid().model.refresh();
    end
    
    function generateChildrenShortName(objArray,propArray)
        return
        
        for i = 1:numel(objArray)
            obj = objArray(i);
            if ~exist('propArray','var')
                propArray = obj.getChildren();
                shortNames = regexprep({propArray.displayName},'[^\w'']','');
                shortNames = matlab.lang.makeUniqueStrings(shortNames);
            else
                existingProps = obj.getChildren();
                exclude = {existingProps.shortName};
                shortNames = regexprep({propArray.displayName},'[^\w'']','');
                shortNames = matlab.lang.makeUniqueStrings(shortNames,exclude); 
            end

            for j = 1:numel(propArray)
                propArray(j).setShortName(shortNames{j});
            end
            propArray.generateChildrenShortName();
        end
    end
    
    function val = isMultiSelection(obj)
        val = strcmp(obj.selectionType,'multiple');
    end
    
    function javaType = getElementJavaClass(obj)
        if strcmp(obj.type,'char')
            javaType = javaclass('char', 1);
        else
            javaType = javaclass(obj.type);
        end        
    end
    
    function javaType = getArrayJavaClass(obj)
        if strcmp(obj.type,'char')
            javaType = javaclass('cellstr', 1);
        else
            javaType = javaclass(obj.type,1);
        end        
    end
end 

methods (Access = private)    
    function updateJProperty(obj)
%         persistent uniqueCounter
%         if isempty(uniqueCounter)
%             uniqueCounter = 0;
%         else
%             uniqueCounter = uniqueCounter + 1;
%         end
        
        uniqueCounter = char(java.util.UUID.randomUUID);

        if isempty(obj.jProperty)
            obj.jProperty = javaObjectEDT('com.jidesoft.grid.DefaultProperty');
        end
        obj.jProperty.setName([obj.displayName uniqueCounter]);
        obj.shortName = char(obj.jProperty.getName());
        obj.jProperty.setCategory(obj.category);
        obj.jProperty.setDisplayName(obj.displayName);
        obj.jProperty.setDescription(obj.description);
        edit = java.lang.Boolean(obj.editable);
        obj.jProperty.setEditable(edit.booleanValue);
        vis = java.lang.Boolean(obj.visible);
        obj.jProperty.setHidden(~vis.booleanValue);
        obj.checkShowCondition();
        
        context = [];
        
        if numel(obj.enum) > 0   % has a list of options
            javaType = obj.getArrayJavaClass();
            
            options = obj.enum;
            switch obj.type
                case 'double'
                    jArray = javaArray('java.lang.Double',numel(options));
                    for i = 1:numel(options)
                        jArray(i) = java.lang.Double(options(i));
                    end
                case 'int32'
                    jArray = javaArray('java.lang.Integer',numel(options));
                    for i = 1:numel(options)
                        jArray(i) = java.lang.Integer(options(i));
                    end
                case 'logical'
                    jArray = javaArray('java.lang.Boolean',numel(options));
                    for i = 1:numel(options)
                        jArray(i) = java.lang.Boolean(options(i));
                    end
                case 'char'
                    jArray = javaStringArray(options);
            end
            if obj.isMultiSelection()
                editor = com.jidesoft.grid.CheckBoxListComboBoxCellEditor(jArray,javaType);
                context = com.jidesoft.grid.EditorContext(['checkboxlistcomboboxeditor' (uniqueCounter)]);
                obj.jProperty.setEditorContext(context);
                com.jidesoft.grid.CellEditorManager.registerEditor(javaType, editor, context);
                ccontext = com.jidesoft.converter.ConverterContext(['checkboxlistcomboboxconverter' (uniqueCounter)]);
                editor.setConverterContext(ccontext);
                com.jidesoft.converter.ObjectConverterManager.registerConverter(javaType,com.jidesoft.converter.DefaultArrayConverter(';',obj.getElementJavaClass()));
            else
                editor = com.jidesoft.grid.ListComboBoxCellEditor(options);
                context = com.jidesoft.grid.EditorContext(['comboboxeditor' (uniqueCounter)]);
                obj.jProperty.setEditorContext(context);
                com.jidesoft.grid.CellEditorManager.registerEditor(javaType, editor, context);                
            end
            
        else   % or is only one free value
            javaType = obj.getElementJavaClass();
        end
        obj.jProperty.setType(javaType);
        obj.jProperty.setValue(obj.value);
        return
        
        switch obj.type
            case 'char'
                if ~obj.isMultiSelection()
                    obj.jProperty.setType(javaclass('char',1));
                    obj.jProperty.setValue(obj.value);
                else
                    
                end
            case 'double'
                obj.jProperty.setType(javaclass('double'));
                obj.jProperty.setValue(double(obj.value));
            case 'int32'
                obj.jProperty.setType(javaclass('int32'));
                obj.jProperty.setValue(int32(obj.value));
            case 'logical'
                javaType = javaclass('logical');
                obj.jProperty.setType(javaType);
                editor = com.jidesoft.grid.BooleanCheckBoxCellEditor();
                context = com.jidesoft.grid.BooleanCheckBoxCellEditor.CONTEXT;
                obj.jProperty.setEditorContext(context);
                com.jidesoft.grid.CellEditorManager.registerEditor(javaclass('logical'), editor, context);
%                 obj.jProperty.setEditorContext(com.jidesoft.grid.BooleanCheckBoxCellEditor.CONTEXT);
                obj.jProperty.setValue(logical(obj.value));
%             case 'tristate'
%                 javaType = javaclass('int32');
%                 obj.jProperty.setType(javaType);
%                 editor = com.jidesoft.grid.TristateCheckBoxCellEditor();
%                 context = com.jidesoft.grid.EditorContext(['booleancheckbox2' (uniqueCounter)]);
%                 obj.jProperty.setEditorContext(context);
%                 com.jidesoft.grid.CellEditorManager.registerEditor(javaclass('int32'), editor, context);
% %                 obj.jProperty.setEditorContext(com.jidesoft.grid.TristateCheckBoxCellEditor.CONTEXT);
%                 obj.jProperty.setValue(int32(obj.value));                
            case 'list'
                javaType = javaclass('char', 1);
                obj.jProperty.setType(javaType);
                options = obj.enum;
                editor = com.jidesoft.grid.ListComboBoxCellEditor(options);
                context = com.jidesoft.grid.EditorContext(['comboboxeditor' (uniqueCounter)]);
                obj.jProperty.setEditorContext(context);
                com.jidesoft.grid.CellEditorManager.registerEditor(javaType, editor, context);
                obj.jProperty.setValue(obj.value);
            case 'checkboxList'
%                 javaType = javaclass('cellstr', 1);
javaType = javaclass('int32', 1);
                obj.jProperty.setType(javaType);
                options = obj.enum;
                if ischar(obj.enum{1})
                    javaA = javaStringArray(options);
                else
                    %javaA = cell2mat(options)';
                    javaA = javaArray('java.lang.Integer',numel(options));
                    for i = 1:numel(options)
                        javaA(i) = java.lang.Integer(options{i});
                    end
                end
                %oldEditor = com.jidesoft.grid.CellEditorManager.getEditor(javaType,obj.jProperty.getEditorContext())
%                 com.jidesoft.grid.CellEditorManager.unregisterEditor(javaType, obj.context_);
                editor = com.jidesoft.grid.CheckBoxListComboBoxCellEditor(javaA,javaType); %javaType
%                 editor.setComboBoxType(javaType);
                context = com.jidesoft.grid.EditorContext(['checkboxlistcomboboxeditor' (uniqueCounter)]);
%                 com.jidesoft.grid.CellEditorManager.registerEditor(javaType, editor, context);
                obj.jProperty.setEditorContext(context);
                com.jidesoft.grid.CellEditorManager.registerEditor(javaType, editor, context);
                
                
%                 ccontext = com.jidesoft.converter.ConverterContext(['checkboxlistcomboboxconverter' (uniqueCounter)]);
%                 editor.setConverterContext(ccontext);
%                 editor.setType(javaclass('int32',1));
%                 editor.setConverter(com.jidesoft.converter.IntegerConverter());
%                 com.jidesoft.converter.ObjectConverterManager.registerConverter(javaclass('int32'),com.jidesoft.converter.IntegerConverter);
                com.jidesoft.converter.ObjectConverterManager.registerConverter(javaType,com.jidesoft.converter.DefaultArrayConverter(';',javaclass('int32')));
                
                val = obj.value;
                if isempty(val)
                    val = {''};
                end
                obj.jProperty.setValue(javaA(1));
                a=2;
%                 obj.jProperty.setValue(val);
            case 'checkboxTree'
                javaType = javaclass('cellstr', 1);
                obj.jProperty.setType(javaType);
                editor = com.jidesoft.grid.CheckBoxTreeComboBoxCellEditor(obj.value.getJTreeModel());
                context = com.jidesoft.grid.EditorContext(['checkboxtreecomboboxeditor' (uniqueCounter)]);
                obj.jProperty.setEditorContext(context);
                com.jidesoft.grid.CellEditorManager.registerEditor(javaType, editor, context);
            case 'clickable'
                javaType = javaclass('char', 1);
                obj.jProperty.setType(javaType);
                editor = javaObjectEDT(com.jidesoft.grid.StringCellEditor);
                editor.setClickCountToStart(intmax);             
                renderer = javaObjectEDT(com.jidesoft.grid.PropertyTableCellRenderer);
%                 renderer.setFont(renderer.getFont().deriveFont(java.awt.Font.BOLD));
%                 renderer.getTableCellRendererComponent().setCursor(java.awt.Cursor(java.awt.Cursor.HAND_CURSOR));
                context = com.jidesoft.grid.EditorContext(['clickableeditor' (uniqueCounter)]);
                obj.jProperty.setEditorContext(context);
                com.jidesoft.grid.CellEditorManager.registerEditor(javaType, editor, context);
                obj.jProperty.setTableCellRenderer(renderer);
                obj.jProperty.setValue(['<html><b><u>' obj.value '</u></b></html>']);
%                 obj.jProperty.isPreferred();
            case 'color'
                javaType = javaclass('color',0);
                obj.jProperty.setType(javaType);
                editor = javaObjectEDT(com.jidesoft.grid.ColorCellEditor);
                renderer = javaObjectEDT(com.jidesoft.grid.ColorCellRenderer);
                context = com.jidesoft.grid.EditorContext(['coloreditor' (uniqueCounter)]);
                obj.jProperty.setEditorContext(context);
                com.jidesoft.grid.CellEditorManager.registerEditor(javaType, editor, context);
                obj.jProperty.setTableCellRenderer(renderer);
                obj.setValue(obj.value);
        end
        obj.context_ = context;
    end
    
end


methods (Static)
    function obj = makeFromObject(mObj,displayName,getFcn,setFcn)
        obj = PropGridField(displayName,getFcn());
        obj.mObject = mObj;
        obj.getFcn = getFcn;
        obj.setFcn = setFcn;
    end
    
    function [type, selType] = autoDiscover(value,enum)
        if numel(value) == 3 && isa(value,'double')
            type = 'color';
            error('Not supported.');
            return;
        end
        
        selType = '';
        switch class(value)
            case {'char','double','int32','logical'}
                type = class(value);
            case 'cell'
                type = 'char';
                selType = 'multiple';
%             case 'class.datatype.MultipleChoiceTree'
%                 type = 'class.datatype.CheckboxTree';
            otherwise
                error('Could not determine type.')
        end
    end
end
    
end