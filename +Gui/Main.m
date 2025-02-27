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

classdef Main < handle
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
        
        version = '0.3';
    end
    
    methods
        function obj = Main()
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
            % statusbar
            proxyF = uifigure(...
                'Units', 'normalized', ...
                'Position', [.375 .45 .25 .1],...
                'Name', 'DAV³E © Initialization',...
                'NumberTitle', 'off');
            prog = uiprogressdlg(proxyF,'Title','Initializing',...
                'Indeterminate','on');
            centerFigure(proxyF)
            drawnow

            f = uifigure( ...
                'Name', 'DAV³E © Laboratory for Measurement Technology', ...
                'Tag', ['DAV³E Version ',num2str(obj.version)],...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'HandleVisibility', 'on', ...
                'Units', 'normalized', ...
                'Position', [.15 .15 .7 .7],...
                'Color','w',...
                'CloseReq',@(h,e)obj.delete);
            f.Units = 'pixels';
            f.Visible = 'off';            
            obj.hFigure = f;
            
            % menubar
            callback = getMenuCallbackName();
            mh = uimenu(f,'Label','File');
            uimenu(mh,'Label','New project', callback,@(varargin)obj.newProject);
            uimenu(mh,'Label','Load project...', callback,@(varargin)obj.loadProject);
            uimenu(mh,'Label','Save project', callback,@(varargin)obj.saveProject);
            uimenu(mh,'Label','Save project as...', callback,@(varargin)obj.saveProjectAs);
            m = uimenu(mh,'Label','Export', 'Separator','on');
%             uimenu(m,'Label','Data...',...
%                 callback, []);
            uimenu(m,'Label','Data to workspace',...
                callback, @obj.exportDataToWorkspace);
            uimenu(m,'Label','All sensors and corresponding groupings',...
                callback, @obj.exportAllSensorsAndCorrespondingGroupings);
            uimenu(m,'Label','All sensors and corresponding groupings to workspace',...
                callback, @obj.exportAllSensorsAndCorrespondingGroupingsToWorkspace);
            uimenu(m,'Label','Merged Features',...
                callback, @obj.exportMergedFeature);
            uimenu(m,'Label','Merged Features to workspace',...
                callback, @obj.exportMergedFeatureToWorkspace);
            uimenu(m,'Label','Model parameters (beta)',...
                callback, @obj.exportModelParameters);
            uimenu(m,'Label','Model parameters (beta) to workspace',...
                callback, @obj.exportModelParametersToWorkspace); 
            uimenu(m,'Label','Full model data',...
                callback, @obj.exportFullModelData);
            uimenu(m,'Label','Full model data to workspace',...
                callback, @obj.exportFullModelDataToWorkspace);
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
            
            mh = uimenu(f,'Label','Extract Plots');
            uimenu(mh,'Label','Default Plot',callback,@obj.openDefaultPlot);
            uimenu(mh,'Label','Square Plot',callback,@obj.openSquarePlot);
            uimenu(mh,'Label','Two Plots vertical Stack',callback,@obj.openDivPlotVertical);
            uimenu(mh,'Label','Scatter+Histogram Plot',callback,@obj.openScatterHistPlot);
            uimenu(mh,'Label','Very wide Plot',callback,@obj.openVeryWidePlot);
                        
            mainLayout = uigridlayout(f,[2 2]);
            mainLayout.RowHeight = {'3x','1x'};
            mainLayout.ColumnWidth = {'1x','7x'};
            
            bottomTable = uitable(mainLayout);
            bottomTable.Layout.Row = 2;
            bottomTable.Layout.Column = [1 2];

            cm = uicontextmenu();
            m1 = uimenu(cm,'Text','Set all sensors active',...
                'MenuSelectedFcn',@(src,event) m1clickedCallback(obj));
            m2 = uimenu(cm,'Text','Set all sensors inactive',...
                'MenuSelectedFcn',@(src,event) m2clickedCallback(obj));
            m3 = uimenu(cm,'Text','Toggle current track active/inactive (all clusters and sensors)','Separator','on',...
                 'MenuSelectedFcn',@(src,event) m3clickedCallback(obj));
            m4 = uimenu(cm,'Text','Toggle current cluster active/inactive (all sensors)',...
                'MenuSelectedFcn',@(src,event) m4clickedCallback(obj));
            m5 = uimenu(cm,'Text','Toggle current sensor active/inactive in all clusters (same track)',...
                 'MenuSelectedFcn',@(src,event) m5clickedCallback(obj));
            m6 = uimenu(cm,'Text','Copy Preproc. chain and Feat.Def. set of current sensor to all clusters (same sensor name, same track)','Separator','on',...
                 'MenuSelectedFcn',@(src,event) m6clickedCallback(obj));
            bottomTable.ContextMenu = cm;

            
            modulesSidebar = uigridlayout(mainLayout,...
                [numel(obj.moduleNames) 1],...
                'Padding',[0 0 0 0]);
            modulesSidebar.Layout.Row = 1;
            modulesSidebar.Layout.Column = 1;
            
            module = uipanel(mainLayout,'BorderType','none');
            module.Layout.Row = 1;
            module.Layout.Column = 2;
