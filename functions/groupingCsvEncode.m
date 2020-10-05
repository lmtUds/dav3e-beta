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

function printable = groupingCsvEncode(groupingStruct)
    printable = '';
    groupings = groupingStruct.groupings;

    numGroupings = size(groupings,2);
    maxOrderSz = 0;
    % find the maximum order of all the groupings
    for i = 1:numGroupings
        maxOrderSz = max(maxOrderSz, size(groupings(i).order,1));
    end
    
    % initialize and fill the cell matrix for export
    exportee = cell(maxOrderSz + 1, numGroupings);
    for i = 1:numGroupings
        exportee{1,i} = groupings(i).caption;
        exportee(2:end,i) = groupings(i).categories(groupings(i).order);
    end
    
    % compose the printable for output from the filled cell matrix
    for i = 1:maxOrderSz + 1
       line = '';
       for j = 1:numGroupings
           line = [line,sprintf('%s',exportee{i,j}),';'];
       end
       if i ~= maxOrderSz + 1
           printable = [printable,sprintf('%s\n',line(1:end-1))];
       else
           printable = [printable,sprintf('%s',line(1:end-1))];
       end
    end
end

