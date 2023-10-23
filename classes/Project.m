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

classdef Project < handle
    properties
        poolPreprocessingChains
        poolCyclePointSets
        poolIndexPointSets
        poolFeatureDefinitionSets
        
        % measurements
        ranges
        clusters
        groupings
        components
        models
        
%         currentMeasurement
        currentCluster
        
        timeOrigin
        mergedFeatureData = Data.empty
        
        currentModel
        currentGrouping
    end
    
    properties (Dependent)
        currentCyclePointSet
        currentIndexPointSet
        currentPreprocessingChain
        currentFeatureDefinitionSet
    end    
    
    methods
        function obj = Project()
            obj.poolPreprocessingChains = PreprocessingChain();
            obj.poolCyclePointSets = PointSet();
            obj.poolIndexPointSets = PointSet();
            obj.poolFeatureDefinitionSets = FeatureDefinitionSet();
            obj.ranges = Range.empty;
            obj.models = Model();
            obj.groupings = Grouping();
            obj.timeOrigin = datetime.empty;
            obj.currentModel = obj.models(1);
            obj.currentGrouping = obj.groupings(1);
        end
        
        function s = toStruct(objArray)
            s = struct();
            for i = 1:numel(objArray)
                obj = objArray(i);
                s(i).poolPreprocessingChains = obj.poolPreprocessingChains.toStruct();
                s(i).poolCyclePointSets = obj.poolCyclePointSets.toStruct();
                s(i).poolIndexPointSets = obj.poolIndexPointSets.toStruct();
                s(i).poolFeatureDefinitionSets = obj.poolFeatureDefinitionSets.toStruct();
                s(i).ranges = obj.ranges.toStruct();
                s(i).clusters = obj.clusters.toStruct();
                s(i).groupings = obj.groupings.toStruct();
                s(i).components = obj.components.toStruct();
                s(i).models = obj.models.toStruct();
                s(i).currentCluster = obj.currentCluster.getUUID();
                s(i).timeOrigin = obj.timeOrigin;
                %s(i).mergedFeatureData = obj.mergedFeatureData.;
            end
        end

        function val = get.currentCyclePointSet(obj)
            val = obj.getCurrentSensor().cyclePointSet;
        end
        
        function set.currentCyclePointSet(obj,val)
            s = obj.getCurrentSensor();
            s.cyclePointSet = val;
        end
        
        function val = get.currentIndexPointSet(obj)
            val = obj.getCurrentSensor().indexPointSet;
        end
        
        function set.currentIndexPointSet(obj,val)
            s = obj.getCurrentSensor();
            s.indexPointSet = val;
        end        
        
        function val = get.currentPreprocessingChain(obj)
            val = obj.getCurrentSensor().preprocessingChain;
        end
        
        function set.currentPreprocessingChain(obj,val)
            s = obj.getCurrentSensor();
            s.preprocessingChain = val;
        end
        
        function val = get.currentFeatureDefinitionSet(obj)
            val = obj.getCurrentSensor().featureDefinitionSet;
        end
        
        function set.currentFeatureDefinitionSet(obj,val)
            s = obj.getCurrentSensor();
            s.featureDefinitionSet = val;
        end         
        
        function addCluster(obj,clusters)
            clusters = clusters(:);
            
            % ensure unique captions
            if ~isempty(obj.clusters)
                captions = cellstr(obj.clusters.getCaption());
                for i = 1:numel(clusters)
                    clusters(i).setCaption(matlab.lang.makeUniqueStrings(char(clusters(i).getCaption()),captions))
                end
            end
            captions = matlab.lang.makeUniqueStrings(cellstr(clusters.getCaption()));
            for i = 1:numel(captions)
                clusters(i).setCaption(captions{i});
            end
            
            n = numel(clusters);
            if isempty(obj.clusters)
                obj.clusters = clusters;
                obj.currentCluster = clusters(end);
            else
                obj.clusters(end+1:end+n) = clusters;
            end
            
            for i = 1:numel(clusters)
                clusters(i).project = obj;
                clusters(i).sensors.init();
            end
        end
        
        function setCurrentCluster(obj,cluster)
            if isnumeric(cluster)
                cluster = obj.clusters(cluster);
            elseif all(islogical(cluster))
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
            if isempty(cluster)
                cluster = Cluster.empty;
            end
        end
        
        function removeCluster(obj,clusters)
            found = ismember(obj.clusters,clusters);
            for i = 1:numel(found)
                if found(i)
                    obj.clusters(found(i)).project = [];
                end
            end
            
            obj.clusters(found) = [];
        end
        
        function d = getLongestCycleDuration(obj)
            d = max(obj.clusters.getCycleDuration());
        end
        
        function s = getSensors(obj)
            s = Sensor.empty;
            for i = 1:numel(obj.clusters)
                cs = obj.clusters(i).sensors;
                s(end+1:end+numel(cs)) = cs;
            end
        end
        
        function s = getActiveSensors(obj)
            s = obj.getSensors();
            s = s(s.isActive());
        end
        
        function s = getSensorByCaption(obj,caption,varargin)
            sensors = obj.getSensors();
            captions = sensors.getCaption(varargin{1});
            s = sensors(ismember(captions,caption));
        end
        
        function s = getCurrentSensor(obj)
            s = obj.getCurrentCluster().getCurrentSensor();
        end
        
        function grouping = addGrouping(obj,grouping)
            if nargin < 2
                grouping = Grouping();
            end
            
            grouping = obj.makeCaptionsUnique(grouping,obj.groupings);

            grouping.addRange(obj.ranges);
            grouping.updateColors();
            obj.groupings = [obj.groupings,grouping];
            
            if isempty(obj.currentGrouping)
                obj.currentGrouping = grouping(1);
            end
        end
        
        function removeGrouping(obj,grouping)
            pos = find(ismember(obj.groupings,grouping));
            obj.groupings(pos) = [];
            if pos <= numel(obj.groupings)
                obj.currentGrouping = obj.groupings(pos);
            elseif pos > 1
                obj.currentGrouping = obj.groupings(pos-1);
            else
                obj.currentGrouping = Grouping.empty;
            end
        end
        
        function createGroupingFrom(obj,baseGrouping,maskGrouping,maskCats,action)
            new = obj.addGrouping();
            new.vals = baseGrouping.vals;
