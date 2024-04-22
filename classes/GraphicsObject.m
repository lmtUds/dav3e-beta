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

classdef GraphicsObject < handle
    properties
        object
        mode = string('cycle');
        dragEnabled = true
        highlighted = false

        currentCluster
        currentSensor

        UserData
    end
    
    properties(Abstract,Constant)
        nPos
    end
    
    properties(Transient)
        onDragStartCallback
        onDraggedCallback
        onDragStopCallback
        onDeleteRequestCallback
        dragStartMousePosition
        dragStartObjectPosition
    end
    
    methods
        function obj = GraphicsObject(object,mode,dragEnabled)
            obj.object = object;
            obj.mode = string(mode);
            obj.dragEnabled = dragEnabled;
        end
        
        function r = getObject(objArray)
            if isempty(objArray)
                r = [];
                return
            end
            r = vertcat(objArray.object);
        end
        
        function pos = getPosition(objArray,sensor)
            if isempty(objArray)
                pos = nan(0,GraphicsObject.nPos);
                return
            end
            if nargin < 2
                sensor = objArray(1).currentSensor;
            end
            if isscalar(objArray)
                switch objArray.mode
                    case 'cycle'
                        pos = objArray.object.getCyclePosition(sensor.cluster);
                    case 'index'
                        pos = objArray.object.getAbscissaPosition(sensor);
                end
                return
            end
            cyclePosIdx = [objArray.mode] == 'cycle';
            indexPosIdx = [objArray.mode] == 'index';
            pos = nan(numel(objArray),objArray(1).nPos);
            pos(cyclePosIdx,:) = objArray(cyclePosIdx).getObject().getCyclePosition(sensor.cluster);
            pos(indexPosIdx,:) = objArray(indexPosIdx).getObject().getAbscissaPosition(sensor);
        end
        
        function pos = getTimePosition(objArray)
            pos = objArray.getObject().getTimePosition();
        end

        function setPosition(objArray,pos,sensor)
            if nargin < 3
                sensor = objArray(1).currentSensor;
            end
            if isscalar(objArray)
                switch objArray.mode
                    case 'cycle'
                        objArray.object.setCyclePosition(pos,sensor.cluster);
                    case 'index'
                        objArray.object.setAbscissaPosition(pos,sensor);
                end
                objArray.updatePosition(sensor);
                return
            end
            cyclePosIdx = [objArray.mode] == 'cycle';
            indexPosIdx = [objArray.mode] == 'index';
            objArray(cyclePosIdx).getObject().setCyclePosition(pos(cyclePosIdx,:),sensor.cluster);
            objArray(indexPosIdx).getObject().setAbscissaPosition(pos(indexPosIdx,:),sensor);
            objArray.updatePosition(sensor);
        end
        
        function setTimePosition(objArray, pos)
            objArray.object.setTimePosition(pos);
            sensor = objArray(1).currentSensor;
            objArray.updatePosition(sensor);
        end

        function setColor(objArray,color)
            objArray.getObject().setColor(color);
            objArray.updateColor();
        end

        function updateYLimits(objArray)
            if isempty(objArray)
                return
            end
            ylimits = ylim(objArray(1).hAx);
            objArray.setYLimits(ylimits);
        end        
        
        function delete(obj)
            h = obj.getGraphicHandles();
            delete(h);
            obj.onDragStartCallback = [];
            obj.onDraggedCallback = [];
            obj.onDragStopCallback = [];
        end
    end
    
    methods(Abstract)
        draw(objArray,hAx,cluster,ylimits)
        updatePosition(objArray,cluster)
        updateColor(objArray,colorCell)
        setYLimits(objArray,ylimits)
        setHighlight(objArray,state);
        h = getGraphicHandles(objArray)
    end

    methods(Abstract,Static)
        dragged(gRange,draggedObject)
    end

    methods(Static)
        function dragStart(h,~)
            gObject = h.UserData;
            
            mouseButton = get(gcf,'SelectionType');
            if strcmp(mouseButton,'alt')
                gObject.onDeleteRequestCallback(gObject);
            end
            if ~strcmp(mouseButton,'normal')
                return
            end
            
            draggedObject = h.Tag;
            clickedPoint = get(gca,'CurrentPoint');
            gObject.dragStartMousePosition = clickedPoint(1);
            gObject.dragStartObjectPosition = gObject.getPosition(gObject.currentSensor);
            
            gObject.setHighlight(true);
            
            if ~isempty(gObject.onDragStartCallback)
                gObject.onDragStartCallback(gObject);
            end
            
            set(gcf,'WindowButtonMotionFcn',@(h,e)gObject.dragged(gObject,draggedObject));
            set(gcf,'WindowButtonUpFcn',@(h,e)gObject.dragStop(gObject));            
            % Turn off Zoom/Pan/Brush if activated, otherwise dragStop
            % cannot be executed
            if contains(lastwarn,'Setting the "WindowButtonUpFcn" property is not permitted while this mode is active.')
                zoom off
                brush off
                pan off
                lastwarn('')
                set(gcf,'WindowButtonMotionFcn',@(h,e)gObject.dragged(gObject,draggedObject));
                set(gcf,'WindowButtonUpFcn',@(h,e)gObject.dragStop(gObject));
            end
        end
       
        function dragStop(gObject)
            gObject.setHighlight(false);
            set(gcf,'WindowButtonMotionFcn',[]);
            set(gcf,'WindowButtonUpFcn',[]);
            
            if ~isempty(gObject.onDragStopCallback)
                gObject.onDragStopCallback(gObject);
            end
        end
    end
end