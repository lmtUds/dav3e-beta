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

classdef GraphicsPoint < GraphicsObject
    properties
        hAx
        handleLine
        
        handleInvRect
    end
    
    properties(Constant)
        nPos = 1
    end    
    
    methods
        function obj = GraphicsPoint(point,mode,dragEnabled)
            obj@GraphicsObject(point,mode,dragEnabled);
        end
        
        function r = getObject(objArray)
            r = objArray.getObject@GraphicsObject();
            if isempty(r)
                r = Point.empty;
            end
        end
        
        function r = getPoint(objArray)
            r = objArray.getObject();
        end
                
        function draw(objArray,hAx,sensor,ylimits)
            hold(hAx,'on');
            [objArray.hAx] = deal(hAx);
            
            [objArray.currentCluster] = deal(sensor.cluster);
            [objArray.currentSensor] = deal(sensor);
            objCell = num2cell(objArray);
            
            % line
            ys = ylimits;
            pos = objArray.getPosition(sensor);
            lineX = repmat(pos',2,1);
            lineY = repmat(ys',1,size(pos,1));
            l = line(hAx,lineX,lineY,...
                'LineStyle','-','LineWidth',1.5,'YLimInclude','off');
            lCell = num2cell(l);
            [objArray.handleLine] = deal(lCell{:});
            [l.UserData] = deal(objCell{:});
            colorCell = objArray.getObject().getColorCell();  %mat2cell(vertcat(objArray.clr),ones(1,numel(objArray)),3);
            [l.Color] = deal(colorCell{:});
            
            % we are finished drawing the non-dragabble points
            del = ~[objArray.dragEnabled];
            l(del) = [];
            if isempty(objArray)
                return
            end
            
            % (almost) invisible patches to increase the clickable area
            p = patch(); delete(p); p = p([]);
            span = diff(xlim(hAx)) / 100;
            for i = 1:numel(l)
                x = l(i).XData(1);
                ys = l(i).YData;
                p(i) = fill(hAx,[x-span,x-span,x+span,x+span],[ys ys([2,1])],'white');
                p(i).FaceAlpha = 0.01;
                p(i).EdgeColor = 'none';
                objArray(i).handleInvRect = p(i);
                p(i).UserData = objArray(i);
            end
            [p.XLimInclude] = deal('off');
            [p.YLimInclude] = deal('off');

            % callbacks for lines
            [l.ButtonDownFcn] = deal(@GraphicsPoint.dragStart);
            [p.ButtonDownFcn] = deal(@GraphicsPoint.dragStart);

            hold(hAx,'off');
        end
        
        function updatePosition(objArray,sensor)
            [objArray.currentCluster] = deal(sensor.cluster);
            [objArray.currentSensor] = deal(sensor);
            pos = objArray.getPosition(sensor);
            
            span = diff(xlim(objArray(1).hAx)) / 100;
            if isscalar(objArray)
                objArray.handleLine.XData = pos([1 1]);
                objArray.handleInvRect.XData = pos + span*[1 1 -1 -1];
                return
            end
            
            lineX = mat2cell(repmat(pos,1,2),ones(1,numel(objArray)),2);
            l = [objArray.handleLine];
            [l.XData] = deal(lineX{:});
        end

        function updateColor(objArray)
            cClr = objArray.getObject().getColorCell();
            l = [objArray.handleLine];
            [l.Color] = deal(cClr{:});
        end

        function setYLimits(objArray,ylimits)
            l = [objArray.handleLine];
            [l.YData] = deal(ylimits);
        end
        
        function ylimits = getYLimits(obj)
            ylimits = obj.handleLine.YData;
        end
        
        function setHighlight(objArray,state)
            if any(state)
                yes = objArray(state).handleLine;
                [yes.LineWidth] = deal(2.5);
            end
            if any(~state)
                no = objArray(~state).handleLine;
                [no.LineWidth] = deal(1.5);
            end
        end        
        
        function h = getGraphicHandles(objArray)
            h = [objArray.handleLine];
            h = [h, objArray.handleInvRect];
        end
    end
    
    methods(Static)
        function dragged(gPoint,~)
            point = get(gca,'CurrentPoint');
            startMousePos = gPoint.dragStartMousePosition;
            startPointPos = gPoint.dragStartObjectPosition;
            diffPos = point(1) - startMousePos;
            newPos = startPointPos + diffPos;
            gPoint.setPosition(newPos,gPoint.currentCluster.getCurrentSensor());
            if ~isempty(gPoint.onDraggedCallback)
                gPoint.onDraggedCallback(gPoint);
            end
        end
    end
end