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

