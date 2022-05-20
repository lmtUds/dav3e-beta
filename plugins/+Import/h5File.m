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

function info = h5File()
    info.type = DataProcessingBlockTypes.RawDataImport;
    info.caption = 'HDF5 file (*.h5)';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','extensions', 'value',{'*.h5'}, 'internal',true),...
        Parameter('shortCaption','convertTo', 'value','memory', 'internal',true),...
        Parameter('shortCaption','conversionPath', 'value','./temp/', 'internal',true)
        ];
    info.apply = @apply;
end

function [data,prms] = apply(files,prms)
    warning('Unable to extract sampling period from this filetype. Assuming 1 s.');
    clusters = [];
    for fidx = 1:numel(files)
        file = files{fidx};
        [~,filename,~] = fileparts(file);
        
        datasets = getAllH5Datasets(file);
        [map,exit] = Gui.Dialogs.ImportGenericH5(datasets);
        if ~exit %dialog closed without selection
            continue
        end
        
        clusterNames = keys(map);
        for i = 1:numel(clusterNames)
            clusterDatasets = map(clusterNames{i});
            
            d = h5read(file,clusterDatasets{1});
            fields = fieldnames(d);
            if size(d.(fields{1}),2) == 1
                in = inputdlg('how many points per cycle?');
                nCyclePoints = str2double(in{1});
                nCycles = floor(numel(d.(fields{1})) / nCyclePoints);
                wasLinear = true;
            else
                nCyclePoints = size(d.(fields{1}),2);
                nCycles = size(d.(fields{1}),1);
                wasLinear = false;
            end
            nPoints = nCyclePoints * nCycles;
            
            c = Cluster('samplingPeriod',1,...
                    'nCyclePoints',nCyclePoints,...
                    'nCycles',nCycles,...
                    'caption',clusterNames{i});
                
            for j = 1:numel(clusterDatasets)
                d = h5read(file,clusterDatasets{j});
                fields = fieldnames(d);
                for k = 1:numel(fields)
                    sdata = double(d.(fields{k}));
                    if wasLinear
                        sdata = reshape(sdata(1:nPoints),nCyclePoints,nCycles)';
                    end
                    sensordata = SensorData.Memory(sdata);
                    sensor = Sensor(sensordata,'caption',fields{k});
                    c.addSensor(sensor);
                end
            end
            
            if isempty(clusters)
                clusters = c;
            else
                clusters(end+1) = c;
            end
        end
    end
    data.clusters = clusters;
end