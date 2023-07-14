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

function info = deleteNaNcycles()
    info.type = DataProcessingBlockTypes.DataReduction;
    info.caption = 'deleteNaNcycles';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','a', 'value',[], 'internal',true),...
    ];
    info.apply = @apply;
end

function [data,params] = apply(data,params)
    d = data.data; 
    t = data.target;
    [nanCyc,~] = find(isnan(d));
    nanTar = find(ismember(t,'NaN'));
    undefTar = find(isundefined(t));
    params.a = unique([nanCyc;nanTar;undefTar]);
    data.reduceData(@reduceFun, params.a);
end

% function params = train(data,params)
%     d = data.getSelectedData();
%     [params.a,~] = find(isnan(d)==1);
% end

function [newData,newGrouping,newTarget,newOffsets] = reduceFun(data,grouping,target,offsets,varargin)
    n = varargin{1};
    data(n,:)=[];
    newData = data;
    grouping(n,:)=[];
    newGrouping = grouping;
    target(n,:)=[];
    newTarget = target;
    offsets(n,:)=[];
    newOffsets = offsets;
end