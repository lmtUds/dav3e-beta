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

function extractAxSquare(MainFig)
%EXTRACTAXSQUARE Extracts the CurrentAxes of MainFig into a square(ish) uiFigure
    fig = uifigure('Name','Plot Extraction: Square','Visible','off');
    fig.Position(3:4) = [460 420];
    grid = uigridlayout(fig,[1 1],'Padding',[0 0 0 0]);
    ax = copyobj(MainFig.CurrentAxes,grid);
    ax.Layout.Row = 1; ax.Layout.Column = 1;
    fig.Visible = 'on';
end

