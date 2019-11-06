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

classdef GuiModule < handle & matlab.mixin.Heterogeneous
    %% GUIMODULE - Base class for DAV³E GUI modules.
    % This class is a superclass of all GUI modules. It implements several
    % common convenience methods as well as necessary abstract methods
    % which must be implemented in each module.
    
    properties
        main  % The main figure.
        lastSensor
        lastCluster
        lastCyclePointSet
        lastIndexPointSet
        lastPreprocessingChain
        lastFeatureDefinitionSet
        lastGrouping
        lastModel
        
        lastSensorModificationDate
        lastClusterModificationDate
        lastCyclePointSetModificationDate
        lastIndexPointSetModificationDate
        lastPreprocessingChainModificationDate
        lastFeatureDefinitionSetModificationDate
        lastGroupingModificationDate
        lastModelModificationDate
        
        menuCallbackName
    end
    
    methods
        function obj = GuiModule(main)
            %% Constructor
            % in: main (the main figure)
            obj.main = main;
            obj.lastSensorModificationDate = datetime(0,1,1);
            obj.lastClusterModificationDate = datetime(0,1,1);
            obj.lastCyclePointSetModificationDate = datetime(0,1,1);
            obj.lastIndexPointSetModificationDate = datetime(0,1,1);
            obj.lastPreprocessingChainModificationDate = datetime(0,1,1);
            obj.lastFeatureDefinitionSetModificationDate = datetime(0,1,1);
            obj.lastGroupingModificationDate = datetime(0,1,1);
            obj.lastModelModificationDate = datetime(0,1,1);
        end
        
        function p = getProject(obj)
            %% Returns the current project.
            p = obj.main.project;
        end
        
        function s = getCurrentCluster(obj)
            %% Returns the current cluster.
            s = obj.main.project.getCurrentCluster();
        end        
        
        function s = getCurrentSensor(obj)
            %% Returns the current sensor.
            s = obj.main.project.getCurrentSensor();
        end
        
        function [panel,menu] = makeLayout(obj)
            %% Called upon creation to make the layout.
            % This method must be implemented by subclasses.
            % out: panel (handle to the panel in which the layout was made)
            % out: menu (handle to a menubar menu)
        end
        
        function allowed = canOpen(obj)
            %% Chekcs whether the module is allowed to be opened.
            % This method can be overridden in subclasses to achieve custom
            % behavior.
            allowed = true;
        end
        
        function onOpen(obj)
            %% Called right before the module is opened.
            % This method can be overridden in subclasses to achieve custom
            % behavior.
        end
        
        function onClose(obj)
            %% Called right before the module is closed.
            % This method can be overridden in subclasses to achieve custom
            % behavior.
            obj.lastCluster = obj.getProject().getCurrentCluster();
            obj.lastSensor = obj.getProject().getCurrentSensor();
            obj.lastCyclePointSet = obj.getProject().currentCyclePointSet;
            obj.lastIndexPointSet = obj.getProject().currentIndexPointSet;
            obj.lastPreprocessingChain = obj.getProject().currentPreprocessingChain;
            obj.lastFeatureDefinitionSet = obj.getProject().currentFeatureDefinitionSet;
            obj.lastGrouping = obj.getProject().currentGrouping;
            obj.lastModel = obj.getProject().currentModel;
            
            obj.lastSensorModificationDate = obj.lastSensor.getModifiedDate();
            obj.lastClusterModificationDate = obj.lastCluster.getModifiedDate();
            obj.lastCyclePointSetModificationDate = obj.lastCyclePointSet.getModifiedDate();
            obj.lastIndexPointSetModificationDate = obj.lastIndexPointSet.getModifiedDate();
            obj.lastPreprocessingChainModificationDate = obj.lastPreprocessingChain.getModifiedDate();
            obj.lastFeatureDefinitionSetModificationDate = obj.lastFeatureDefinitionSet.getModifiedDate();
            obj.lastGroupingModificationDate = obj.lastGrouping.getModifiedDate();
            obj.lastModelModificationDate = obj.lastModel.getModifiedDate();
        end
        
        function onCurrentSensorChanged(obj,sensor,oldSensor)
            %% Called right after the current sensor was changed.
            % This method can be overridden in subclasses to achieve custom
            % behavior.
            % in: sensor (the new sensor)
        end
        
        function onCurrentClusterChanged(obj,cluster,oldCluster)
            %% Called right after the current cluster was changed.
            % This method can be overridden in subclasses to achieve custom
            % behavior.
            % in: cluster (the new cluster)
        end
        
        function onCurrentPreprocessingChainChanged(obj,preprocessingChain)
            %% Called right after the current preprocessing was changed.
            % This method can be overridden in subclasses to achieve custom
            % behavior.
            % in: preprocessing chain (the new preprocessingChain)
        end        
        
        function onCurrentCyclePointSetChanged(obj,cyclePointSet)
            %% Called right after the current cycle point set was changed.
            % This method can be overridden in subclasses to achieve custom
            % behavior.
            % in: cycle point set (the new cyclePointSet)
        end

        function onCurrentIndexPointSetChanged(obj,indexPointSet)
            %% Called right after the current index point set was changed.
            % This method can be overridden in subclasses to achieve custom
            % behavior.
            % in: index point set (the new indexPointSet)
        end
        
        function onCurrentFeatureDefinitionSetChanged(obj,featureSet)
            %% Called right after the current feature set was changed.
            % This method can be overridden in subclasses to achieve custom
            % behavior.
            % in: feature set (the new featureSet)
        end        
        
        function reset(obj)
            %% Resets the module so that all data is loaded anew when it is opened the next time.
            % This method can be overridden in subclasses to achieve custom
            % behavior.
            obj.lastSensor = [];
            obj.lastCluster = [];
            obj.lastCyclePointSet = [];
            obj.lastIndexPointSet = [];
            obj.lastPreprocessingChain = [];
            obj.lastFeatureDefinitionSet = [];
            obj.lastGrouping = [];
            obj.lastModel = [];
            
            obj.lastSensorModificationDate = datetime(0,1,1);
            obj.lastClusterModificationDate = datetime(0,1,1);
            obj.lastCyclePointSetModificationDate = datetime(0,1,1);
            obj.lastIndexPointSetModificationDate = datetime(0,1,1);
            obj.lastPreprocessingChainModificationDate = datetime(0,1,1);
            obj.lastFeatureDefinitionSetModificationDate = datetime(0,1,1);
            obj.lastGroupingModificationDate = datetime(0,1,1);
            obj.lastModelModificationDate = datetime(0,1,1);
        end
        
        function val = sensorHasChanged(obj,sensor)
            if nargin < 2
                sensor = obj.getProject().getCurrentSensor();
            end
            if sensor ~= obj.lastSensor
                val = true;
            elseif sensor.getModifiedDate() ~= obj.lastSensorModificationDate
                val = true;
            else
                val = false;
            end
        end
        
        function val = clusterHasChanged(obj,cluster)
            if nargin < 2
                cluster = obj.getProject().getCurrentCluster();
            end
            if cluster ~= obj.lastCluster
                val = true;
            elseif cluster.getModifiedDate() ~= obj.lastClusterModificationDate
                val = true;
            else
                val = false;
            end
        end
        
        function val = cyclePointSetHasChanged(obj,cyclePointSet)
            if nargin < 2
                cyclePointSet = obj.getProject().currentCyclePointSet;
            end
            if cyclePointSet ~= obj.lastCyclePointSet
                val = true;
            elseif cyclePointSet.getModifiedDate() ~= obj.lastCyclePointSetModificationDate
                val = true;
            else
                val = false;
            end
        end
        
        function val = indexPointSetHasChanged(obj,indexPointSet)
            if nargin < 2
                indexPointSet = obj.getProject().currentIndexPointSet;
            end
            if indexPointSet ~= obj.lastIndexPointSet
                val = true;
            elseif indexPointSet.getModifiedDate() ~= obj.lastIndexPointSetModificationDate
                val = true;
            else
                val = false;
            end
        end
        
        function val = preprocessingChainHasChanged(obj,preprocessingChain)
            if nargin < 2
                preprocessingChain = obj.getProject().currentPreprocessingChain;
            end
            if preprocessingChain ~= obj.lastPreprocessingChain
                val = true;
            elseif preprocessingChain.getModifiedDate() ~= obj.lastPreprocessingChainModificationDate
                val = true;
            else
                val = false;
            end
        end
        
        function val = featureDefinitionSetHasChanged(obj,featureDefinitionSet)
            if nargin < 2
                featureDefinitionSet = obj.getProject().currentFeatureDefinitionSet;
            end
            if featureDefinitionSet ~= obj.lastFeatureDefinitionSet
                val = true;
            elseif featureDefinitionSet.getModifiedDate() ~= obj.lastFeatureDefinitionSetModificationDate
                val = true;
            else
                val = false;
            end
        end
        
        function val = groupingHasChanged(obj,grouping)
            if nargin < 2
                grouping = obj.getProject().currentGrouping;
            end
            if grouping ~= obj.lastGrouping
                val = true;
            elseif grouping.getModifiedDate() ~= obj.lastGroupingModificationDate
                val = true;
            else
                val = false;
            end
        end
        
        function val = modelHasChanged(obj,model)
            if nargin < 2
                model = obj.getProject().currentModel;
            end
            if model ~= obj.lastModel
                val = true;
            elseif model.getModifiedDate() ~= obj.lastModelModificationDate
                val = true;
            else
                val = false;
            end
        end
    end
end