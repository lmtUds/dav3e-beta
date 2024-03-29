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

function info = manualFeatureSelection()
    info.type = DataProcessingBlockTypes.DimensionalityReduction;
    info.caption = 'manual feature selection';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','features', 'value',{''}, 'enum',{''}, 'selectionType','multiple')...
        ];
    info.apply = @apply;
    info.train = @train;
    info.updateParameters = @updateParameters;
end

function [data,params] = apply(data,params)
    data.setSelectedFeatures(params.features);
end

function params = train(data,params)
    data.setSelectedFeatures(params.features);
end

function updateParameters(params,project)
    for i = 1:numel(params)
        if params(i).shortCaption == 'features'
            params(i).enum = cellstr(project.mergedFeatureData.featureCaptions);
            params(i).value = cellstr(project.mergedFeatureData.featureCaptions);
        end
    end
end