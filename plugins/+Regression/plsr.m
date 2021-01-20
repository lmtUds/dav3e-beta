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

function info = plsr()
    info.type = DataProcessingBlockTypes.Regression;
    info.caption = 'PLS regression';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','trained', 'value',false, 'internal',true)...
        Parameter('shortCaption','beta0', 'internal',true)...
        Parameter('shortCaption','offset', 'internal',true)...
        Parameter('shortCaption','nComp', 'value',int32(1), 'enum',1:20, 'selection','multiple'),...
        Parameter('shortCaption','projectedData', 'value',[], 'internal',true),...
        Parameter('shortCaption','lastTrainData', 'value',[], 'internal',true),...
        Parameter('shortCaption','trainError','value',1,'editable',false),...
        Parameter('shortCaption','validationError','value',1,'editable',false),...
        Parameter('shortCaption','testError','value',1,'editable',false)...
        ];
    info.apply = @apply;
    info.train = @train;
    info.reset = @reset;
    info.updateParameters = @updateParameters;
    info.detailsPages = {'calibration','predictionOverTime','coefficients'};
    info.requiresNumericTarget = true;
end

function [data,params] = apply(data,params)
    if ~params.trained
        error('Regressor must first be trained.');
    end
    b = params.beta0(:,params.nComp);
    o = params.offset(params.nComp);
    pred = data.getSelectedData() * b + o;
    
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
            && size(params.beta0,2) >= params.nComp
        disp('PLSR already trained.')
        return
    end
    
    target = data.getSelectedTarget();
    if ~isnumeric(target) || any(isnan(target))
        error('PLSR requires numeric target.');
    end
    if numel(unique(target)) <= 1
        error('PLSR requires at least two different target values.');
    end
    if numel(target) < params.nComp
        error('PLSR requires more observations than components.');
    end
    
    d = data.getSelectedData();
    nans = isnan(d);
    if any(any(nans))
        warning('%d feature values were NaN and have been replaced with 0.',sum(sum(nans)));
        d(nans) = 0;
    end
    
    try
        [b,o] = Regression.helpers.quickPLSR(d,target);
    catch
        % quickPLSR is based on MATLAB code and cannot be distributed
        % due to copyright
        % use this slower alternative instead
        b = zeros(size(d,2)+1,params.nComp);
        for i = 1:params.nComp
            [~,~,~,~,beta] = plsregress(d,target,i);
            b(:,i) = beta;
        end
        o = b(1,:);
        b(1,:) = [];
    end
    params.beta0 = b;
    params.offset = o;
    params.trained = true;
end

function params = reset(params)
    params.trained = false;
    params.beta0 = [];
    params.offset = [];
end

function updateParameters(params,project)
    for i = 1:numel(params)
        if params(i).shortCaption == string('trainError')
            val = project.currentModel.trainingErrors;
            if ~isnan(val)
                params(i).value = val;
            else
                params(i).value = 1;
            end
        elseif params(i).shortCaption == string('validationError')
            val = project.currentModel.validationErrors;
            if ~isnan(val)
                params(i).value = val;
            else
                params(i).value = 1;
            end
        elseif params(i).shortCaption == string('testError')
            val = project.currentModel.testingErrors;
            if ~isnan(val)
                params(i).value = val;
            else
                params(i).value = 1;
            end
        end       
    end
end
