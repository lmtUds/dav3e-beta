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

classdef MainRework < handle
    properties
        moduleNames = {...
            'Gui.Modules.Start',...
            'Gui.Modules.Preprocessing',...
            'Gui.Modules.CycleRanges',...
            'Gui.Modules.Grouping',...
            'Gui.Modules.FeatureDefinition',...
            'Gui.Modules.Model'...
            }
        
        modulePanel
        moduleSidebar
        modules = Gui.Modules.GuiModule.empty
        sensorSetTable
        hFigure
        
        project
        projectFile
        projectPath
        
        version = '0.2';
    end
    
    methods
        function obj = MainRework()
            obj.makeLayout();
        end
        
        function delete(obj)
            for i = 1:numel(obj.modules)
                delete(obj.modules(i));
            end
            delete(obj.sensorSetTable);
            delete(obj.hFigure);
        end
        
        function makeLayout(obj)
            f = uifigure( ...
                'Name', 'DAV³E © Laboratory for Measurement Technology', ...
                'Tag', ['DAV³E Version ',num2str(obj.version)],...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'HandleVisibility', 'on', ...
                'Units', 'normalized', ...
                'Position', [.2 .2 .7 .7],...
                'Color','w',...
                'CloseReq',@(h,e)obj.delete);
            obj.hFigure = f;
        
            % remove some buttons that are not needed
%             a = findall(gcf);
%             b = findall(a,'ToolTipString','Save Figure');
%             b = [b, findall(a,'ToolTipString','Open File')];
%             b = [b, findall(a,'ToolTipString','New Figure')];
%             b = [b, findall(a,'ToolTipString','Print Figure')];
%             b = [b, findall(a,'ToolTipString','Show Plot Tools')];
%             b = [b, findall(a,'ToolTipString','Hide Plot Tools')];
%             b = [b, findall(a,'ToolTipString','Link Plot')];
%             b = [b, findall(a,'ToolTipString','Insert Colorbar')];
%             b = [b, findall(a,'ToolTipString','Open File')];
%             b = [b, findall(a,'ToolTipString','Insert Legend')];
%             b = [b, findall(a,'ToolTipString','Show Plot Tools and Dock Figure')];
%             set(b,'Visible','Off');
            
            % menubar
            callback = getMenuCallbackName();
            mh = uimenu(f,'Label','File');
            uimenu(mh,'Label','New project', callback,@(varargin)obj.newProject);
            uimenu(mh,'Label','Open project', callback,@(varargin)obj.loadProject);
            uimenu(mh,'Label','Save project', callback,@(varargin)obj.saveProject);
            uimenu(mh,'Label','Save project as...', callback,@(varargin)obj.saveProjectAs);
            m = uimenu(mh,'Label','Export', 'Separator','on');
            uimenu(m,'Label','Data...',...
                callback, []);
            uimenu(m,'Label','Data to workspace',...
                callback, @obj.exportDataToWorkspace);
            uimenu(m,'Label','Full model data',...
                callback, @obj.exportFullModelData);
            uimenu(m,'Label','Full model data to workspace',...
                callback, @obj.exportFullModelDataToWorkspace);
            uimenu(m,'Label','Merged Features',...
                callback, @obj.exportMergedFeature);
            uimenu(m,'Label','Merged Features to workspace',...
                callback, @obj.exportMergedFeatureToWorkspace);
            uimenu(m,'Label','CRG (ranges/groups) files',...
                callback, @obj.exportCycleRangesAndGroups);
            m = uimenu(mh,'Label','Import');
            uimenu(m,'Label','Data from workspace...',...
                callback,@obj.importDataFromWorkspace);
            uimenu(m,'Label','GRUPY (gasmixer) files',...
                callback,@obj.importGasmixerFile);
            uimenu(m,'Label','CRG (ranges/groups) files',...
                callback,@obj.importCycleRangesAndGroups);
            uimenu(mh,'Label','Sensor properties', 'Separator','on',...
                callback,@obj.showSensorProperties);
            uimenu(mh,'Label','Cluster properties',...
                callback,@obj.showClusterProperties);
            uimenu(mh,'Label','Virtual sensors',...
                callback,@obj.showVirtualSensors);
            
            mh = uimenu(f,'Label','Plots');
            uimenu(mh,'Label','default plot',callback,@obj.openDefaultPlot);
            uimenu(mh,'Label','square plot',callback,@obj.openSquarePlot);
            uimenu(mh,'Label','div. plot vertical',callback,@obj.openDivPlotVertical);
            uimenu(mh,'Label','scatter/histogram plot',callback,@obj.openScatterHistPlot);
            uimenu(mh,'Label','very wide plot',callback,@obj.openVeryWidePlot);
            
            % statusbar
