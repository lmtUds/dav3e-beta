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

function info = addition()
    info.type = DataProcessingBlockTypes.VirtualSensor;
    info.caption = 'addition';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','sensor1', 'value','', 'enum',{''}),...
        Parameter('shortCaption','sensor2', 'value','', 'enum',{''})
        ];
    info.apply = @apply;
    info.updateParameters = @updateParameters;
end

function [data,params] = apply(data,params)
    prj = data.cluster.project;
    s1 = prj.getSensorByCaption(params.sensor1,'cluster');
    s2 = prj.getSensorByCaption(params.sensor2,'cluster');
    data = s1.data + s2.data;
end

function updateParameters(params,project)
    for i = 1:numel(params)
        if params(i).shortCaption == string('sensor1')
            params(i).enum = cellstr(project.getSensors().getCaption('cluster'));
            if isempty(params(i).value)
                params(i).value = params(i).enum{1};
            end
            params(i).updatePropGridField();
        elseif params(i).shortCaption == string('sensor2')
            params(i).enum = cellstr(project.getSensors().getCaption('cluster'));
            if isempty(params(i).value)
                params(i).value = params(i).enum{1};
            end
            params(i).updatePropGridField();
        end
    end
end