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

classdef FeatureDefinition < Gui.Modules.GuiModule
    properties
        caption = 'FeatureDefinition'
        
%         currentFeatureDefinitionSet = FeatureDefinitionSet.empty;
        currentFeatureDefinition
        ranges = GraphicsRange.empty;
        
        cycleLines
        previewLines
        
        hAxPreview
        hAxCycle
        
        featurePreviewX
        featurePreviewY
        
        rangeTable
        propGrid
        setDropdown

        copiedRangeInfo
    end
    
    properties (Dependent)
        currentFeatureDefinitionSet
    end    
    
    methods
        function obj = FeatureDefinition(main)
            %% constructor
            obj@Gui.Modules.GuiModule(main);
        end
        
        function delete(obj)
            delete(obj.rangeTable);
        end
        
        function reset(obj)
            reset@Gui.Modules.GuiModule(obj);
            obj.rangeTable.clear();
            obj.propGrid.clear();
            delete(obj.ranges);
            obj.ranges = GraphicsRange.empty;
            delete(obj.cycleLines);
            delete(obj.previewLines);
        end
        
        function [newData,newOffsets] = insertNanAtOffsetSteps(obj,data,offsets)
            do = diff(offsets);
            steps = find(do > mean(do));
            steps([2;diff(steps)]==1) = [];
            newData = [data; nan(2*numel(steps),size(data,2))];
            newOffsets = [offsets; nan(2*numel(steps),1)];
            steps(end+1) = size(data,1);
            for i = numel(steps)-1:-1:1
                newData((steps(i)+1:steps(i+1))+2*i,:) = newData(steps(i)+1:steps(i+1),:);
                newOffsets((steps(i)+1:steps(i+1))+2*i,:) = newOffsets(steps(i)+1:steps(i+1),:);
                newData(steps(i) - [1 0] + 2*i,:) = nan;
                newOffsets(steps(i) - [1 0] + 2*i,:) = nan;
            end            
        end
        
        function onClickMenuPlotFeaturesOverTime(obj)
            if isempty(obj.getProject().mergedFeatureData)
                errordlg('No features to plot.');
                return
            end
            figure; axes;
            d = obj.getProject().mergedFeatureData;
            data = d.data;
%             [data,offsets] = obj.insertNanAtOffsetSteps(data,d.offsets);
            offsets = (1:size(data,1))';
            plot(repmat(offsets,1,size(data,2)),data);
            l = legend(d.featureCaptions,'Interpreter','none');
            l.ItemHitFcn = @obj.legendCallback;
            xlabel('time / s'); ylabel('feature / a.u.');
        end
        
        function onClickMenuPlotFeaturesOverTimeStandardized(obj)
            if isempty(obj.getProject().mergedFeatureData)
                errordlg('No features to plot.');
                return
            end
            figure; axes;
            d = obj.getProject().mergedFeatureData;
            data = (d.data - mean(d.data)) ./ std(d.data);
%             [data,offsets] = obj.insertNanAtOffsetSteps(data,d.offsets);
            offsets = (1:size(data,1))';
            plot(repmat(offsets,1,size(data,2)),data);
            l = legend(d.featureCaptions,'Interpreter','none');
            l.ItemHitFcn = @obj.legendCallback;
            xlabel('time / s'); ylabel('feature / a.u.');
        end
        
        function legendCallback(obj,src,evt)
            if strcmp(evt.Peer.Visible,'on')
                evt.Peer.Visible = 'off';
            else 
                evt.Peer.Visible = 'on';
            end
        end
               
        function onClickMenuComputeFeatures(obj)
            success = true;
            sb = statusbar(obj.main.hFigure, 'Computing features...');
            set(sb.ProgressBar, 'Visible',false, 'Indeterminate',true);
            try
                features = obj.getProject().computeFeatures();
            catch ME
                errordlg(sprintf('Could not compute features.\n %s', ME.message),'WindowStyle','modal');
                success = false;
            end
            try
                features = obj.getProject().mergeFeatures();
            catch ME
                errordlg(sprintf('Could not merge features.\n %s', ME.message),'WindowStyle','modal');
                success = false;
            end
