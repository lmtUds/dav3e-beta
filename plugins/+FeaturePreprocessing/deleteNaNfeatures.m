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

function info = deleteNaNfeatures()
    info.type = DataProcessingBlockTypes.FeaturePreprocessing;
    info.caption = 'deleteNaNfeatures';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','a', 'value',[], 'internal',true),...
        Parameter('shortCaption','b', 'value',[], 'internal',true),...
    ];
    info.apply = @apply;
    info.train = @train;
end

function [data,paramOut] = apply(data,params)
    paramOut = struct();
    h = data.featureCaptions(params.a);
    params.b = [h{:}]; 
    
    data.data(:,params.a) = [];
    data.featureSelection(params.a) = [];
    data.featureCaptions(params.a) = [];
    warning([num2str(length(params.a)), ' features are ignored because NaN ', params.b])
end

function params = train(data,params)
    d = data.getSelectedData();
    [~,params.a] = find(isnan(d(1,:))==1);   
end