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

classdef SensorSet < Descriptions
    properties
        clusterStruct
    end
    
    methods
        function obj = SensorSet()
            obj@Descriptions();
            obj.clusterStruct = struct();
        end

        function updateSet(obj,project)
            obj.clusterStruct = struct();
            c = project.clusters;
            for i = 1:numel(c)
                s = c.sensors;
                for j = 1:numel(s)
                    temp = struct();
                    temp.cyclePointSet = s(j).cyclePointSet;
                    temp.indexPointSet = s(j).indexPointSet;
                    temp.preprocessingChain = s(j).preprocessingChain;
                    temp.featureDefinitionSet = s(j).featureDefinitionSet;
                    temp.active = s(j).active;
                    obj.clusterStruct.(char(c(i).getUUID())).(char(s(j).getUUID())) = temp;
                end
            end
        end
        
        function updateProject(obj,project)
            c = project.clusters;
            for i = 1:numel(c)
                for j = 1:numel(c.sensors)
                    s = obj.clusterStruct.(char(c(i).getUUID())).(char(c.sensors(j).getUUID));
                    c(i).sensors(j).cyclePointSet = s.cyclePointSet;
                    c(i).sensors(j).indexPointSet = s.indexPointSet;
                    c(i).sensors(j).preprocessingChain = s.preprocessingChain;
                    c(i).sensors(j).featureDefinitionSet = s.featureDefinitionSet;
                    c(i).sensors(j).active = s.active;
                end
            end
        end
    end
end