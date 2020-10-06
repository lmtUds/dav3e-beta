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

function groupingStruct = groupingCsvDecode(content)
    lines = strsplit(content,'\n');
    imported = cellfun(@(x) strsplit(x,';'),lines,'UniformOutput',false);
    if size(imported{end},2) ~= size(imported{end - 1},2)
        imported = imported(1:end - 1);
    end
    imported = vertcat(imported{:});
    
    groupings = struct();
    for i = 1:size(imported,2)       
       uuid = string(char(java.util.UUID.randomUUID));
       uuid  = string('u') + strrep(uuid,'-','');
       groupings(i).uuid = uuid;
       groupings(i).creationDate = datetime;
       groupings(i).modifiedDate = datetime;       
       groupings(i).caption = string(imported{1,i});       
       groupings(i).shortCaption = 'grouping';
       groupings(i).description = string('');
       groupings(i).tag = string('');
       
       [categories,~,order] = unique(imported(2:end,i));
       groupings(i).categories = categories;
       groupings(i).order = order;
       
       colors = cell(size(categories));
       c1 = [ 0 0 1];
       c2 = [ 0 1 0];
       usedColors = [c1;c2];
       for j = 1:size(categories,1)
           switch j
               case 1
                   colors{j} = c1;
               case 2
                   colors{j} = c2;
               otherwise
                   newCol = distinguishable_colors(1,usedColors);
                   colors{j} = newCol;
                   usedColors = [usedColors; newCol];
           end
       end
       groupings(i).colors = colors;
    end
    groupingStruct = struct('groupings',groupings);
end

