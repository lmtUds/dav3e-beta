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

function info = mdfFile()
    info.type = DataProcessingBlockTypes.RawDataImport;
    info.caption = 'MDF file (*.MF4)';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','extensions', 'value',{'*.MF4'}, 'internal',true),...
        Parameter('shortCaption','convertTo', 'value','binary', 'internal',true),...
        Parameter('shortCaption','conversionPath', 'value','./temp/', 'internal',true)
        ];
    info.apply = @apply;
end

function [data,prms] = apply(files,prms)
    clusters = [];
    allData = {};
    sensNames = {};
    clusNames = {};
    pointCounts = [];
    
    % import multi sensor data as one cycle per file
    for fidx = 1:numel(files)
        file = files{fidx};
        mdfObj = mdf(file);
        sensors = {};
        counter = 1;
        for i = 1: numel(mdfObj.ChannelGroup)
            for j = 1:numel(mdfObj.ChannelNames{i})
                names = mdfObj.ChannelNames{i};
                channel = names{j};
                if strcmp(channel,'time')   % exclude time data
                    continue
                end
                sensors{counter} = read(mdfObj,i,channel,'OutputFormat','Vector')';
                pointCounts(end + 1) = size(sensors{counter},2);
                sensNames{end + 1} = channel;
                counter = counter + 1;
            end
            clusNames{i} = mdfObj.ChannelGroup(i).AcquisitionName;
        end
        allData{fidx}= sensors;
    end
    % unify all sensors into multiple cycles per sensor
    pointCounts = unique(pointCounts,'stable');
    clusNames = unique(clusNames,'stable');
    try
        allData = vertcat(allData{:});
    catch ME
        error('Non uniform sensor count occured across multiple MDF files.');
    end
    sensors = cell(1,size(allData,2));
    for i = 1:size(allData,2)
        try 
            sensors{i} =  vertcat(allData{:,i});
        catch ME
            currDat = allData(:,i);
            sz = cellfun(@(x) size(x,2),currDat);
            nonMin = sz(sz ~= min(sz));
            pointRM = pointCounts ~= nonMin;
            if(size(pointRM,1)>1)
                pointRM = and(pointRM(1,:),pointRM(2:end,:));
            end
            pointCounts = pointCounts(pointRM);
            currDat = cellfun(@(x) x(1:min(sz)),currDat,'UniformOutput',false);
            sensors{i} = vertcat(currDat{:});
            warning(['Cycle lengths for Sensor ',num2str(i),' needed to be cut. New lengths are unified to ',num2str(min(sz))]);
%             error(['Cycle point mismatch for Sensor ',num2str(i),' while combining multiple MDF files']);
        end
    end
    
    % construct one cluster per point count group of sensors
    for i = 1:size(pointCounts,2)
        [~,filename,~] = fileparts(file);
        warning('Unable to extract sampling period from this filetype. Assuming 1 s.');
        c = Cluster('samplingPeriod',1,...
            'nCyclePoints',pointCounts(i),...
            'nCycles',fidx,...
            'caption',[filename,clusNames{i}]);
        
        ind = cellfun(@(x) size(x,2) == pointCounts(i),sensors);
        grouped = sensors(ind);
        gNames = sensNames(ind);
        for j = 1:numel(grouped)
            d = grouped{j};
            sensordata = SensorData.Memory(d);
%             sensor = Sensor(sensordata,'caption',...
%                 [filename,'mdfCluster',num2str(i),'sensor',num2str(j)]);
            sensor = Sensor(sensordata,'caption',gNames{j});
            c.addSensor(sensor);
        end
        
        if isempty(clusters)
            clusters = c;
        else
            clusters(end+1) = c;
        end
    end
    data.clusters = clusters;
end