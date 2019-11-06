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

        function addVirtualSensor(obj)
            vs = Sensor.getAvailableMethods(true);
            s = keys(vs);
            [sel,ok] = listdlg('ListString',s);
            if ~ok
                return
            end
            virtualSensor = Sensor(DataProcessingBlock(vs(s{sel})),...
                'caption',s{sel});
            obj.main.project.getCurrentCluster().addSensor(virtualSensor);
            obj.refreshPropGrid();
        end
        
        function removeVirtualSensor(obj)
            prop = obj.hPropGrid.getSelectedProperty().getHighestParent();
            if isempty(prop)
                return
            end
            block = prop.getMatlabObj();
            obj.main.project.getCurrentCluster().removeSensor(block.getCaption());
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
            pgf = dpb.makePropGridField();
            obj.hPropGrid.addProperty(pgf);
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