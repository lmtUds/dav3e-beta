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

function About(version)
    fig = uifigure('Name','About',...
        'WindowStyle','modal','Visible','off',...
        'Units', 'normalized', ...
        'Position', [.35 .25 .3 .5]);
    centerFigure(fig);
    grid = uigridlayout(fig,[1 1],'Scrollable','on',...
        'RowHeight',{'fit'});
    if isdeployed
        copyrightNotice = fileread([ctfroot '/DAVE/+Gui/+Dialogs/copyrightNotice.txt']);
    else
        copyrightNotice = fileread('./+Gui/+Dialogs/copyrightNotice.txt');
    end
    licenseText = fileread('LICENSE');
    labelText = sprintf('DAV�E v%s\n\n%s\n\n%s',...
        version,copyrightNotice,licenseText);
    lbl = uilabel(grid,'Text',labelText,'WordWrap','on');
    fig.Visible = 'on';
end