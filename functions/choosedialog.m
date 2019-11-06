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

function choice = choosedialog(mainPos)
%CHOOSEDIALOG Summary of this function goes here
%   Detailed explanation goes here
    d = dialog('Name','Import Method Selection','WindowStyle','normal');
    d.Units = 'normalized';
    x=mainPos(1);
    y=mainPos(2);
    w=mainPos(3);
    h=mainPos(4);
    d.Position = [x+(3*w/8),y+(3*h/8),w/4,h/4];
    txt = uicontrol('Parent',d,...
           'Style','text',...
           'Units','normalized',...
           'Position',[.2 .7 .6 .2],...
           'String','Select the desired method for importing data');

    popup = uicontrol('Parent',d,...
           'Style','popup',...
           'Units','normalized',...
           'Position',[.25 .5 .5 .15],...
           'String',{'File by File Import';'Automated multi File Import'},...
           'Callback',@popup_callback);

    btn = uicontrol('Parent',d,...
           'Units','normalized',...
           'Position',[.4 .2 .2 .15],...
           'String','Continue',...
           'Callback','delete(gcf)');

    choice = 'simple';

    % Wait for d to close before running to completion
    uiwait(d);

    function popup_callback(popup,event)
      idx = popup.Value;
      switch idx
          case 1
              choice = 'simple';
          case 2
              choice = 'complex';
          otherwise
              choice = 'simple';
      end
    end
end