%             
            obj.sensorSetTable = bottomTable;
            
            obj.modulePanel = module;
            obj.moduleSidebar = modulesSidebar;
            
            % load modules
            for i = 1:numel(obj.moduleNames)
                m = feval(obj.moduleNames{i},obj);
                [moduleLayout,moduleMenu] = m.makeLayout(module,f);
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
            
            close(prog)
            delete(proxyF)
            
            obj.hFigure.Visible = 'on';
        end
 
       
        function m1clickedCallback(obj)
                selSensor = obj.project.getCurrentSensor();
                state = true; % true fest vorgeben
                clusters = obj.project.clusters();

                for cidx=1:numel(clusters)
                    for sidx=1:numel(obj.project.clusters(cidx).sensors())
                        newSensor = obj.project.clusters(cidx).sensors(sidx);
                        newSensor.setActive(state); 
                    end
                end
                selSensor.setCurrent();
                obj.populateSensorSetTable();
        end
        
        function m2clickedCallback(obj)
                selSensor = obj.project.getCurrentSensor();
                state = false; %false fest vorgeben
                clusters = obj.project.clusters();

                for cidx=1:numel(clusters)
                    for sidx=1:numel(obj.project.clusters(cidx).sensors())
                        newSensor = obj.project.clusters(cidx).sensors(sidx);
                        newSensor.setActive(state); 
                    end
                end
                selSensor.setCurrent();
                obj.populateSensorSetTable();
        end
        
        function m3clickedCallback(obj)
                selSensor = obj.project.getCurrentSensor();
                selTrack = selSensor.cluster.track;
                state = selSensor.isActive();
                clusters = obj.project.clusters();
                
                for cidx=1:numel(clusters)
                    if strcmp(clusters(cidx).track, selTrack)
                        for sidx=1:numel(obj.project.clusters(cidx).sensors())
                            newSensor = obj.project.clusters(cidx).sensors(sidx);
                            newSensor.setActive(~state);
                        end
                    end
                end
                selSensor.setCurrent();
                obj.populateSensorSetTable();
        end
        
        function m4clickedCallback(obj)
                selSensor = obj.project.getCurrentSensor();
                selCluster = selSensor.cluster;
                state = selSensor.isActive();
                
                for sidx=1:numel(selCluster.sensors())
                    newSensor = selCluster.sensors(sidx);
                    newSensor.setActive(~state);
                end
                selSensor.setCurrent();
                obj.populateSensorSetTable();
        end

        function m5clickedCallback(obj)
                selSensor = obj.project.getCurrentSensor();
                selTrack = selSensor.cluster.track;
                state = selSensor.isActive();
                clusters = obj.project.clusters();
                
                for cidx=1:numel(clusters)
                    for sidx=1:numel(obj.project.clusters(cidx).sensors())
                        if strcmp(clusters(cidx).sensors(sidx).caption, selSensor.caption) ...
                                && strcmp(clusters(cidx).track, selTrack)
                            newSensor = obj.project.clusters(cidx).sensors(sidx);
                            newSensor.setActive(~state);
                        end
                    end
                end
                selSensor.setCurrent();
                obj.populateSensorSetTable();
        end

        function m6clickedCallback(obj)
            selSensor = obj.project.getCurrentSensor();
            selTrack = selSensor.cluster.track;
            selPPC = obj.project.currentPreprocessingChain;
            selFDS = obj.project.currentFeatureDefinitionSet;
            clusters = obj.project.clusters();
            
            for cidx=1:numel(clusters)
                for sidx=1:numel(obj.project.clusters(cidx).sensors())
                    if strcmp(clusters(cidx).sensors(sidx).caption, selSensor.caption) ...
                            && strcmp(clusters(cidx).track, selTrack)
                        newSensor = obj.project.clusters(cidx).sensors(sidx);
                        newSensor.preprocessingChain = selPPC;
                        newSensor.featureDefinitionSet = selFDS;
                    end
                end
            end
            selSensor.setCurrent();
            obj.populateSensorSetTable();
        end

        function importGasmixerFile(obj,varargin)
            prog = uiprogressdlg(obj.hFigure,'Title','Import cycle ranges and groupings',...
                'Indeterminate','on');
            drawnow
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
            close(prog)
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
            % swap invisible shortly to regain window focus after
            % uiputfile
            obj.hFigure.Visible = 'off';
            obj.hFigure.Visible = 'on';
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
            msg = 'Click a plot, then Ok';
            uialert(obj.hFigure,msg,'Plot Extraction: Default','Icon','info',...
                'Modal',false,'CloseFcn',@(Fig,Struct)extractAxDefault(Fig))
        end
        
        function openSquarePlot(obj,varargin)
            msg = 'Click a plot, then Ok';
            uialert(obj.hFigure,msg,'Plot Extraction: Square','Icon','info',...
                'Modal',false,'CloseFcn',@(Fig,Struct)extractAxSquare(Fig))
        end
        
        function openDivPlotVertical(obj,varargin)
            msg = 'Click first plot, then Ok';
            uialert(obj.hFigure,msg,'Plot Extraction: vert. Stack','Icon','info',...
                'Modal',false,'CloseFcn',@(Fig,Struct)extractAxStacked(Fig))
        end
        
        function openScatterHistPlot(obj,varargin)
            msg = 'Click center plot, then Ok';
            uialert(obj.hFigure,msg,'Plot Extraction: Scatter+Hist','Icon','info',...
                'Modal',false,'CloseFcn',@(Fig,Struct)extractAxScatterHist(Fig))
        end
        
        function openVeryWidePlot(obj,varargin)
            msg = 'Click a plot, then Ok';
            uialert(obj.hFigure,msg,'Plot Extraction: Very wide','Icon','info',...
                'Modal',false,'CloseFcn',@(Fig,Struct)extractAxVeryWide(Fig))
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
            if isempty(obj.getActiveModule().getProject())
                obj.project = Project();
            end
            vars = evalin('base','who');
            [sel,ok] = Gui.Dialogs.Select('ListItems',vars);
            if ~ok
                return
            end
            for i = 1:numel(sel)
                data = evalin('base',sel{i});
                if ~isnumeric(data)
                    warning('Format of variable %s not supported.',sel{i});
                    continue
                end
                c = Cluster('samplingPeriod',1,...
                    'nCyclePoints',size(data,2),...
                    'nCycles',size(data,1),...
                    'caption',sel{i});        

                sensordata = SensorData.Memory(data);
                sensor = Sensor(sensordata,'caption',sel{i});
                c.addSensor(sensor);
                %when there is no project, create one
                if isempty(obj.project)
                    obj.project = Project();
                end
                obj.project.addCluster(c);
            end
            obj.populateSensorSetTable();
        end
        
        function exportDataToWorkspace(obj,varargin)
            sensors = obj.project.getSensors();
            [sel,ok] = Gui.Dialogs.Select('ListItems',sensors.getCaption('cluster'));
            if ~ok
                return
            end
            for i = 1:numel(sel)
                s = matlab.lang.makeValidName(sel{i});
                assignin('base',s,sensors(ismember(sensors.getCaption('cluster'),sel{i})).data);
            end
        end
        
        function exportFullModelDataToWorkspace(obj,varargin)
            fullModelData = struct(obj.project.currentModel.fullModelData);
            assignin('base', 'fullModelData',fullModelData);
        end
        
        function exportFullModelData(obj,varargin)
            [file,path] = uiputfile({'*.mat'},'Save full model data');
            % swap invisible shortly to regain window focus after
            % uiputfile
            obj.hFigure.Visible = 'off';
            obj.hFigure.Visible = 'on';
            if file == 0
                return
            end
            filename = fullfile(path, file);
            fullModelData = struct(obj.project.currentModel.fullModelData);
            save(filename,'fullModelData')
        end

        function exportModelParameters(obj,varargin)
            [file,path] = uiputfile({'*.mat'},'Save model parameters');
            % swap invisible shortly to regain window focus after
            % uiputfile
            obj.hFigure.Visible = 'off';
            obj.hFigure.Visible = 'on';
            if file == 0
                return
            end
            fullModelData = struct(obj.project.currentModel.fullModelData);
            processingChain = struct(obj.project.currentModel.processingChain);

            for i = 1:numel(processingChain.blocks)
                for j = 1:numel(processingChain.blocks(i).parameters)
                    blocks = processingChain.blocks(i);
                    param = processingChain.blocks(i).parameters(j);
                    blocks_caption = matlab.lang.makeValidName(func2str(blocks.infoFcn));
                    param_caption = matlab.lang.makeValidName(param.caption);
                    parameters.(blocks_caption).(param_caption) = struct(param);
                end
            end

            nClusters = numel(obj.project.clusters);
            for i = 1:nClusters
                nSensors = numel(obj.project.clusters(1, i).sensors);
                for j = 1:nSensors
                    samplingPeriod.(obj.project.clusters(1, i).sensors(1, j).caption) = obj.project.clusters(1, i).sensors(1, j).cluster.samplingPeriod;
                end
            end
            fullModelData.samplingPeriod = samplingPeriod;

            filename = fullfile(path, file);
            save(filename, 'fullModelData', 'parameters')
        end

        function exportModelParametersToWorkspace(obj,varargin)
            fullModelData = struct(obj.project.currentModel.fullModelData);
            processingChain = struct(obj.project.currentModel.processingChain);

            for i = 1:numel(processingChain.blocks)
                for j = 1:numel(processingChain.blocks(i).parameters)
                    blocks = processingChain.blocks(i);
                    param = processingChain.blocks(i).parameters(j);
                    blocks_caption = matlab.lang.makeValidName(func2str(blocks.infoFcn));
                    param_caption = matlab.lang.makeValidName(param.caption);
                    parameters.(blocks_caption).(param_caption) = struct(param);
                end
            end

            nClusters = numel(obj.project.clusters);
            for i = 1:nClusters
                nSensors = numel(obj.project.clusters(1, i).sensors);
                for j = 1:nSensors
                    samplingPeriod.(obj.project.clusters(1, i).sensors(1, j).caption) = obj.project.clusters(1, i).sensors(1, j).cluster.samplingPeriod;
                end
            end
            fullModelData.samplingPeriod = samplingPeriod;

            assignin('base', 'fullModelData',fullModelData);
            assignin('base', 'parameters',parameters);
        end
        
        function exportMergedFeatureToWorkspace(obj,varargin)
            mergeFeature = struct(obj.project.mergeFeatures);
            assignin('base', 'mergeFeature',mergeFeature);
        end
        
        function exportMergedFeature(obj,varargin)
            [file,path] = uiputfile({'*.mat'},'Save full model data');
            % swap invisible shortly to regain window focus after
            % uiputfile
            obj.hFigure.Visible = 'off';
            obj.hFigure.Visible = 'on';
            if file == 0
                return
            end
            filename = fullfile(path, file);
            mergeFeature = struct(obj.project.mergeFeatures);
            save(filename,'mergeFeature')
        end

        function exportAllSensorsAndCorrespondingGroupings(obj,varargin)
            [file,path] = uiputfile({'*.mat'},'Save all sensors and correspondig groupings');
            % swap invisible shortly to regain window focus after
            % uiputfile
            obj.hFigure.Visible = 'off';
            obj.hFigure.Visible = 'on';
            if file == 0
                return
            end
            filename = fullfile(path, file);
           
            prog = uiprogressdlg(obj.hFigure,'Title','Saving all sensors and corresponding groupings',...
                'Indeterminate','on');
            drawnow

            prj = obj.project;

            % get grouping captions
            for h = 1:numel(prj.groupings)
                target_captions(h,1) = prj.groupings(h).caption;
            end
            
            target_captions = matlab.lang.makeValidName(target_captions);
            
            sensor_names = string([]);
            % get cluster and sensor captions
            for i = 1:numel(prj.clusters)
                clusters(i) = prj.clusters(i).caption;
                offset_order(i) = prj.clusters(i).offset;
                for j = 1:numel(prj.clusters(i).sensors)
                    sensor_names(end+1) = prj.clusters(i).sensors(j).caption;
                end
            end
            sensor_names = unique(sensor_names);
            
            % sort clusters to offset, if they are imported disordered
            [~, idx] = sort(offset_order);
            clusters_sorted = clusters(idx);
            
            sensor = cell2struct(cell(1, numel(sensor_names)), sensor_names, 2);
            
            % iterate over sensors first 
            for k = 1:numel(sensor_names)
                target.(sensor_names(k)) = cell2struct(cell(1, numel(target_captions)), target_captions, 2);
                % then iterate over cluster per sensor - to merge cluster for one sensor
                for l = 1:numel(clusters_sorted)
                    cluster = getClusterByCaption(prj, clusters_sorted(l));
                    if ~isempty(getSensorByCaption(cluster, sensor_names(k)))
                            sval = getSensorByCaption(cluster, sensor_names(k));
                            preComputePreprocessedData(sval)
                            sensor.(sensor_names(k)) = [sensor.(sensor_names(k)); sval.ppData];
                            for m = 1:numel(prj.groupings)
                                tval = prj.groupings(m).getTargetVector(cluster.getCycleRanges(),cluster);
                                target.(sensor_names(k)).(target_captions(m)) = [target.(sensor_names(k)).(target_captions(m)); str2double(strrep(string(tval),'*',''))];
                            end
                    end
                end
            end
            save(filename,'sensor','target','-v7.3')

            close(prog)
        end

        function exportAllSensorsAndCorrespondingGroupingsToWorkspace(obj,varargin)        
            prog = uiprogressdlg(obj.hFigure,'Title','Saving all sensors and corresponding groupings to workspace',...
                'Indeterminate','on');
            drawnow

            prj = obj.project;

            % get grouping captions
            for h = 1:numel(prj.groupings)
                target_captions(h,1) = prj.groupings(h).caption;
            end
            
            target_captions = matlab.lang.makeValidName(target_captions);
            
            sensor_names = string([]);
            % get cluster and sensor captions
            for i = 1:numel(prj.clusters)
                clusters(i) = prj.clusters(i).caption;
                offset_order(i) = prj.clusters(i).offset;
                for j = 1:numel(prj.clusters(i).sensors)
                    sensor_names(end+1) = prj.clusters(i).sensors(j).caption;
                end
            end
            sensor_names = unique(sensor_names);
            
            % sort clusters to offset, if they are imported disordered
            [~, idx] = sort(offset_order);
            clusters_sorted = clusters(idx);
            
            sensor = cell2struct(cell(1, numel(sensor_names)), sensor_names, 2);
            
            % iterate over sensors first 
            for k = 1:numel(sensor_names)
                target.(sensor_names(k)) = cell2struct(cell(1, numel(target_captions)), target_captions, 2);
                % then iterate over cluster per sensor - to merge cluster for one sensor
                for l = 1:numel(clusters_sorted)
                    cluster = getClusterByCaption(prj, clusters_sorted(l));
                    if ~isempty(getSensorByCaption(cluster, sensor_names(k)))
                            sval = getSensorByCaption(cluster, sensor_names(k));
                            preComputePreprocessedData(sval)
                            sensor.(sensor_names(k)) = [sensor.(sensor_names(k)); sval.ppData];
                            for m = 1:numel(prj.groupings)
                                tval = prj.groupings(m).getTargetVector(cluster.getCycleRanges(),cluster);
                                target.(sensor_names(k)).(target_captions(m)) = [target.(sensor_names(k)).(target_captions(m)); str2double(strrep(string(tval),'*',''))];
                            end
                    end
                end
            end

            assignin('base', 'sensor',sensor);
            assignin('base', 'target',target);

            close(prog)
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
            prog = uiprogressdlg(obj.hFigure,'Title','Changing module',...
                'Indeterminate','on');
            drawnow
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
            obj.moduleSidebar.Children(i).FontWeight = 'bold';
            close(prog)
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
            widths = {'1x','4x','4x','4x','4x'};
            
            obj.sensorSetTable.Data = data;
            obj.sensorSetTable.RowName = 'numbered';
            obj.sensorSetTable.ColumnName = vars;
            obj.sensorSetTable.ColumnWidth = widths;
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
                if isempty(event.Indices) 
                    return
                else
                    row = event.Indices(1);
                    newSensor = sensors(row);
                    prevSensor = obj.project.getCurrentSensor();
                    prevCluster = prevSensor.getCluster();
                end
                
                newSensor.setCurrent();
                newSensor.getCluster().setCurrent();
                removeStyle(obj.sensorSetTable);                           % Clear marking of previously selected Row                
                style = uistyle("BackgroundColor",[51,153,255]./256);       
                addStyle(src,style,"Row",row);                             % apply marking of newly selected Row

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
            selection = uiconfirm(obj.hFigure,...
                'All unsaved changes in the current project will be lost. Proceed?',...
                'Confirm new project','Icon','warning',...
                'Options',{'Yes, Overwrite','No, Cancel'},...
                'DefaultOption',2,'CancelOption',2);
            switch selection
                case 'No, Cancel'
                    return
                case 'Yes, Overwrite'
                    obj.setModule(1);                   % set active Module to 'Start' to avoid Errors
                    
                    obj.project = Project();

                    obj.populateSensorSetTable();
                    for i = 1:numel(obj.modules)
                        obj.modules(i).reset();
                    end
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
                % swap invisible shortly to regain window focus after
                % uiputfile
                obj.hFigure.Visible = 'off';
                obj.hFigure.Visible = 'on';
                if file == 0
                    return
                end
                oldPath = path;
            end
            
            prog = uiprogressdlg(obj.hFigure,'Title','Saving project',...
                'Indeterminate','on');
            drawnow
            
            project = obj.project; %#ok<NASGU,PROPLC>
            save(fullfile(path,file),'project','-v7.3');
            obj.projectPath = path;
            obj.projectFile = file;
            
            close(prog)
        end
        
        function loadProject(obj)
            persistent oldPath
            if ~exist('oldPath','var')
                oldPath = pwd;
            end
            
            [file,path] = uigetfile({'*.dave','DAV³E project'},'Choose project file',oldPath);
            % swap invisible shortly to regain window focus after
            % uigetfile
            obj.hFigure.Visible = 'off';
            obj.hFigure.Visible = 'on';
            if file == 0
                return
            end
            oldPath = path;
            
            prog = uiprogressdlg(obj.hFigure,'Title','Loading project',...
                'Indeterminate','on');
            drawnow
            
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
            obj.modulePanel.Children(1).Visible = 1;
            obj.modules(1).onOpen();
            obj.moduleSidebar.Children(1).FontWeight = 'bold';
            
%             obj.modulePanel.SelectedChild = 1;
%             obj.modules(1).onOpen();
%             [obj.moduleSidebar.Children.FontWeight] = deal('normal');
%             obj.moduleSidebar.Children(end).FontWeight = deal('bold');
            
            close(prog)
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