%             features.featureCaptions'
            sb = statusbar(obj.main.hFigure, 'Ready.');
            set(sb.ProgressBar, 'Visible',false, 'Indeterminate',false);
        end
        
        function [panel,menu] = makeLayout(obj)
            %%
            panel = Gui.Modules.Panel();
            
            menu = uimenu('Label','FeatureDefinition');
            uimenu(menu,'Label','plot features over time', getMenuCallbackName(),@(varargin)obj.onClickMenuPlotFeaturesOverTime);
            uimenu(menu,'Label','plot features over time (standardized)', getMenuCallbackName(),@(varargin)obj.onClickMenuPlotFeaturesOverTimeStandardized);
            uimenu(menu,'Label','compute features', getMenuCallbackName(),@(varargin)obj.onClickMenuComputeFeatures);
            uimenu(menu,'Label','copy all ranges',getMenuCallbackName(),@(varargin)obj.copyRangesCallback);
            uimenu(menu,'Label','paste all ranges',getMenuCallbackName(),@(varargin)obj.pasteRangesCallback);
            
            layout = uiextras.HBox('Parent',panel);
            leftLayout = uiextras.VBox('Parent',layout);
            axesLayout = uiextras.VBox('Parent',layout, 'Spacing',5, 'Padding',5);
            
            defsPanel = Gui.Modules.Panel('Parent',leftLayout, 'Title','feature definitions', 'Padding',5);
            tablePanel = Gui.Modules.Panel('Parent',leftLayout, 'Title','feature ranges', 'Padding',5);
            
            propGridLayout = uiextras.VBox('Parent',defsPanel);
            
            % feature definition set dropdown
            obj.setDropdown = Gui.EditableDropdown(propGridLayout);
            obj.setDropdown.AppendClickCallback = @obj.dropdownNewFeatureDefinitionSet;
            obj.setDropdown.RemoveClickCallback = @obj.dropdownRemoveFeatureDefinitionSet;
            obj.setDropdown.EditCallback = @obj.dropdownFeatureDefinitionSetRename;
            obj.setDropdown.SelectionChangedCallback = @obj.dropdownFeatureDefinitionSetChange;
            
            % prop grid
            obj.propGrid = PropGrid(propGridLayout);
            obj.propGrid.setShowToolbar(false);
            propGridControlsLayout = uiextras.HBox('Parent',propGridLayout);
            uicontrol(propGridControlsLayout,'String','add', 'Callback',@(h,e)obj.addFeatureDefinition);
            uicontrol(propGridControlsLayout,'String','delete', 'Callback',@(h,e)obj.removeFeatureDefinition);
            uicontrol(propGridControlsLayout,'String','/\');
            uicontrol(propGridControlsLayout,'String','\/');
            propGridLayout.Sizes = [30,-1,20];

            obj.hAxPreview = axes(axesLayout); title('feature preview');
            xlabel('time / s'); ylabel('features / a.u.');% yyaxis right, ylabel('raw data / a.u.');
            box on, 
            set(gca,'LooseInset',get(gca,'TightInset')) % https://undocumentedmatlab.com/blog/axes-looseinset-property
            
            obj.hAxCycle = axes(axesLayout); title('cycles with grouping colors');
            xlabel('time / s'); ylabel('data / a.u.');% yyaxis right, ylabel('raw data / a.u.');
            box on
            set(gca,'LooseInset',get(gca,'TightInset'))
            
            obj.hAxCycle.ButtonDownFcn = @obj.axesButtonDownCallback;

            tableLayout = uiextras.VBox('Parent',tablePanel);
            obj.rangeTable = JavaTable(tableLayout);
            tableControlsLayout = uiextras.HBox('Parent',tableLayout);
            uicontrol(tableControlsLayout,'String','add', 'Callback',@(h,e)obj.addRange);
            uicontrol(tableControlsLayout,'String','delete', 'Callback',@(h,e)obj.removeRange);
            tableLayout.Sizes = [-1,20];
            
            layout.Sizes = [-1,-3];
            leftLayout.Sizes = [-1,-1];
        end

        function copyRangesCallback(obj)
            obj.copiedRangeInfo = obj.ranges.getObject().toStruct();
        end
        
        function pasteRangesCallback(obj)
            if isempty(obj.copiedRangeInfo)
                return;
            end
            r = Range.fromStruct(obj.copiedRangeInfo);
            obj.addRange([],r);
        end
        
        function scrollWheelCallback(obj,~,e)
            dir = e.VerticalScrollCount;
            p = get(gca,'CurrentPoint');
            x = p(1,1); y = p(1,2); ylimits = ylim;
            pos = obj.ranges.getPosition();
            onRange = (x >= pos(:,1)) & (x <= pos(:,2));
            inYLimits = (y >= ylimits(1)) && (y <= ylimits(2));
            if ~inYLimits || ~any(onRange)
                return
            end
            affectedRanges = obj.ranges(onRange);
            for i = 1:numel(affectedRanges)
                r = affectedRanges(i);
                obj.cycleRangeDragStartCallback(r);
                oldPos = r.getObject().getIndexPosition(obj.getCurrentSensor());
                r.getObject().setIndexPosition(oldPos - dir*[-1 1],obj.getCurrentSensor());
                r.updatePosition(obj.getCurrentSensor());
                obj.rangeDraggedCallback(r);
                obj.cycleRangeDragStopCallback(r);
            end
        end

        function val = get.currentFeatureDefinitionSet(obj)
            val = obj.getProject().getCurrentSensor().featureDefinitionSet;
        end
        
        function set.currentFeatureDefinitionSet(obj,val)
            obj.getProject().getCurrentSensor().featureDefinitionSet = val;
        end
        
        function fds = addFeatureDefinition(obj,desc)
            if nargin < 2
                fe = FeatureDefinitionSet.getAvailableMethods(true);
                s = keys(fe);
                [sel,ok] = listdlg('ListString',s);
                if ~ok
                    return
                end
            else
                sel = {desc};
            end
            
            fds = FeatureDefinition.empty;
            for i = 1:numel(sel)
                fcn = fe(s{sel(i)});
                fd = FeatureDefinition(fcn);
                obj.currentFeatureDefinitionSet.addFeatureDefinition(fd);
                fds(end+1) = fd;
            end
            obj.propGrid.clear();
            pgf = obj.currentFeatureDefinitionSet.makePropGridFields();
            obj.propGrid.addProperty(pgf);
            [pgf.onMouseClickedCallback] = deal(@obj.propGridFieldClickedCallback);
            obj.changeFeatureDefinition(fds(end));
        end
        
        function removeFeatureDefinition(obj,fd)
            if nargin < 2
                fds = obj.currentFeatureDefinitionSet.getFeatureDefinitions();
                [sel,ok] = listdlg('ListString',fds.getCaption());
                if ~ok
                    return
                end
                fd = fds(sel);
            end
            obj.currentFeatureDefinitionSet.removeFeatureDefinition(fd);
            obj.deleteRangeDrawings();
            
            fds = obj.currentFeatureDefinitionSet.getFeatureDefinitions();
            if numel(fds) > 0
                if isempty(obj.currentFeatureDefinition) || ~any(fds==obj.currentFeatureDefinition)
                    obj.changeFeatureDefinition(fds(1));
                end
            else
                obj.currentFeatureDefinition = FeatureDefinition.empty;
            end
            
            obj.propGrid.clear();
            pgf = obj.currentFeatureDefinitionSet.makePropGridFields();
            obj.propGrid.addProperty(pgf);
            [pgf.onMouseClickedCallback] = deal(@obj.propGridFieldClickedCallback);
        end
        
        function handleFeatureDefinitionSetChange(obj)
            fds = obj.currentFeatureDefinitionSet;
            obj.propGrid.clear();
            pgf = obj.currentFeatureDefinitionSet.makePropGridFields();
            obj.propGrid.addProperty(pgf);
            [pgf.onMouseClickedCallback] = deal(@obj.propGridFieldClickedCallback);
            fdefs = fds.getFeatureDefinitions();
            if ~isempty(fdefs)
                obj.changeFeatureDefinition(fdefs(1));
            else
                obj.changeFeatureDefinition(FeatureDefinition.empty);
            end
        end
        
        function dropdownNewFeatureDefinitionSet(obj,h)
            fds = obj.getProject().addFeatureDefinitionSet();
            obj.currentFeatureDefinitionSet = fds;
            h.appendItem(fds.getCaption());
            h.selectLastItem();
            obj.handleFeatureDefinitionSetChange();
            obj.main.populateSensorSetTable();
        end
        
        function dropdownRemoveFeatureDefinitionSet(obj,h)
            idx = h.getSelectedIndex();
            fdss = obj.getProject().poolFeatureDefinitionSets;
            fds = fdss(idx);
            sensorsWithFds = obj.getProject().checkForSensorsWithFeatureDefinitionSet(fds);
            
            if numel(sensorsWithFds) > 1  % the current sensor always has the FDS to delete
                choices = {};
                if numel(fdss) > 1
                    choices{1} = 'Choose a replacement';
                end
                choices{end+1} = 'Replace with new';
                choices{end+1} = 'Cancel';
                answer = questdlg('The feature definition set is used in other sensors. What would you like to do?', ...
                    'Conflict', ...
                    choices{:},'Cancel');
                switch answer
                    case 'Choose a replacement'
                        fdss(idx) = [];
                        [sel,ok] = listdlg('ListString',fdss.getCaption(), 'SelectionMode','single');
                        if ~ok
                            return
                        end
                        obj.getProject().replaceFeatureDefinitionSetInSensors(fds,fdss(sel));
                        newFds = fdss(sel);
                    case 'Replace with new'
                        newFds = obj.getProject().addFeatureDefinitionSet();
                        h.appendItem(newFds.getCaption());
                        obj.getProject().replaceFeatureDefinitionSetInSensors(fds,newFds);
                    case 'Cancel'
                        return
                end
            else
                % if there is only one FDS, it will now be deleted
                % so we have to add a new one
                if numel(obj.getProject().poolFeatureDefinitionSets) == 1
                    newFds = obj.getProject().addFeatureDefinitionSet();
                    h.appendItem(newFds.getCaption());
                else
                    if idx == 1
                        newFds = obj.getProject().poolFeatureDefinitionSets(2);
                    else
                        newFds = obj.getProject().poolFeatureDefinitionSets(idx-1);
                    end
                end
            end

            obj.currentFeatureDefinitionSet = newFds;
            obj.getProject().removeFeatureDefinitionSet(fds);
                
            h.removeItemAt(idx);
            h.setSelectedItem(obj.currentFeatureDefinitionSet.getCaption());
            obj.handleFeatureDefinitionSetChange();
            obj.main.populateSensorSetTable();
        end
        
        function dropdownFeatureDefinitionSetRename(obj,h,newName,index)
            newName = matlab.lang.makeUniqueStrings(newName,obj.getProject().poolFeatureDefinitionSets.getCaption());
            obj.getProject().poolFeatureDefinitionSets(index).setCaption(newName);
            h.renameItemAt(newName,h.getSelectedIndex());
            obj.handleFeatureDefinitionSetChange();
            obj.main.populateSensorSetTable();
        end
        
        function dropdownFeatureDefinitionSetChange(obj,h,newItem,newIndex)
            obj.currentFeatureDefinitionSet = ...
                obj.getProject().poolFeatureDefinitionSets(newIndex);
            obj.handleFeatureDefinitionSetChange();
            obj.main.populateSensorSetTable();
        end        
        
        function axesButtonDownCallback(obj,varargin)
            %% Called when the mouse is clicked in the axes.
            % Adds a new range upon double-click.
            switch get(gcf,'SelectionType')
                case 'open' % double-click
                    coord = get(gca,'Currentpoint');
                    x = coord(1,1);
                    obj.addRange(x);
            end
        end        
        
        function addRange(obj,pos,ranges)
            if nargin < 2
                pos = 1;
            else
                pos = DataSelector.abscissaToIndex(pos,obj.getCurrentSensor());
            end
            fd = obj.currentFeatureDefinition;
            cc = obj.getProject().getCurrentCluster();
            iPos = [pos pos+floor(cc.nCyclePoints/10)];
            if isempty(fd)
                fd = obj.addFeatureDefinition();
                for i = 1:numel(fd)
                    r = cc.makeIndexRange(iPos);
                    fd(i).addRange(r);
                end
            else
                if nargin >= 3
                    r = ranges;
                else
                    r = cc.makeIndexRange(iPos);
                end
                obj.currentFeatureDefinition.addRange(r);
            end
            obj.drawRanges(r);
            obj.populateRangeTable(obj.ranges);
            obj.updateFeaturePreview();
        end
        
        function removeRange(obj)
            selectedRangeIDs = obj.rangeTable.jTable.getSelectedRows() + 1;
            gObjects = {};
            for i=1:numel(selectedRangeIDs)
                selectedRangeID = selectedRangeIDs(i);
                if selectedRangeID == 0
                    return
                end
                gObjects{i} = obj.rangeTable.getRowObjectsAt(selectedRangeID);
            end
            for i=1:numel(gObjects)
                deleteRangeCallback(obj,gObjects{i})
            end
        end

        function deleteRangeCallback(obj,gObject)
            %% Called upon right-click on a range to delete it.
            % in: gObject (graphical range)
            obj.currentFeatureDefinition.removeRange(gObject.getObject());
            obj.ranges(obj.ranges==gObject) = [];
            delete(gObject);
            obj.populateRangeTable(obj.ranges);
            obj.updateFeaturePreview();
        end        
        
        function propGridFieldClickedCallback(obj,pgf)
            obj.changeFeatureDefinition(pgf.getMatlabObj());
        end
        
        function changeFeatureDefinition(obj,fd)
            obj.currentFeatureDefinition = fd;
            obj.onFeatureDefinitionChanged(fd);
        end
        
        function onFeatureDefinitionChanged(obj,fd)
            obj.deleteRangeDrawings();
            obj.drawRanges();
            obj.populateRangeTable(obj.ranges);
            obj.updateFeaturePreview();
        end
        
        function ranges = drawRanges(obj,ranges)
            if nargin < 2
                ranges = obj.currentFeatureDefinition.getRanges();
            end
            ylimits = obj.getProject().getCurrentSensor().getDataMinMax(true);
            ylimits = ylimits + [-.1 .1] * diff(ylimits);
            ranges = ranges.makeGraphicsObject('index',true);
            ranges.draw(obj.hAxCycle,obj.getProject().getCurrentSensor(),ylimits);
            [ranges.getRange().onPositionChanged] = deal(@obj.cycleRangePositionChangedCallback);
            [ranges.onDraggedCallback] = deal(@obj.rangeDraggedCallback);
            [ranges.onDragStartCallback] = deal(@obj.cycleRangeDragStartCallback);
            [ranges.onDragStopCallback] = deal(@obj.cycleRangeDragStopCallback);
            [ranges.onDeleteRequestCallback] = deal(@obj.deleteRangeCallback);
            obj.ranges = [obj.ranges, ranges];
        end
        
        function deleteRangeDrawings(obj)
            if isempty(obj.ranges)
                return
            end
            [obj.ranges.getRange().onPositionChanged] = deal([]);
            delete(obj.ranges);
            obj.ranges = [];
        end
        
        function allowed = canOpen(obj)
            p = obj.getProject();
            if isempty(p) || isempty(p.getCurrentCluster()) || isempty(p.getCurrentSensor())
                allowed = false;
                errordlg('Load at least one sensor.');
            elseif isempty(obj.getProject().groupings)
                allowed = false;
                errordlg('Make at least one grouping.');
            else
                allowed = true;
            end
        end
        
        function onOpen(obj)
            if isempty(obj.lastSensor)
                linkaxes([obj.hAxPreview,obj.hAxCycle],'x');
            end
            if obj.clusterHasChanged()
                obj.handleClusterChange(obj.getProject().getCurrentCluster(),obj.lastCluster);
            end
            if obj.sensorHasChanged() || obj.groupingHasChanged()
                obj.handleSensorChange(obj.getProject().getCurrentSensor(),obj.lastSensor);
            end
            
            obj.setDropdown.setItems(obj.getProject().poolFeatureDefinitionSets.getCaption());
            obj.setDropdown.setSelectedItem(obj.currentFeatureDefinitionSet.getCaption());
            if obj.featureDefinitionSetHasChanged()
                obj.handleFeatureDefinitionSetChange();
            end
            
            % display the current grouping features are being computed for
            tCyc = 'cycles with grouping colors';
            tCyc = strcat(tCyc, {' of '''},...
                obj.getProject.currentGrouping.caption, {''''});
            obj.hAxCycle.Title.String = tCyc;
            set(obj.hAxCycle.Title,'Interpreter','none');
            
            tPre = 'feature preview';
            tPre = strcat(tPre, {' for '''},...
                obj.getProject.currentGrouping.caption, {''''});
            obj.hAxPreview.Title.String = tPre;
            set(obj.hAxPreview.Title,'Interpreter','none');
            
            obj.updateFeaturePreview();
            set(gcf,'WindowScrollWheelFcn',@obj.scrollWheelCallback);
        end
        
        function onClose(obj)
            onClose@Gui.Modules.GuiModule(obj);
            set(gcf,'WindowScrollWheelFcn',[]);
        end

        function handleClusterChange(obj,newCluster,oldCluster)
            delete(obj.cycleLines);
            obj.cycleLines = [];
            delete(obj.previewLines);
            obj.previewLines = [];
        end
        
        function handleSensorChange(obj,newSensor,oldSensor)
%             newSensor.getCaption()
            
            delete(obj.cycleLines);
            obj.cycleLines = [];
            delete(obj.previewLines);
            obj.previewLines = [];
            
            ylimits = newSensor.getDataMinMax(true);
            ylimits = ylimits + [-.1 .1] * diff(ylimits);
            if diff(ylimits) == 0
                ylimits(2) = ylimits(1) + 1;
            end

%             obj.getProject().sortCycleRanges();
%             obj.getProject().sortGroupings();
            dpb = DataProcessingBlock(@FeatureCycleAverage.groupAverage);
            [~,lineParams] = dpb.apply(newSensor.getDataObject(obj.getProject().currentGrouping));
            cClr = mat2cell(lineParams.color,ones(numel(lineParams.group),1),3);
            d = lineParams.data';
            
            if isempty(obj.cycleLines)
                abscissa = obj.getCurrentSensor().abscissa;
                x = repmat(abscissa',1,size(d,2));
                if numel(abscissa) == 1
                    abscissa = [-1 0] + abscissa;
                end
                hold(obj.hAxCycle,'on');
                obj.cycleLines = plot(obj.hAxCycle,x,d,'-k');
                xlim(obj.hAxCycle,[min(abscissa),max(abscissa)]);
                xlim(obj.hAxPreview,[min(abscissa),max(abscissa)]);
                hold(obj.hAxCycle,'off');
            else
                for i = 1:numel(obj.cycleLines)
                    obj.cycleLines(i).XData = obj.getCurrentSensor().abscissa;
                    obj.cycleLines(i).YData = d(:,i);
                end
            end
            
            if ~isempty(obj.getCurrentSensor().abscissaSensor)
                xlabel(obj.hAxCycle,obj.getCurrentSensor().abscissaSensor.getCaption());
                xlabel(obj.hAxPreview,obj.getCurrentSensor().abscissaSensor.getCaption());
            else
                xlabel(obj.hAxCycle,obj.getCurrentSensor().abscissaType);
                xlabel(obj.hAxPreview,obj.getCurrentSensor().abscissaType);
            end            
            
            l = [obj.cycleLines];
            [l.Color] = deal(cClr{:});

            % lines are invisible for mouse clicks; nice for moving ranges,
            % not so nice when interacting with the lines...
            % TODO: dynamically swtich on/off
            [l.HitTest] = deal('off');
            
%             if numel(obj.previewLines) ~= numel(obj.cycleLines)
            x = repmat([1;2],1,numel(obj.cycleLines));
            hold(obj.hAxPreview,'on');
            obj.previewLines = plot(obj.hAxPreview,x,x,'-k');
            hold(obj.hAxPreview,'off');
%             end
            
            l = [obj.previewLines];
            if ~isempty(l)
                [l.Color] = deal(cClr{:});
            end

            if ~isempty(oldSensor) && (oldSensor.featureDefinitionSet == newSensor.featureDefinitionSet)
                obj.ranges.updatePosition(newSensor);
                obj.ranges.setYLimits(ylimits);
            else
                obj.setDropdown.setSelectedItem(obj.currentFeatureDefinitionSet.getCaption());
%                 obj.handleFeatureDefinitionSetChange();
%                 fds = newSensor.featureDefinitionSet.getFeatureDefinitions();
%                 if numel(fds) > 0
%                     obj.changeFeatureDefinition(fds(1));
%                 else
%                     obj.changeFeatureDefinition(FeatureDefinition.empty);
% %                     obj.currentFeatureDefinition = FeatureDefinition.empty;
%                 end
%                 obj.deleteRangeDrawings()
%                 r = sensor.featureDefinitionSet.getRanges(obj.currentFeatureDefinition);
%                 obj.drawRanges(r);
%                 obj.populateRangeTable(obj.ranges);
            end
            
            obj.updateFeaturePreview();
        end
        
        function onCurrentClusterChanged(obj,cluster,oldCluster)
            obj.handleClusterChange(cluster,oldCluster);
        end
        
        function onCurrentSensorChanged(obj,sensor,oldSensor)
            obj.handleSensorChange(sensor,oldSensor);
        end
        
        function onCurrentPreprocessingChainChanged(obj,ppc)
            obj.handleSensorChange(obj.getProject().getCurrentSensor(),[]);
        end
        
        function onCurrentFeatureDefinitionSetChanged(obj,fsd)
            obj.handleFeatureDefinitionSetChange();
        end

        function populateRangeTable(obj,gRanges)
            %%
            % write data to the table, style and configure it, activate callbacks
            if isempty(gRanges)
                data = {};
            else
                captions = cellstr(gRanges.getRange().getCaption()');
                positions = num2cell(gRanges.getPosition());
    %             colors = num2cell(gRanges.getRange().getJavaColor());
                divs = num2cell(vertcat(gRanges.getRange().subRangeNum));
                forms = {gRanges.getRange().subRangeForm}';
                data = [captions, positions, divs, forms];  %colors];
            end

            t = obj.rangeTable;
            
            t.setData(data,{'caption','begin','end','divs','form'});
            t.setRowObjects(gRanges);
            t.setColumnClasses({'str','double','double','int',{'lin','log','invlog'}});
            t.setColumnsEditable([true true true true true true]);
            t.setSortingEnabled(false)
            t.setFilteringEnabled(false);
            t.setColumnReorderingAllowed(false);
            t.jTable.sortColumn(2);
            t.jTable.setAutoResort(false);
            obj.rangeTable.onDataChangedCallback = @obj.rangeTableDataChangeCallback;
            obj.rangeTable.onMouseClickedCallback = @obj.rangeTableMouseClickedCallback;
        end
        
        function updateFeaturePreview(obj)
            fd = obj.currentFeatureDefinition;
            if isempty(fd)
                delete(obj.previewLines);
                obj.previewLines = [];
%                 cla(obj.hAxPreview);
                return
            end
            x = nan(0);
            y = nan(numel(obj.previewLines),0);
            sensor = obj.getCurrentSensor();
            ydata = vertcat(obj.cycleLines.YData);
            
            r = fd.getRanges();
            for i = 1:numel(r)
                % the call to computeRaw is cached if nothing has changed
                [d,xPos] = fd.computeRaw(ydata,sensor,r(i));
                
                for j = 1:size(d,3)
                    xPos_ = [xPos, nan(size(xPos,1),1)]';
                    x = [x; xPos_(:)];
                    y = [y,d(:,:,j)];
                end
            end
            y = repelem(y,1,3);
            
            % get rid of feature offset for graphing
            for i = 1:size(y,2)
                y(:,i) = y(:,i) - nanmean(y(:,i));%zscore(y(:,i));
            end
            
            for i = 1:numel(obj.previewLines)
                obj.previewLines(i).XData = x;
                obj.previewLines(i).YData = y(i,:);
            end
        end
        
        function cycleRangePositionChangedCallback(obj,range,~)
            obj.updateFeaturePreview();
        end        
        
        function rangeDraggedCallback(obj,gRange)
            %%
            % update the position in the table when the point is dragged
            row = obj.rangeTable.getRowObjectRow(gRange);
            pos = gRange.getPosition();
            obj.rangeTable.setValue(pos(1),row,2);
            obj.rangeTable.setValue(pos(2),row,3);
        end
        
        function cycleRangeDragStartCallback(obj,gObj)
            %%
            % disable table callbacks (to omit "wrong" data changed events),
            % move the current selection to the corresponding row, and make
            % the corresponding cycle line bold
            obj.rangeTable.setCallbacksActive(false);
            objRow = obj.rangeTable.getRowObjectRow(gObj);
            obj.rangeTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
        end
        
        function cycleRangeDragStopCallback(obj,gObj)
            %%
            % re-enable table callbacks and set selection again (can get
            % messed up, probably due to dynamic sorting in the table?),
            % set cycle line width back to normal
            pause(0.01); % to make sure all callbacks have been processed
            objRow = obj.rangeTable.getRowObjectRow(gObj);
            obj.rangeTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
            obj.rangeTable.setCallbacksActive(true);
        end
        
        function rangeTableDataChangeCallback(obj,rc,v)
            %%
            % write changes from the table to the point object
            for i = 1:size(rc,1)
                o = obj.rangeTable.getRowObjectsAt(rc(i,1));
                switch rc(i,2)
                    case 1
                        o.getObject().setCaption(v{i});
                    case 2
                        o.setPosition([v{i} nan]);
                    case 3
                        o.setPosition([nan v{i}]);
                    case 4
                        o.getObject().setSubRangeNum(v{i});
                        o.updateSubRanges();
                        obj.updateFeaturePreview();
                    case 5
                        o.getObject().setSubRangeForm(v{i});
                        o.updateSubRanges();
                        obj.updateFeaturePreview();
                end
                pos = o.getPosition();
                obj.rangeTable.setValue(pos(1),rc(i,1),2);
                obj.rangeTable.setValue(pos(2),rc(i,1),3);
                obj.rangeTable.jTable.sortColumn(2);
            end
        end
                
        function rangeTableMouseClickedCallback(obj,visRC,actRC)
            %%
            % highlight the corresponding graphics object when the mouse
            % button is pressed on a table row
            o = obj.rangeTable.getRowObjectsAt(visRC(1));
            o.setHighlight(true);
            obj.rangeTable.onMouseReleasedCallback = @()obj.rangeTableMouseReleasedCallback(o);
        end
        
        function rangeTableMouseReleasedCallback(obj,gObject)
            %%
            % un-highlight the previously highlighted graphics object when
            % the mouse button is released again
            gObject.setHighlight(false);
            obj.rangeTable.onMouseReleasedCallback = [];
        end
    end
end