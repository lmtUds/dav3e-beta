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

function VirtualSensors(main)
    fig = uifigure('Name','Virtual Sensors','WindowStyle','modal');
    grid = uigridlayout(fig,[2 2],'RowHeight',{'1x',22});
    propG = Gui.uiParameterBlockGrid('Parent',grid,...
        'ValueChangedFcn',@(src,event)Update(src,event,main));
    propG.Layout.Column = [1 2];
    bAdd = uibutton(grid,'Text','Add',...
        'ButtonPushedFcn',@(src, event)AddVirtualSensor(src, event, main, propG));
    bAdd.Layout.Column = 1;
    bDel = uibutton(grid,'Text','Delete',...
        'ButtonPushedFcn',@(src, event)RemoveVirtualSensor(src, event, main, propG));
    bDel.Layout.Column = 2;
    Refresh(propG, main);

    function AddVirtualSensor(src, event, main, propG)
        MethodMap = Sensor.getAvailableMethods(true);
        MethodNames = keys(MethodMap);
        [selection, exit] = ...
            Gui.Dialogs.Select('ListItems',MethodNames,...
                               'Name','New Virtual Sensors');
        if ~exit
            return
        end
        for i = 1:size(selection,1)
            virtualSensor = ...
                Sensor(DataProcessingBlock(MethodMap(selection{i})),...
                       'caption',selection{i});
            virtualSensor.dataProcessingBlock.parameters.getByCaption('virtual_sensor').value = virtualSensor;
            main.project.getCurrentCluster().addSensor(virtualSensor);    
        end
        Refresh(propG, main);
    end
    function RemoveVirtualSensor(src, event, main, propG)
        block = propG.getSelectedBlock();
        if isempty(block)
            return
        end
        id = [main.project.getCurrentCluster().sensors.dataProcessingBlock] == block;
        virtual_sensors = main.project.getCurrentCluster().sensors([main.project.getCurrentCluster().sensors.virtual]);
        sensor = virtual_sensors(id);
        main.project.getCurrentCluster().removeSensor(sensor.getCaption());
        Refresh(propG, main);
    end
    function Refresh(propG, main)
        propG.clear();
        sensors = main.project.getSensors();
        sensors(~[sensors.virtual]) = [];
        if ~isempty(sensors)
            blocks = [sensors.dataProcessingBlock];
            propG.addBlocks(blocks);
        end
        Update(propG,[],main);
    end
    function Update(src, event, main)
        blocks = src.getAllBlocks();
        if ~isempty(blocks)
            for i = 1:numel(blocks)
                blocks(i).updateParameters(main.project);
            end
        end
        main.populateSensorSetTable();
    end
end