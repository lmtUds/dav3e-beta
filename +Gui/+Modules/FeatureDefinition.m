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
        selectedRanges
        
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
%             obj.rangeTable.clear();
            obj.rangeTable.Data = {};
            obj.rangeTable.UserData = {};
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
                uialert(obj.main.hFigure,'No Features to plot.','Features required');
                return
            end
            d = obj.getProject().mergedFeatureData;
            data = d.data;
            offsets = (1:size(data,1))';
%             [data,offsets] = obj.insertNanAtOffsetSteps(data,d.offsets);
            
            popOut = figure('Visible','off');
            ax = axes(popOut);
            plot(ax,repmat(offsets,1,size(data,2)),data);
            legend(ax,d.featureCaptions,'Interpreter','none',...
                'ItemHitFcn',@obj.legendCallback);
            xlabel(ax,'time / s'); ylabel(ax,'feature / a.u.');
            popOut.Visible = 'on';
        end
        
        function onClickMenuPlotFeaturesOverTimeStandardized(obj)
            if isempty(obj.getProject().mergedFeatureData)
                uialert(obj.main.hFigure,'No Features to plot.','Features required');
                return
            end
            d = obj.getProject().mergedFeatureData;
            data = (d.data - mean(d.data)) ./ std(d.data);
            offsets = (1:size(data,1))';
%             [data,offsets] = obj.insertNanAtOffsetSteps(data,d.offsets);
            
            popOut = figure('Visible','off');
            ax = axes(popOut);
            plot(ax,repmat(offsets,1,size(data,2)),data);
            legend(ax,d.featureCaptions,'Interpreter','none',...
                'ItemHitFcn',@obj.legendCallback);
            xlabel(ax,'time / s'); ylabel(ax,'feature / a.u.');
            popOut.Visible = 'on';
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
            prog = uiprogressdlg(obj.main.hFigure,'Title','Computing features',...
                'Indeterminate','on');
            drawnow
            try
                features = obj.getProject().computeFeatures();
            catch ME
                uialert(obj.main.hFigure,...
                        sprintf('Could not compute features.\n %s', ME.message),...
                        'Feature computation failed');
                success = false;
            end
            try
                features = obj.getProject().mergeFeatures();
            catch ME
                uialert(obj.main.hFigure,...
                        sprintf('Could not merge features.\n %s', ME.message),...
                        'Feature merge failed');
                success = false;
            end
