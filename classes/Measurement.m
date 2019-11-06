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

classdef Measurement < Descriptions
    properties
        ranges
        groupings
        components
        
        project
        clusters
        currentCluster
    end
    
    methods
        function obj = Measurement()
            obj = obj@Descriptions();
            obj.setCaption('measurement');
        end
        
        function project = getProject(objArray)
            project = [objArray.project];
        end
        
        function setCurrent(obj)
            obj.getProject().setActiveMeasurement(obj);
        end
        
        function addCluster(obj,clusters)
            clusters = clusters(:);
            n = numel(clusters);
            if isempty(obj.clusters)
                obj.clusters = clusters;
            else
                obj.clusters(end+1:end+n) = clusters;
            end
            
            for i = 1:numel(clusters)
                clusters(i).measurement = obj;
            end
        end
        
        function setCurrentCluster(obj,cluster)
            if isnumeric(cluster)
                cluster = obj.clusters(cluster);
            elseif all(isboolean(cluster))
                if sum(cluster) ~= 1
                    error('Exactly one cluster must be selected');
                else
                    cluster = obj.clusters(cluster);
                end
            end
            obj.currentCluster = cluster;
        end
        
        function cluster = getCurrentCluster(obj)
            cluster = obj.currentCluster;
        end
        
        function removeCluster(obj,clusters)
            found = ismember(obj.clusters,clusters);
            
            for i = 1:numel(found)
                obj.clusters(found(i)).measurement = [];
            end
            
            obj.clusters(found) = [];
        end
        
        function mask = getCycleMask(obj,cluster)
            cPos = obj.ranges.getCyclePosition(cluster);
            mask = false(max(cPos(:)),1);
            for i = 1:size(cPos,1)
                if any(mask(cPos(i,1):cPos(i,2)))
                    error('Cycle ranges may not overlap!');
                end
                mask(cPos(i,1):cPos(i,2)) = true;
            end
        end
        
        function featDatasets = computeFeatures(obj)
            featDatasets = FeatureDataSet.empty;

            for i = 1:numel(obj.clusters)
                if ~obj.clusters(i).hasActiveSensors()
                    continue
                end
                
                cycleMask = obj.getCycleMask(obj);
                cycleNumbers = cycleMask .* (1:numel(cycleMask))';
                cycleNumbers(cycleNumbers==0) = [];    
                
                fds = obj.clusters(i).computeFeatures(cycleMask);
                for j = 1:numel(fds)
                    fds(j).cycleNumbers = cycleNumbers;
                end
                featDatasets = [featDatasets, fds];
            end
        end        
    end
end