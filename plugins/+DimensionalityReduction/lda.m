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

function info = lda()
    info.type = DataProcessingBlockTypes.DimensionalityReduction;
    info.caption = 'LDA';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','trained', 'value',false, 'internal',true),...    
        Parameter('shortCaption','coeffs', 'internal',true),...
        Parameter('shortCaption','offsets', 'internal',true),...
        Parameter('shortCaption','cumEnergy', 'internal',true),...
        Parameter('shortCaption','nDF', 'value',int32(1), 'enum',int32(1:20), 'selectionType','multiple'),...
        Parameter('shortCaption','projectedData', 'value',[], 'internal',true),...
        Parameter('shortCaption','lastTrainData', 'value',[], 'internal',true)...
        Parameter('shortCaption','lastTrainTarget', 'value',[], 'internal',true)...
        ];
    info.apply = @apply;
    info.train = @train;
    info.reset = @reset;
    info.updateParameters = @updateParameters;
    info.detailsPages = {'histogram','scatter'};
end

function [data,params] = apply(data,params)
    if ~params.trained
        error('LDA must first be trained.');
    end

    coeffs = params.coeffs;
    nDF = double(params.nDF);
    projectedData = data.getSelectedData() * coeffs(:,1:nDF) - params.offsets(1:nDF);
    
    switch data.mode
        case 'training'
            params.projectedData.training = projectedData;
        case 'testing'
            params.projectedData.testing = projectedData;
    end
    captions = string.empty;
    for i=1:nDF
        captions(i) = ['lda_coeff',num2str(i)];
    end
    data.setSelectedData(projectedData, 'captions', captions);

end

function params = train(data,params)
    % if we are trained and train data is as before, we can completely skip
    % the training
    if params.trained ...
            && all(size(params.lastTrainData)==size(data.getSelectedData()))...
            && all(all(params.lastTrainData == data.getSelectedData()))...
            && all(size(params.lastTrainTarget)==size(data.getSelectedTarget()))...
            && all(params.lastTrainTarget == data.getSelectedTarget())
        disp('LDA already trained.')
        return
    end
    
    dataMat = data.getSelectedData();
    target = data.getSelectedTarget();
    if isempty(target)
        error('No training data selected.');
    end
    
    if params.nDF > size(dataMat,2)
        error('Number of DFs cannot be larger than number of features.');
    end
    if params.nDF > numel(unique(target))-1
        error('Number of DFs cannot be larger than number of classes minus one.');
    end
    [eVal,eVec] = quickLDA(dataMat,target);
    params.coeffs = eVec;
    disp('coeffs');
    disp(eVec(:,1));
    params.offsets = mean(dataMat) * eVec;
    params.cumEnergy = eVal / sum(eVal);
    params.trained = true;
    params.projectedData = struct();
    params.lastTrainData = dataMat;
    params.lastTrainTarget = target;
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
    params.lastTrainTarget = [];
end

function [eVal,eVec] = quickLDA(data,group)
    % based on Backhaus et al., "Multivariate Analysemethoden", Springer
    % Verlag, ISBN: 978-3-540-85044-1
    %
    % T: total sum of squares
    % W: within sum of squares
    % B: between sum of squares
    % T = W + B

    % prepare
    group = removecats(categorical(group));
    cats = categories(group);
    g = numel(cats);
    n = size(data,1);

    % compute T
    data = data - mean(data);
    T = data' * data;

    % compute W
    W = zeros(size(T));
    for i = 1:g
       idx = group == cats{i};
       if sum(idx)
          groupObs = data(idx,:);
          groupObs = groupObs - mean(groupObs);
          W = W + groupObs' * groupObs;
       end
    end

    % compute B ( from T and W)
    B = T - W;

    % adapted from MATLAB's manova1
    [R,p] = chol(W);
    if (p > 0)
       error('Singular within sum of squares. Too many identical observations?');
    end
    A = R' \ B / R;     % A = W^(-1)B
    A = (A + A') / 2;   % remove numeric inaccuracies/asymmetries
    
    [V,D] = eig(A);
    eVec = R \ V;

    [eVal,eValIdx] = sort(diag(D),'descend');  % sort eigenvalues
    eVec = eVec(:,eValIdx);  % apply same sorting to eigenvectors

    % normalize coefficients
    s2 = diag((eVec' * W * eVec))' ./ (n-g);
    s2(s2<=0) = 1;
    eVec = eVec ./ sqrt(s2);  %repmat(sqrt(s2), size(eVec,1), 1);
end