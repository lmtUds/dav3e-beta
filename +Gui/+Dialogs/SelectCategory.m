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

function [Selection,ExitStatus,SelectionCategories] = SelectCategory(varargin)
%SELECT Display a list of multiple, selectable items in a modal uiFigure
%   In addition to displaying the list, allows adding custom options to the list.

%internal variables
baseCharHeight = 22;
cancelStr  = 'Cancel';
categories = {};
message = '';
multiSelect = 1;
name = 'Select from List';
okStr  = 'Ok';

%return variables
ExitStatus = 0;
ListItems = {};
Selection = {};
SelectionCategories = {};

if mod(length(varargin),2) ~= 0
    error('Selection dialog arguments must be pairs.')
end
%loop through arguments and set the corresponding variables
for i = 1:2:length(varargin)
    switch varargin{i}
        case 'CancelStr'
            cancelStr = varargin{i+1};
        case 'Categories'
            categories = varargin{i+1};
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
%define variables to keep track of needed grid measurements
n = 0;
rowHeights = {};
% if ~isempty(message)
%     n = n+1;
%     rowHeights{n} = 'fit';
% end
%split the items into their categories
%add rows for label and listbox per category
uCats = unique(categories,'stable');
catLists = cell(1,size(uCats,2));
for i = 1:size(uCats,2)
    catInd = ismember(categories,uCats{i});
    catLists{i} = ListItems(catInd);
    n = n+1;
    rowHeights{n} = baseCharHeight;
    n = n+1;
    rowHeights{n} = sum(catInd)*baseCharHeight+1;
end
% %we need a final row for 'ok' and 'cancel'
% n = n+1;    
% rowHeights{n} = baseCharHeight;
%build the ui figure
fig = uifigure('Name',name,'WindowStyle','modal','Visible','off',...
    'DeleteFcn',@cancelFcn);
fig.Position(3) = 300;
centerFigure(fig);
if ~isempty(message)
    outerGrid = uigridlayout(fig,[3,2],'RowHeight',{'fit','1x',baseCharHeight});
    msgLbl = uilabel(outerGrid,'Text',message,'WordWrap','on');
    msgLbl.Layout.Column = [1 2];
else
    outerGrid = uigridlayout(fig,[2,2],'RowHeight',{'1x',baseCharHeight});
end
% panel = uipanel(outerGrid,'BorderType','none','Scrollable','on');
% panel.Layout.Column = [1 2];
grid = uigridlayout(outerGrid,[n,2],'RowHeight',rowHeights,'Scrollable','on',...
    'RowSpacing',4,'ColumnSpacing',4,'Padding',[0 0 0 0]);
grid.Layout.Column = [1 2];
catBoxes = cell(1,size(uCats,2));
for i = 1:size(uCats,2)
    catLabel = uilabel(grid,'Text',uCats{i},'FontWeight','bold');
    catLabel.Layout.Column = [1 2];
    catBox = uilistbox(grid,'Items',catLists{i},'UserData',uCats{i},...
        'Multiselect',multiSelect,'Value',{},...
        'ValueChangedFcn',@(src,event) listSelect(src,event,i,catBoxes,multiSelect),...
        'DoubleClickedFcn',@(src,event) doubleclickedOkFcn(src,event));
    catBox.Layout.Column = [1 2];
    catBoxes{i} = catBox;
end
okButton = uibutton(outerGrid,'Text',okStr,...
    'ButtonPushedFcn',@(src,event) okFcn(src,event,catBoxes));
okButton.Layout.Column = 1;
cancelButton = uibutton(outerGrid,'Text',cancelStr,'ButtonPushedFcn',@cancelFcn);
cancelButton.Layout.Column = 2;
fig.Visible = 'on';
uiwait(fig);
%functions for interaction
    function listSelect(src,event,CurrentInd,allBoxes,multiSelect)
        if ~multiSelect
            for j = 1:size(allBoxes,2)
                if j == CurrentInd
                    continue
                end
                allBoxes{j}.Value = {};
            end
        end
    end
    function okFcn(src,event,catBoxes)
        sel = {};
        selCats = {};
        for j = 1:size(catBoxes,2)
            lb = catBoxes{j};
            v = lb.Value;
            c = lb.UserData;
            c = repmat({c},1,numel(v));
            sel = [sel, v];
            selCats = [selCats, c];
        end
        ExitStatus = 1;
        SelectionCategories = selCats;
        Selection = sel;
        delete(fig)
    end
    
    function doubleclickedOkFcn(src,event)              % handle double Click in Model->Add Dialogue
      sel = {};
      selCats = {};
      
      sel = [sel, src.Value];
      selCats = [selCats, src.UserData];

      ExitStatus = 1;
      SelectionCategories = selCats;
      Selection = sel;
      delete(fig)
    end  
    
    function cancelFcn(src,event)
        delete(fig)
    end
end