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

classdef Sensors < handle
    properties
        main
        f
        hTable
    end
    
    methods
        function obj = Sensors(main)
            obj.main = main;
            obj.f = figure('Name','Sensors','WindowStyle','modal');
            layout = uiextras.VBox('Parent',obj.f);
            t = JavaTable(layout,'default');
            
            s = obj.main.project.getSensors();
            data = cell(numel(s),4);
            for i = 1:numel(s)
                data{i,1} = char(s(i).getCaption());
                if strcmp(s(i).abscissaType,'sensor')
                    data{i,2} = char(s(i).abscissaSensor.getCaption('cluster'));
                else
                    data{i,2} = char(s(i).abscissaType);
                end
                data{i,3} = s(i).abscissaSensorCycle;
                data{i,4} = s(i).abscissaSensorPreprocessed;
            end
            t.setData(data,{'caption','abscissa','abscissa cycle','abscissa preprocessed'});
            t.setColumnsEditable([true true true true]);
            t.setColumnClasses({'str',[{'time','data points'},cellstr(s.getCaption('cluster'))],'int32','logical'});
            t.setRowObjects(s);
            t.onDataChangedCallback = @obj.tableDataChange;
            t.jTable.repaint();
            obj.hTable = t;
        end

        function tableDataChange(obj,rc,v)
            for i = 1:size(rc,1)
                o = obj.hTable.getRowObjectsAt(rc(i,1));
                switch rc(i,2)
                    case 1
                        o.setCaption(v{i});
                    case 2
                        o.abscissaType = v{i};
                        if ~strcmp(o.abscissaType,'time') && ~strcmp(o.abscissaType,'data points')
                            o.abscissaType = 'sensor';
                            o.abscissaSensor = obj.main.project.getSensorByCaption(v{i},'cluster');
                        end
                    case 3
                        o.abscissaSensorCycle = v{i};
                    case 4
                        o.abscissaSensorPreprocessed = logical(v{i});
                end
                o.modified();
            end
        end
    end
end