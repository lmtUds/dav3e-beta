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

function [Inputs,ExitStatus] = Input(varargin)
%SELECT Display a list of multiple, selectable items in a modal uiFigure
%   In addition to displaying the list, allows adding custom options to the list.

%internal variables
baseCharHeight = 22;
cancelStr  = 'Cancel';
defaultValues = {};
hasDefault = 0;
message = '';
name = 'User Input';
okStr  = 'Ok';

%return variables
ExitStatus = 0;
FieldNames = {};
Inputs = {};

if mod(length(varargin),2) ~= 0
    error('Selection dialog arguments must be pairs.')
end
%loop through arguments and set the corresponding variables
for i = 1:2:length(varargin)
    switch varargin{i}
        case 'CancelStr'
            cancelStr = varargin{i+1};
        case 'DefaultValues'
            defaultValues = varargin{i+1};
            hasDefault = 1;
        case 'FieldNames'
            FieldNames = varargin{i+1};
        case 'Message'
            message = varargin{i+1};
        case 'Name'
            name = varargin{i+1};
        case 'OkStr'
            okStr = varargin{i+1};
        otherwise
            error('Unknown argument %s',varargin{i})
    end
end
if ~isempty(defaultValues) && numel(FieldNames) ~= numel(defaultValues)
   error('When providing default field values, give one per field');
end
%build the ui figure
fig = uifigure('Name',name,'WindowStyle','modal','Visible','off',...
    'DeleteFcn',@figDelFcn);
fig.Position(3) = 250;
centerFigure(fig);
n = 0;
rowHeights = {};
if ~isempty(message)
    n = n+1;
    rowHeights{n} = 'fit';
end
for i = 1:numel(FieldNames)
    n = n+1;    
    rowHeights{n} = baseCharHeight;
end
n = n+1;    
rowHeights{n} = baseCharHeight;
%adjust figure size to fit grid rowspacing 10, padding 10
fig.Position(4) = (baseCharHeight + 10) * n + 10;
grid = uigridlayout(fig,[n,2],'RowHeight',rowHeights);%,...
%     'ColumnWidth',{'1x','2x'});
if ~isempty(message)
    msgLbl = uilabel(grid,'Text',message,'WordWrap','on');
    msgLbl.Layout.Column = [1 2];
end
edits = [];
for i = 1:numel(FieldNames)
    fldLbl = uilabel(grid,'Text',FieldNames{i});
    fldLbl.Layout.Column = 1;
    fldEdit = uieditfield(grid);
    fldEdit.Layout.Column = 2;
    if hasDefault
        fldEdit.Value = defaultValues{i};
    end
    edits = [edits fldEdit];
end
okButton = uibutton(grid,'Text',okStr,'ButtonPushedFcn',@okFcn);
okButton.Layout.Column = 1;
cancelButton = uibutton(grid,'Text',cancelStr,'ButtonPushedFcn',@cancelFcn);
cancelButton.Layout.Column = 2;
fig.Visible = 'on';
uiwait(fig);
%functions for interaction
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
            Inputs = defaultValues;
        else
            for j= 1:numel(FieldNames)
                Inputs = [Inputs {edits(j).Value}];
            end
        end
    end
end