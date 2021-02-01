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

function info = knn()
    info.type = DataProcessingBlockTypes.Classification;
    info.caption = 'kNN';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','trained', 'value',false, 'internal',true)...
        Parameter('shortCaption','classifier', 'internal',true)...
        Parameter('shortCaption','k', 'value',int32(1), 'enum',int32(1:2:30), 'selectionType','multiple')...
        Parameter('shortCaption','inputData', 'value',[], 'internal',true),...
        Parameter('shortCaption','trainError','value',1,'editable',false),...
        Parameter('shortCaption','validationError','value',1,'editable',false),...
        Parameter('shortCaption','testError','value',1,'editable',false)...
        ];
    info.apply = @apply;
    info.train = @train;
    info.updateParameters = @updateParameters;
    info.detailsPages = {'confusionmatrix','territorialPlot'};
end

function [data,params] = apply(data,params)
    if ~params.trained
        error('Classifier must first be trained.');
    end
%     data.mode
    pred = params.classifier.predict(data.getSelectedData());
    data.setSelectedPrediction(pred);
    
    switch data.mode
        case 'training'
            params.inputData.training = data.getSelectedData();
        case 'testing'
            params.inputData.testing = data.getSelectedData();
    end    
end

function params = train(data,params)
    params.trained = true;
    params.classifier = fitcknn(data.getSelectedData(),data.getSelectedTarget());
    params.classifier.NumNeighbors = double(params.k);
    pred = params.classifier.predict(data.getSelectedData());
    data.setSelectedPrediction(pred);
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