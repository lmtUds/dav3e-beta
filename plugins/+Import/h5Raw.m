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

function info = h5Raw()
    info.type = DataProcessingBlockTypes.RawDataImport;
    info.caption = 'HDF5 raw data file (*.h5)';
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
    clusters = [];
    for fidx = 1:numel(files)
        file = files{fidx};
        
        info = h5info(file);
        setCount = size(info.Datasets,1);
        for i = 1:setCount
            d = h5read(file,['/',info.Datasets(i).Name]);

            dim = size(d);

            [~,filename,~] = fileparts(file);
            sensordata = SensorData.Memory(d);
            sensor = Sensor(sensordata,'caption',filename);

            warning('Unable to extract sampling period from this filetype. Assuming 1 s.');
            c = Cluster('samplingPeriod',1,...
                'nCyclePoints',size(d,2),...
                'nCycles',size(d,1),...
                'caption',[filename,num2str(i)]);
            c.addSensor(sensor);

            if isempty(clusters)
                clusters = c;
            else
                clusters(end+1) = c;
            end
        end
    end
    data.clusters = clusters;
end