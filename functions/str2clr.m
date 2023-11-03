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

function rgbClr = str2clr(clrStr)
%STR2CLR reads a string representing a RGB colour triplet as 'r,g,b' and returns a numerical 1x3 array in [0,1].
%  input: colour string encoding the triplet as 'r,g,b'
%  output: colour triplet as 1x3 double r,g,b array in [0,1]

% split the input string at each ','
split = strsplit(clrStr,',');

% check is the string contains the correct number of values
if size(split,1) ~= 1 || size(split,2) ~= 3
    error(['RBG string must contain 1x3 values, but had ',...
        num2str(size(split,1)),'x',num2str(size(split,2)),'.'])
end
% try to convert the split string into numbers
try
    conv = cellfun(@(x) str2double(x),split);
catch ME
    disp(ME)
    error('Conversion of RGB string to numbers failed.')
end
% check if the converted values are withing the valid range
if any(conv < 0) || any(conv > 255) 
    error('RGB values must be withing [0,255] or [0,1].')
end
% if they are in [0,255] project them into [0,1]
if any(conv > 1)
    conv = conv ./ 255;
    warning('RGB value was in [0,255] and was projected into [0,1]')
end
% return the converted array
rgbClr = conv;
end

