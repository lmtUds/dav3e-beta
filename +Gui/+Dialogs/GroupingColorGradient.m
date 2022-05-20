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

classdef GroupingColorGradient < handle
    properties
        main
        module
        f
        hColorChooser
        jColorChooser
        hGroupList
        infosection
        applyButton
    end
    
    methods
        function obj = GroupingColorGradient(main,module)
%             obj.GroupingColorGradientNew(main,module);
            obj.main = main;
            obj.module = module;
            obj.f = figure('Name','Grouping color gradient',...
                'Visible','off',...
                'menubar','none','toolbar','none',...
                'CloseRequestFcn',@(varargin)obj.onDialogClose);
            layout = uiextras.VBox('Parent',obj.f);
            
            cc = javax.swing.JColorChooser(); %com.mathworks.mlwidgets.graphics.ColorPicker(0,0,'');
            [obj.jColorChooser,obj.hColorChooser] = javacomponent(cc,[0,0,1,1],layout);
            
            obj.hGroupList = uicontrol(layout,...
                'Style','listbox', 'String',{'a','b','c'},...
                'min',0,'max',100);
            
            obj.infosection = uicontrol(layout,...
                'Style','text','String','The selected groups will be ignored for color gradient');
            
            obj.applyButton = uicontrol(layout,...
                'String','apply',...
                'Callback',@(h,e)obj.applyButtonClicked);
            
            layout.Sizes = [-3,-1,30,30];
        end
        function GroupingColorGradientNew(obj,main,module)
            if isempty(module.currentGrouping)
                uialert(main.hFigure,...
                    'Setting a grouping color requires a grouping to be created first.',...
                    'No grouping found')
                return
            end
            fig = uifigure('Name','Grouping color gradient',...
                'Visible','off');
            grid = uigridlayout(fig,[4 1],'RowHeight',{'2x','1x',22,22});
            
            clrPicker = uipanel(grid);
%             cc = javax.swing.JColorChooser(); %com.mathworks.mlwidgets.graphics.ColorPicker(0,0,'');
%             [obj.jColorChooser,obj.hColorChooser] = javacomponent(cc,[0,0,1,1],layout);
            
            infoLabel = uilabel(grid,...
                'Text','The selected groups will be ignored for color gradient');
            grouping = module.currentGrouping;
            groupList = uilistbox(grid,...
                'Items',deStar(grouping.getDestarredCategories()));
            applyButton = uibutton(grid,'Text','Apply',...
                'ButtonPushedFcn',@(src,event) ApplyClr(src,event,groupList,module,clrPicker));
                        
            fig.Visible = 'on';
            function ApplyClr(src,event,groupList,module,clrPicker)
%                 clr = clrPicker.getColor();
                clr = [1 1 0];
                ignoreGroups = groupList.Value;
                module.currentGrouping.makeColorGradientHSV(clr,ignoreGroups);
                module.populateGroupsTable();
                module.updateRangeColors();
            end
        end
        
        function show(obj)
            obj.f.Visible = 'on';
        end
        
        function hide(obj)
            obj.f.Visible = 'off';
        end
        
        function update(obj,groups)
            obj.hGroupList.String = groups;
        end
        
        function applyButtonClicked(obj)
            clr = double(obj.jColorChooser.getColor().getRGBColorComponents([]))';
            ignoreGroups = obj.hGroupList.String(obj.hGroupList.Value);
            obj.module.currentGrouping.makeColorGradientHSV(clr,ignoreGroups);
            obj.module.populateGroupsTable();
            obj.module.updateRangeColors();
        end

        function onDialogClose(obj)
            if ishandle(obj.main.hFigure)
                obj.hide();
            else
                delete(obj.f) 
            end
        end
    end
end