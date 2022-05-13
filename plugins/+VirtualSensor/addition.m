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
        Parameter('shortCaption','caption','value','','editable', false),...
        Parameter('shortCaption','description','value','= sensor 1 + sensor 2','editable', false),...
        Parameter('shortCaption','virtual_sensor','value','','internal',true),...
        Parameter('shortCaption','sensor1_caption', 'value','', 'enum',{''}, 'caption', 'sensor 1'),...
        Parameter('shortCaption','sensor1', 'value',[], 'internal', true),...
        Parameter('shortCaption','sensor2_caption', 'value','', 'enum',{''}, 'caption', 'sensor 2'),...
        Parameter('shortCaption','sensor2', 'value',[], 'internal', true)
        ];
    info.apply = @apply;
    info.updateParameters = @updateParameters;
end

function [data,params] = apply(data,params)
    data = params.sensor1.data + params.sensor2.data;
end

function updateParameters(params,project)
    virtual_sensor = params(strcmp([params.shortCaption], 'virtual_sensor')).value;
    sensors = project.getSensors();
    sensors = sensors(sensors~=virtual_sensor);
    for i = 1:numel(params)
            % caption of the virtual sensor
        if strcmp(params(i).shortCaption, 'caption')
            params(i).value = virtual_sensor.caption;
            params(i).updatePropGridField();
            params(i).onChangedCallback = @()changeCaption(params,project);
        elseif strcmp(params(i).shortCaption, 'sensor1_caption')
            params(i).enum = cellstr(sensors.getCaption('cluster'));
            if isempty(params(i).value)
                params(i).value = params(i).enum{1};
            end
            params(i).updatePropGridField();
            params(i).onChangedCallback = @()updateParameters(params,project);
       elseif strcmp(params(i).shortCaption, 'sensor2_caption')
            params(i).enum = cellstr(sensors.getCaption('cluster'));
            if isempty(params(i).value)
                params(i).value = params(i).enum{1};
            end
            params(i).updatePropGridField();
            params(i).onChangedCallback = @()updateParameters(params,project);
       elseif strcmp(params(i).shortCaption, 'sensor1')
            idSensorCaption = strcmp([params.shortCaption], 'sensor1_caption');
            sensor = project.getSensorByCaption(params(idSensorCaption).value,'cluster');
            if numel(sensor)==0
                sensor = params(i).value;
                if numel(sensor)==0
                    
                else
                   params(idSensorCaption).value = sensor.getCaption('cluster'); 
                   params(idSensorCaption).updatePropGridField();
                end
            else
                params(i).value = sensor;
            end
            params(i).updatePropGridField();
        elseif strcmp(params(i).shortCaption, 'sensor2')
            idSensorCaption = strcmp([params.shortCaption], 'sensor2_caption');
            sensor = project.getSensorByCaption(params(idSensorCaption).value,'cluster');
            if numel(sensor)==0
                sensor = params(i).value;
                if numel(sensor)==0
                    
                else
                   params(idSensorCaption).value = sensor.getCaption('cluster'); 
                   params(idSensorCaption).updatePropGridField();
                end
            else
                params(i).value = sensor;
            end
            params(i).updatePropGridField();
        end
    end
end