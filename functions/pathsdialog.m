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

function choices = pathsdialog(mainPos)
%PATHSDIALOG Summary of this function goes here
%   Detailed explanation goes here
    d = dialog('Name','Specify Paths for automatic Data Import','WindowStyle','normal');
    d.Units = 'normalized';
    x=mainPos(1);
    y=mainPos(2);
    w=mainPos(3);
    h=mainPos(4);
    d.Position = [x+(3*w/8),y+(3*h/8),w/4,h/4];
    
    txtRoot = uicontrol('Parent',d,...
           'Style','text',...
           'Units','normalized',...
           'Position',[.2 .7 .6 .2],...
           'String','Specify the root path for importing data');
       
    editRoot = uicontrol('Parent',d,...
            'Style','edit',...
            'Units','normalized',...
            'Position',[.2 .7 .5 .1],...
            'String',matlabroot);
        
    btnRoot = uicontrol('Parent',d,...
           'Units','normalized',...
           'Position',[.7 .7 .1 .1],...
           'String','Choose',...
           'Callback',@root_callback);
       
    txtType = uicontrol('Parent',d,...
            'Style','text',...
            'Units','normalized',...
            'Position',[.2 .45 .6 .2],...
            'String','Specify a type path for importing data');
       
    editType = uicontrol('Parent',d,...
            'Style','edit',...
            'Units','normalized',...
            'Position',[.2 .45 .5 .1],...
            'String',matlabroot);
        
    btnType = uicontrol('Parent',d,...
           'Units','normalized',...
           'Position',[.7 .45 .1 .1],...
           'String','Choose',...
           'Callback',@type_callback);

    btn = uicontrol('Parent',d,...
           'Units','normalized',...
           'Position',[.4 .2 .2 .15],...
           'String','Continue',...
           'Callback','delete(gcf)');

    choices = {ctfroot, ctfroot};

    % Wait for d to close before running to completion
    uiwait(d);

    function root_callback(btnRoot,event)
      rootDir = uigetdir(ctfroot, 'Select the root path for data import');
      editRoot.String = rootDir;
      temp = {rootDir, choices{2}};
      choices = temp;
    end

    function type_callback(btnType,event)
      typeDir = uigetdir(ctfroot, 'Select a type path for data import');
      editType.String = typeDir;
      temp = {choices{1}, typeDir};
      choices = temp;
    end

end