%             warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
%             sb = statusbar(f,'Initialize...');
%             set(sb.ProgressBar, 'Visible',true, 'Indeterminate',true);
            
            % layout
%             mainLayout = uiextras.VBoxFlex('Parent',f, 'Spacing',5);
            mainLayout = uigridlayout(f,[2 2]);
            mainLayout.RowHeight = {'3x','1x'};
            mainLayout.ColumnWidth = {'1x','7x'};
%             content = uiextras.HBox('Parent',mainLayout);
%             content = uigridlayout(mainlayout,[4 4]);
%             content.Layout.Row = 1;
%             content.Layout.Column = 2;
%             bottomTable = uiextras.HBox('Parent',mainLayout);
            bottomTable = uitable(mainLayout);
            bottomTable.Layout.Row = 2;
            bottomTable.Layout.Column = [1 2];
%             modulesSidebar = uiextras.VButtonBox('Parent',content);
            modulesSidebar = uigridlayout(mainLayout,...
                [numel(obj.moduleNames) 1],...
                'Padding',[0 0 0 0]);
            modulesSidebar.Layout.Row = 1;
            modulesSidebar.Layout.Column = 1;
%             module = uiextras.CardPanel('Parent',content);
%             module = uigridlayout(mainLayout,[1 1]);
            module = uipanel(mainLayout,'BorderType','none');
            module.Layout.Row = 1;
            module.Layout.Column = 2;
            %uicontrol('Parent',modulesSidebar, 'Background','y')
            %uicontrol('Parent',module, 'Background','r')
            %uicontrol('Parent',bottomTable, 'Background','b')
            
%             t = JavaTable(bottomTable,'sortable');
%             t.setSortingEnabled(true)
%             t.setFilteringEnabled(true);
%             t.setColumnReorderingAllowed(false);
%             
%             % context menu
%               bTableContextMenu = uicontextmenu(f);
%               selectAll = uimenu(bTableContextMenu,...
%                   'Text','Select all',...
%                   'MenuSelectedFcn',@obj.selectVisibleSensors);
%               deselectAll = uimenu(bTableContextMenu,...
%                   'Text','Deselect all',...
%                   'MenuSelectedFcn',@obj.deselectVisibleSensors);
%               bottomTable.ContextMenu = bTableContextMenu;
%             popupMenu = javax.swing.JPopupMenu();
%             selectItem = javax.swing.JMenuItem('select all');
%             deselectItem = javax.swing.JMenuItem('deselect all');
%             popupMenu.add(selectItem);
%             popupMenu.add(deselectItem);
%             t.jTable.setComponentPopupMenu(popupMenu);
%             set(handle(selectItem,'CallbackProperties'),'MousePressedCallback',@obj.selectVisibleSensors)
%             set(handle(deselectItem,'CallbackProperties'),'MousePressedCallback',@obj.deselectVisibleSensors)
%             
            obj.sensorSetTable = bottomTable;
            
