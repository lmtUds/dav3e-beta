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

function [Selection,ExitStatus,ListItems] = Select(varargin)
%SELECT Display a list of multiple, selectable items in a modal uiFigure
%   In addition to displaying the list, allows adding custom options to the list.

%internal variables
allowAdd = 0;
baseCharHeight = 22;
cancelStr  = 'Cancel';
initialSelect = 1;
message = '';
multiSelect = 1;
name = 'Select from List';
okStr  = 'Ok';

%return variables
ExitStatus = 0;
ListItems = {};
Selection = 1;

if mod(length(varargin),2) ~= 0
    error('Selection dialog arguments must be pairs.')
end
%loop through arguments and set the corresponding variables
for i = 1:2:length(varargin)
    switch varargin{i}
        case 'AllowAdd'
            allowAdd = varargin{i+1};
        case 'CancelStr'
            cancelStr = varargin{i+1};
        case 'InitialSelect'
            initialSelect = varargin{i+1};
        case 'ListItems'
            ListItems = varargin{i+1};
        case 'Message'
            message = varargin{i+1};
        case 'MultiSelect'
            multiSelect = varargin{i+1};
        case 'Name'
            name = varargin{i+1};
        case 'OkStr'
            okStr = varargin{i+1};
        otherwise
            error('Unknown argument %s',varargin{i})
    end
end
%build the ui figure
fig = uifigure('Name',name,'WindowStyle','modal','Visible','off',...
    'DeleteFcn',@figDelFcn);
fig.Position(3) = 200;
n = 0;
rowHeights = {};
if ~isempty(message)
    n = n+1;
    rowHeights{n} = 'fit';
end
n = n+1;
rowHeights{n} = '1x';
if allowAdd
    n = n+1;    
    rowHeights{n} = baseCharHeight;
    n = n+1;    
    rowHeights{n} = baseCharHeight;
end
if multiSelect
    n = n+1;    
    rowHeights{n} = baseCharHeight;
end
n = n+1;    
rowHeights{n} = baseCharHeight;
grid = uigridlayout(fig,[n,2],'RowHeight',rowHeights);
if ~isempty(message)
    msgLbl = uilabel(grid,'Text',message,'WordWrap','on');
    msgLbl.Layout.Column = [1 2];
end
listBox = uilistbox(grid,'Items',ListItems);
listBox.Multiselect = multiSelect;
listBox.Value = listBox.Items(initialSelect);
listBox.Layout.Column = [1 2];
if allowAdd
    addEdit = uieditfield(grid);
    addEdit.Layout.Column = [1 2];
    addButton = uibutton(grid,'Text','Add Item','ButtonPushedFcn',@listAddItem);
    addButton.Layout.Column = 1;
    delButton = uibutton(grid,'Text','Delete Item','ButtonPushedFcn',@listDelItem);
    delButton.Layout.Column = 2;
end
if multiSelect
    allButton = uibutton(grid,'Text','Select all','ButtonPushedFcn',@selectAll);
    allButton.Layout.Column = [1 2];
end
okButton = uibutton(grid,'Text',okStr,'ButtonPushedFcn',@okFcn);
okButton.Layout.Column = 1;
cancelButton = uibutton(grid,'Text',cancelStr,'ButtonPushedFcn',@cancelFcn);
cancelButton.Layout.Column = 2;
fig.Visible = 'on';
uiwait(fig);
%functions for interaction
    function listAddItem(src,event)
        listBox.Items{end+1} = addEdit.Value;
        ListItems = listBox.Items;
    end
    function listDelItem(src,event)
       listBox.Items(ismember(listBox.Items,listBox.Value)) = [];
       ListItems = listBox.Items;
    end
    function selectAll(src,event)
        listBox.Value = listBox.Items;
    end
    function okFcn(src,event)
        ExitStatus = 1;
        delete(fig)
    end
    function cancelFcn(src,event)
        ExitStatus = 0;
        delete(fig)
    end
    function figDelFcn(src,event)
        if ~ExitStatus
            Selection = ListItems(initialSelect);
        else
            Selection = listBox.Value;
        end
    end
end