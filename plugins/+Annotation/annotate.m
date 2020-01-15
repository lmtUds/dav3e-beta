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

function info = annotate()
    info.type = DataProcessingBlockTypes.Annotation;
    info.caption = 'annotate';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','grouping', 'value','', 'enum',{''}),...
        Parameter('shortCaption','groups', 'value',{''}, 'enum',{''}, 'selection','multiple')...
        Parameter('shortCaption','target', 'value','same as grouping', 'enum',{'same as grouping'}),...
        Parameter('shortCaption','features', 'value',{''}, 'enum',{''}),...
        Parameter('shortCaption','nFeatures', 'value','', 'editable',false)...
        Parameter('shortCaption','nObservations', 'value','', 'editable',false)...
        ];
    info.apply = @apply;
    info.updateParameters = @updateParameters;
    info.detailsPages = {}; %{'annotation'};
end

function [data,params] = apply(data,params)
    data.groupingCaption = params.grouping;
    data.setSelectedFeatures(params.features);
    data.setSelectedGroups(params.groups);
    targetCaption = params.target;
    data.targetCaption = targetCaption;
    if strcmp(targetCaption,'same as grouping')
%         data.setTarget(data.grouping,'numeric');
%         if any(isnan(data.target(data.grouping~='<ignore>')))
        data.setTarget(data.grouping,'categorical');
%         end
    else
        data.setTarget(data.getFeatureByName(targetCaption),'numeric');
    end    
    data.setValidation('none');
    data.setTesting('none');
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
            grouping = project.mergedFeatureData.getGroupingByName(params(i).getValue());
            % update all parameters when this one is changed
            params(i).onChangedCallback = @()updateParameters(params,project);
        elseif params(i).shortCaption == string('groups')
            if isempty(params(i).enum) || ~all(ismember(params(i).enum,cellstr(categories(grouping))))
                params(i).enum = categories(grouping);
                params(i).value = params(i).enum;
            end
            params(i).onChangedCallback = @()updateParameters(params,project);
            params(i).updatePropGridField();
            groups = params(i).getValue();
        elseif params(i).shortCaption == string('target')
            params(i).enum = ['same as grouping',cellstr(project.mergedFeatureData.featureCaptions)];
        elseif params(i).shortCaption == string('features')
            params(i).enum = cellstr(project.mergedFeatureData.featureCaptions);
            if isempty(params(i).value) || isempty(params(i).value{1})
                params(i).value = cellstr(project.mergedFeatureData.featureCaptions);
            end
            selected = {};
            for j=1:numel(params(i).enum)
                if sum(strcmp(params(i).enum{j},params(i).getValue()))
                    selected = [selected, params(i).enum(j)];
                end
            end
            params(i).value = cellstr(selected);
            params(i).updatePropGridField();
            features = params(i).getValue();
            % update all parameters when this one is changed
            params(i).onChangedCallback = @()updateParameters(params,project);
        elseif params(i).shortCaption == string('nFeatures')
            params(i).value = sprintf('%d/%d',numel(features),numel(project.mergedFeatureData.featureCaptions));
            params(i).updatePropGridField();
        elseif params(i).shortCaption == string('nObservations')
            params(i).value = sprintf('%d/%d',sum(ismember(grouping,groups)),size(project.mergedFeatureData.data,1));    
            params(i).updatePropGridField();
        end
    end
end