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

function info = groupAverage()
    info.type = DataProcessingBlockTypes.FeatureCycleAverage;
    info.caption = 'group average';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [];
    info.apply = @apply;
end

function [data,paramOut] = apply(data,paramIn)
    paramOut.group = cell(0,1);
    paramOut.color = nan(0,3);
    paramOut.data = nan(0,0);
    clr = data.groupingObj.getColors();
    cat = deStar(data.groupingObj.getCategories());
%     cat = categories(removecats(data.grouping));
    grouping = deStar(data.grouping);
    for i = 1:numel(cat)
        mask = grouping == cat{i};
        avg = mean(data.data(mask,:),1);
        paramOut.group = [paramOut.group; cat{i}];
        paramOut.color = [paramOut.color; clr(cat{i})];
        paramOut.data = [paramOut.data; avg];
    end
end