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

function tableColSort(table,column,direction)
%TABLECOLSORT Sort a table in the specified direction by a given column,
%will also sort user data
%   table       a uitable created for a uifigure
%   column      the numbered column of the table to sort by
%   direction   specify 'd' for descending ordering, anything else defaults
%               to ascending ordering
sortColumn = table.Data(:,column);
if isnumeric(sortColumn{1})
    sortColumn = cellfun(@(x) double(x),sortColumn);
else
    sortColumn = cellfun(@(x) string(x),sortColumn);
end

switch direction
    case 'd'
        [~,ind] = sort(sortColumn,'descend');
    otherwise
        [~,ind] = sort(sortColumn);
end
table.UserData = table.UserData(ind);
table.Data = table.Data(ind,:);
end

