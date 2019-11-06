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

classdef GroupingCreation < handle
    properties
        main
        module
        f
        hPopupBase
        hPopupMask
        hPopupAction
        hListboxGroups
        applyButton
    end
    
    methods
        function obj = GroupingCreation(main,module)
            obj.main = main;
            obj.module = module;
            obj.f = figure('Name','Grouping color gradient',...
                'Visible','off',...
                'menubar','none','toolbar','none',...
                'CloseRequestFcn',@(varargin)obj.onDialogClose);
            layout = uiextras.VBox('Parent',obj.f);

            uicontrol(layout,'Style','text', 'String','base grouping');
            obj.hPopupBase = uicontrol(layout,...
                'Style','popupmenu', 'String',{'a'});
            
            uicontrol(layout,'Style','text', 'String','mask grouping');
            obj.hPopupMask = uicontrol(layout,...
                'Style','popupmenu', 'String',{'a'},...
                'Callback',@(varargin)obj.update);
            
            uicontrol(layout,'Style','text', 'String','selected groups');
            obj.hListboxGroups = uicontrol(layout,...
                'Style','listbox', 'String',{'a','b','c'},...
                'min',0,'max',100);
            
            uicontrol(layout,'Style','text', 'String','action');
            obj.hPopupAction = uicontrol(layout,...
                'Style','popupmenu', 'String',{'<ignore>','*'});

            obj.applyButton = uicontrol(layout,...
                'String','apply',...
                'Callback',@(h,e)obj.applyButtonClicked);
            
            layout.Sizes = [20,30,20,30,20,-1,20,30,30];
        end
        
        function show(obj)
            obj.update();
            obj.f.Visible = 'on';
        end
        
        function hide(obj)
            obj.f.Visible = 'off';
        end
        
        function update(obj)
            groupings = obj.main.project.groupings;
            obj.hPopupBase.String = cellstr(groupings.getCaption());
            obj.hPopupMask.String = cellstr(groupings.getCaption());
            currentMaskGrouping = groupings(obj.hPopupMask.Value);
            obj.hListboxGroups.String = categories(currentMaskGrouping.vals);
        end
        
        function applyButtonClicked(obj)
            p = obj.main.project;
            baseGrouping = p.getGroupingByCaption(obj.hPopupBase.String{obj.hPopupBase.Value});
            maskGrouping = p.getGroupingByCaption(obj.hPopupMask.String{obj.hPopupMask.Value});
            maskCats = obj.hListboxGroups.String(obj.hListboxGroups.Value);
            action = obj.hPopupAction.String{obj.hPopupAction.Value};
            p.createGroupingFrom(baseGrouping,maskGrouping,maskCats,action);
            obj.module.populateGroupingTable();
            obj.module.populateGroupsTable();
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