%             mainLayout.Sizes = [-1,200];
%             content.Sizes = [200,-5];
%             modulesSidebar.ButtonSize = [190,35];
%             modulesSidebar.VerticalAlignment = 'top';
            
            obj.modulePanel = module;
            obj.moduleSidebar = modulesSidebar;
            
            % load modules
            for i = 1:numel(obj.moduleNames)
                m = feval(obj.moduleNames{i},obj);
                [moduleLayout,moduleMenu] = m.makeLayoutRework(module,f);
                moduleButton = uibutton(modulesSidebar,...
                    'Text',m.caption,...
                    'ButtonPushedFcn',@(varargin)obj.setModule(i));
                moduleButton.Layout.Row = i;
                obj.modules(i) = m;
            end
            
            % reverse child order as they are pushed to the front in the
            % panel children array, but to the back of obj.modules
            obj.modulePanel.Children = obj.modulePanel.Children(end:-1:1);
            
            mh = uimenu(f,'Label','DevTools');
            uimenu(mh,'Label','create example data','Callback',@(varargin)obj.createTestData);
            
            mh = uimenu(f,'Label','Help');
            uimenu(mh,'Label','How to',callback,@obj.howto);
            uimenu(mh,'Label','About',callback,@obj.about);
            uimenu(mh,'Label','Licenses',callback,@obj.licenses);
            
            % set first module active
            % this is not done with the setModule method in order to avoid
            % calling onClose on the last module here
            obj.modulePanel.Children(1).Visible = 1;
            obj.modules(1).onOpen();
            obj.moduleSidebar.Children(1).FontWeight = 'bold';
        end
 
        function importGasmixerFile(obj,varargin)
            sb = statusbar(obj.hFigure,'Import cycle ranges and groupings...');
            set(sb.ProgressBar, 'Visible',true, 'Indeterminate',true);
            output = Gui.Dialogs.DataExchange();
            waitfor(Gui.Dialogs.LoadGRUPY(output));
            if isempty(output.data)
                return
            end
            time = output.data.time;
            groupings = output.data.data;
            groupnames = output.data.captions;
            deleteOldRanges = output.data.deleteOldRanges; 
            obj.project.importCycleRangesAndGroupings(time, groupings, groupnames, deleteOldRanges)
            if any(contains(obj.moduleNames, 'Gui.Modules.CycleRanges'))
               obj.modules(contains(obj.moduleNames, 'Gui.Modules.CycleRanges')).onOpen()
            end
            if any(contains(obj.moduleNames, 'Gui.Modules.Grouping'))
               obj.modules(contains(obj.moduleNames, 'Gui.Modules.Grouping')).onOpen()
            end
            sb = statusbar(obj.hFigure,'Ready.');
            set(sb.ProgressBar, 'Visible',false, 'Indeterminate',false);
        end
        
        function importCycleRangesAndGroups(obj,varargin)
            [file,path] = uigetfile({'*.crg','CRG file'},'Choose Cycle Ranges and groupings file');
            if file == 0
                return
            end
            obj.project.importCycleRangesAndGroups(fullfile(path,file));
            if any(contains(obj.moduleNames, 'Gui.Modules.CycleRanges'))
               obj.modules(contains(obj.moduleNames, 'Gui.Modules.CycleRanges')).onOpen()
            end
            if any(contains(obj.moduleNames, 'Gui.Modules.Grouping'))
               obj.modules(contains(obj.moduleNames, 'Gui.Modules.Grouping')).onOpen()
            end
        end
        
        function exportCycleRangesAndGroups(obj,varargin)
            [file, path] = uiputfile({'*.crg','CRG file'},'Choose Cycle Ranges and groupings file');
            if file == 0
                return
            end
            filename = fullfile(path,file);
            fid = fopen(filename,'wt');
            
            ranges = obj.project.ranges;
            groupings = obj.project.groupings;
            header = ['beginTime', 'endTime', 'caption',...
                'label: '+horzcat(groupings.caption), ...
                'color: '+horzcat(groupings.caption)];

            out = [string(vertcat(ranges.timePosition)), vertcat(ranges.caption), ...
                string(horzcat(groupings.vals))];

            for i=1:numel(groupings)
