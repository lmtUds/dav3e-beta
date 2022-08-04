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

function centerFigure(Figure)
%CENTERFIGURE Center the target figure on the screen the mouse pointer currently is
%find the correct screen S
gRoot = get(groot);
for S = 1:size(gRoot.MonitorPositions,1)
    bounds = [gRoot.MonitorPositions(S,1) - 1 + gRoot.MonitorPositions(S,3)...
              gRoot.MonitorPositions(S,2) - 1 + gRoot.MonitorPositions(S,4)];
    if all(gRoot.PointerLocation <= bounds)
        break
    end
end
%compute the center of that screen
center = [gRoot.MonitorPositions(S,1) - 1 + floor(0.5 * gRoot.MonitorPositions(S,3))...
          gRoot.MonitorPositions(S,2) - 1 + floor(0.5 * gRoot.MonitorPositions(S,4))];
%check which Unit style the Figure uses and set its position accordingly
switch Figure.Units
    case 'pixels' %retain pixel size, center on proper screen
        w = Figure.Position(3); h = Figure.Position(4);
        x = center(1) - floor(0.5 * w);
        y = center(2) - floor(0.5 * h);
        Figure.Position(1:2) = [x y];
    case 'normalized' %retain relative size and center on proper screen
        w = floor(Figure.Position(3) * gRoot.MonitorPositions(S,3));
        h = floor(Figure.Position(4) * gRoot.MonitorPositions(S,4));
        x = center(1) - floor(0.5 * w);
        y = center(2) - floor(0.5 * h);
        Figure.Units = 'pixels';
        Figure.Position = [x y w h];
        Figure.Units = 'normalized';
    otherwise
        warning('Unsupported unit style %s.\nNo Position changes made.',Figure.Units)
        return
end
end

