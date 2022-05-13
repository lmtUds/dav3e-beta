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

classdef VirtualSensors < handle
    properties
        main
        f
        hPropGrid
    end
    
    methods
        function obj = VirtualSensors(main)
            obj.main = main;
            obj.f = figure('Name','Sensors','WindowStyle','modal',...
                'CloseRequestFcn',@(varargin)obj.onDialogClose);
            layout = uiextras.VBox('Parent',obj.f);
            pg = PropGrid(layout);
            pg.setShowToolbar(false);
            propGridControlsLayout = uiextras.HBox('Parent',layout);
            uicontrol(propGridControlsLayout,'String','add', 'Callback',@(h,e)obj.addVirtualSensor);
            uicontrol(propGridControlsLayout,'String','delete', 'Callback',@(h,e)obj.removeVirtualSensor);
            layout.Sizes = [-1,20];
            obj.hPropGrid = pg;
            obj.refreshPropGrid();
        end
        function VirtualSensorsNew(main)
            fig = uifigure('Name','Virtual Sensors','WindowStyle','modal',...
                'DeleteFcn',@(varargin)obj.onDialogClose);
            grid = uigridlayout(fig,[2 2],'RowHeight',{'1x',22});
            propG = Gui.uiParameterBlockGrid('Parent',grid);
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
                id = main.project.getCurrentCluster().sensors.dataProcessingBlock == block;
                virtual_sensors = main.project.getCurrentCluster().sensors(main.project.getCurrentCluster().sensors.virtual);
                sensor = virtual_sensors(id);
                main.project.getCurrentCluster().removeSensor(sensor.getCaption());
                Refresh(propG, main);
            end
            function Refresh(propG, main)
                propG.clear();
                sensors = main.project.getSensors();
                sensors(~sensors.virtual) = [];
                if isempty(sensors)
                    return
                end
                blocks = sensors.dataProcessingBlock;
                propG.addBlocks(blocks);
                for i = 1:numel(blocks)
                    blocks(i).updateParameters(main.project);
                end
                main.populateSensorSetTable();
            end
        end

        function addVirtualSensor(obj)
            vs = Sensor.getAvailableMethods(true);
            s = keys(vs);
            [sel,ok] = listdlg('ListString',s);
            if ~ok
                return
            end
            for i=1:numel(sel)
                virtualSensor = Sensor(DataProcessingBlock(vs(s{sel(i)})),...
                    'caption',s{sel(i)});
                virtualSensor.dataProcessingBlock.parameters.getByCaption('virtual_sensor').value = virtualSensor;
                obj.main.project.getCurrentCluster().addSensor(virtualSensor);
            end
            obj.refreshPropGrid();
        end
        
        function removeVirtualSensor(obj)
            prop = obj.hPropGrid.getSelectedProperty().getHighestParent();
            if isempty(prop)
                return
            end
            block = prop.getMatlabObj();
            id = [obj.main.project.getCurrentCluster().sensors.dataProcessingBlock]==block;
            virtual_sensors = obj.main.project.getCurrentCluster().sensors([obj.main.project.getCurrentCluster().sensors.virtual]);
            sensor = virtual_sensors(id);
            obj.main.project.getCurrentCluster().removeSensor(sensor.getCaption());
            obj.hPropGrid.removeProperty(prop);
            obj.refreshPropGrid();
        end        
        
        function refreshPropGrid(obj)
            obj.hPropGrid.clear();
            s = obj.main.project.getSensors();
            s(~[s.virtual]) = [];
            if isempty(s)
                return
            end
            dpb = [s.dataProcessingBlock];
            for i = 1:numel(dpb)
                pgf = dpb(i).makePropGridField();
                obj.hPropGrid.addProperty(pgf);
            end
            for i = 1:numel(dpb)
                dpb(i).updateParameters(obj.main.project);
            end
%             [pgf.onMouseClickedCallback] = deal(@obj.changeCurrentPreprocessing);
        end        
        
        function onDialogClose(obj)
            obj.main.populateSensorSetTable();
            delete(obj.f);
        end
    end
end