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

classdef DataSelection < Descriptions
    properties
        usedDataMask
        target
        
        trainingSelection
        validationSelection
    end
    
    properties(Hidden)
        empty = false
    end

    methods
        function obj = DataSelection()
            if nargin == 0
                obj.empty = true;
                return
            end
        end
        
        function target = getSelectedTarget(obj,mode,valStep)
            if nargin < 2
                mode = obj.mode;
            end
            if nargin < 3
                valStep = obj.validationStep;
            end
            target = obj.target(obj.cycleSelection,:);
            sel = obj.getCurrentCycleSelection(mode,valStep);
            target = target(sel,:);
        end
        
        function prediction = getSelectedPrediction(obj,mode,valStep)
            if nargin < 2
                mode = obj.mode;
            end
            if nargin < 3
                valStep = obj.validationStep;
            end
            cols = size(obj.target,2);
            sel = obj.getCurrentCycleSelection(mode) & obj.cycleSelection;
            switch mode
                case 'training'
                    prediction = obj.trainingPrediction(sel,:);
                case 'validation'
                    range = (valStep-1) * cols + 1 : valStep * cols;
                    prediction = obj.validationPrediction(sel,range);
                case 'testing'
                    prediction = obj.testingPrediction(sel,:);
            end
        end
        
        function setSelectedPrediction(obj,prediction,mode,valStep)
            if nargin < 3
                mode = obj.mode;
            end
            if nargin < 4
                valStep = obj.validationStep;
            end
            cols = size(obj.target,2);
            sel = obj.getCurrentCycleSelection(mode,valStep) & obj.cycleSelection;
            switch mode
                case 'training'
                    obj.trainingPrediction(sel,:) = prediction;
                case 'validation'
                    range = (obj.validationStep-1) * cols + 1 : obj.validationStep * cols;
                    obj.validationPrediction(sel,range) = prediction;
                case 'testing'
                    obj.testingPrediction(sel,:) = prediction;
            end
        end
        
        function sel = getCurrentCycleSelection(obj,mode,valStep)
            if nargin < 2
                mode = obj.mode;
            end
            if nargin < 3
                valStep = obj.validationStep;
            end
            switch mode
                case 'training'
                    sel = obj.trainingSelection(:,valStep,valIt,testStep,testIt);
                case 'validation'
                    sel = obj.validationSelection(:,valStep,valIt,testStep,testIt);
                case 'testing'
                    sel = obj.testingSelection;
            end
        end
        
        function newObj = applySelections(obj)
            newObj = Data(obj.data(obj.cycleSelection,obj.featureSelection),...
                obj.offsets(obj.cycleSelection,:));
            newObj.abscissa = obj.abscissa(obj.featureSelection);
            newObj.grouping = obj.grouping(obj.cycleSelection,:);
            newObj.target = obj.target(obj.cycleSelection,:);
            newObj.trainingSelection = obj.trainingSelection(obj.cycleSelection,:);
            newObj.validationSelection = obj.validationSelection(obj.cycleSelection,:);
            newObj.testingSelection = obj.testingSelection(obj.cycleSelection,:);
            newObj.featureCaptions = obj.featureCaptions(obj.featureSelection);
            newObj.selectedCycles = find(obj.cycleSelection);
            newObj.selectedFeatures = find(obj.featureSelection);
            newObj.cycleSelection = ones(sum(obj.cycleSelection),1);
            newObj.featureSelection = ones(1,sum(obj.featureSelection));
            newObj.trainingPrediction = newObj.trainingPrediction(obj.cycleSelection,:);
            newObj.validationPrediction = newObj.validationPrediction(obj.cycleSelection,:);
            newObj.testingPrediction = newObj.testingPrediction(obj.cycleSelection,:);
            
            newObj.setCaption(obj.getCaption());
        end
        
        function newObj = copy(obj)
            newObj = Data(obj.data,obj.offsets);
            newObj.abscissa = obj.abscissa;
            newObj.grouping = obj.grouping;
            newObj.target = obj.target;
            newObj.trainingSelection = obj.trainingSelection;
            newObj.validationSelection = obj.validationSelection;
            newObj.testingSelection = obj.testingSelection;
            newObj.featureCaptions = obj.featureCaptions;
            newObj.selectedCycles = obj.selectedCycles;
            newObj.selectedFeatures = obj.selectedFeatures;
            newObj.cycleSelection = obj.cycleSelection;
            newObj.featureSelection = obj.featureSelection;
            newObj.trainingPrediction = obj.trainingPrediction;
            newObj.validationPrediction = obj.validationPrediction;
            newObj.testingPrediction = obj.testingPrediction;
            
            newObj.setCaption(obj.getCaption());
        end
        
        function newObj = horizontalCopy(obj,data)
            if size(data,1) ~= size(obj.data,1)
                error('Number of rows must not change for a horizontal copy.')
            end
            newObj = obj.copy();
            newObj.data = data;
            newObj.abscissa = 1:size(data,2);
            newObj.featureSelection = true(1,size(data,2));
            newObj.featureCaptions = cell(1,size(data,2));
        end
        
        function setValidation(obj,type,varargin)
            p = inputParser();
            p.addRequired('type');
            p.addParameter('folds',10);
            p.addParameter('iterations',1);
            p.addParameter('logicalMask',false);
            p.addParameter('offsetRange',nan(1,2));
            p.parse(type,varargin{:});
            p = p.Results;
            
            
            
            switch p.type
                case 'none'
                    obj.validationSelection = false(numel(obj.target),1);
                case 'kFold'
                    for i = 1:p.iterations
                        c = cvpartition(obj.target,'kFold',p.folds);
                        for j = 1:p.folds
                            
                        end
                    end
                case 'loocv'
                    
                case 'mask'
                    
                case 'offsets'
                    
                otherwise
                    error('Type unknwon.');
            end
        end
        
        function rmse = computeRMSE(obj)
            rmse = [];
        end
        
        function cError = computeClassificationError(obj)
            validTrainingPrediction = ~isundefined(obj.trainingPrediction);
            validTestingPrediction = ~isundefined(obj.testingPrediction);
            training = obj.trainingPrediction(validTrainingPrediction) == obj.target(validTrainingPrediction);
            testing = obj.testingPrediction(validTestingPrediction) == obj.target(validTestingPrediction);
            validation = [];
            for i = 1:size(obj.validationSelection,2)
                validation = [validation, obj.getSelectedPrediction('validation',i) == obj.getSelectedTarget('validation',i)];
            end
            cError.training = sum(~training) / numel(training);
            cError.validation = sum(~validation,1) / size(validation,1);
            cError.testing = sum(~testing) / numel(testing);
        end
    end
end