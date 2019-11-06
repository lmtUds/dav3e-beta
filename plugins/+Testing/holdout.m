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

function info = holdout()
    info.type = DataProcessingBlockTypes.Testing;
    info.caption = 'holdout';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','groupbased', 'value',true),...
        Parameter('shortCaption','grouping', 'value','', 'enum',{''}),...
        Parameter('shortCaption','percent', 'value',20),...
        Parameter('shortCaption','iterations', 'value',int32(1)),...
        ];
    info.apply = @apply;
    info.updateParameters = @updateParameters;
end

function [data,params] = apply(data,params)
    data.setTesting('holdout','folds',1,...
        'iterations',params.iterations,...
        'groupbased',params.groupbased,...
        'grouping',params.grouping,...
        'percent',params.percent);
end

function updateParameters(params,project)
    for i = 1:numel(params)
        if params(i).shortCaption == string('groupbased')
            % update all parameters when this one is changed
            params(i).onChangedCallback = @()updateParameters(params,project);
            groupbased = params(i).value;
        elseif params(i).shortCaption == string('grouping')
            params(i).enum = cellstr(project.groupings.getCaption());
            if isempty(params(i).value)
                params(i).value = params(i).enum{1};
            end
            params(i).hidden = ~groupbased;
            params(i).updatePropGridField();
        end
    end
end