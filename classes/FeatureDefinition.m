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

classdef FeatureDefinition < Descriptions
    properties
        fcn
        dataProcessingBlock
        ranges
    end
    properties(Transient)
        cachedFeatureValues
    end
    
    methods
        function obj = FeatureDefinition(fcn)
            obj@Descriptions();
            obj.fcn = fcn;
            obj.dataProcessingBlock = DataProcessingBlock(fcn);
            obj.ranges = Range.empty;
            obj.setCaption(obj.dataProcessingBlock.getCaption());
            obj.cachedFeatureValues = cell(0,1);
        end

        function dates = getModifiedDate(objArray)
            if isempty(objArray)
                dates = datetime.empty;
                return
            end
            dates = [objArray.modifiedDate];
            for i = 1:numel(objArray)
                dates(i) = max([dates(i),...
                    objArray(i).ranges.getModifiedDate(),...
                    objArray(i).dataProcessingBlock.getModifiedDate()]);
            end
        end
        
        function addRange(obj,range)
            obj.ranges = [obj.ranges,range];
            obj.cachedFeatureValues = [obj.cachedFeatureValues,cell(1,numel(range))];
        end
        
        function removeRange(obj,range)
            idx = obj.ranges==range;
            obj.ranges(idx) = [];
            obj.cachedFeatureValues(idx) = [];
        end
        
        function ranges = getRanges(obj)
            if isempty(obj)
                ranges = Range.empty;
                return
            end
            ranges = obj.ranges;
        end

        function [featDataMat,header,valueLabels] = computeRawBatch(obj,y,sensor,ranges)
            if nargin < 4
                ranges = obj.ranges;
            end
            
            featDataMat = [];
            header = string.empty;

            if numel(ranges) == 0
                error('No feature ranges defined in %s.', obj.getCaption());
            end
            
            for i = 1:numel(ranges)
                range = ranges(i);

                % compute features
                iPos = range.getAllIndexPositions(sensor);
                x = sensor.abscissa;
                aPos = DataSelector.indexToAbscissa(iPos,sensor);
                [featData,params] = obj.dataProcessingBlock.apply(y,...
                    struct('raw',true,'iPos',iPos,'x',x));
                
                featDataMat = [featDataMat,featData];
                header = [header,params.header];
            end
            valueLabels = params.valueLabels;
        end        
        
        function [featData,aPos,params] = computeRaw(obj,y,sensor,ranges)
            if nargin < 4
                ranges = obj.ranges;
            end

            for i = 1:numel(ranges)
                range = ranges(i);

                % return a cached value if inputs are the same as before and
                % range position has not changed
                tPos = range.getAllTimePositions();
                if ~isempty(obj.cachedFeatureValues) && (i <= numel(obj.cachedFeatureValues)) && ~isempty(obj.cachedFeatureValues{i})...
                        && ((numel(y) ~= numel(obj.cachedFeatureValues{i}.y))...
                        || (numel(tPos) ~= numel(obj.cachedFeatureValues{i}.tPos)))
                    obj.cachedFeatureValues{i} = [];
                end

                if ~isempty(obj.cachedFeatureValues) && (i <= numel(obj.cachedFeatureValues)) && ~isempty(obj.cachedFeatureValues{i})...
                        && (obj.cachedFeatureValues{i}.sensor == sensor)...
                        && all(all(obj.cachedFeatureValues{i}.y == y))...
                        && all(all(obj.cachedFeatureValues{i}.tPos == tPos))
                    featData = obj.cachedFeatureValues{i}.featData;
                    aPos = obj.cachedFeatureValues{i}.aPos;
                    params = obj.cachedFeatureValues{i}.params;
                    continue
                end

                % compute features
                iPos = range.getAllIndexPositions(sensor);
                x = sensor.abscissa;
                aPos = DataSelector.indexToAbscissa(iPos,sensor);
                [featData,params] = obj.dataProcessingBlock.apply(y,...
                    struct('raw',true,'iPos',iPos,'x',x));

                % save result to cache
                obj.cachedFeatureValues{i}.y = y;
                obj.cachedFeatureValues{i}.sensor = sensor;
                obj.cachedFeatureValues{i}.featData = featData;
                obj.cachedFeatureValues{i}.iPos = iPos;
                obj.cachedFeatureValues{i}.tPos = tPos;
                obj.cachedFeatureValues{i}.aPos = aPos;
                obj.cachedFeatureValues{i}.params = params;
            end
        end
        
        function featData = compute(obj,rawData,xData,sensor)
            pos = obj.range.getIndexPosition(sensor.cluster);
            pos = pos(1):pos(2);
            [data,header] = obj.fcn(rawData(:,pos),xData(pos));
            featData = FeatureData(obj,data,header);
        end
        
        function pgf = makePropGridFields(obj)
            pgf = obj.dataProcessingBlock.makePropGridField();
        end
    end
    
%     methods (Static)
%         function out = getAvailableMethods(force)
%             persistent fe
%             if ~exist('force','var')
%                 force = false;
%             end
%             if ~isempty(fe) && ~force
%                 out = fe;
%                 return
%             end
%             fe = parsePlugin('FeatureExtraction');
%             out = fe;
%         end
%     end     
end