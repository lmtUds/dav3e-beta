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

function info = pca()
    info.type = DataProcessingBlockTypes.DimensionalityReduction;
    info.caption = 'PCA';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','trained', 'value',false, 'internal',true),...    
        Parameter('shortCaption','coeffs', 'internal',true),...
        Parameter('shortCaption','offsets', 'internal',true),...
        Parameter('shortCaption','cumEnergy', 'internal',true),...
        Parameter('shortCaption','nPC', 'value',int32(1), 'enum',int32(1:20), 'selectionType','multiple'),...
        Parameter('shortCaption','projectedData', 'value',[], 'internal',true),...
        Parameter('shortCaption','lastTrainData', 'value',[], 'internal',true)...
        ];
    info.apply = @apply;
    info.train = @train;
    info.reset = @reset;
    info.updateParameters = @updateParameters;
    info.detailsPages = {'histogram','scatter'};
end

function [data,params] = apply(data,params)
    if ~params.trained
        error('PCA must first be trained.');
    end
    coeffs = params.coeffs;
    nPC = double(params.nPC);
    projectedData = data.getSelectedData() * coeffs(:,1:nPC) - params.offsets(1:nPC);
    switch data.mode
        case 'training'
            params.projectedData.training = projectedData;
        case 'testing'
            params.projectedData.testing = projectedData;
    end
    captions = string.empty;
    for i=1:nPC
        captions(i) = ['pca_coeff_',num2str(i)];
    end
    data.setSelectedData(projectedData, 'captions', captions);
end

function params = train(data,params)
    % if we are trained and train data is as before, we can completely skip
    % the training
    if params.trained ...
            && all(size(params.lastTrainData)==size(data.getSelectedData()))...
            && all(all(params.lastTrainData == data.getSelectedData()))
        disp('PCA already trained.')
        return
    end
    
    dataMat = data.getSelectedData();
    if params.nPC > size(dataMat,2)
        error('Number of PCs cannot be larger than number of features.');
    end
    stats = quickPCA(dataMat);
    params.coeffs = stats.eigenvec;
    params.offsets = mean(dataMat) * stats.eigenvec;
    params.cumEnergy = stats.eigenval / sum(stats.eigenval);
    params.trained = true;
    params.projectedData = struct();
    params.lastTrainData = dataMat;
end

function updateParameters(params,project)
    %
end

function params = reset(params)
    params.trained = false;
    params.coeffs = [];
    params.offsets = [];
    params.cumEnergy = [];
    params.projectedData = [];
    params.lastTrainData = [];
end

function stats = quickPCA(x)
    x = x - mean(x,1);
    [~,eigenval,eigenvec] = svd(x, 0);
    if size(eigenval,1) == 1
        eigenval = eigenval(1);
    else
        eigenval = diag(eigenval);
    end
%     eigVals = diag(d);
%     eigenvec = u;
    stats.eigenvec = eigenvec;
    stats.eigenval = eigenval;
end