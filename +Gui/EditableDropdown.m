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

classdef EditableDropdown < handle
    
properties
    parent
    jCombo
    mdl
    appendBtn
    removeBtn
    items = {}
    selectedIndex = 0
    AppendClickCallback
    RemoveClickCallback
    EditCallback
    SelectionChangedCallback
    callbacksActive = true
end

events
    onItemEdit
    onSelectionChange
    onItemAppend
    onItemRemove
end

methods
    function obj = EditableDropdown(parent,items)
        if ~exist('parent','var')
            parent = figure;
        end        
        if ~exist('items','var')
            items = {''};
        end
        obj.init(parent,items);
    end
    
    function layout = init(obj,parent,items)
        if ~exist('items','var')
            items = {'abc','b'};
        end
        layout = uiextras.HBox('Parent',parent, ...
            'Padding',0, 'Spacing',0);         
        
        obj.mdl = javaObjectEDT(javax.swing.DefaultComboBoxModel(items));
        combo = javax.swing.JComboBox(obj.mdl);
        combo.setEditable(1);
        p = uipanel('Parent',layout);
        pos = p.Position;
        [obj.jCombo,h.jComboContainer] = javacomponent(combo, [0 0 pos(3) pos(4)], p);
        set(h.jComboContainer,'Units','normalized');
        
        % selection changed
        c = handle(obj.jCombo,'CallbackProperties');
        c.ItemStateChangedCallback = @(h,e)dropdownSelectionChanged(obj,h,e);
        
        % item text was edited
        c = handle(obj.jCombo.getEditor(),'CallbackProperties');
        c.ActionPerformedCallback = @(h,e)dropdownItemCaptionChanged(obj,h,e);
        
        obj.appendBtn = uicontrol('Parent',layout,...
            'Style','pushbutton',...
            'String','+',...
            'Callback',@(h,e)obj.appendButtonCallback());
        obj.removeBtn = uicontrol('Parent',layout,...
            'Style','pushbutton',...
            'String','-',...
            'Callback',@(h,e)obj.removeButtonCallback());
        
        set(layout, 'Sizes',[-1,27,27]);
        
        obj.selectedIndex = 1;
    end
    
    function appendButtonCallback(obj)
%         obj.appendItem('xgs');
        if ~isempty(obj.AppendClickCallback)
            obj.AppendClickCallback(obj);
        end
    end
    
    function removeButtonCallback(obj)
%         obj.mdl.removeAllElements();
        if ~isempty(obj.RemoveClickCallback)
            obj.RemoveClickCallback(obj);
        end        
    end
    
    function renameItemAt(obj,newName,idx)
        obj.insertItemAt(newName,idx);
        obj.removeItemAt(idx+1);
    end
    
    function setItems(obj,items)
        obj.mdl = javax.swing.DefaultComboBoxModel(cellstr(items));
        obj.jCombo.setModel(obj.mdl);
    end
    
    function item = getSelectedItem(obj)
        item = obj.mdl.getSelectedItem();
    end
    
    function idx = getIndexOf(obj,item)
        idx = obj.mdl.getIndexOf(item);
    end

    function dropdownItemCaptionChanged(obj,~,e)
        newValue = char(e.getActionCommand());
        obj.renameItemAt(newValue,obj.selectedIndex);
        if ~isempty(obj.EditCallback) && obj.callbacksActive
            obj.EditCallback(obj,newValue,obj.selectedIndex);
        end
    end
    
    function dropdownSelectionChanged(obj,~,e)
        if e.getStateChange() == 2 % DESELECTED
            return;
        end
        
        newItem = obj.getSelectedItem();
        obj.selectedIndex = obj.getSelectedIndex();
        if ~isempty(obj.SelectionChangedCallback) && obj.callbacksActive
            obj.SelectionChangedCallback(obj,newItem,obj.selectedIndex);
        end        
    end
    
    function insertItemAt(obj,item,idx)
        obj.mdl.insertElementAt(char(item),idx-1);
    end
    
    function appendItem(obj,item)
        obj.mdl.addElement(char(item));
    end
    
    function removeItem(obj,item)
        obj.mdl.removeElement(char(item));
    end
    
    function removeItemAt(obj,idx)
        obj.mdl.removeElementAt(idx-1);
    end
    
    function idx = getSelectedIndex(obj)
        idx = obj.mdl.getIndexOf(obj.getSelectedItem()) + 1; 
    end
    
    function setSelectedIndex(obj,index)
        obj.mdl.setSelectedItem(obj.mdl.getElementAt(index-1));
    end
    
    function setSelectedItem(obj,item)
        obj.mdl.setSelectedItem(char(item));
    end
    
    function selectLastItem(obj)
        obj.setSelectedIndex(obj.mdl.getSize());
    end
    
    function selectFirstItem(obj)
        obj.setSelectedIndex(1);
    end
    
    function setCallbacksActive(obj,state)
        drawnow;
        obj.callbacksActive = state;
    end
end
    
end