%             features.featureCaptions'
            close(prog)
        end
                
        function [moduleLayout,moduleMenu] = makeLayout(obj,uiParent,mainFigure)
            %%
            moduleLayout = uigridlayout(uiParent,[2 2],...
                'Visible','off',...
                'Padding',[0 0 0 0],...
                'ColumnWidth',{'1x','4x'},...
                'RowHeight',{'1x','1x'},...
                'RowSpacing',7);
            
            moduleMenu = uimenu(mainFigure,'Label','FeatureDefinition');
            uimenu(moduleMenu,'Label','plot features over time', getMenuCallbackName(),@(varargin)obj.onClickMenuPlotFeaturesOverTime);
            uimenu(moduleMenu,'Label','plot features over time (standardized)', getMenuCallbackName(),@(varargin)obj.onClickMenuPlotFeaturesOverTimeStandardized);
            uimenu(moduleMenu,'Label','compute features', getMenuCallbackName(),@(varargin)obj.onClickMenuComputeFeatures);
            uimenu(moduleMenu,'Label','copy all ranges',getMenuCallbackName(),@(varargin)obj.copyRangesCallback);
            uimenu(moduleMenu,'Label','paste all ranges',getMenuCallbackName(),@(varargin)obj.pasteRangesCallback);
                        
            defsGrid = uigridlayout(moduleLayout, [4 4],...
                'ColumnWidth',{'2x','2x','1x','1x'},...
                'RowHeight',{'fit','fit','8x','fit'},...
                'RowSpacing',4,...
                'Padding',[4 4 4 4]);
            defsGrid.Layout.Row = 1;
            defsGrid.Layout.Column = 1;
            
            defsLabel = uilabel(defsGrid,...
                'Text','Feature definitions',...
                'FontWeight','bold');
            defsLabel.Layout.Row = 1;
            defsLabel.Layout.Column = [1 4];
            
            % feature definition set dropdown
            defsDropdown = uidropdown(defsGrid,...
                'Editable','on',...
                'ValueChangedFcn',@(src,event) obj.dropdownFeatureDefinitionSetCallback(src,event));
            defsDropdown.Layout.Row = 2;
            defsDropdown.Layout.Column = [1 2];
            
            obj.setDropdown = defsDropdown;
            
            defsAdd = uibutton(defsGrid,...
                'Text','+',...
                'ButtonPushedFcn',@(src,event) obj.dropdownNewFeatureDefinitionSet(src,event,defsDropdown));
            defsAdd.Layout.Row = 2;
            defsAdd.Layout.Column = 3;
            
            defsRem = uibutton(defsGrid,...
                'Text','-',...
                'ButtonPushedFcn',@(src,event) obj.dropdownRemoveFeatureDefinitionSet(src,event,defsDropdown));
            defsRem.Layout.Row = 2;
            defsRem.Layout.Column = 4;
            
            propGrid = Gui.uiParameterBlockGrid('Parent',defsGrid,...'ValueChangedFcn',@(src,event) obj.onParameterChangedCallback(src,event),...
                'SelectionChangedFcn',@(src,event) obj.propGridFieldClickedCallback(src,event),...
                'SizeChangedFcn',@(src,event) obj.sizechangedCallback(src,event));
            propGrid.Layout.Row = 3;
            propGrid.Layout.Column = [1 4];
            
            obj.propGrid = propGrid;
            
            defsElementAdd = uibutton(defsGrid,...
                'Text','Add',...
                'ButtonPushedFcn',@(src,event) obj.addFeatureDefinition);
            defsElementAdd.Layout.Row = 4;
            defsElementAdd.Layout.Column = [1 2];
            
            defsElementDel = uibutton(defsGrid,...
                'Text','Delete...',...
                'ButtonPushedFcn',@(src,event) obj.removeFeatureDefinition);
            defsElementDel.Layout.Row = 4;
            defsElementDel.Layout.Column = [3 4];
            