%                 color = cell2mat(cellfun(@(x) groupings(i).colors(x)*255,...
%                     cellstr(deStar(groupings(i).vals)),'UniformOutput', false));
                color = groupings(i).getColorsInOrder*255;
                out = [out, join(string(color),',')];
            end

            out = join(out, '\t');
            out = [join(header,'\t'); out];
            out = join(out, '\n');

            
            fprintf(fid, out);
            fclose(fid);
        end
        
        function openDefaultPlot(obj,varargin)
            defaultPlot
        end
        
        function openSquarePlot(obj,varargin)
            squarePlot
        end
        
        function openDivPlotVertical(obj,varargin)
            twoPlotsVertical
        end
        
        function openScatterHistPlot(obj,varargin)
            centerHistSubplot
        end
        
        function openVeryWidePlot(obj,varargin)
            veryWidePlot
        end
        
        function howto(obj,varargin)
            web('https://github.com/lmtUds/dav3e-beta');
        end
        
        function about(obj,varargin)
            Gui.Dialogs.About(obj.version);
        end
        
        function licenses(obj,varargin)
            Gui.Dialogs.Licenses();
        end
        
        function showClusterProperties(obj,varargin)
            Gui.Dialogs.Clusters(obj);
        end
        
        function showSensorProperties(obj,varargin)
            Gui.Dialogs.Sensors(obj);
        end
        
        function showVirtualSensors(obj,varargin)
            Gui.Dialogs.VirtualSensors(obj);
        end
        
        function importDataFromWorkspace(obj,varargin)
            vars = evalin('base','who');
            [sel,ok] = listdlg('ListString',vars);
            if ~ok
                return
            end
            for i = 1:numel(sel)
                data = evalin('base',vars{sel(i)});
                if ~isnumeric(data)
                    warning('Format of variable %s not supported.',vars{sel(i)});
                    continue
                end
                c = Cluster('samplingPeriod',1,...
                    'nCyclePoints',size(data,2),...
                    'nCycles',size(data,1),...
                    'caption',vars{sel(i)});        

                sensordata = SensorData.Memory(data);
                sensor = Sensor(sensordata,'caption',vars{sel(i)});
                c.addSensor(sensor);

                obj.project.addCluster(c);
            end
            obj.populateSensorSetTable();
        end
        
        function exportDataToWorkspace(obj,varargin)
            sensors = obj.project.getSensors();
            [sel,ok] = listdlg('ListString',sensors.getCaption('cluster'));
            if ~ok
                return
            end
            for i = 1:numel(sel)
                s = matlab.lang.makeValidName(char(sensors(sel(i)).getCaption('cluster')));
                assignin('base',s,sensors(sel(i)).data);
            end
        end
        
        function exportFullModelDataToWorkspace(obj,varargin)
            fullModelData = struct(obj.project.currentModel.fullModelData);
            assignin('base', 'fullModelData',fullModelData);
        end
        
        function exportFullModelData(obj,varargin)
            [file,path] = uiputfile({'*.mat'},'Save full model data');
            if file == 0
                return
            end
            filename = fullfile(path, file);
            fullModelData = struct(obj.project.currentModel.fullModelData);
            save(filename,'fullModelData')
        end
        
        function exportMergedFeatureToWorkspace(obj,varargin)
            mergeFeature = struct(obj.project.mergeFeatures);
            assignin('base', 'mergeFeature',mergeFeature);
        end
        
        function exportMergedFeature(obj,varargin)
            [file,path] = uiputfile({'*.mat'},'Save full model data');
            if file == 0
                return
            end
            filename = fullfile(path, file);
            mergeFeature = struct(obj.project.mergeFeatures);
            save(filename,'mergeFeature')
        end
        
        function selectVisibleSensors(obj,varargin)
            s = obj.sensorSetTable.getRowObjectsAt(1:numel(obj.project.getSensors()));
            s.setActive(true);
            obj.populateSensorSetTable();
        end
        
        function deselectVisibleSensors(obj,varargin)
            s = obj.sensorSetTable.getRowObjectsAt(1:numel(obj.project.getSensors()));
            s.setActive(false);
            obj.populateSensorSetTable();
        end
        
        function setModule(obj,i)
            if ~obj.modules(i).canOpen()
                return
            end
%             statusbar(obj.hFigure,'Changing module...');
            try
%                 ind = 1;
%                 children = obj.modulePanel.Children;
%                 % select the first visible child
%                 for j = 1:size(children,1)
%                     if children(j).Visible == 1
%                         ind = j;
%                         break
%                     end
%                 end
                obj.modules(panelChildFind(obj.modulePanel)).onClose()
            catch ME
                disp(ME);
                error(['An error occured. This one is usually resolved '...
                       'by executing "clear classes" or restarting MATLAB.']);
            end
%             obj.modulePanel.SelectedChild = i;
            panelChildSelect(obj.modulePanel,i);
            obj.modules(i).onOpen();
            [obj.moduleSidebar.Children.FontWeight] = deal('normal');
            c = obj.moduleSidebar.Children(end:-1:1);
            c(i).FontWeight = 'bold';
%             statusbar(obj.hFigure,'Ready.');
        end
        
        function m = getActiveModule(obj)
