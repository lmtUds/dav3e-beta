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
            obj.GroupingCreationNew(main,module);
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
        function GroupingCreationNew(obj,main,module)  
            if isempty(main.project)
                uialert(main.hFigure,...
                    {'Creating a new grouping requires a project and grouping to be created first.',...
                    'Load some data, define a grouping and try again.'},...
                    'No project found')
                return
            end                
            if isempty(deStar(module.currentGrouping.getDestarredCategories()))
                uialert(main.hFigure,...
                    {'Creating a new grouping requires a grouping with categories to be created first.',...
                    'Define some grouping categories and try again.'},...
                    'No valid grouping found')
                return
            end
            fig = uifigure('Name','Grouping creation',...
                'Visible','off','WindowStyle','modal');
            grid = uigridlayout(fig,[5 4],'RowHeight',{'fit',22,22,'fit',22});
            labelRow = 2;
            dropdownRow = 3;
            
            msgLabel = uilabel(grid,'Wordwrap','on',...
                'Text','A new grouping will be created by masking the base grouping with selected groups by appending the selected Token.');
            msgLabel.Layout.Column = [1 4];
            msgLabel.Layout.Row = 1;
            
            baseLabel = uilabel(grid,'Text','Base Grouping');
            baseLabel.Layout.Column = 1;
            baseLabel.Layout.Row = labelRow;            
            
            baseDropdown = uidropdown(grid,...
                'Items',main.project.groupings.getCaption);
            baseDropdown.Layout.Column = 1;
            baseDropdown.Layout.Row = dropdownRow;
            
            maskLabel = uilabel(grid,'Text','Mask Grouping');
            maskLabel.Layout.Column = 2;
            maskLabel.Layout.Row = labelRow;
            
            maskDropdown = uidropdown(grid,...
                'Items',main.project.groupings.getCaption);
            maskDropdown.Layout.Column = 2;
            maskDropdown.Layout.Row = dropdownRow;
            
            selectLabel = uilabel(grid,'Text','Select Groups');
            selectLabel.Layout.Column = 3;
            selectLabel.Layout.Row = labelRow;
            
            groupings = main.project.groupings;
            currentMaskGrouping = ...
                groupings(ismember(groupings.getCaption(),maskDropdown.Value));
            selectList = uilistbox(grid,'Value',{},'Multiselect','on',...
                'Items',categories(currentMaskGrouping.vals)); 
            selectList.Layout.Column = 3;
            selectList.Layout.Row = [dropdownRow dropdownRow+1];
            
            maskDropdown.ValueChangedFcn =...
                @(src,event) UpdateList(src,event,selectList,main);
            
            tokenLabel = uilabel(grid,'Text','Token');
            tokenLabel.Layout.Column = 4;
            tokenLabel.Layout.Row = labelRow;
            
            tokenDropdown = uidropdown(grid,'Items',{'<ignore>','*'});
            tokenDropdown.Layout.Column = 4;
            tokenDropdown.Layout.Row = dropdownRow;
            
            applyButton = uibutton(grid,'Text','Create new Grouping',...
                'ButtonPushedFcn',@(src,event)...
                    CreateGrouping(src,event,main,module,...
                    baseDropdown,maskDropdown,selectList,tokenDropdown));
            applyButton.Layout.Column = [1 4];
            applyButton.Layout.Row = 5;
                
            fig.Visible = 'on';
            
            function CreateGrouping(src,event,main,module,base,mask,list,token)
                p = main.project;
                baseGrouping = p.getGroupingByCaption(base.Value);
                maskGrouping = p.getGroupingByCaption(mask.Value);
                maskCats = list.Value;
                action = token.Value;
                p.createGroupingFrom(baseGrouping,maskGrouping,maskCats,action);
                module.populateGroupingTable();
                module.populateGroupsTable();
            end
            function UpdateList(src,event,list,main)
                gps = main.project.groupings;
                cmg = gps(ismember(gps.getCaption(),src.Value));
                list.Items = categories(cmg.vals);
                list.Value = {};
            end
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