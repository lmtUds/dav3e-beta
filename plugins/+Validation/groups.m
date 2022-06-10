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

function info = groups()
    info.type = DataProcessingBlockTypes.Validation;
    info.caption = 'groups';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','grouping', 'value','', 'enum',{''}),...
        Parameter('shortCaption','groups', 'value',{''}, 'enum',{''})...
        ];
    info.apply = @apply;
    info.updateParameters = @updateParameters;
    info.detailsPages = {'performance','correlationCoefficient'};
end

function [data,params] = apply(data,params)
    data.setValidation('groups','grouping',params.grouping,...
        'groups',params.groups);
end

function updateParameters(params,project)
    groupings = project.mergedFeatureData.groupings;    
    grouping_captions = project.mergedFeatureData.groupingCaptions;
    for i = 1:numel(params)
        if params(i).shortCaption == string('grouping')
            params(i).enum = cellstr(grouping_captions);
            if isempty(params(i).value)
                params(i).value = params(i).enum{1};
            end
            grouping = removecats(groupings(:,strcmp(grouping_captions,params(i).getValue())));
            % update all parameters when this one is changed
            params(i).onChangedCallback = @()updateParameters(params,project);
        elseif params(i).shortCaption == string('groups')
            if ~all(ismember(params(i).enum,cellstr(categories(grouping))))
                params(i).enum = cellstr(categories(grouping));
                params(i).value = params(i).enum;
            end
        end
    end
end