%             %new.colors = baseGrouping.colors;
%             new.updateColors();
            tempKeys = baseGrouping.colors.keys;
            tempColors = baseGrouping.colors.values;
            new.colors = containers.Map(tempKeys,tempColors);

            new.setCaption(baseGrouping.getCaption());
            obj.makeCaptionsUnique(new,obj.groupings);
            
            mask = ismember(maskGrouping.vals,maskCats);
            
            switch action
                case '<ignore>'
                    new.vals(mask) = '<ignore>';
                case '*'
                    for i = 1:numel(new.vals)
                        if mask(i)
                            new.vals(i) = [char(new.vals(i)) '*'];
                        end
                    end
                otherwise
                    error('Unknown action argument.');
            end
            new.updateColors();
        end
        
        function featData = computeFeatures(obj)
            featData = Data();
            cl = obj.clusters;
            for i = 1:numel(obj.clusters)
                r = cl(i).getCycleRanges().getCycleIndices(cl(i));
                offsets = cl(i).getCycleOffsets();
                [fData,h] = cl(i).computeFeatures(r);
                if isempty(fData)
                    cl(i).featureData = Data.empty;
                    continue
                end

                featData(i) = Data(fData,offsets(r));
                featData(i).featureCaptions = h;
                cl(i).featureData = featData(i);
            end
        end
        
        function data = mergeFeatures(obj,resolve,ignoreTracks)
            % Merges all features that have previously been computed with
            % computeFeatures() into one big Data matrix. It first builds a
            % cluster matrix and resolves missing clusters with the "time"
            % or "track" method. The "time" method deletes all rows with
            % missing clusters, the "track" method deletes all tracks with
            % missing clusters. The method is given as the "resolve"
            % argument, default is "time". The tracks given in
            % "ignoreTracks" are deleted before the resolution. The Data
            % merge methods are then used with the complete cluster matrix.
            if nargin < 2
                resolve = string('time'); % alternative: tracks
            else
                resolve = string(resolve);
            end
            if nargin < 3
                ignoreTracks = string.empty;
            end
            
            % update grouping data
            for i = 1:numel(obj.clusters)
                if isempty(obj.clusters(i).featureData)
                    continue;
                end
                groupingData = [];
                for j = 1:numel(obj.groupings)
                    groupingData = [groupingData, obj.groupings(j).getTargetVector(obj.clusters(i).getCycleRanges(),obj.clusters(i))];
                end
%                 groupingData(any(isundefined(groupingData),2),:) = [];
%                 if ~isempty(obj.clusters(i).featureData)
                    obj.clusters(i).featureData.groupings = groupingData;
                    obj.clusters(i).featureData.groupingCaptions = obj.groupings.getCaption();
