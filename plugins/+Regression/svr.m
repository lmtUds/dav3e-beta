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

function info = svr()
    info.type = DataProcessingBlockTypes.Regression;
    info.caption = 'Support Vector Regression';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','trained', 'value',false, 'internal',true)...
        Parameter('shortCaption','mdl', 'internal',true)...
        Parameter('shortCaption','projectedData', 'value',[], 'internal',true),...
        ];
    info.apply = @apply;
    info.train = @train;
    info.reset = @reset;
    info.detailsPages = {'calibration','predictionOverTime'};
    info.requiresNumericTarget = true;
end
function [params] = train(data,t,params,rank)    
    
    if exist('rank','var')
        target = cat2num(data.target(data.trainingSelection));
        help = single(data.data(data.trainingSelection,:));
        d = help(:,rank);
    else
        d = data.getSelectedData();
        target = data.getSelectedTarget();
    end

    if numel(unique(target)) <= 1
        error('SVR requires at least two different target values.');
    end

    nans = isnan(d);
    if any(any(nans))
        warning('%d feature values were NaN and have been replaced with 0.',sum(sum(nans)));
        d(nans) = 0;
    end
    
    % [mdl,FitInfo,HyperparameterOptimizationResults] = fitrlinear(d,target,...
    % 'OptimizeHyperparameters','auto');
    
    % mdl = fitlm(d, target);

     %mdl = fitrsvm(d,target,'KernelFunction','rbf');
     
     mdl = fitrlinear(d, target, ...
                    'Learner','leastsquares', 'Regularization', ...
                    'ridge', 'Solver', 'lbfgs');

 %    mdl = fitrgp(d,target, 'KernelFunction','squaredexponential');
    
%     mdl = fitrsvm(d,target,'OptimizeHyperparameters','auto',...
%     'HyperparameterOptimizationOptions',struct('AcquisitionFunctionName',...
%     'expected-improvement-plus'));
    
    params.mdl = mdl;
    params.trained = true;
end

function [data, params] = apply(data,params,rank)
    
    if ~params.trained
        error('Regressor must first be trained.');
    end
    
    if exist('rank','var') 
        if strcmp(data.mode, 'training')
            help = single(data.data(data.trainingSelection,:));
            dataH = help(:,rank);
        elseif strcmp(data.mode, 'validation')
            help = single(data.data(data.validationSelection,:));
            dataH = help(:,rank);
        elseif strcmp(data.mode, 'testing')
            dataH = [];
        end

        pred = predict(params.mdl,dataH);
        params.pred = pred;

    else
        pred = predict(params.mdl,data.getSelectedData());
        params.pred = pred;
    end
    
    switch data.mode
        case 'training'
            params.projectedData.training = pred;
        case 'testing'
            params.projectedData.testing = pred;
    end

    try
        data.setSelectedPrediction(pred);
    catch
        params.pred = pred;
    end 
end

function params = reset(params)
    params.trained = false;
    params.mdl = [];
end