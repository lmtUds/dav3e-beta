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

function info = standardize()
    info.type = DataProcessingBlockTypes.FeaturePreprocessing;
    info.caption = 'standardize';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','mean', 'value',[], 'internal',true),... 
        Parameter('shortCaption','std', 'value',[], 'internal',true),... 
    ];
    info.apply = @apply;
    info.train = @train;
end

function [data,paramOut] = apply(data,params)
    paramOut = struct();
    d = (data.getSelectedData() - params.mean) ./ params.std;
    dTest = (data.getSelectedData('testing') - params.mean) ./ params.std;
    data.setSelectedData(d, 'captions', data.featureCaptions(data.featureSelection));
    data.data(data.testingSelection,:) = dTest;
end

function params = train(data,params)
    params.mean = mean(data.getSelectedData(),1);
    params.std = std(data.getSelectedData(),[],1);
end