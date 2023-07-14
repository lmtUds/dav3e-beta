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

function Licenses()
    fig = uifigure('Name','Licenses','Visible','off',...
        'WindowStyle','modal');
    centerFigure(fig);
    gridOuter = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);

    if isdeployed
        files = {
            'distinguishable_colors',...
                [ctfroot '/DAVE/functions/licenses/distinguishable_colors.txt'];...
            };
    else
        files = {...
            'distinguishable_colors',...
                './functions/licenses/distinguishable_colors.txt';...
            };
    end

    tabgroup = uitabgroup(gridOuter);
    for i = 1:size(files,1)
        tab = uitab(tabgroup,'title',files{i,1});
        grid = uigridlayout(tab,[1 1],'Scrollable','on',...
            'RowHeight',{'fit'});
        licenseText = fileread(files{i,2});
        licenseLabel= uilabel(grid,'WordWrap','on',...
            'Text',licenseText);
    end
    fig.Visible = 'on';
end