%             ind = 1;
%             children = obj.modulePanel.Children;
%             % select the first visible child
%             for i = 1:size(children,1)
%                 if children(i).Visible == 1
%                     ind = i;
%                     break
%                 end
%             end
            m = obj.modules(panelChildFind(obj.modulePanel));
        end
        
        function populateSensorSetTable(obj)
            % retrieve sensor information
            s = obj.project.getSensors();
            data = cell(numel(s),5);
            for i = 1:numel(s)
                data{i,1} = s(i).isActive();
                data{i,2} = char(s(i).getCluster().getCaption());
                data{i,3} = char(s(i).getCaption());
                data{i,4} = char(s(i).preprocessingChain.getCaption());
                data{i,5} = char(s(i).featureDefinitionSet.getCaption());
            end
            
            % prepare the table for display
            vars = {'Use','Cluster','Sensor','Preprocessing','Feature set'};
            
            obj.sensorSetTable.Data = data;
            obj.sensorSetTable.ColumnName = vars;
            obj.sensorSetTable.RowName = 'numbered';
            obj.sensorSetTable.ColumnEditable = ...
                [true true true true true];
            obj.sensorSetTable.ColumnSortable = ...
                [false true true false false];
            
            % make certain columns selectable via a dropdown
            prepChains = cellstr(obj.project.poolPreprocessingChains.getCaption());
            featSets = cellstr(obj.project.poolFeatureDefinitionSets.getCaption());
            obj.sensorSetTable.ColumnFormat = {...
                'logical' 'char' 'char' prepChains featSets};
            
            obj.sensorSetTable.CellEditCallback =...
                @(src,event) editCallback(src,event,s,obj);
            obj.sensorSetTable.CellSelectionCallback =...
                @(src,event) selectCallback(src,event,s,obj);
            
            function editCallback(src, event, sensors, obj)
                row = event.Indices(1);
                col = event.Indices(2);
                sensor = sensors(row);
                switch col
                    case 1
                        sensor.setActive(event.EditData);
                    case 2
                        sensor.getCluster().setCaption(event.EditData);
                    case 3
                        sensor.setCaption(event.EditData);
                    case 4
                        idx = obj.project.poolPreprocessingChains.getCaption()...
                            == string(event.EditData);
                        
                        % if the edit did not point to a valid chain revert
                        % the edit and change nothing
                        if ~idx
                            src.Data{row, col} = event.PreviousData;
                            src.ColumnFormat{col} = ...
                                cellstr(obj.project.poolPreprocessingChains.getCaption());
                            return
                        end
                        
                        sensor.preprocessingChain = obj.project.poolPreprocessingChains(idx);
                        if obj.project.getCurrentSensor() == sensor
                            obj.project.currentPreprocessingChain = ...
                                obj.project.poolPreprocessingChains(idx);
                            obj.getActiveModule().onCurrentPreprocessingChainChanged(...
                                obj.project.poolPreprocessingChains(idx));
                        end
                    case 5
                        idx = obj.project.poolFeatureDefinitionSets.getCaption()...
                            == string(event.EditData);
                        
                        % if the edit did not point to a valid set revert
                        % the edit and change nothing
                        if ~idx
                            src.Data{row, col} = event.PreviousData;
                            src.ColumnFormat{col} = ...
                                cellstr(obj.project.poolFeatureDefinitionSets.getCaption());
                            return
                        end
                        
                        sensor.featureDefinitionSet = obj.project.poolFeatureDefinitionSets(idx);
                        if obj.project.getCurrentSensor() == sensor
                            obj.project.currentFeatureDefinitionSet = ...
                                obj.project.poolFeatureDefinitionSets(idx);
                            obj.getActiveModule().onCurrentFeatureDefinitionSetChanged(...
                                obj.project.poolFeatureDefinitionSets(idx));  
                        end
                end
            end
            
            function selectCallback(src, event, sensors, obj)
                row = event.Indices(1);
                newSensor = sensors(row);
                prevSensor = obj.project.getCurrentSensor();
                prevCluster = prevSensor.getCluster();
                
                newSensor.setCurrent()
                newSensor.getCluster().setCurrent();
                
                if prevCluster ~= newSensor.getCluster()
                    obj.getActiveModule().onCurrentClusterChanged(...
                        newSensor.getCluster(),prevSensor.getCluster());
                end
                if prevSensor ~= newSensor
                    obj.getActiveModule().onCurrentSensorChanged(newSensor,prevSensor);
                end
            end            
        end
        
        function newProject(obj)
            questdlg('All unsaved changes in the current project will be lost. Proceed?','Really?','Yes','No','No');
            obj.project = Project();
            
            obj.populateSensorSetTable();
            for i = 1:numel(obj.modules)
                obj.modules(i).reset();
            end            
        end        
        
        function saveProject(obj)
            if isempty(obj.projectPath) || isempty(obj.projectFile)
                obj.saveProjectAs();
            end
            obj.saveProjectAs(obj.projectPath,obj.projectFile);
        end
        
        function saveProjectAs(obj,path,file)
            persistent oldPath
            if ~exist('oldPath','var')
                oldPath = pwd;
            end
            
            if nargin < 2
                [file,path] = uiputfile({'*.dave','DAV³E project'},'Save project file',oldPath);
                if file == 0
                    return
                end
                oldPath = path;
            end
            
            sb = statusbar(obj.hFigure,'Saving project...');
            set(sb.ProgressBar, 'Visible',true, 'Indeterminate',true);
            
            project = obj.project; %#ok<NASGU,PROPLC>
            save(fullfile(path,file),'project','-v7.3');
            obj.projectPath = path;
            obj.projectFile = file;
            
            sb = statusbar(obj.hFigure,'Ready.');
            set(sb.ProgressBar, 'Visible',false, 'Indeterminate',false);
        end
        
        function loadProject(obj)
            persistent oldPath
            if ~exist('oldPath','var')
                oldPath = pwd;
            end
            
            [file,path] = uigetfile({'*.dave','DAV³E project'},'Choose project file',oldPath);
            if file == 0
                return
            end
            oldPath = path;
            
            sb = statusbar(obj.hFigure,'Loading project...');
            set(sb.ProgressBar, 'Visible',true, 'Indeterminate',true);
            
            l = load(fullfile(path,file),'-mat');
            obj.project = l.project;
            obj.projectPath = path;
            obj.projectFile = file;
            
            obj.populateSensorSetTable();
            for i = 1:numel(obj.modules)
                obj.modules(i).reset();
            end
            
            % set first module active
            % this is not done with the setModule method in order to avoid
            % calling onClose on the last module here
            obj.modulePanel.SelectedChild = 1;
            obj.modules(1).onOpen();
            [obj.moduleSidebar.Children.FontWeight] = deal('normal');
            obj.moduleSidebar.Children(end).FontWeight = deal('bold');
            
            sb = statusbar(obj.hFigure,'Ready.');
            set(sb.ProgressBar, 'Visible',false, 'Indeterminate',false);
        end
        
        function createTestData(obj)
            p = Project();
            obj.project = p;

            c = Cluster('samplingPeriod',0.1,'nCyclePoints',100,'nCycles',200,'offset',1000);
            p.addCluster(c);

            s = Sensor(SensorData.Memory(repmat(1:100,200,1)),'caption','linear sensor');
            c.addSensor(s);
            
            s = Sensor(SensorData.Memory(rand(200,100)),'caption','sensor2');
            c.addSensor(s);
            
            s = Sensor(SensorData.Memory(rand(200,100)),'caption','sensor3');
            c.addSensor(s);

            
            c = Cluster('samplingPeriod',0.1,'nCyclePoints',100,'nCycles',200,'offset',1000,'caption','another cluster','track','other');
            p.addCluster(c);
            
            s = Sensor(SensorData.Memory(rand(200,100)),'caption','sensor2');
            c.addSensor(s);
            
            s = Sensor(SensorData.Memory(rand(200,100)),'caption','sensor3');
            c.addSensor(s);
           
            r = c.makeCycleRange([1,20] + 20*(0:5)');

            p.addCycleRange(r);

%             g = Grouping();
            g = p.addGrouping();
%             g.addRange(r);
            groups = {'b1','b5','n3','n10','f50','f100'};
            for i = 1:6
                g.setGroup(groups{i},r(i))
            end
            
            g(2) = p.addGrouping();
%             g(2) = Grouping();
            g(2).setCaption('another grouping');
%             g(2).addRange(r);
            groups = {'b','b','n','n','f','f'};
            for i = 1:6
                g(2).setGroup(groups{i},r(i))
            end
            
            g.updateColors();
%             p.groupings = g;
%             g.updateColors()

            p.addModel();
%             m = Model(DataProcessingBlockChain());
%             p.models = m;

            obj.populateSensorSetTable();
        end
    end
end