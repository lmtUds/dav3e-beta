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

classdef FeatureDataSet < Descriptions
    properties
        featureDatas
        sensor
        featureDefinitionSet
        cycleNumbers
        
        empty = false
    end
    
    methods
        function obj = FeatureDataSet(sensor)
            obj@Descriptions();
            if ~exist('sensor','var')
                obj.empty = true;
                return
            end
            obj.sensor = sensor;
            obj.featureDefinitionSet = sensor.featureDefinitionSet;
            obj.featureDatas = FeatureData.empty;
        end
        
        function addFeatureData(obj,featData)
            obj.featureDatas = [obj.featureDatas, featData];
        end
        
        function [featMat,header] = getFeatureMatrix(obj)
            [nCycles,~] = obj.getNCycles();
            [nFeatures,featureArray] = obj.getNFeatures();
            featMat = nan(nCycles,nFeatures);
            header = strings(1,nFeatures);
            starts = [1, 1+ cumsum(featureArray(1:end-1))];
            ends = starts + featureArray - 1;
            for i = 1:numel(starts)
                fd = obj.featureDatas(i);
                featMat(:,starts(i):ends(i)) = fd.data;
                header(starts(i):ends(i)) = ...
                    obj.featureDatas(i).header + string(sprintf('_r%d/%d',fd.rangeNr,fd.subrangeNr));
            end
        end
        
        function dim = getDimensions(obj)
            dim = [obj.getNCycles(), obj.getNFeatures()];
        end
        
        function [nCycles,asArray] = getNCycles(obj)
            asArray = arrayfun(@(x)size(x.data,1),obj.featureDatas);
            nCycles = sum(max(asArray,[],2));
        end
        
        function [nFeatures,asArray] = getNFeatures(obj)
            asArray = arrayfun(@(x)size(x.data,2),obj.featureDatas);
            nFeatures = sum(asArray);
        end
    end
end