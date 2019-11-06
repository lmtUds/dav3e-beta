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

function info = takeOnlyFirstNGroups()
    info.type = DataProcessingBlockTypes.DataReduction;
    info.caption = 'take only first n groups';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','n', 'value',100)...
        ];
    info.apply = @apply;
    info.updateParameters = @updateParameters;
end

function [data,params] = apply(data,params)
    data.reduceData(@reduceFun, params.n);
end

function updateParameters(params,project)
    %
end

function [newData,newGrouping,newTarget,newOffsets] = reduceFun(data,grouping,target,offsets,varargin)
    n = varargin{1};
    newData = data(1:n,:);
    newGrouping = grouping(1:n,:);
    newTarget = target(1:n,:);
    newOffsets = offsets(1:n,:);
end