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

function rangeStruct = rangeCsvDecode(content)
    lines = strsplit(content,'\n');
    imported = cellfun(@(x) strsplit(x,';'),lines,'UniformOutput',false);
    if size(imported{end},2) ~= 7
        imported = imported(1:end - 1);
    end
    imported = vertcat(imported{:});
    
    cycleRanges = struct();
    
    for i = 2:size(imported,1)
       j = i - 1;
       
       uuid = string(char(java.util.UUID.randomUUID));
       uuid  = string('u') + strrep(uuid,'-','');
       cycleRanges(j).uuid = uuid;
       cycleRanges(j).creationDate = datetime;
       cycleRanges(j).modifiedDate = datetime;
       cycleRanges(j).caption = string(imported{i,1});
       cycleRanges(j).shortCaption = string('');
       cycleRanges(j).description = string('');
       cycleRanges(j).tag = string('');
       cycleRanges(j).timePosition = ...
           [str2double(imported{i,2}),str2double(imported{i,3})];
       cycleRanges(j).clr = [str2double(imported{i,4}),...
           str2double(imported{i,5}),str2double(imported{i,6})];
       cycleRanges(j).subRangeNum = 1;
       cycleRanges(j).subRangeForm = 'lin';
    end
    rangeStruct = struct('cycleRanges',cycleRanges);
end

