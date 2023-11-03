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

function clrStr = clr2str(rgbClr)
%CLR2STR generates a string to display a colour triplet's values in  the UI.
% input: colour triplet as 1x3 double r,g,b array in [0,1]
% output: colour string encoding the triplet as 'r,g,b'

% check if the triplet is numeric
if ~isnumeric(rgbClr)
    error('RGB triplet values must be of numeric type.')
end
% check is the triplet has the correct dimensions
if size(rgbClr,1) ~= 1 || size(rgbClr,2) ~= 3
    error(['RBG triplet must be of size 1x3, but was ',...
        num2str(size(rgbClr,1)),'x',num2str(size(rgbClr,2)),'.'])
end
% check if the values of the triplet are withing the valid range
if any(rgbClr >1) || any(rgbClr <0)
    error('RBG triplet values must be in range [0,1].')
end

% as we asserted integrity we can generate the final string
precision = 2;
clrStr = [num2str(rgbClr(1),precision),',',...
    num2str(rgbClr(2),precision),',',num2str(rgbClr(3),precision)];
end