%             defsElementUp = uibutton(defsGrid,...
%                 'Text','/\',...
%                 'ButtonPushedFcn',@(h,e)obj.movePreprocessingUp);
%             defsElementUp.Layout.Row = 4;
%             defsElementUp.Layout.Column = 3;
%             
%             defsElementDwn = uibutton(defsGrid,...
%                 'Text','\/',...
%                 'ButtonPushedFcn',@(h,e)obj.movePreprocessingDown);
%             defsElementDwn.Layout.Row = 4;
%             defsElementDwn.Layout.Column = 4;
                        
            rangeGrid = uigridlayout(moduleLayout, [3 2],...
                'ColumnWidth',{'2x','1x'},...
                'RowHeight',{'fit','8x','fit'},...
                'RowSpacing',4,...
                'Padding',[4 4 4 4]);
            rangeGrid.Layout.Row = 2;
            rangeGrid.Layout.Column = 1;
            
            rangeLabel = uilabel(rangeGrid,...
                'Text','Feature ranges',...
                'FontWeight','bold');
            rangeLabel.Layout.Row = 1;
            rangeLabel.Layout.Column = [1 2];
            
            rangeTable = uitable(rangeGrid,...
                'CellSelectionCallback',@(src,event) obj.rangeTableSelectionCallback(src,event),...
                'CellEditCallback',@(src,event) obj.rangeTableDataChangeCallback(src,event));
            rangeTable.Layout.Row = 2;
            rangeTable.Layout.Column = [1 2];
            
            obj.rangeTable = rangeTable;
            
            rangeAdd = uibutton(rangeGrid,...
                'Text','Add',...
                'ButtonPushedFcn',@(h,e)obj.addRange);
            rangeAdd.Layout.Row = 3;
            rangeAdd.Layout.Column = 1;
            
            rangeDel = uibutton(rangeGrid,...
                'Text','Delete',...
                'ButtonPushedFcn',@(src,event) obj.removeRange(src,event));
            rangeDel.Layout.Row = 3;
            rangeDel.Layout.Column = 2;
            
            previewAx = uiaxes(moduleLayout);
            previewAx.Title.String = 'Feature Preview';
            previewAx.XLabel.String = 'Time / s';
            previewAx.YLabel.String = 'Features / a.u.';
            previewAx.Layout.Row = 1;
            previewAx.Layout.Column = 2;

            obj.hAxPreview = previewAx;
            
            cycleAx = uiaxes(moduleLayout);
            cycleAx.Title.String = 'Cycles with grouping colors';
            cycleAx.ButtonDownFcn = @obj.axesButtonDownCallback;
            cycleAx.XLabel.String = 'Time / s';
            cycleAx.YLabel.String = 'Data / a.u.';
            cycleAx.Layout.Row = 2;
            cycleAx.Layout.Column = 2;
            
            obj.hAxCycle = cycleAx;
        end
        
        function sizechangedCallback(obj, src, event)
            obj.propGrid.panel.Visible = 'off';
            pos_parent = obj.propGrid.Position;
            obj.propGrid.panel.Position = pos_parent - [0,25,9,12]; %values possibly subject to change 
            obj.propGrid.panel.Visible = 'on';                     % depending on screen resolution?
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
                [sel,ok] = Gui.Dialogs.Select('ListItems',s);
                if ~ok
                    fds = FeatureDefinition.empty;
                    return
                end
            else
                sel = {desc};
            end
            
            fds = FeatureDefinition.empty;
            for i = 1:numel(sel)
                fcn = fe(sel{i});
                fd = FeatureDefinition(fcn);
                obj.currentFeatureDefinitionSet.addFeatureDefinition(fd);
                fds(end+1) = fd;
            end
            obj.propGrid.clear();
%             pgf = obj.currentFeatureDefinitionSet.makePropGridFields();
            blocks = [];
            fdSetDefs = obj.currentFeatureDefinitionSet.featureDefinitions;
            for i = 1:size(fdSetDefs,2)
               blocks = [blocks fdSetDefs(i).dataProcessingBlock]; 
            end
            obj.propGrid.addBlocks(blocks);
            obj.changeFeatureDefinition(fds(end));
        end
        
        function removeFeatureDefinition(obj,fd)
            if nargin < 2
                fds = obj.currentFeatureDefinitionSet.getFeatureDefinitions();
                [sel,ok] = Gui.Dialogs.Select('ListItems',fds.getCaption(),...
                    'MultiSelect',true);
                if ~ok
                    return
                end
                fd = fds(ismember(fds.getCaption(),sel));
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
%             pgf = obj.currentFeatureDefinitionSet.makePropGridFields();
%             obj.propGrid.addProperty(pgf);
            blocks = [];
            fdSetDefs = obj.currentFeatureDefinitionSet.featureDefinitions;
            for i = 1:size(fdSetDefs,2)
               blocks = [blocks fdSetDefs(i).dataProcessingBlock]; 
            end
            obj.propGrid.addBlocks(blocks);
            [pgf.onMouseClickedCallback] = deal(@obj.propGridFieldClickedCallback);
        end
        
        function handleFeatureDefinitionSetChange(obj)
            fds = obj.currentFeatureDefinitionSet;
            obj.propGrid.clear();
%             pgf = obj.currentFeatureDefinitionSet.makePropGridFields();
%             obj.propGrid.addProperty(pgf);
            blocks = [];
            fdSetDefs = obj.currentFeatureDefinitionSet.featureDefinitions;
            for i = 1:size(fdSetDefs,2)
               blocks = [blocks fdSetDefs(i).dataProcessingBlock]; 
            end
            obj.propGrid.addBlocks(blocks);
