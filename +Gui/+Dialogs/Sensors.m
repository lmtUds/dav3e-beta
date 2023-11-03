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

function Sensors(main)
    fig = uifigure('Name','Sensors','WindowStyle','modal',...
        'Visible','off');
    centerFigure(fig);
    grid = uigridlayout(fig,[1 1],'RowHeight',{'1x'});
    t = uitable(grid);

    s = main.project.getSensors();
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
    vars = {'caption','abscissa','abscissa cycle','abscissa preprocessed'};
    t.Data = data;
    t.ColumnName = vars;
    t.ColumnEditable = [true true true true];
    abcissaStr = [{'time','data points'},cellstr(s.getCaption('cluster'))];
    t.ColumnFormat = {'char',abcissaStr,'numeric','logical'};
    t.UserData = s;
    t.CellEditCallback = @(src,event) tableDataChange(src,event);
    t.CellSelectionCallback = @(src,event) selectionChanged(src,event,t);
    fig.Visible = 'on';

    function tableDataChange(src,event)
        o = src.UserData(event.Indices(1));
        switch event.Indices(2)
            case 1
                o.setCaption(event.NewData);
            case 2
                o.abscissaType = event.NewData;
                if ~strcmp(o.abscissaType,'time') && ~strcmp(o.abscissaType,'data points')
                    o.abscissaType = 'sensor';
                    o.abscissaSensor = main.project.getSensorByCaption(event.NewData,'cluster');
                end
            case 3
                o.abscissaSensorCycle = event.NewData;
            case 4
                o.abscissaSensorPreprocessed = event.NewData;
        end
        o.modified();
        main.populateSensorSetTable();
    end
    function selectionChanged(src,event,t)
        if isempty(event.Indices)
            return
        end
        row = event.Indices(1,1);
        removeStyle(t);
        style = uistyle("BackgroundColor",[221,240,255]./256);
        addStyle(src,style,"Row",row);
    end
end