%                 end
            end
            
            [clusterMat,clusterAvailable,timeMat,tracks] = obj.buildClusterMatrix();
            clusterMat(:,ismember(tracks,ignoreTracks)) = [];
            clusterAvailable(:,ismember(tracks,ignoreTracks)) = [];
            if resolve == 'time'
                notComplete = ~all(clusterAvailable,2);
                clusterMat(notComplete,:) = [];
                clusterAvailable(notComplete,:) = [];
                timeMat(notComplete,:) = [];
            elseif resolve == 'tracks'
                notComplete = ~all(clusterAvailable,1);
                clusterMat(:,notComplete) = [];
                clusterAvailable(:,notComplete) = [];
                timeMat(notComplete,:) = [];
                tracks(notComplete) = [];
            else
                error('Unknown resolution method.');
            end
            
%             for i = 1:numel(clusterMat)
%                 featureDataMat(i) = clusterMat(i).featureData;
%             end
%             featureDataMat = reshape(featureDataMat,size(clusterMat));
            
%             datas = Data();
%             for i = 1:size(clusterMat,2)
%                 datas(i) = Data.mergeVertical(featureDataMat(:,i));
%             end
%             data = Data.mergeHorizontal(datas,clusterMat,timeMat,0.1);
            data = Data.mergeAll([],clusterMat,timeMat,0.1);
            data.abscissa = 1:numel(data.abscissa);
            data.groupingCaptions = cellstr(obj.groupings.getCaption());
            data.setCaption('features');
            invalid = sum(isnan(data.data),1) ./ size(data.data,1) > 0.5;
            data.featureSelection(invalid) = [];
            data.featureCaptions(invalid) = [];
            data.data(:,invalid) = [];
            obj.mergedFeatureData = data;
        end
        
        function [clusterMat,clusterAvailable,timeMat,tracks] = buildClusterMatrix(obj)
            % Arranges the available clusters in a matrix depending on
            % their offset (dim 1) and track (dim 2). If two clusters
            % belong to the same track in the same time interval, a cluster
            % collision error is raised.
            clusterTimes = obj.getClusterTimeRanges();
            clusterAvailable = false(size(clusterTimes,1),1);
            tracks = string.empty;
            clusterMat(size(clusterTimes,1),1) = Cluster();
            
            for i = 1:size(clusterTimes,1)
                c = obj.getClustersInTimeRange(clusterTimes(i,:));
                c(~c.hasActiveSensors()) = [];
                if numel(unique([c.track])) < numel(c)
                    error('Cluster collision!');
                end
                for j = 1:numel(c)
                    if ~ismember(c(j).track,tracks)
                        tracks(end+1) = c(j).track;
                    end
                    
                    % cluster is not available if it has no features
                    % (eg. because no sensor in the cluster is active)
                    if ~isempty(c(j).featureData) 
                        clusterAvailable(i,tracks==c(j).track) = true;
                    else
                        clusterAvailable(i,tracks==c(j).track) = false;
                    end
                    
                    clusterMat(i,tracks==c(j).track) = c(j);
                end
            end
            
            % remove clusters in track where no cluster is available
            % otherwise, this column of zeros would interfere with the
            % resolution (no times where all clusters are available)
            noClusterInTrack = ~any(clusterAvailable,1);
            tracks(noClusterInTrack) = [];
            clusterMat(:,noClusterInTrack) = [];
            clusterAvailable(:,noClusterInTrack) = [];
            
            noClusterInRow = ~any(clusterAvailable,2);
            clusterMat(noClusterInRow,:) = [];
            clusterAvailable(noClusterInRow,:) = [];
            clusterTimes(noClusterInRow,:) = [];
            
            if isempty(clusterMat)
                error('No features have been computed.');
            end
            
            timeMat = clusterTimes;
        end
        
        function tRange = getClusterTimeRanges(obj)
            % Returns time intervals in which the cluster configuration
            % does not change. Each interval can have its own longest
            % cycle, missing cycles, etc.
            tRange = obj.clusters.getClusterTimeRange();
            tRange = unique(tRange(:));
            tRange = [tRange(1:end-1),tRange(2:end)];
        end
        
        function c = getClustersInTimeRange(obj,tRange)
            % Returns all clusters that are completely within the given
            % time range.
            c = Cluster.empty;
            for i = 1:numel(obj.clusters)
                ctr = obj.clusters(i).getClusterTimeRange();
                if (ctr(1)<=tRange(1)) && (tRange(2)<=ctr(2))
                    c(end+1) = obj.clusters(i);
                end
            end
        end
        
        function plotClusterTimeline(obj)
            figure, axes, hold on
            cm = containers.Map();
            samplingRates = [];
            for i = 1:numel(obj.clusters)
                samplingRates(end+1) = obj.clusters(i).samplingRate;
                cap = char(obj.clusters(i).getCaption());
                if cm.isKey(cap)
                    cm(cap) = [cm(cap), obj.clusters(i)];
                else
                    cm(cap) = obj.clusters(i);
                end
            end
            samplingRates = [min(samplingRates), max(samplingRates)];
            k = keys(cm);
            yoffset = 0;
            for i = 1:numel(k)
                cl = cm(k{i});
                for j = 1:numel(cl)
                    c = cl(j);
                    s = obj.timeOrigin + seconds(c.offset);
                    ns = numel(c.sensors);
                    p = fill([s,s+seconds(c.getDuration()),s+seconds(c.getDuration()),s],[yoffset+.05,yoffset+.05,yoffset+ns-.05,yoffset+ns-.05],'red');
                    p.FaceColor = [.8,.8,.95];
                    p.EdgeColor = [.3,.3,.8];
                    srRatio = (c.samplingRate - samplingRates(1)) / samplingRates(2) * 0.003 + 0.001;
                    step = 1 / srRatio;
                    for m = 1:round(srRatio*c.getDuration())
                        line([s+seconds(m*step),s+seconds(m*step)],[yoffset+.05,yoffset+ns-.05],'Color','k');
                    end
                end
                yoffset = yoffset + ns;
            end
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
        
        function addCycleRange(obj,r)
            obj.ranges = [obj.ranges,r];
            for i = 1:numel(obj.groupings)
                obj.groupings(i).addRange(r);
            end
            for i = 1:numel(obj.components)
                obj.components(i).addRange(r);
            end
        end
        
        function removeCycleRange(obj,r)
            obj.ranges(ismember(obj.ranges,r)) = [];
            for i = 1:numel(obj.groupings)
                obj.groupings(i).removeRange(r);
            end
            for i = 1:numel(obj.components)
                obj.components(i).removeRange(r);
            end            
        end
        
        function sortCycleRanges(obj)
            pos = obj.ranges.getTimePosition();
            if ~isempty(pos)
                [~,idx] = sort(pos(:,1));
                obj.ranges = obj.ranges(idx);
            end
        end
        
        function sortGroupings(obj)
            obj.sortCycleRanges();
            for i = 1:numel(obj.groupings)
                obj.groupings(i).sortRanges(obj.ranges);
            end
        end
        
        function grouping = getGroupingByCaption(obj,caption)
            grouping = obj.groupings(obj.groupings.getCaption() == caption);
        end
        
        %% PreprocessingChains
        function ppc = addPreprocessingChain(obj,ppc)
            if nargin < 2
                ppc = PreprocessingChain();
            end
            ppc.setCaption(matlab.lang.makeUniqueStrings(...
                char(ppc.getCaption()),cellstr(obj.poolPreprocessingChains.getCaption())));
            obj.poolPreprocessingChains(end+1) = ppc;
        end
        
        function removePreprocessingChain(obj,ppc)
            sensorsWithPPC = obj.checkForSensorsWithPreprocessingChain(ppc);
            if ~isempty(sensorsWithPPC)
                error('One or more sensors still refer to this preprocessing chain: %s',...
                    strjoin(sensorsWithPPC.getCaption(),','));                
            end
            toDelete = ismember(obj.poolPreprocessingChains,ppc);
            obj.poolPreprocessingChains(toDelete) = [];
        end
        
        function removePreprocessingChainAt(obj,idx,replaceWith)
            if nargin < 3
                replaceWith = false;
            end            
            obj.removePreprocessingChain(obj.poolPreprocessingChains(idx,replaceWith));
        end
        
        function sensorsWithPPC = checkForSensorsWithPreprocessingChain(obj,ppc)
            sensors = obj.getSensors();
            ppcs = [sensors.preprocessingChain];
            sensorsWithPPC = sensors(ismember(ppcs,ppc));
        end
        
        function replacePreprocessingChainInSensors(obj,oldPPC,newPPC)
            sensorsWithPPC = obj.checkForSensorsWithPreprocessingChain(oldPPC);
            for i = 1:numel(sensorsWithPPC)
                sensorsWithPPC(i).preprocessingChain = newPPC;
            end            
        end
        
        %% CyclePointSets
        function cps = addCyclePointSet(obj,cps)
            if nargin < 2
                cps = PointSet();
                cps.setCaption('cycle point set');
                cps.addPoint(obj.getCurrentCluster().makeCyclePoint(0));
            end
            cps.setCaption(matlab.lang.makeUniqueStrings(...
                char(cps.getCaption()),cellstr(obj.poolCyclePointSets.getCaption())));
            obj.poolCyclePointSets(end+1) = cps;
        end
        
        function removeCyclePointSet(obj,cps)
            sensorsWithCps = obj.checkForSensorsWithCyclePointSet(cps);
            if ~isempty(sensorsWithCps)
                error('One or more sensors still refer to this preprocessing chain: %s',...
                    strjoin(sensorsWithCps.getCaption(),','));                
            end
            toDelete = ismember(obj.poolCyclePointSets,cps);
            obj.poolCyclePointSets(toDelete) = [];
        end
        
        function removeCyclePointSetAt(obj,idx,replaceWith)
            if nargin < 3
                replaceWith = false;
            end            
            obj.removeCyclePointSet(obj.poolCyclePointSets(idx,replaceWith));
        end
        
        function sensorsWithCps = checkForSensorsWithCyclePointSet(obj,cps)
            sensors = obj.getSensors();
            ppcs = [sensors.cyclePointSet];
            sensorsWithCps = sensors(ismember(ppcs,cps));
        end
        
        function replaceCyclePointSetInSensors(obj,oldCps,newCps)
            sensorsWithCps = obj.checkForSensorsWithCyclePointSet(oldCps);
            for i = 1:numel(sensorsWithCps)
                sensorsWithCps(i).cyclePointSet = newCps;
            end            
        end
        
        %% IndexPointSets
        function ips = addIndexPointSet(obj,ips)
            if nargin < 2
                ips = PointSet();
                ips.setCaption('index point set');
                ips.addPoint(obj.getCurrentCluster().makeIndexPoint(0));
            end
            ips.setCaption(matlab.lang.makeUniqueStrings(...
                char(ips.getCaption()),cellstr(obj.poolIndexPointSets.getCaption())));
            obj.poolIndexPointSets(end+1) = ips;
        end
        
        function removeIndexPointSet(obj,ips)
            sensorsWithIps = obj.checkForSensorsWithIndexPointSet(ips);
            if ~isempty(sensorsWithIps)
                error('One or more sensors still refer to this preprocessing chain: %s',...
                    strjoin(sensorsWithIps.getCaption(),','));                
            end
            toDelete = ismember(obj.poolIndexPointSets,ips);
            obj.poolIndexPointSets(toDelete) = [];
        end
        
        function removeIndexPointSetAt(obj,idx,replaceWith)
            if nargin < 3
                replaceWith = false;
            end            
            obj.removeIndexPointSet(obj.poolIndexPointSets(idx,replaceWith));
        end
        
        function sensorsWithIps = checkForSensorsWithIndexPointSet(obj,ips)
            sensors = obj.getSensors();
            ppcs = [sensors.indexPointSet];
            sensorsWithIps = sensors(ismember(ppcs,ips));
        end
        
        function replaceIndexPointSetInSensors(obj,oldIps,newIps)
            sensorsWithPPC = obj.checkForSensorsWithIndexPointSet(oldIps);
            for i = 1:numel(sensorsWithPPC)
                sensorsWithPPC(i).indexPointSet = newIps;
            end            
        end
        
        %% FeatureDefinitionSets
        function fds = addFeatureDefinitionSet(obj,fds)
            if nargin < 2
                fds = FeatureDefinitionSet();
            end
            fds.setCaption(matlab.lang.makeUniqueStrings(...
                char(fds.getCaption()),cellstr(obj.poolFeatureDefinitionSets.getCaption())));
            obj.poolFeatureDefinitionSets(end+1) = fds;
        end
        
        function removeFeatureDefinitionSet(obj,fds)
            sensorsWithFds = obj.checkForSensorsWithFeatureDefinitionSet(fds);
            if ~isempty(sensorsWithFds)
                error('One or more sensors still refer to this feature definition set: %s',...
                    strjoin(sensorsWithFds.getCaption(),','));                
            end
            toDelete = ismember(obj.poolFeatureDefinitionSets,fds);
            obj.poolFeatureDefinitionSets(toDelete) = [];
        end
        
        function removeFeatureDefinitionSetAt(obj,idx,replaceWith)
            if nargin < 3
                replaceWith = false;
            end            
            obj.removeFeatureDefinitionSet(obj.poolFeatureDefinitionSets(idx,replaceWith));
        end
        
        function sensorsWithFds = checkForSensorsWithFeatureDefinitionSet(obj,fds)
            sensors = obj.getSensors();
            fdss = [sensors.featureDefinitionSet];
            sensorsWithFds = sensors(ismember(fdss,fds));
        end
        
        function replaceFeatureDefinitionSetInSensors(obj,oldFds,newFds)
            sensorsWithFds = obj.checkForSensorsWithFeatureDefinitionSet(oldFds);
            for i = 1:numel(sensorsWithFds)
                sensorsWithFds(i).featureDefinitionSet = newFds;
            end            
        end        
        
        %% Models
        function model = addModel(obj,model)
            if nargin < 2
                model = Model();
            end
            model.setCaption(matlab.lang.makeUniqueStrings(...
                char(model.getCaption()),cellstr(obj.models.getCaption())));
            obj.models(end+1) = model;
        end
        
        function removeModel(obj,model)
            obj.models(ismember(obj.models,model)) = [];
        end
        
        function removeModelAt(obj,idx)
            obj.removeModel(obj.models(idx));
        end        
        
        %%
        function saveProject(obj,path,name)
            % create folder with DAVE folder icon
            [status,~] = system(['cd ' pwd '\template_folder & makedavedir.bat']);
            if status
                error('Could not create template folder.');
            end
            wholePath = fullfile(path,name);
            
            fileattrib template_folder\davefolder;
            movefile('template_folder\davefolder',['template_folder\' name]);
            fileattrib(['template_folder\' name]);
            movefile(['template_folder\' name],path);
            fileattrib(wholePath,'+s');
            fileattrib(fullfile(wholePath,'desktop.ini'),'+s +h');
            fileattrib(fullfile(wholePath,'dave.ico'),'+s +h');
            
            function saveObjectsTo(folderName,objs,splitToFiles)
                if nargin <= 2
                    splitToFiles = false;
                end
                
                if splitToFiles
                    mkdir(wholePath,folderName);
                    for i = 1:numel(objs)
                        o = objs(i);
                        fid = fopen(fullfile(wholePath,folderName,...
                            [char(o.getUUID()) '.txt']),'wt');
                        fprintf(fid,o.jsondump());
                        fclose(fid);
                    end
                else
                    fid = fopen(fullfile(wholePath,...
                        [folderName '.txt']),'wt');
                    fprintf(fid,objs.jsondump());
                    fclose(fid);
                end
            end
            
            saveObjectsTo('cyclePointSets',obj.poolCyclePointSets,true);
            saveObjectsTo('indexPointSets',obj.poolIndexPointSets,true);
            saveObjectsTo('ranges',obj.ranges);

        end
        
        function o = resolveUUIDRefs(obj,uuidString)
            tok = regexp(uuidString,'^(\w+)::(\w{32})$','tokens');
            if isempty(tok)
                o = uuidString;
                return
            end
            type = tok{1}(1);
            uuid = tok{1}(2);
            switch type
                case 'Sensor'
                    
                case 'PointSet'
                    cps = ismember(uuid,obj.poolCyclePointSets.getUUID());
                    if any(cps)
                        o = obj.poolCyclePointSets(cps);
                        return
                    end
                    ips = ismember(uuid,obj.poolIndexPointSets.getUUID());
                    if any(ips)
                        o = obj.poolIndexPointSets(ips);
                        return
                    end
            end
            error('Could not find the reference.');
        end
        
        function importFile(obj,files,importAs)
            imports = obj.getAvailableImportMethods(true);
            captions = keys(imports);
            types = strncmpi(importAs,captions,numel(char(importAs)));
            if ~any(types)
                error('Type not found.');
            elseif sum(types) > 1
                error('Type ambiguous.')
            end
            importBlock = DataProcessingBlock(imports(captions{types}));
            if strcmp(importBlock.shortCaption,'qDasFile')
                data = importBlock.apply(files);
                obj.addCluster(data.clusters);
                for i=1:size(data.ranges,2)
                    obj.addCycleRange(data.ranges(i));
                end
                obj.addGrouping(data.grouping);
            else
                data = importBlock.apply(files);
                obj.addCluster(data.clusters);
            end
            
            if isfield(data,'timeOrigin')
                if isempty(obj.timeOrigin)
                    obj.timeOrigin = data.timeOrigin;
                else
                    timeDiff = seconds(data.timeOrigin - obj.timeOrigin);
                    for i = 1:numel(data.clusters)
                        data.clusters(i).offset = data.clusters(i).offset + timeDiff;
                    end
                end
            end
        end
        
        function importGasmixerFile(obj,filename)
            [~, ~, ext] = fileparts(filename);
            switch lower(ext)
              case '.json'
                importGasmixerFileJSON(obj, filename)
              case '.h5'
                importGasmixerFileH5(obj, filename)
              otherwise  % Under all circumstances SWITCH gets an OTHERWISE!
                error('Unexpected file extension: %s', ext);
            end
            
        end
        
        function importGasmixerFileJSON(obj,filename)
            json = fileread(filename);
            data = jsondecode(json);

            defaults = data.defaults;
            fieldnames = fields(defaults);
            gasmixerFields = strncmp(fieldnames,'Gasmixer',8);
            defaults = rmfield(defaults,fieldnames(~gasmixerFields));
            fieldnames = fields(defaults);

            states = data.states;
            for i = 1:numel(states)
                tempstate = defaults;
                for j = 1:numel(fieldnames)
                    if isfield(states(i).setpoints,fieldnames{j})
                        tempstate.(fieldnames{j}) = states(i).setpoints.(fieldnames{j});
                    end
                end
                states(i).setpoints = tempstate;
            end
            
            t = cumsum(vertcat(states.duration));
            t = [[0;t(1:end-1)], t];
            t = t / 1000 + obj.getCurrentCluster().offset;
            cr = Range.empty;
            for i = 1:size(t,1)
                cr(i) = Range(t(i,:));
            end
            obj.addCycleRange(cr);
            
            setpoints = [states.setpoints];
            for i = 1:numel(fieldnames)
                g = obj.getGroupingByCaption(fieldnames{i});
                if isempty(g)
                    g = Grouping();
                    g.setCaption(fieldnames{i});
                    obj.addGrouping(g);
                end
                vals = vertcat(setpoints.(fieldnames{i}));
                g.setGroup(categorical(vals),cr);
                g.updateColors();
            end
        end
        
        function importCycleRangesAndGroupings(obj, time, groupings, groupnames, deleteOldRanges)
            nRanges = numel(obj.ranges);
            nGroupings = numel(obj.groupings);
            if deleteOldRanges
                for i=nRanges:-1:1
                    obj.removeCycleRange(obj.ranges(i))
                end
                for i=nGroupings:-1:1
                    obj.removeGrouping(obj.groupings(i))
                end 
            end
            
            cr = Range.empty;
            for i = 1:size(time,1)
                cr(i) = Range(time(i,:));
            end
            obj.addCycleRange(cr);
            
            for i = 1:numel(groupnames)
                g = obj.getGroupingByCaption(groupnames{i});
                if isempty(g)
                    g = Grouping();
                    g.setCaption(groupnames{i});
                    obj.addGrouping(g);
                end
                vals = vertcat(cellstr(num2str(groupings(:,i),'%-0.5g')));
                g.setGroup(categorical(vals),cr);
                g.updateColors();
            end

        end
        
        function importGasmixerFileH5(obj,filename)
            
            states = h5read(filename,'/statesequence');
            names = fieldnames(states);
            hw_setpoints = h5read(filename,'/hardware_setpoints');
            hw_names = fieldnames(hw_setpoints);
            states_mat = [];
            states_names = {};
            for i=1:length(names)
                if strcmp(names{i},'time')
                    continue
                end
                if strcmp(names{i},'state')
                    continue
                end
                if any(strcmp(hw_names,names{i}))
                    states.(names{i}) = hw_setpoints.(names{i});
                end
                states_mat = [states_mat; states.(names{i})];
                states_names = [states_names ,names(i)];
            end
            
            time = double([states.time(1:end-1)', states.time(2:end)'])/1000;
            time = time + obj.getCurrentCluster().offset;
            if numel(obj.ranges) > 0
                answer = questdlg('Retain or delete existing cycle ranges and groups ?', ...
                    'Cycle ranges and groups', ...
                    'Retain', 'Delete','Delete');
                % Handle response
                nRanges = numel(obj.ranges);
                nGroupings = numel(obj.groupings);
                switch answer
                    case 'Delete'
                        for i=nRanges:-1:1
                            obj.removeCycleRange(obj.ranges(i))
                        end
                        for i=nGroupings:-1:1
                            obj.removeGrouping(obj.groupings(i))
                        end
                    case 'Retain'

                end
            end
            cr = Range.empty;
            for i = 1:size(time,1)
                cr(i) = Range(time(i,:));
            end
            obj.addCycleRange(cr);
            
            setpoints = states_mat;
            for i = 1:numel(states_names)
                g = obj.getGroupingByCaption(states_names{i});
                if isempty(g)
                    g = Grouping();
                    g.setCaption(states_names{i});
                    obj.addGrouping(g);
                end
                vals = vertcat(cellstr(num2str(states.(states_names{i})','%-0.5g')));
                g.setGroup(categorical(vals(1:end-1)),cr);
                g.updateColors();
            end
        end
        
        function importCycleRangesAndGroups(obj,filename)
            t = readtable(filename, 'Delimiter','tab','Filetype', 'text');
            
            beginTime = t.beginTime;
            endTime = t.endTime;
            caption = string(t.caption);
            
            if numel(obj.ranges) > 0
                answer = questdlg('Retain or delete existing cycle ranges and groups ?', ...
                    'Cycle ranges and groups', ...
                    'Retain', 'Delete','Delete');
                % Handle response
                nRanges = numel(obj.ranges);
                nGroupings = numel(obj.groupings);
                switch answer
                    case 'Delete'
                        for i=nRanges:-1:1
                            obj.removeCycleRange(obj.ranges(i))
                        end
                        for i=nGroupings:-1:1
                            obj.removeGrouping(obj.groupings(i))
                        end
                    case 'Retain'

                end
            end
            
            cr = Range.empty;
            for i = 1:size(t,1)
                cr(i) = Range([beginTime(i), endTime(i)]);
                if ~ismissing(caption(i))
                    cr(i).setCaption(caption(i))
                end
            end
            obj.addCycleRange(cr);

            [groupsVarName, id] = setdiff(t.Properties.VariableNames, {'beginTime', 'endTime', 'caption','color'},'stable');
            groupCaptions = string.empty;
            colorCaptions = string.empty;
            for i=1:numel(id)
                groupCaptions(i) = '';
                colorCaptions(i) = '';
                varDesription = t.Properties.VariableDescriptions{id(i)};
                if ~isempty(varDesription)
%                     if contains(varDesription, 'Original column heading:')
%                         newStr = erase(varDesription,"'");
%                         newStr = erase(varDesription,string(''''));
%                         strSpl = strsplit(newStr, 'Original column heading: label:');
                        strSpl = strsplit(varDesription, 'label:');
                        if numel(strSpl) == 2
                            groupCaptions(i) = strSpl{2}; 
                        end
%                         strSpl = strsplit(newStr, 'color:');
%                         if numel(strSpl) == 2
%                             colorCaptions(i) = strSpl{2};
%                         end
%                     end
                end
            end
            
            for i = 1:numel(groupCaptions)
                if ~strcmp(groupCaptions(i),'')
                    gCaption = groupCaptions(i);
                    g = obj.getGroupingByCaption(gCaption);
                    if isempty(g)
                        g = Grouping();
                        g.setCaption(gCaption);
                        obj.addGrouping(g);
                    end
                    vals = string(vertcat(t.(groupsVarName{i})));
                    g.setGroup(categorical(vals),cr);
                    idColor = strcmp(colorCaptions, groupCaptions(i));
                    if any(idColor)
                        color = cellfun(@(x) str2double(strsplit(x,',')), t.(groupsVarName{idColor}),'UniformOutput', false);
                        for j=1:numel(color)
                            if ~isnan(color{j})
                                g.setColor(vals{j}, color{j} / 255);
                            end
                        end
                    end
                    g.updateColors();
                end
            end
            
            if numel(obj.groupings)==0 
                g = Grouping();
                obj.addGrouping(g);
            end
        
        end
    end
    
    methods (Static)
        function out = getAvailableImportMethods(force)
            persistent fe
            if ~exist('force','var')
                force = false;
            end
            if ~isempty(fe) && ~force
                out = fe;
                return
            end
            fe = parsePlugin('Import');
            out = fe;
        end
        
        function objsIn = makeCaptionsUnique(objsIn,objsExist)
            % ensure unique captions
            if ~isempty(objsExist)
                captions = cellstr(objsExist.getCaption());
                for i = 1:numel(objsIn)
                    objsIn(i).setCaption(matlab.lang.makeUniqueStrings(char(objsIn(i).getCaption()),captions))
                end
            end
            captions = matlab.lang.makeUniqueStrings(cellstr(objsIn.getCaption()));
            for i = 1:numel(objsIn)
                objsIn(i).setCaption(captions{i});
            end            
        end
    end    
end