%             [pgf.onMouseClickedCallback] = deal(@obj.propGridFieldClickedCallback);
            fdefs = fds.getFeatureDefinitions();
            if ~isempty(fdefs)
                obj.changeFeatureDefinition(fdefs(1));
            else
                obj.changeFeatureDefinition(FeatureDefinition.empty);
            end
        end
        
        function dropdownNewFeatureDefinitionSet(obj,src,event,dropdown)
            fds = obj.getProject().addFeatureDefinitionSet();
            obj.currentFeatureDefinitionSet = fds;
            dropdown.Items{end+1} = char(fds.getCaption());
            dropdown.Value = char(fds.getCaption());
            obj.handleFeatureDefinitionSetChange();
            obj.main.populateSensorSetTable();
        end
        
        function dropdownRemoveFeatureDefinitionSet(obj,src,event,dropdown)
            fdss = obj.getProject().poolFeatureDefinitionSets;
            idx = arrayfun(@(set) strcmp(set.caption,dropdown.Value),fdss);
            fds = fdss(idx);
            sensorsWithFds = obj.getProject().checkForSensorsWithFeatureDefinitionSet(fds);
            
            if numel(sensorsWithFds) > 1  % the current sensor always has the FDS to delete
                choices = {};
                if numel(fdss) > 1
                    choices{1} = 'Choose a replacement';
                end
                choices{end+1} = 'Replace with new';
                choices{end+1} = 'Cancel';
                
                answer = uiconfirm(obj.main.hFigure,...
                    ['The feature definition set "' char(fds.caption) '" is used in other sensors. What would you like to do?'],...
                    'Feature Definition set usage conflict',...
                    'Icon','warning',...
                    'Options',choices,...
                    'DefaultOption',numel(choices),'CancelOption',numel(choices));
                
                switch answer
                    case 'Choose a replacement'
                        fdss(idx) = [];
                        [sel,ok] = Gui.Dialogs.Select('MultiSelect',false,...
                            'ListItems',fdss.getCaption(),...
                            'Message','Please select a replacement feature definition set.');
                        if ~ok
                            return
                        end
                        selInd = ismember(fdss.getCaption,sel);
                        obj.getProject().replaceFeatureDefinitionSetInSensors(fds,fdss(selInd));
                        newFds = fdss(selInd);
                    case 'Replace with new'
                        newFds = obj.getProject().addFeatureDefinitionSet();
                        dropdown.Items = [dropdown.Items char(newFds.getCaption())];
                        obj.getProject().replaceFeatureDefinitionSetInSensors(fds,newFds);
                    case 'Cancel'
                        return
                end
            else
                % if there is only one FDS, it will now be deleted
                % so we have to add a new one
                if numel(obj.getProject().poolFeatureDefinitionSets) == 1
                    newFds = obj.getProject().addFeatureDefinitionSet();
                    dropdown.Items = [dropdown.Items char(newFds.getCaption())];
                else %select a FDS we already have
                    if idx(1)   %the first logical index had the true
                        newFds = obj.getProject().poolFeatureDefinitionSets(2);
                    else
                        %shift the logical index one position to the front (left)
                        newFds = obj.getProject().poolFeatureDefinitionSets(circshift(idx,-1));
                    end
                end
            end

            obj.currentFeatureDefinitionSet = newFds;
            obj.getProject().removeFeatureDefinitionSet(fds);
                
            dropdown.Items = dropdown.Items(~idx);  %drop the old option
            dropdown.Value = char(newFds.caption);  %set the new one
            obj.handleFeatureDefinitionSetChange();
            obj.main.populateSensorSetTable();
        end
        
        function dropdownFeatureDefinitionSetCallback(obj,src,event)
            if event.Edited
                index = cellfun(@(x) strcmp(x,event.PreviousValue), src.Items);
                newName = matlab.lang.makeUniqueStrings(event.Value,...
                    cellstr(obj.getProject().poolFeatureDefinitionSets.getCaption()));
                obj.getProject().poolFeatureDefinitionSets(index).setCaption(newName);
                src.Items{index} = newName;
                obj.handleFeatureDefinitionSetChange();
                obj.main.populateSensorSetTable();
            else 
                index = cellfun(@(x) strcmp(x,event.Value), src.Items);
                obj.currentFeatureDefinitionSet = ...
                    obj.getProject().poolFeatureDefinitionSets(index);
                obj.handleFeatureDefinitionSetChange();
                obj.main.populateSensorSetTable();
            end
        end
        
        function dropdownFeatureDefinitionSetRename(obj,src,newName,index)
            newName = matlab.lang.makeUniqueStrings(newName,obj.getProject().poolFeatureDefinitionSets.getCaption());
            obj.getProject().poolFeatureDefinitionSets(index).setCaption(newName);
            src.renameItemAt(newName,src.getSelectedIndex());
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
            iPos = [pos pos+floor(cc.nCyclePoints/60)];
            if isempty(fd)
                fd = obj.addFeatureDefinition();
                if isempty(fd) %feature def. method dialog was canceled
                    return
                end
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
        
        function removeRange(obj,src,event)
