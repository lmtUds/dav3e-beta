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

function info = matFile()
    info.type = DataProcessingBlockTypes.RawDataImport;
    info.caption = 'MAT file (*.mat)';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','extensions', 'value',{'*.mat'}, 'internal',true),...
        Parameter('shortCaption','convertTo', 'value','memory', 'internal',true),...
        Parameter('shortCaption','conversionPath', 'value','./temp/', 'internal',true)
        ];
    info.apply = @apply;
end

function [data,prms] = apply(files,prms)
    clusters = [];
    for fidx = 1:numel(files)
        file = files{fidx};
        [~,filename,~] = fileparts(file);
        d = load(file);
        fields = fieldnames(d);
        
        warning('Unable to extract sampling period from this filetype. Assuming 1 s.');
        c = Cluster('samplingPeriod',1,...
            'nCyclePoints',size(d.(fields{1}),2),...
            'nCycles',size(d.(fields{1}),1),...
            'caption',filename);        
        
        for i = 1:numel(fields)
            sensordata = SensorData.Memory(d.(fields{i}));
            sensor = Sensor(sensordata,'caption',fields{i});
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