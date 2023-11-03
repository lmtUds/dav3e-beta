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

classdef GraphicsRange < GraphicsObject
    properties
        hAx
        handlePatch
        handleStartLine
        handleStopLine
        handleSubRangeLines
    end
    
    properties(Constant)
        nPos = 2;
    end    
    
    methods
        function obj = GraphicsRange(range,mode,dragEnabled)
            obj@GraphicsObject(range,mode,dragEnabled);
        end
        
        function r = getObject(objArray)
            r = objArray.getObject@GraphicsObject();
            if isempty(r)
                r = Range.empty;
            end
        end
        
        function r = getRange(objArray)
            r = objArray.getObject();
        end
                
        function pos = getAllPositions(obj,sensor)
            if nargin < 2
                sensor = obj(1).currentSensor;
            end
            switch obj.mode
                case 'cycle'
                    pos = obj.object.getAllCyclePositions(sensor.cluster);
                case 'index'
                    pos = obj.object.getAllIndexPositions(sensor);
            end
        end
        
        function divs = getSubRangeDivs(obj,sensor)
            if nargin < 2
                sensor = obj(1).currentSensor;
            end
            pos = obj.getAllPositions(sensor);
            divs = pos(2:end,1)';
            if obj.mode == 'index'
                divs = DataSelector.indexToAbscissa(divs,sensor);
            end
        end
        
        function draw(objArray,hAx,sensor,ylimits)
            if isempty(objArray)
                return
            end
            
            hold(hAx,'on');
            
            [objArray.hAx] = deal(hAx);
            
            [objArray.currentCluster] = deal(sensor.cluster);
            [objArray.currentSensor] = deal(sensor);
            objCell = num2cell(objArray);
            colorCell = objArray.getRange().getColorCell();
            ys = ylimits;
            
            % sub range dividers
            for i = 1:numel(objArray)
                if objArray(i).getObject().subRangeNum > 1
                    posTemp = objArray(i).getSubRangeDivs();
                    lineX = repmat(posTemp,2,1);
                    lineY = repmat(ys',1,numel(posTemp));
                    l = line(hAx,lineX,lineY,...
                        'LineStyle','-','LineWidth',1,'Marker','none',...
                        'YLimInclude','off','Color',colorCell{i});
                    objArray(i).handleSubRangeLines = l;
                end
            end
            
            % patches as range area
            pos = objArray.getPosition(sensor);
            patchX = [pos pos(:,[2 1])]';
            patchY = repmat(ys([1 1 2 2])',1,size(pos,1));
            p = fill(hAx,patchX,patchY,'red');
            set(p,'FaceAlpha',0.3,'EdgeColor','none','YLimInclude','off');
            pCell = num2cell(p);
            [objArray.handlePatch] = deal(pCell{:});
            [p.UserData] = deal(objCell{:});
            [p.Tag] = deal('patch');
            [p.FaceColor] = deal(colorCell{:});

            % we are finished drawing the non-dragabble ranges
            del = ~[objArray.dragEnabled];
            objArray(del) = [];
            pos(del,:) = [];
            p(del) = [];
            if isempty(objArray)
                return
            end

            % lines as drag anchor
            lineX = repmat(pos(:)',2,1);
            lineY = repmat(ys',1,2*size(pos,1));
            l = line(hAx,lineX,lineY,...
                'LineStyle','-','LineWidth',1.5,'Marker','none',...
                'YLimInclude','off');
            lCell = num2cell(l);
            [objArray.handleStartLine] = deal(lCell{1:numel(objArray)});
            [objArray.handleStopLine] = deal(lCell{numel(objArray)+1:end});
            [l(1:numel(objArray)).UserData] = deal(objCell{:});
            [l(numel(objArray)+1:end).UserData] = deal(objCell{:});
            [l(1:numel(objArray)).Tag] = deal('startLine');
            [l(numel(objArray)+1:end).Tag] = deal('stopLine');
            [l(1:numel(objArray)).Color] = deal(colorCell{:});
            [l(numel(objArray)+1:end).Color] = deal(colorCell{:});
            
            % callbacks for patches and lines
            [p.ButtonDownFcn] = deal(@GraphicsRange.dragStart);
            [l.ButtonDownFcn] = deal(@GraphicsRange.dragStart);

            hAx.Clipping = 'on';
            hold(hAx,'off');
        end
        
        function updatePosition(objArray,sensor)
            if isempty(objArray)
                return
            end
            
            [objArray.currentCluster] = deal(sensor.cluster);
            [objArray.currentSensor] = deal(sensor);
            pos = objArray.getPosition(sensor);
            
            if isscalar(objArray)
                objArray.handlePatch.XData = [pos pos(:,[2 1])]';
                objArray.handleStartLine.XData = pos([1 1]);
                objArray.handleStopLine.XData = pos([2 2]);
                if objArray.getObject().subRangeNum > 1
                    srPos = objArray.getSubRangeDivs();
                    srPos = repmat(srPos,2,1);
                    srPos = mat2cell(srPos,2,ones(size(srPos,2),1));
                    [objArray.handleSubRangeLines.XData] = deal(srPos{:});
                end
                return
            end
            
            patchX = [pos pos(:,[2 1])]';
            patchX = mat2cell(patchX,4,ones(1,numel(objArray)));
            p = [objArray.handlePatch];
            [p.XData] = deal(patchX{:});
            
            for i = 1:numel(objArray)
                if objArray(i).getObject().subRangeNum > 1
                    srPos = objArray(i).getSubRangeDivs();
                    srPos = repmat(srPos,2,1);
                    srPos = mat2cell(srPos,2,ones(size(srPos,2),1));
                    [objArray(i).handleSubRangeLines.XData] = deal(srPos{:});
                end
            end
            
            if objArray(1).dragEnabled
                lineX = mat2cell(repmat(pos(:,1),1,2),ones(1,numel(objArray)),2);
                l = [objArray.handleStartLine];
                [l.XData] = deal(lineX{:});

                lineX = mat2cell(repmat(pos(:,2),1,2),ones(1,numel(objArray)),2);
                l = [objArray.handleStopLine];
                [l.XData] = deal(lineX{:});
            end
        end

        function updateColor(objArray)
            if isempty(objArray)
                return
            end
            
            cClr = objArray.getObject().getColorCell();
            p = [objArray.handlePatch];
            [p.FaceColor] = deal(cClr{:});
            for i = 1:numel(objArray)
                l = objArray(i).handleSubRangeLines;
                if ~isempty(l)
                    [l.Color] = deal(cClr{i});
                end
            end
            if objArray(1).dragEnabled
                l = [objArray.handleStartLine];
                [l.Color] = deal(cClr{:});
                l = [objArray.handleStopLine];
                [l.Color] = deal(cClr{:});
            end
        end
        
        function setYLimits(objArray,ylimits)
            if isempty(objArray)
                return
            end
            
            p = [objArray.handlePatch];
            [p.YData] = deal(ylimits([1 1 2 2]));
            for i = 1:numel(objArray)
                l = objArray(i).handleSubRangeLines;
                if ~isempty(l)
                    [l.YData] = deal(ylimits);
                end
            end
            if objArray(1).dragEnabled
                l = [objArray.handleStartLine, objArray.handleStopLine];
                [l.YData] = deal(ylimits);
            end
        end
        
        function updateSubRanges(objArray)
            if isempty(objArray)
                return
            end
            
            for i = 1:numel(objArray)
                delete(objArray(i).handleSubRangeLines);
                objArray(i).handleSubRangeLines = [];
                if objArray(i).getObject().subRangeNum > 1
                    pos = objArray(i).getSubRangeDivs();
                    lineX = repmat(pos,2,1);
                    lineY = repmat(objArray(i).handleStartLine.YData',1,numel(pos));
                    l = line(objArray(i).hAx,lineX,lineY,...
                        'LineStyle','-','LineWidth',1,'Marker','none',...
                        'YLimInclude','off','Color',objArray(i).getObject().clr);
                    objArray(i).handleSubRangeLines = l;
%                     uistack(l,'bottom');
                end
            end
        end
        
        function setHighlight(objArray,state)
            if isempty(objArray)
                return
            end
            
            if any(state)
                yes = objArray(state).handlePatch;
                [yes.FaceAlpha] = deal(0.5);
            end
            if any(~state)
                no = objArray(~state).handlePatch;
                [no.FaceAlpha] = deal(0.3);
            end
        end
        
        function h = getGraphicHandles(objArray)
            if isempty(objArray)
                h = [];
                return
            end
            
            h = [objArray.handlePatch];
            h = [h; objArray.handleStartLine];
            h = [h; objArray.handleStopLine];
            h = [h; objArray.handleSubRangeLines];
        end
    end
    
    methods(Static)
        function dragged(gRange,draggedObject)
            point = get(gca,'CurrentPoint');
            startMousePos = gRange.dragStartMousePosition;
            startRangePos = gRange.dragStartObjectPosition;
            diffPos = point(1) - startMousePos;
            switch draggedObject
                case 'patch'
                    newPos = startRangePos + diffPos;
                case 'startLine'
                    newPos = startRangePos + [1 0] * diffPos;
                case 'stopLine'
                    newPos = startRangePos + [0 1] * diffPos;
            end
            gRange.setPosition(newPos,gRange.currentSensor);
            if ~isempty(gRange.onDraggedCallback)
                gRange.onDraggedCallback(gRange);
            end
        end
    end
end