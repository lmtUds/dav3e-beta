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
clrStr = [num2str(rgbClr(1)),',',num2str(rgbClr(2)),',',num2str(rgbClr(3))];
end

