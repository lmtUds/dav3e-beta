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

function info = lsr()
    info.type = DataProcessingBlockTypes.Regression;
    info.caption = 'Least squares regression';
    info.shortCaption = mfilename;
    info.description = ['Fit linear regression model to high-dimensional data'];
    info.parameters = [...
        Parameter('shortCaption','trained', 'value',false, 'internal',true)...
        Parameter('shortCaption','Mdl', 'internal',true)...
        Parameter('shortCaption','projectedData', 'value',[], 'internal',true),...
        Parameter('shortCaption','lastTrainData', 'value',[], 'internal',true),...
        ];
    info.apply = @apply;
    info.train = @train;
    info.reset = @reset;
    info.updateParameters = @updateParameters;
    info.detailsPages = {'calibration','predictionOverTime'};
    info.requiresNumericTarget = true;
end

function [data,params] = apply(data,params)
    if ~params.trained
        error('Regressor must first be trained.');
    end
    Mdl = params.Mdl;
    pred = predict(Mdl,data.getSelectedData());
    
    switch data.mode
        case 'training'
            params.projectedData.training = pred;
        case 'testing'
            params.projectedData.testing = pred;
    end    
    
    data.setSelectedPrediction(pred);
end

function params = train(data,params)
    % if we are trained and train data is as before, we can completely skip
    % the training
    if params.trained ...
            && all(size(params.lastTrainData)==size(data.getSelectedData())) ...
            && all(all(params.lastTrainData == data.getSelectedData())) ...
        disp('LSR already trained.')
        return
    end
    
    target = data.getSelectedTarget();
    if ~isnumeric(target) || any(isnan(target))
        error('LSR requires numeric target.');
    end
    if numel(unique(target)) <= 1
        error('LSR requires at least two different target values.');
    end
    
    d = data.getSelectedData();
    nans = isnan(d);
    if any(any(nans))
        warning('%d feature values were NaN and have been replaced with 0.',sum(sum(nans)));
        d(nans) = 0;
    end
    
    Mdl = fitrlinear(d, target, ...
                    'Learner','leastsquares', 'Regularization', ...
                    'ridge', 'Solver', 'lbfgs');
    params.Mdl = Mdl;
    params.trained = true;
end

function params = reset(params)
    params.trained = false;
end

function updateParameters(params,project)

end
