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

function info = fetcontrolFile()
    info.type = DataProcessingBlockTypes.RawDataImport;
    info.caption = 'FETcontrol (*.h5)';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','extensions', 'value',{'*.h5'}, 'internal',true),...
        Parameter('shortCaption','convertTo', 'value','memory', 'internal',true),...
        Parameter('shortCaption','conversionPath', 'value','./temp/', 'internal',true)
        ];
    info.apply = @apply;
end

function [data,prms] = apply(file,prms)
    file = file{1};
    try
        software = cell2mat(h5readatt(file,'/','software'));
        version = cell2mat(h5readatt(file,'/','version'));
        startTime = cell2mat(h5readatt(file,'/','starttime'));
    catch
        error('File does not have the expected format.');
    end
    
    if strcmp(version,'1706')
        cluster = load_v1706(file);
    elseif strcmp(version,'1802')
        cluster = load_v1802(file);
    end

    data.clusters = cluster;
    
    timeParts = cellfun(@str2double,strsplit(startTime,'_'));
    timeParts(1) = timeParts(1) + 2000;
    data.timeOrigin = datetime(timeParts);
end


function cluster = load_v1802(file)
    fileInfo = h5info(file);
    boards = fileInfo.Datasets;
    for i = numel(boards):-1:1
        if ~strcmp(boards(i).Name(1:5),'Board')
            boards(i) = [];
        end
    end
    
    cluster = [];
    for i = 1:numel(boards)
        data = h5read(file,['/' boards(i).Name]);

        cycleLengths = floor(([find(data.temp_cycle>1,1),...
                        find(data.gate_cycle>1,1),...
                        find(data.bulk_cycle>1,1),...
                        find(data.dcurrent_cycle>1,1),...
                        find(data.dsvoltage_cycle>1,1)]-1) / 2);

        cycleChoice = listdlg('PromptString','Main Cycle?',...
            'SelectionMode','Single',...
            'ListString',{'temperature','gate bias','substrate bias','voltage','current'});
        if isempty(cycleChoice)
            continue
        end
        pointsPerCycle = cycleLengths(cycleChoice);

        if pointsPerCycle == 0
            warning('No cycle found. Skipping this sensor.');
            continue
        end        
        
        f = fieldnames(data);
        fullCycles = floor(numel(data.(f{1})) / pointsPerCycle);
        
        c = Cluster('samplingPeriod',0.1,...
            'nCyclePoints',pointsPerCycle,...
            'nCycles',fullCycles,...
            'caption',boards(i).Name);
        if isempty(cluster)
            cluster = c;
        else
            cluster(end+1) = c;
        end
        
        for j = 1:numel(f)
            fullCycles = floor(numel(data.(f{j})) / pointsPerCycle);
            d = double(data.(f{j}));
            d = d(1:(fullCycles*pointsPerCycle));
            d = reshape(d,pointsPerCycle,fullCycles)';
            sData = SensorData.Memory(d);
            sensor = Sensor(sData,'caption',f{j});
            cluster(end).addSensor(sensor);
        end
    end
end


function cluster = load_v1706(file)
    fileInfo = h5info(file);
    sensors = fileInfo.Datasets;

    for i = 1:numel(sensors)
        sensorParameters = h5read(file,[sensors{1}(i).Name '/general parameters']);
%         tCycle = h5read(file,[sensors{1}(i).Name '/cycles/temp'])';
%         gCycle = h5read(file,[sensors{1}(i).Name '/cycles/gate bias'])';
%         sCycle = h5read(file,[sensors{1}(i).Name '/cycles/substrate'])';
%         uCycle = h5read(file,[sensors{1}(i).Name '/cycles/Uds'])';
        sensorData = h5read(file,['\' sensors(i).Name]);


    %     sampleRate = sensorParameters.sampleRate;
        sampleRate = sensorParameters.rate_s;
    %     c.Dauer(c.Modus==0) = [];
    %     longestCycleDuration = sum(c.Dauer);
        longestCycleDuration = sum(c(:,1));
    % % %     longestCycleDuration = sum(sCycle.Dauer);
    %     pointsPerCycle = longestCycleDuration*sampleRate;
        pointsPerCycle = longestCycleDuration/sampleRate;

        cluster(i) = class.project.cluster.Default('caption', sensors(i).Name);
        cluster(i).setSecondsPerPoint(seconds(0.1));

        f = fieldnames(sensorData);
        for j = 1:numel(f)
            fullCycles = floor(numel(sensorData.(f{j})) / pointsPerCycle);
            data = sensorData.(f{j});
            data = data(1:(fullCycles* pointsPerCycle));
            data = reshape(data,pointsPerCycle,fullCycles);
            sensor = class.project.Sensor('data',double(data), 'caption',f{j}, 'file',file);
            cluster(i).appendSensor(sensor);
        end
    end
end