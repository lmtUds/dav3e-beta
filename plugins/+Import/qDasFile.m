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

function info = qDasFile()
    info.type = DataProcessingBlockTypes.RawDataImport;
    info.caption = 'QDas file (*.dfd,*.dfx)';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','extensions', 'value',{'*.dfd','*.dfx'}, 'internal',true),...
        Parameter('shortCaption','convertTo', 'value','binary', 'internal',true),...
        Parameter('shortCaption','conversionPath', 'value','./temp/', 'internal',true)
        ];
    info.apply = @apply;
end

function [data,prms] = apply(files,prms)
    if mod(numel(files),2)~=0
        error('Please select an even number of files');
    end
    dataExts = {'.dfx'};
    infoExts = {'.dfd'};
    dataInds = cellfun(@(x) dataExtEval(x,dataExts),files,'UniformOutput',false);
    dataInds = horzcat(dataInds{:});
    infoInds = cellfun(@(x) dataExtEval(x,infoExts),files,'UniformOutput',false);
    infoInds = horzcat(infoInds{:});
    dataFiles = files(dataInds);
    infoFiles = files(infoInds);
    if numel(dataFiles)~=numel(infoFiles)
        error('Please select pairs of Data and Info files');
    end
    
    d = cell(1,size(dataFiles,2));
    t = cell(1,size(dataFiles,2));
    igno = cell(1,size(dataFiles,2));
    parfor i = 1:numel(dataFiles)
        reader = Import.QDasHelper.QDasReader();
        entries = reader.importFile(dataFiles{i},infoFiles{i});
        dTemp = cellfun(@(x) x.getMeasVals(), entries,'UniformOutput',false);
        d{i} = vertcat(dTemp{:});
        tTemp = cellfun(@(x) x.isIO(), entries,'UniformOutput',false);
        t{i} = vertcat(tTemp{:});
        iTemp = cellfun(@(x) x.getIgnore(), entries,'UniformOutput',false);
        igno{i} = vertcat(iTemp{:});
    end
    reader = Import.QDasHelper.QDasReader();
    entries = reader.importFile(dataFiles{1},infoFiles{1});
    module = entries{1}.info.module;
    d = vertcat(d{:});
    t = vertcat(t{:});
    igno = vertcat(igno{:});
    disp([num2str(sum(igno)) ' entries ignored']);
    d = d(~igno,:);
    t = t(~igno,:);
    
    sensorTag = ['QDAS' module];
    sensordata = SensorData.Memory(d);
    sensor = Sensor(sensordata,'caption',sensorTag);
    
    clusters = [];
    warning('Unable to extract sampling period from this filetype. Assuming 1 s.');
    c = Cluster('samplingPeriod',1,...
        'nCyclePoints',size(d,2),...
        'nCycles',size(d,1),...
        'caption',sensorTag);
    c.addSensor(sensor);

    if isempty(clusters)
        clusters = c;
    else
        clusters(end+1) = c;
    end
    data.clusters = clusters;
    
    rangeInds = [1,size(t,1)];
    for i = 2:size(t,1)
        if t(i)~=t(i-1)
            rangeInds(end,2) = i-1;
            rangeInds(end+1,1) = i;
        else
            continue
        end
    end
    rangeInds(end,2) = size(t,1);
    groupVals = zeros(size(rangeInds,1),1);
    ranges = [];
    for i = 1:size(rangeInds,1)
        groupVals(i) =t(rangeInds(i,1));  
        tPos = [(rangeInds(i,1)-1)*size(d,2),(rangeInds(i,2))*size(d,2)];
        ranges = [ranges,Range(tPos)];
    end
    groupVals = categorical(groupVals);
    grouping = Grouping();
    grouping.vals = groupVals;
    grouping.ranges = ranges;
    grouping.setCaption('QDasIO');
    
    data.ranges = ranges;
    data.grouping = grouping;
    
    function isInfo = infoExtEval(file, infoExts)
        [~,~,ext] = fileparts(file);
        isInfo = ismember(ext,infoExts);
    end
    function isData = dataExtEval(file, dataExts)
        [~,~,ext] = fileparts(file);
        isData = ismember(ext,dataExts);
    end
end