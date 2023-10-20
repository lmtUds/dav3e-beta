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
        heading
        hColorChooser
        jColorChooser
        heading2
        hColorChooser2
        jColorChooser2
        infosection
        hGroupList
        applyButton
    end
    
    methods
        function obj = GroupingColorGradient(main,module)
            obj.main = main;
            obj.module = module;
            obj.f = figure('Name','Grouping color gradient',...
                'Visible','off',...
                'menubar','none','toolbar','none',...
                'CloseRequestFcn',@(varargin)obj.onDialogClose);
            obj.f.Position(1,4) = 600;%adapt size for two colors
            obj.f.Position(1,2) = 50;%adapt position for two colors
            layout = uiextras.VBox('Parent',obj.f);
            
            obj.heading = uicontrol(layout,...
                'Style','text','BackgroundColor','y','String','Choose start color:');
            
            cc = javax.swing.JColorChooser(); %com.mathworks.mlwidgets.graphics.ColorPicker(0,0,'');
            [obj.jColorChooser,obj.hColorChooser] = javacomponent(cc,[0,0,1,1],layout);
            
            obj.heading2 = uicontrol(layout,...
                'Style','text','BackgroundColor','y','String','Choose end color:');
            
            cc2 = javax.swing.JColorChooser(); %com.mathworks.mlwidgets.graphics.ColorPicker(0,0,'');
            [obj.jColorChooser2,obj.hColorChooser2] = javacomponent(cc2,[0,0,1,1],layout);
            
            obj.infosection = uicontrol(layout,...
                'Style','text','BackgroundColor','y','String','Select the groups that are to be ignored for color gradient');
            
            obj.hGroupList = uicontrol(layout,...
                'Style','listbox', 'String',{'a','b','c'},...
                'min',0,'max',100, 'Value', []);
            
            obj.applyButton = uicontrol(layout,...
                'String','apply',...
                'Callback',@(h,e)obj.applyButtonClicked);
            
            layout.Sizes = [15,-5,15,-5,15,-1,30];
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
            clr2 = double(obj.jColorChooser2.getColor().getRGBColorComponents([]))';
            ignoreGroups = obj.hGroupList.String(obj.hGroupList.Value);
            obj.module.currentGrouping.makeColorGradientHSV(clr,clr2,ignoreGroups);
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