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

classdef DataSelector < Descriptions
    properties
        timePosition
        clr = [0 0 0];
        currentCluster
        dataObject
    end
    
    properties(Abstract,Constant)
        nPos
    end
    
    properties(Transient)
        onPositionChanged
    end
    
    methods
        function obj = DataSelector(tPos)
            obj = obj@Descriptions();
            obj.timePosition = tPos;
        end
        
        function s = toStruct(objArray)
            if isempty(objArray)
                s = struct.empty;
                return
            end
            s = toStruct@Descriptions(objArray);
            for i = 1:numel(objArray)
                obj = objArray(i);
                s(i).timePosition = obj.timePosition;
                s(i).clr = obj.clr;
            end
        end
        
        function tPos = getTimePosition(objArray)
            if isempty(objArray)
                tPos = zeros(0,DataSelector.nPos);
                return
            end            
            tPos = vertcat(objArray.timePosition);
        end
        
        function iPos = getIndexPosition(objArray,cluster)
            if isempty(objArray)
                iPos = zeros(0,DataSelector.nPos);
                return
            end
            tPos = objArray.getTimePosition();
            iPos = objArray(1).timeToIndex(tPos,cluster);
        end
        
        function aPos = getAbscissaPosition(objArray,sensor)
            if isempty(objArray)
                aPos = zeros(0,DataSelector.nPos);
                return
            end
            iPos = objArray.getIndexPosition(sensor.cluster);
            aPos = DataSelector.indexToAbscissa(iPos,sensor);
        end
        
        function cPos = getCyclePosition(objArray,cluster)
            if isempty(objArray)
                cPos = zeros(0,DataSelector.nPos);
                return
            end
            tPos = objArray.getTimePosition();
            cPos = objArray(1).timeToCycleNumber(tPos,cluster);
        end
        
        function setTimePosition(objArray,tPos)
            oldPos = objArray.getTimePosition();
            tPos(isnan(tPos)) = oldPos(isnan(tPos));
            for i = 1:numel(objArray)
                oldPos = objArray(i).timePosition;
                objArray(i).timePosition = tPos(i,:);
                if any(oldPos ~= tPos(i,:)) && ~isempty(objArray(i).onPositionChanged)
                    objArray(i).onPositionChanged(objArray(i),tPos(i,:));
                end
            end
            objArray.modified();
        end
        
        function setIndexPosition(objArray,iPos,cluster)
            if isempty(objArray)
                return
            end
            [objArray.currentCluster] = deal(cluster);
            tPos = objArray(1).indexToTime(iPos,cluster);
            objArray.setTimePosition(tPos);
        end
        
        function setAbscissaPosition(objArray,aPos,sensor)
            if isempty(objArray)
                return
            end
            iPos = DataSelector.abscissaToIndex(aPos,sensor);
            objArray.setIndexPosition(iPos,sensor.cluster);         
        end
        
        function setCyclePosition(objArray,cPos,cluster)
            if isempty(objArray)
                return
            end
            [objArray.currentCluster] = deal(cluster);
            tPos = objArray(1).cycleNumberToTime(cPos,cluster);
            objArray.setTimePosition(tPos);
        end
                
        function setColor(objArray,clr)
            if isa(clr,'java.awt.Color')
                jClr = clr;
                clr = zeros(numel(objArray),3);
                for i = 1:numel(objArray)
                    clr(i,1) = jClr(i).getRed() / 255;
                    clr(i,2) = jClr(i).getGreen() / 255;
                    clr(i,3) = jClr(i).getBlue() / 255;
                end
            end
            colorCell = mat2cell(clr,ones(1,numel(objArray)),3);
            [objArray.clr] = deal(colorCell{:});
        end
        
        function clr = getColor(objArray)
            clr = vertcat(objArray.clr);
        end
        
        function jClr = getJavaColor(objArray)
            c = objArray.getColor();
            jClr = javaArray('java.awt.Color',numel(objArray));
            for i = 1:numel(objArray)
                jClr(i) = java.awt.Color(c(i,1),c(i,2),c(i,3));
            end
        end
        
        function cClr = getColorCell(objArray)
            if isempty(objArray)
                cClr = {};
                return
            end
            c = objArray.getColor();
            cClr = mat2cell(c,ones(1,numel(objArray)),3);            
        end
    end
    
    methods(Static)
        function aPos = indexToAbscissa(iPos,sensor)
            aPos = sensor.abscissa(iPos);
            aPos(isnan(iPos)) = nan;
        end
    
        function iPos = abscissaToIndex(aPos,sensor)
            abscissa = repmat(sensor.abscissa,numel(aPos),1);
            pos = sign(abscissa - aPos(:));
            pos(pos==0) = -1; % for cases where the position already has the desired value
            z = zeros(numel(aPos),1);
            iPos = (diff([z pos(:,2:end) z],[],2) > 0) * (1:size(abscissa,2))';
            iPos = reshape(iPos,size(aPos));
            iPos(isnan(aPos)) = nan;
        end
    end
    
    methods(Abstract)
        go = makeGraphicsObject(objArray,mode,dragEnabled)
    end
    
    methods(Abstract,Static)
        iPos = timeToIndex(tPos,cluster)
        cPos = timeToCycleNumber(tPos,cluster)
        tPos = indexToTime(iPos,cluster)
        tPos = cycleNumberToTime(cPos,cluster)
    end
    
    methods(Static)
        function fromStruct(s,objArray)
            for i = 1:numel(objArray)
                objArray(i).timePosition = reshape(s(i).timePosition,1,numel(s(i).timePosition));
                objArray(i).clr = reshape(s(i).clr,1,3);
            end
            fromStruct@Descriptions(s,objArray);
        end
    end
end