%             selectedRangeIDs = obj.rangeTable.jTable.getSelectedRows() + 1;
%             gObjects = {};
            rangeObjects = obj.rangeTable.UserData(obj.selectedRanges);
%             for i=1:numel(selectedRangeIDs)
%                 selectedRangeID = selectedRangeIDs(i);
%                 if selectedRangeID == 0
%                     return
%                 end
%                 gObjects{i} = obj.rangeTable.getRowObjectsAt(selectedRangeID);
%             end
            for i=1:numel(rangeObjects)
                obj.deleteRangeCallback(rangeObjects(i))
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
        
        function propGridFieldClickedCallback(obj,src,event)
            fdSetDefs = obj.currentFeatureDefinitionSet.featureDefinitions;
            blk = src.getSelectedBlock;
            idx = arrayfun(@(fDef) strcmp(fDef.caption,blk.caption),fdSetDefs);
            obj.changeFeatureDefinition(fdSetDefs(idx));
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
            if isempty(obj.ranges)
                obj.selectedRanges = [];
            else
                obj.selectedRanges = 1;
            end
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
                uialert(obj.main.hFigure,'Load at least one sensor.','Data required');
            elseif isempty(obj.getProject().groupings)
                allowed = false;
                uialert(obj.main.hFigure,'Define at least one grouping.','Grouping required');
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
            
            obj.setDropdown.Items = ...
                cellfun(@(x) x,obj.getProject().poolFeatureDefinitionSets.getCaption(),...
                'UniformOutput',false);
            obj.setDropdown.Value = obj.currentFeatureDefinitionSet.getCaption();
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
%             set(gcf,'WindowScrollWheelFcn',@obj.scrollWheelCallback);
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
                obj.setDropdown.Value = obj.currentFeatureDefinitionSet.getCaption();
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
            t = obj.rangeTable;
            if isempty(gRanges)
                t.Data = {};
                return
            else
                captions = cellstr(gRanges.getRange().getCaption()');
                positions = num2cell(gRanges.getPosition());
                divs = num2cell(vertcat(gRanges.getRange().subRangeNum));
                forms = {gRanges.getRange().subRangeForm}';
                data = [captions, positions, divs, forms];
            end

            t.Data = data;
            t.UserData= gRanges;
            
            t.ColumnName = {'caption','begin','end','divs','form'};
            t.ColumnFormat = {'char','numeric','numeric','numeric',{'lin','log','invlog'}};
            t.ColumnEditable = [true true true true true true];
            ind = tableColSort(t,2,'a');
            
%             obj.rangeTable.onDataChangedCallback = @obj.rangeTableDataChangeCallback;
%             obj.rangeTable.onMouseClickedCallback = @obj.rangeTableMouseClickedCallback;
        end
        
        function updateFeaturePreview(obj)
            fd = obj.currentFeatureDefinition;
            if isempty(fd)
                %instead of deleting the lines, just make them invisible
                for line = 1:numel(obj.previewLines)
                    obj.previewLines(line).Visible = 0;
                end
%                 delete(obj.previewLines);
%                 obj.previewLines = [];
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
                y(:,i) = y(:,i) - mean(y(:,i),'omitnan');%zscore(y(:,i));
            end
            
            %set preview line data and make it visible
            for i = 1:numel(obj.previewLines)
                obj.previewLines(i).XData = x;
                obj.previewLines(i).YData = y(i,:);
                obj.previewLines(i).Visible = 1;
            end
        end
        
        function cycleRangePositionChangedCallback(obj,range,~)
            obj.updateFeaturePreview();
        end        
        
        function rangeDraggedCallback(obj,gRange)
            %%
            % update the position in the table when the point is dragged
%             row = obj.rangeTable.getRowObjectRow(gRange);
            row = ismember(obj.rangeTable.UserData,gRange);
            pos = gRange.getPosition();
            obj.rangeTable.Data{row,2} = pos(1);
            obj.rangeTable.Data{row,3} = pos(2);
            tableColSort(obj.rangeTable,2,'a');
%             pos = gRange.getPosition();
%             obj.rangeTable.setValue(pos(1),row,2);
%             obj.rangeTable.setValue(pos(2),row,3);
        end
        
        function cycleRangeDragStartCallback(obj,gObj)
            %%
            % disable table callbacks (to omit "wrong" data changed events),
            % move the current selection to the corresponding row, and make
            % the corresponding cycle line bold
            obj.rangeTable.Enable = 'off';
%             obj.rangeTable.setCallbacksActive(false);
%             objRow = obj.rangeTable.getRowObjectRow(gObj);
%             obj.rangeTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
        end
        
        function cycleRangeDragStopCallback(obj,gObj)
            %%
            % re-enable table callbacks and set selection again (can get
            % messed up, probably due to dynamic sorting in the table?),
            % set cycle line width back to normal
            pause(0.01); % to make sure all callbacks have been processed
%             objRow = obj.rangeTable.getRowObjectRow(gObj);
%             obj.rangeTable.jTable.getSelectionModel().setSelectionInterval(objRow-1,objRow-1);
%             obj.rangeTable.setCallbacksActive(true);
            tableColSort(obj.rangeTable,2,'a');
            obj.rangeTable.Enable = 'on';
            obj.updateFeaturePreview();
        end
        function rangeTableSelectionCallback(obj,src,event)
            obj.selectedRanges = unique(event.Indices(:,1));
            if isempty(event.Indices)
                return
            end
            row = event.Indices(1);
            removeStyle(obj.rangeTable);
            style = uistyle("BackgroundColor",[221,240,255]./256);
            addStyle(src,style,"Row",row);
        end
        function rangeTableDataChangeCallback(obj,src,event)
            %%
            % write changes from the table to the point object
            row = event.Indices(1);
            col = event.Indices(2);
            fRange = src.UserData(row);
            switch col
                case 1
                    fRange.getObject().setCaption(event.EditData);
                case 2
                    fRange.setPosition([event.NewData nan]);
                case 3
                    fRange.setPosition([nan event.NewData]);
                case 4
                    fRange.getObject().setSubRangeNum(event.NewData);
                    fRange.updateSubRanges();
                    obj.updateFeaturePreview();
                case 5
                    fRange.getObject().setSubRangeForm(event.NewData);
                    fRange.updateSubRanges();
                    obj.updateFeaturePreview();
            end
            ind = tableColSort(obj.rangeTable,2,'a');
            obj.ranges = obj.ranges(ind);
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