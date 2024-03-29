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

function GroupingColorGradient(main,module)
    if isempty(main.project)
        uialert(main.hFigure,...
            {'Setting a grouping color requires a project and grouping to be created first.',...
            'Load some data, define a grouping and try again.'},...
            'No project found')
        return
    end                
    if isempty(deStar(module.currentGrouping.getDestarredCategories()))
        uialert(main.hFigure,...
            {'Setting a grouping color requires a grouping with categories to be created first.',...
            'Define some grouping categories and try again.'},...
            'No valid grouping found')
        return
    end
    fig = uifigure('Name','Grouping color gradient',...
        'Visible','off','WindowStyle','modal');
    centerFigure(fig);
    grid = uigridlayout(fig,[4 2],'RowHeight',{100,22,'1x',22});

    clrPicker1 = uibutton(grid,'BackgroundColor',[0.0820 0.8359 0.4961],...
        'ButtonPushedFcn',@(src,event) PickColor(src, event,main,fig),...
        'Text','Click to set base color 1',...
        'FontWeight','bold','FontSize',24,'WordWrap','on');
    clrPicker1.Layout.Column = 1;
    clrPicker1.Layout.Row = 1;
    
    clrPicker2 = uibutton(grid,'BackgroundColor',[0.9258 0.2773 0.2773],...
        'ButtonPushedFcn',@(src,event) PickColor(src, event,main,fig),...
        'Text','Click to set base color 2',...
        'FontWeight','bold','FontSize',24,'WordWrap','on');
    clrPicker2.Layout.Column = 2;
    clrPicker1.Layout.Row = 1;
    
    infoLabel = uilabel(grid,...
        'Text','The selected groups will be ignored for color gradient',...
        'HorizontalAlignment','center');
    infoLabel.Layout.Column = [1 2];
    infoLabel.Layout.Row = 2;
    
    grouping = module.currentGrouping;
    groupList = uilistbox(grid,...
        'Items',deStar(grouping.getDestarredCategories()),...
        'Value',{},'MultiSelect','on');
    groupList.Layout.Column = [1 2];
    groupList.Layout.Row = 3;
    
    applyButton = uibutton(grid,'Text','Create gradient from base colors',...
        'ButtonPushedFcn',@(src,event) ApplyClr(src,event,groupList,module,clrPicker1,clrPicker2));
    applyButton.Layout.Column = [1 2];
    applyButton.Layout.Row = 4;
    
    fig.Visible = 'on';
    
    function ApplyClr(src,event,groupList,module,clrPicker1,clrPicker2)
        clr1 = clrPicker1.BackgroundColor();
        clr2 = clrPicker2.BackgroundColor();
        ignoreGroups = groupList.Value;
        module.currentGrouping.makeColorGradientHSV(clr1,clr2,ignoreGroups);
        module.populateGroupsTable();
        module.updateRangeColors();
    end
    function PickColor(src,event,main,fig)
        fig.Visible = 'off';
        %avoid focus loss
        main.hFigure.Visible = 'off';
        main.hFigure.Visible = 'on';
        c = uisetcolor(src.BackgroundColor,'Set gradient base color');
        src.BackgroundColor = c;
        %avoid focus loss
        main.hFigure.Visible = 'off';
        main.hFigure.Visible = 'on';
        fig.Visible = 'on';
    end
end