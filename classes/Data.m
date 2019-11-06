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

classdef Data < Descriptions
    properties
        data
        
        abscissa
        abscissaSensor
        abscissaCycle
        
        groupings
        groupingCaptions
        groupingCaption
        groupingObj
        reducedGrouping
        target
        targetCaption
%         targetType = 'categorical'
        offsets
        cycleSelection
        featureSelection
        featureCaptions

        trainingSelection
        validationSelection
        testingSelection
        
        trainingPrediction
        validationPrediction
        testingPrediction
        applyPrediction
        
        validationType = 'none'
        validationSteps = 1
        validationIterations = 1
        validationParameters
        testingType = 'none'
        testingSteps = 1
        testingIterations = 1
        testingParameters
        
        sourceSensors
        sensorMapping
        
        history
        
        % can be set to false by setSelectedData()
        % when only part of the data is overwritten
        % in a way that the feature selection must be
        % changed
        % if so, the Data cannot be used with
        % DataProcessingBlocks anymore
        hasIrreversibleChanges = false
        irreversibleChangeWasMade = false
        
        errors
    end
    
    properties(Hidden)
        empty = false
        part = false
        mode = 'training'
        validationStep = 1
        validationIteration = 1
        testingStep = 1
        testingIteration = 1
    end

    properties(Dependent)
        grouping
        applySelection
        availableSelection
        selectedCycles
        selectedFeatures
        targetType
    end
    
    methods
        function obj = Data(data,offsets,asPart)
            obj@Descriptions(true);
            if nargin == 0
                obj.empty = true;
                return
            end
            if nargin == 3 && all(asPart)
                obj.part = true;
                obj.data = data;
            else
                obj.data = data;
                obj.offsets = reshape(offsets,size(data,1),1);
                obj.createMetaData();
                obj.initialize();
            end
        end
        
        function initialize(obj)
            obj.abscissa = 1:size(obj.data,2);
            obj.cycleSelection = true(size(obj.data,1),1);
            obj.featureSelection = true(1,size(obj.data,2));
            obj.groupings = categorical(nan(size(obj.data,1),1));
            obj.groupingCaptions = {''};
            obj.groupingCaption = '';
            obj.target = categorical(nan(size(obj.data,1),1));
            obj.targetCaption = '';
            obj.featureCaptions = cell(1,size(obj.data,2));
            obj.trainingSelection = obj.cycleSelection;
            obj.validationSelection = false(size(obj.data,1),1);
            obj.testingSelection = false(size(obj.data,1),1);
            obj.trainingPrediction = obj.target;
            obj.validationPrediction = obj.target;
            obj.testingPrediction = obj.target;
        end
        
        function val = testIntegrity(obj)
            val = true;
            augmentedTestingSelection(:,1,1,:,:) = obj.testingSelection;
            check1 = obj.trainingSelection & obj.validationSelection;
            check2 = obj.trainingSelection & augmentedTestingSelection;
            check3 = obj.validationSelection & augmentedTestingSelection;
            if any(check1(:)) || any(check2(:)) || any(check3(:))
                val = false;
            end
        end
        
        function setTarget(obj,target,type)
            % remove trailing asterisks
            if iscell(target)
                target = categorical(target);
            end
            if iscategorical(target)
                target = deStar(removecats(target));
            end
            
            switch type
                case 'numeric'
                    if iscategorical(target)
                        target = cellfun(@str2double,cellstr(target));
                    end
                    obj.target = target;
                    obj.trainingPrediction = double(obj.trainingPrediction);
                    obj.validationPrediction = double(obj.validationPrediction);
                    obj.testingPrediction = double(obj.testingPrediction);
                    obj.applyPrediction = double(obj.applyPrediction);
                case 'categorical'
                    obj.target = categorical(target);
                    obj.trainingPrediction = categorical(obj.trainingPrediction);
                    obj.validationPrediction = categorical(obj.validationPrediction);
                    obj.testingPrediction = categorical(obj.testingPrediction);
                    obj.applyPrediction = categorical(obj.applyPrediction);
                otherwise
                    error('Unknown type.');
            end
%             obj.targetType = type;
        end
        
        function setTargetType(obj,type)
            switch type
                case 'numeric'
                    if strcmp(obj.targetType,'numeric')
                        return
                    end
                    if iscategorical(obj.target)
                        obj.target = cellfun(@str2double,cellstr(obj.target));
                    end
                    obj.trainingPrediction = double(obj.trainingPrediction);
                    obj.validationPrediction = double(obj.validationPrediction);
                    obj.testingPrediction = double(obj.testingPrediction);
                    obj.applyPrediction = double(obj.applyPrediction);
                case 'categorical'
                    if strcmp(obj.targetType,'categorical')
                        return
                    end
                    obj.target = categorical(obj.target);
                    obj.trainingPrediction = categorical(obj.trainingPrediction);
                    obj.validationPrediction = categorical(obj.validationPrediction);
                    obj.testingPrediction = categorical(obj.testingPrediction);
                    obj.applyPrediction = categorical(obj.applyPrediction);
                otherwise
                    error('Unknown type.');
            end
%             obj.targetType = type;            
        end
        
        function setSelectedTarget(obj,target,mode)
            if nargin < 3
                mode = obj.mode;
            end
            sel = obj.getCurrentCycleSelection(mode);
            obj.target(sel) = target;
        end        
        
        function f = getFeatureByName(obj,featureCaption)
            fPos = ismember(obj.featureCaptions,featureCaption);
            f = obj.data(:,fPos);
        end
        
        function g = getGroupingByName(obj,groupingCaption)
            gPos = ismember(obj.groupingCaptions,groupingCaption);
            if isempty(obj.reducedGrouping)
                g = removecats(obj.groupings(:,gPos));
            else
                g = removecats(obj.reducedGrouping(:,gPos));
            end
        end
        
        function setSelectedFeatures(obj,features)
            obj.featureSelection = ismember(obj.featureCaptions,features);
%             obj.selectedFeatures = obj.featureCaptions(obj.featureSelection);
        end
        
        function selectAllFeatures(obj)
            obj.featureSelection = true(size(obj.featureCaptions),1);
%             obj.selectedFeatures = obj.featureCaptions;
        end
        
        function idx = getSelectedGroupingIndex(obj)
            idx = find(ismember(obj.groupingCaptions,obj.groupingCaption));
        end
        
        function sel = get.grouping(obj)
            if ~isempty(obj.reducedGrouping)
%                 sel = obj.reducedGrouping;
                sel = removecats(obj.reducedGrouping(:,obj.getSelectedGroupingIndex()));
            else
                sel = removecats(obj.groupings(:,obj.getSelectedGroupingIndex()));
            end
        end    
        
        function t = get.targetType(obj)
            switch class(obj.target)
                case 'categorical'
                    t = string('categorical');
                case 'double'
                    t = string('numeric');
                otherwise
                    error('Unknown target type.');
            end
        end
        
        function sel = get.applySelection(obj)
            switch obj.targetType
                case 'numeric'
                    sel = isnan(obj.target);
                case 'categorical'
                    sel = isundefined(obj.target);
            end
        end
        
        function sel = get.availableSelection(obj)
            sel = ~obj.applySelection & obj.cycleSelection;
%             sel = ~obj.testingSelection & obj.cycleSelection;
        end
        
        function sel = get.selectedCycles(obj)
            sel = find(obj.cycleSelection);
        end
        
        function sel = get.selectedFeatures(obj)
            sel = obj.featureCaptions(obj.featureSelection);
        end
        
        function initProcessing(obj)
            obj.processedData = obj.data;
        end
        
        function idx = getSelectedCycles(obj,mode)
            if nargin < 2
                mode = obj.mode;
            end
            idx = find(obj.getCurrentCycleSelection(mode));
        end
        
        function idx = getSelectedCycleOffsets(obj,mode)
            if nargin < 2
                mode = obj.mode;
            end
            idx = obj.offsets(obj.getCurrentCycleSelection(mode));
        end
        
        function data = getSelectedData(obj,mode)
            if nargin < 2
                mode = obj.mode;
            end
            sel = obj.getCurrentCycleSelection(mode);
            data = obj.data(sel,obj.featureSelection);
%             data = data(sel,:);
        end
        
        function setSelectedData(obj,data)
            sel = obj.getCurrentCycleSelection();
            if size(data,2) == sum(obj.featureSelection)
                obj.data(sel,obj.featureSelection) = data;
            else
                obj.irreversibleChangeWasMade = true;
                obj.data(sel,:) = nan;
                obj.data(sel,1:size(data,2)) = data;
                obj.data(:,size(data,2)+1:end) = [];
                obj.featureSelection = true(1,size(data,2));
                obj.featureCaptions = cell(1,size(data,2));
            end
        end

        function target = getSelectedTarget(obj,mode)
            if nargin < 2
                mode = obj.mode;
            end
            target = obj.target(obj.getCurrentCycleSelection(mode),:);
            if iscategorical(target)
                target = removecats(target);
            end
        end
        
        function grouping = getSelectedGrouping(obj,mode,caption)
            if nargin < 2
                mode = obj.mode;
            end
            if nargin < 3
                grouping = obj.grouping(obj.getCurrentCycleSelection(mode),:);
            else
                grouping = obj.getGroupingByName(caption);
                grouping = grouping(obj.getCurrentCycleSelection(mode),:);
            end
            grouping = removecats(grouping);
        end
        
        function [prediction,sel,indices] = getSelectedPrediction(obj,mode)
            if nargin < 2
                mode = obj.mode;
            end
            sel = obj.getCurrentCycleSelection();
            indices = {obj.validationStep,obj.validationIteration,...
                    obj.testingStep,obj.testingIteration};
            indices_ = indices;
            if obj.part
                indices_ = {1,1,1,1};
            else
                
            end
            switch mode
                case 'training'
%                     obj.trainingPrediction(sel,:,indices_{:})
                    prediction = obj.trainingPrediction(sel,indices_{:});
                case 'validation'
                    prediction = obj.validationPrediction(sel,indices_{:});
                case 'testing'
                    prediction = obj.testingPrediction(sel,indices_{3:4});
                case 'apply'
                    prediction = obj.applyPrediction(sel,indices_{:});
            end
        end
        
        function setSelectedPrediction(obj,prediction,mode,sel,indices,correctNonTrained)
            if nargin < 3
                mode = obj.mode;
            end
            if nargin < 5
                indices = {obj.validationStep,obj.validationIteration,...
                    obj.testingStep,obj.testingIteration};
            end
            if nargin < 4
                sel = obj.getCurrentCycleSelection(mode,indices{:});
            end
            if nargin < 6
                correctNonTrained = true;
            end
            if obj.part
                indices = {1,1,1,1};
            end

            if correctNonTrained && ~strcmp(obj.mode,'training')
                % make sure that classes which were not included in the
                % training become <undefined> instead of a random wrong
                % prediction (for classification only)
                trainedTarget = obj.getSelectedTarget('training');
                thisTarget = obj.getSelectedTarget();
                if iscategorical(trainedTarget)
                    p = categorical(nan(size(prediction)));
                    p(ismember(thisTarget,categories(trainedTarget))) = prediction(ismember(thisTarget,categories(trainedTarget)));
                    prediction = p;
                end
            end
            
            if iscategorical(prediction)
                obj.setTargetType('categorical');
            else
                obj.setTargetType('numeric');
            end
            
            switch mode
                case 'training'
                    obj.trainingPrediction(sel,indices{:}) = prediction;
                case 'validation'
                    obj.validationPrediction(sel,indices{:}) = prediction;
                case 'testing'
                    obj.testingPrediction(sel,indices{3:4}) = prediction;
                case 'apply'
                    obj.applyPrediction(sel,indices{:}) = prediction;
            end
        end
        
        function sel = getCurrentCycleSelection(obj,mode,valStep,valIter,testStep,testIter)
            if nargin < 2
                mode = obj.mode;
            end
            if nargin < 3
                valStep = obj.validationStep;
                valIter = obj.validationIteration;
                testStep = obj.testingStep;
                testIter = obj.testingIteration;
            end
            if obj.part
                valStep = 1;
                valIter = 1;
                testStep = 1;
                testIter = 1;
            end

            switch mode
                case 'training'
                    sel = obj.trainingSelection(:,valStep,valIter,testStep,testIter);
                case 'validation'
                    sel = obj.validationSelection(:,valStep,valIter,testStep,testIter);
                case 'testing'
                    sel = obj.testingSelection(:,testStep,testIter);
                case 'apply'
                    sel = obj.applySelection;
            end
            sel = sel & obj.cycleSelection;
        end
        
        function setSelectedGroups(obj,groups)
            obj.cycleSelection = ismember(obj.grouping,groups);
        end
        
        function groups = getSelectedGroups(obj)
            groups = categories(removecats(obj.grouping(obj.cycleSelection)));
        end
        
        function newObj = applySelections(obj)
            newObj = Data(obj.data(obj.cycleSelection,obj.featureSelection),...
                obj.offsets(obj.cycleSelection,:));
            newObj.abscissa = obj.abscissa(obj.featureSelection);
            newObj.groupings = obj.groupings(obj.cycleSelection,:);
            newObj.groupingCaption = obj.groupingCaption;
            newObj.groupingCaptions = obj.groupingCaptions;
            newObj.target = obj.target(obj.cycleSelection,:);
            newObj.trainingSelection = obj.trainingSelection(obj.cycleSelection,:);
            newObj.validationSelection = obj.validationSelection(obj.cycleSelection,:);
            newObj.testingSelection = obj.testingSelection(obj.cycleSelection,:);
            newObj.featureCaptions = obj.featureCaptions(obj.featureSelection);
%             newObj.selectedCycles = find(obj.cycleSelection);
%             newObj.selectedFeatures = find(obj.featureSelection);
            newObj.cycleSelection = true(sum(obj.cycleSelection),1);
            newObj.featureSelection = true(1,sum(obj.featureSelection));
            newObj.trainingPrediction = newObj.trainingPrediction(obj.cycleSelection,:);
            newObj.validationPrediction = newObj.validationPrediction(obj.cycleSelection,:);
            newObj.testingPrediction = newObj.testingPrediction(obj.cycleSelection,:);
            
            newObj.setCaption(obj.getCaption());
        end

        function reduceData(obj,fcn,varargin)
            selGroups = categories(removecats(obj.grouping(obj.cycleSelection)));
            
            [newData,newGrouping,newTarget,newOffsets] = ...
                fcn(obj.data,obj.groupings,obj.target,obj.offsets, varargin{:});
            obj.data = newData;
            obj.reducedGrouping = newGrouping;
            obj.setTarget(newTarget,obj.targetType);
            
            obj.cycleSelection = true(size(newData,1),1);
            obj.trainingSelection = obj.cycleSelection;
            obj.validationSelection = false(size(obj.data,1),1);
            obj.testingSelection = false(size(obj.data,1),1);
            obj.trainingPrediction = obj.target;
            obj.validationPrediction = obj.target;
            obj.testingPrediction = obj.target;
            obj.offsets = newOffsets;
            
            obj.setSelectedGroups(selGroups);
            obj.updateTesting();
        end
        
        function newObj = copy(obj,num)
            if nargin < 2 % num
                num = 1;
            end
            
            newObj(num) = Data();
            for i = 1:num
                newObj(i) = Data(obj.data,obj.offsets,'asPart');
                newObj(i).part = false;
                newObj(i).createMetaData();
                newObj(i).offsets = obj.offsets;
                newObj(i).abscissa = obj.abscissa;
                newObj(i).groupings = obj.groupings;
                newObj(i).groupingCaption = obj.groupingCaption;
                newObj(i).groupingCaptions = obj.groupingCaptions;
                newObj(i).reducedGrouping = obj.reducedGrouping;
                newObj(i).target = obj.target;
                newObj(i).trainingSelection = obj.trainingSelection;
                newObj(i).validationSelection = obj.validationSelection;
                newObj(i).testingSelection = obj.testingSelection;
                newObj(i).featureCaptions = obj.featureCaptions;
%                 newObj(i).selectedCycles = obj.selectedCycles;
%                 newObj(i).selectedFeatures = obj.selectedFeatures;
                newObj(i).cycleSelection = obj.cycleSelection;
                newObj(i).featureSelection = obj.featureSelection;
                newObj(i).trainingPrediction = obj.trainingPrediction;
                newObj(i).validationPrediction = obj.validationPrediction;
                newObj(i).testingPrediction = obj.testingPrediction;

%                 newObj(i).targetType = obj.targetType;
                newObj(i).mode = obj.mode;
                newObj(i).validationStep = obj.validationStep;
                newObj(i).validationIteration = obj.validationIteration;
                newObj(i).testingStep = obj.testingStep;
                newObj(i).testingIteration = obj.testingIteration;
                
                newObj(i).validationType = obj.validationType;
                newObj(i).validationSteps = obj.validationSteps;
                newObj(i).validationIterations = obj.validationIterations;
                newObj(i).validationParameters = obj.validationParameters;
                newObj(i).testingType = obj.testingType;
                newObj(i).testingSteps = obj.testingSteps;
                newObj(i).testingIterations = obj.testingIterations;
                newObj(i).testingParameters = obj.testingParameters;

                newObj(i).setCaption(obj.getCaption());
            end
        end
        
        function newObj = copyPart(obj,mode,valStep,valIter,testStep,testIter,num)
            if nargin < 7 % num
                num = 1;
            end
            indices = {valStep,valIter,testStep,testIter};

            newObj(num) = Data();
            for i = 1:num
                newObj(i) = Data(obj.data,obj.offsets,'asPart');
                newObj(i).target = obj.target;

                newObj(i).trainingSelection = obj.getCurrentCycleSelection('training',indices{:});
                newObj(i).validationSelection = obj.getCurrentCycleSelection('validation',indices{:});
                newObj(i).testingSelection = obj.getCurrentCycleSelection('testing',indices{:});
                        
                newObj(i).groupings = obj.groupings;
                newObj(i).reducedGrouping = obj.reducedGrouping;
                newObj(i).groupingCaption = obj.groupingCaption;
                newObj(i).groupingCaptions = obj.groupingCaptions;
                newObj(i).trainingPrediction = obj.trainingPrediction(:,indices{:});
                newObj(i).validationPrediction = obj.validationPrediction(:,indices{:});
                newObj(i).testingPrediction = obj.testingPrediction(:,indices{3:4});
                newObj(i).cycleSelection = obj.cycleSelection;
                newObj(i).featureSelection = obj.featureSelection;
                newObj(i).featureCaptions = obj.featureCaptions;
                newObj(i).mode = mode;
                newObj(i).validationType = obj.validationType;
                newObj(i).validationStep = valStep;
                newObj(i).validationIteration = valIter;
                newObj(i).testingType = obj.testingType;
                newObj(i).testingStep = testStep;
                newObj(i).testingIteration = testIter;
            end
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
        
        function setTesting(obj,type,varargin)
            p = inputParser();
            p.addRequired('type');
            p.addParameter('folds',10);
            p.addParameter('iterations',1);
            p.addParameter('logicalMask',false);
            p.addParameter('offsetRange',nan(1,2));
            p.addParameter('percent',0);
            p.addParameter('groupbased',false);
            p.addParameter('grouping','');
            p.addParameter('groups','');
            p.addParameter('trainAlways',{});
            p.parse(type,varargin{:});
            p = p.Results;
            
            obj.testingSteps = p.folds;
            obj.testingIterations = p.iterations;
            
%             obj.testingSteps = 1;
%             obj.testingIterations = 1;
            obj.testingSelection = false(numel(obj.target),1,1);
            
            switch p.type
                case 'none'
                    obj.testingSteps = 1;
                    obj.testingIterations = 1;
                    obj.testingSelection = false(numel(obj.target),1,1);
                case 'kFold'
                    %
                case 'loocv'
                    %
                case 'holdout'
                    obj.testingSteps = 1;
                case 'groups'
                    obj.testingSteps = 1;
                    obj.testingIterations = 1;
                    p.groupbased = true;
                case 'mask'
                    if size(p.logicalMask,1) ~= numel(obj.target)
                        error('Mask must have same number of rows as target.');
                    end
                    obj.testingSteps = size(p.logicalMask,2);
                    obj.testingIterations = 1;
                    obj.testingSelection = repmat(p.logicalMask,1,1);
                case 'offsets'
                    obj.testingSteps = 1;
                    obj.testingIterations = 1;
                    mask = obj.offsets >= p.offsetRange(1) & obj.offsets <= p.offsetRange(2);
                    obj.testingSelection = repmat(mask,1,1);
                otherwise
                    error('Type unknwon.');
            end
            obj.testingType = p.type;
            obj.testingParameters = varargin;
            
            availSel = obj.availableSelection;
            obj.testingSelection = false(numel(obj.target),...
                obj.testingSteps,obj.testingIterations);
            
            for testit = 1:obj.testingIterations
                sel = availSel;
                t = obj.target(sel);
                if p.groupbased
                    actualTarget = t;
                    g = obj.getGroupingByName(p.grouping);
                    t = categories(removecats(g(sel)));
                    t(ismember(t,p.trainAlways)) = [];
                end
                switch p.type
                    case 'kFold'
                        c = cvpartition(numel(t),'kFold',double(p.folds));
                    case 'loocv'
                        c = cvpartition(numel(t),'LeaveOut');
                    case 'holdout'
                        c = cvpartition(numel(t),'HoldOut',p.percent/100);
                    case 'groups'
                        c = my_cvpartition(...
                            ~ismember(t,p.groups),ismember(t,p.groups));
                    otherwise
                        continue
                end
                obj.testingSteps = c.NumTestSets;
                
                for teststep = 1:c.NumTestSets
                    testSel = c.test(teststep);
                    if p.groupbased
                        testSelNew = false(size(actualTarget));
                        g = obj.getGroupingByName(p.grouping);
                        g = g(sel);
                        for cidx = 1:numel(t)
                            testSelNew(g==t(cidx)) = testSel(cidx);
                        end
                        testSel = testSelNew;
                    end
                    testSelFinal = false(size(obj.testingSelection,1),1);
                    testSelFinal(sel) = testSel;
                    obj.testingSelection(:,teststep,testit) = testSelFinal;
                end
            end
            
            s = size(obj.testingSelection);
            obj.testingPrediction = nan([size(obj.target,1),s(2:end)]);
            if strcmp(obj.targetType,'categorical')
                obj.testingPrediction = categorical(obj.testingPrediction);
            end
            
            obj.updateValidation();
        end
        
        function updateTesting(obj)
            obj.setTesting(obj.testingType,obj.testingParameters{:});
        end
        
        function updateValidation(obj)
            obj.setValidation(obj.validationType,obj.validationParameters{:});
        end
        
        function setValidation(obj,type,varargin)
            p = inputParser();
            p.addRequired('type');
            p.addParameter('folds',10);
            p.addParameter('iterations',1);
            p.addParameter('logicalMask',false);
            p.addParameter('offsetRange',nan(1,2));
            p.addParameter('percent',0);
            p.addParameter('groupbased',false);
            p.addParameter('grouping','');
            p.addParameter('groups','');
            p.addParameter('trainAlways',{});
            p.parse(type,varargin{:});
            p = p.Results;

            obj.validationIterations = p.iterations;
            
            switch p.type
                case 'none'
                    obj.validationSteps = 1;
                    obj.validationIterations = 1;
                    obj.trainingSelection = repmat(~obj.applySelection & ~obj.testingSelection,...
                        1,1,1,obj.testingSteps,obj.testingIterations);
                    obj.validationSelection = false(size(obj.target,1),...
                        1,1,obj.testingSteps,obj.testingIterations);
                case 'kFold'
                    obj.validationSteps = p.folds;
                case 'loocv'
                    %
                case 'holdout'
                    obj.validationSteps = 1;
                case 'groups'
                    obj.validationSteps = 1;
                    obj.validationIterations = 1;
                    p.groupbased = true;
                case 'mask'
                    if size(p.logicalMask,1) ~= numel(obj.target)
                        error('Mask must have same number of rows as target.');
                    end
                    obj.validationSteps = size(p.logicalMask,2);
                    obj.validationIterations = 1;
                    mask = p.logicalMask & ~obj.applySelection & ~obj.testingSelection;
                    trainSel = ~mask  & ~obj.applySelection & ~obj.testingSelection;
                    obj.validationSelection = repmat(mask,1,1,...
                        obj.testingSteps,obj.testingIterations);
                    obj.trainingSelection = repmat(trainSel,...
                        0,0,obj.testingSteps,obj.testingIterations);
                case 'offsets'
                    obj.validationSteps = 1;
                    obj.validationIterations = 1;
                    mask = obj.offsets >= p.offsetRange(1) & obj.offsets <= p.offsetRange(2);
                    trainSel = ~mask  & ~obj.applySelection & ~obj.testingSelection;
                    obj.validationSelection = repmat(mask,1,1,...
                        obj.testingSteps,obj.testingIterations);
                    obj.trainingSelection = repmat(trainSel,...
                        0,0,obj.testingSteps,obj.testingIterations);
                otherwise
                    error('Type unknwon.');
            end
            obj.validationType = p.type;
            obj.validationParameters = varargin;
            
            availSel = obj.availableSelection;
            
            for testit = 1:obj.testingIterations
                for teststep = 1:obj.testingSteps
                    for valit = 1:obj.validationIterations
                        testSel = obj.getCurrentCycleSelection('testing',[],[],teststep,testit);
                        sel = ~testSel & availSel;
                        t = obj.target(sel);
                        if p.groupbased
                            actualTarget = t;
                            g = obj.getGroupingByName(p.grouping);
                            t = categories(removecats(g(sel)));
                            t(ismember(t,p.trainAlways)) = [];
                        end
                        switch p.type
                            case 'kFold'
                                c = cvpartition(numel(t),'kFold',double(p.folds));
                            case 'loocv'
                                c = cvpartition(numel(t),'LeaveOut');
                            case 'holdout'
                                c = cvpartition(numel(t),'HoldOut',p.percent/100);
                            case 'groups'
                                c = my_cvpartition(...
                                    ~ismember(t,p.groups),ismember(t,p.groups));
                            otherwise
                                continue
                        end
                        obj.validationSteps = c.NumTestSets;
                        for valstep = 1:c.NumTestSets
%                             if obj.testingSteps > 0 && obj.testingIterations > 0
                                trainSel = c.training(valstep);
                                valSel = c.test(valstep);
                                if p.groupbased
                                    trainSelNew = true(size(actualTarget));
                                    valSelNew = false(size(actualTarget));
                                    if isnumeric(actualTarget)
                                        trainSelNew = double(trainSelNew);
                                        valSelNew = double(valSelNew);
                                    end
                                    g = obj.getGroupingByName(p.grouping);
                                    g = g(sel);
                                    for cidx = 1:numel(t)
                                        trainSelNew(g==t(cidx)) = trainSel(cidx);
                                        valSelNew(g==t(cidx)) = valSel(cidx);
                                    end
                                    trainSel = trainSelNew;
                                    valSel = valSelNew;
                                end
                                trainSelFinal = false(size(obj.trainingSelection,1),1);
                                trainSelFinal(sel) = trainSel;
                                validationSelFinal = false(size(obj.validationSelection,1),1);
                                validationSelFinal(sel) = valSel;
                                obj.trainingSelection(:,...
                                    valstep,valit,teststep,testit) = trainSelFinal;
                                obj.validationSelection(:,...
                                    valstep,valit,teststep,testit) = validationSelFinal;
%                             end
                        end
                    end
                end
            end
            
            obj.trainingSelection = obj.trainingSelection(:,...
                1:obj.validationSteps,...
                1:obj.validationIterations,...
                1:obj.testingSteps,...
                1:obj.testingIterations);
            
            obj.validationSelection = obj.validationSelection(:,...
                1:obj.validationSteps,...
                1:obj.validationIterations,...
                1:obj.testingSteps,...
                1:obj.testingIterations);
            
            s = size(obj.trainingSelection);
            obj.trainingPrediction = nan([size(obj.target,1),s(2:end)]);
            s = size(obj.validationSelection);
            obj.validationPrediction = nan([size(obj.target,1),s(2:end)]);
            
            if strcmp(obj.targetType,'categorical')
                obj.trainingPrediction = categorical(obj.trainingPrediction);
                obj.validationPrediction = categorical(obj.validationPrediction);
            end
        end
        
        function datas = split(obj,num)
            if nargin < 2
                num = 1;
            end
            datas(num,obj.validationSteps,obj.validationIterations,...
                obj.testingSteps,obj.validationIterations) = Data();
            for n = 1:num
                for testit = 1:obj.testingIterations
                    for teststep = 1:obj.testingSteps
                        for valit = 1:obj.validationIterations
                            for valstep = 1:obj.validationSteps
                                d = obj.copy();
                                d.validationStep = valstep;
                                d.validationIteration = valit;
                                d.testingStep = teststep;
                                d.testingIteration = testit;
                                datas(n,valstep,valit,teststep,testit) = d;
                            end
                        end
                    end
                end
            end
        end
        
        function addPredictionsFrom(obj,datas)
            for i = 1:numel(datas)
                [pred,sel,indices] = datas(i).getSelectedPrediction();
                obj.setSelectedPrediction(pred,datas(i).mode,sel,indices,false);
            end
        end
        
        function [target,pred] = getTargetAndValidatedPrediction(obj)
            if iscategorical(obj.validationPrediction)
                validValidationPrediction = ~isundefined(obj.validationPrediction);
            else
                validValidationPrediction = ~isnan(obj.validationPrediction);
            end
            dims = size(obj.trainingPrediction);
            t = repmat(obj.target,[1 dims(2:end)]);
            pred = obj.validationPrediction(validValidationPrediction);
            target = t(validValidationPrediction);
            if iscategorical(target)
                target = removecats(target);
                pred = removecats(pred);
            end
        end
        
        function idx = getBestParametersFromErrors(obj,criterion,errors,x,varargin)
            if nargin < 2
                criterion = 'min';
            end
            if nargin < 3 || isempty(errors)
                errors = obj.errors;
            end
            x = double(x);
            
            switch criterion
                case 'min'
                    [~,idx] = min(errors.validation);
                case 'minDivStd'
                    [~,idx] = max(errors.validation ./ errors.validationStd);
                case 'minOneStd'
                    [minErr,idx] = min(errors.validation);
                    idx = find(errors.validation <= minErr + errors.validationStd(idx),1);
                case 'trainValQuotient'
                    q = errors.validation(2:end) ./ errors.training(1:end-1);
                    th = varargin{1};
                    idx = find(q > th,1) - 1;
                case 'elbow'
                    y = errors.validation;
                    p1 = [x(1),y(1)];
                    p2 = [x(end),y(end)];
                    dpx = p2(1) - p1(1);
                    dpy = p2(2) - p1(2);
                    dp = sqrt(sum((p2-p1).^2));
                    dists = abs(dpy*x - dpx*y + p2(1)*p1(2) - p2(2)*p1(1)) / dp;
                    [~,idx] = max(dists);
            end
            if idx > 0
                idx = x(idx);
            else
                idx = nan;
            end
        end
        
        function cCorr = computePearsonCorrelation(obj)
            if obj.targetType ~= 'numeric'
                cCorr.training = nan;
                cCorr.trainingStd = nan;
                cCorr.validation = nan;
                cCorr.validationStd = nan;
                cCorr.testing = nan;
                cCorr.testingStd = nan;
                return
            end
            
            validTrainingPrediction = ~isnan(obj.trainingPrediction);
            validValidationPrediction = ~isnan(obj.validationPrediction);
            validTestingPrediction = ~isnan(obj.testingPrediction);
            dims = size(obj.trainingPrediction);
            t = repmat(obj.target,[1 dims(2:end)]);
            
            sizes = size(validTrainingPrediction);
            nTraining = prod(sizes(2:end));
            nValidation = prod(sizes(2:end));
            nTesting = prod(sizes(4:end));
            
            pred = num2cell(obj.trainingPrediction,1); pred = pred(:);
            target = num2cell(t,1); target = target(:);
            valid = num2cell(validTrainingPrediction,1); valid = valid(:);
            c = [];
            for i = 1:numel(pred)
                cmat = corrcoef(pred{i}(valid{i}),target{i}(valid{i}));
                c(i) = cmat(2,1);
            end
%             fprintf('\ntraining corr coef: %.3f +/- %.3f\n', mean(c), std(c));
            cCorr.training = mean(c);
            cCorr.trainingStd = std(c) / sqrt(nTraining);

            pred = num2cell(obj.validationPrediction,1); pred = pred(:);
            target = num2cell(t,1); target = target(:);
            valid = num2cell(validValidationPrediction,1); valid = valid(:);
            c = [];
            for i = 1:numel(pred)
                cmat = corrcoef(pred{i}(valid{i}),target{i}(valid{i}),'rows','complete');
                c(i) = cmat(2,1);
            end
            c(isnan(c)) = [];
%             fprintf('validation corr coef: %.3f +/- %.3f\n', mean(c), std(c));
            cCorr.validation = mean(c);
            cCorr.validationStd = std(c) / sqrt(nValidation);
            
            pred = num2cell(obj.testingPrediction,1); pred = pred(:);
            target = num2cell(t,1); target = target(:);
            valid = num2cell(validTestingPrediction,1); valid = valid(:);
            c = [];
            for i = 1:numel(pred)
                cmat = corrcoef(pred{i}(valid{i}),target{i}(valid{i}),'rows','complete');
                c(i) = cmat(2,1);
            end
            c(isnan(c)) = [];
%             fprintf('testing corr coef: %.3f +/- %.3f\n', mean(c), std(c));
            cCorr.testing = mean(c);
            cCorr.testingStd = std(c) / sqrt(nTesting);
        end
        
        function cError = computeErrors(obj)
            if iscategorical(obj.trainingPrediction)
                cError = obj.computeClassificationError();
            else
                cError = obj.computeRMSE();
            end
        end
        
        function cError = computeRMSE(obj)
            validTrainingPrediction = ~isnan(obj.trainingPrediction);
            validValidationPrediction = ~isnan(obj.validationPrediction);
            validTestingPrediction = ~isnan(obj.testingPrediction);
            dims = size(obj.trainingPrediction);
            t = repmat(obj.target,[1 dims(2:end)]);
            training = obj.trainingPrediction(validTrainingPrediction) - t(validTrainingPrediction);
            validation = obj.validationPrediction(validValidationPrediction) - t(validValidationPrediction);
            testing = obj.testingPrediction(validTestingPrediction) - t(validTestingPrediction);

            trainingCorrect = nansum((obj.trainingPrediction - t).^2,1);
            trainingTotalValid = sum(validTrainingPrediction,1);
            trainingCorrectRatio = sqrt(trainingCorrect ./ trainingTotalValid);

            validationCorrect = nansum((obj.validationPrediction - t).^2,1);
            validationTotalValid = sum(validValidationPrediction,1);
            validationCorrectRatio = sqrt(validationCorrect ./ validationTotalValid);

            testingCorrect = nansum((obj.testingPrediction - t(:,1,1,:,:)).^2,1);
            testingTotalValid = sum(validTestingPrediction,1);
            testingCorrectRatio = sqrt(testingCorrect ./ testingTotalValid);

            cError.training = sqrt(sum(training.^2) / numel(training));
            cError.validation = sqrt(sum(validation.^2) / numel(validation));
            cError.testing = sqrt(sum(testing.^2) / numel(testing));
            
            sizes = size(validTrainingPrediction);
            nTraining = prod(sizes(2:end));
            nValidation = prod(sizes(2:end));
            nTesting = prod(sizes(4:end));
            
            cError.trainingStd = nanstd(trainingCorrectRatio(:)) / sqrt(nTraining);
            cError.validationStd = nanstd(validationCorrectRatio(:)) / sqrt(nValidation);
            cError.testingStd = nanstd(testingCorrectRatio(:)) / sqrt(nTesting);
            
            obj.errors = cError;
%             validTrainingPrediction = ~isnan(obj.trainingPrediction);
%             validValidationPrediction = ~isnan(obj.validationPrediction);
%             validTestingPrediction = ~isnan(obj.testingPrediction);
%             dims = size(obj.trainingPrediction);
% %             t = repmat(obj.target,size(obj.trainingPrediction));
%             t = repmat(obj.target,[1 dims(2:end)]);
%             training = obj.trainingPrediction(validTrainingPrediction) - t(validTrainingPrediction);
%             validation = obj.validationPrediction(validValidationPrediction) - t(validValidationPrediction);
%             testing = obj.testingPrediction(validTestingPrediction) - t(validTestingPrediction);
%             cError.training = sqrt(sum(training.^2) / numel(training));
%             cError.validation = sqrt(sum(validation.^2) / numel(validation));
%             cError.testing = sqrt(sum(testing.^2) / numel(testing));
        end
        
        function cError = computeClassificationError(obj)
            validTrainingPrediction = ~isundefined(obj.trainingPrediction);
            validValidationPrediction = ~isundefined(obj.validationPrediction);
            validTestingPrediction = ~isundefined(obj.testingPrediction);
            dims = size(obj.trainingPrediction);
            t = repmat(obj.target,[1 dims(2:end)]);
            training = obj.trainingPrediction(validTrainingPrediction) == t(validTrainingPrediction);
            validation = obj.validationPrediction(validValidationPrediction) == t(validValidationPrediction);
            testing = obj.testingPrediction(validTestingPrediction) == t(validTestingPrediction);
            
            trainingCorrect = sum(obj.trainingPrediction == t,1);
            trainingTotalValid = sum(validTrainingPrediction,1);
            trainingCorrectRatio = trainingCorrect ./ trainingTotalValid;

            validationCorrect = sum(obj.validationPrediction == t,1);
            validationTotalValid = sum(validValidationPrediction,1);
            validationCorrectRatio = validationCorrect ./ validationTotalValid;

            testingCorrect = sum(obj.testingPrediction == t(:,1,1,:,:),1);
            testingTotalValid = sum(validTestingPrediction,1);
            testingCorrectRatio = testingCorrect ./ testingTotalValid;

            cError.training = sum(~training) / numel(training);
            cError.validation = sum(~validation) / numel(validation);
            cError.testing = sum(~testing) / numel(testing);
            
            sizes = size(validTrainingPrediction);
            nTraining = prod(sizes(2:end));
            nValidation = prod(sizes(2:end));
            nTesting = prod(sizes(4:end));
            
            cError.trainingStd = nanstd(trainingCorrectRatio(:)) / sqrt(nTraining);
            cError.validationStd = nanstd(validationCorrectRatio(:)) / sqrt(nValidation);
            cError.testingStd = nanstd(testingCorrectRatio(:)) / sqrt(nTesting);
            
            obj.errors = cError;
            
            valPred = removecats(obj.validationPrediction(validValidationPrediction));
            valTarget = removecats(t(validValidationPrediction));
            cats = categories(valTarget);
            for cidx = 1:numel(cats)
                pidx = valTarget==cats{cidx};
                nidx = valTarget~=cats{cidx};
                p = sum(pidx);
                n = sum(nidx);
                tp = sum(valPred(pidx)==cats{cidx});
                tn = sum(valPred(nidx)~=cats{cidx});
                sensitivity(cidx) = tp / p;
                specifity(cidx) = tn / n;
                accuracy(cidx) = (tp+tn) / (p+n);
            end
            
            if ~isempty(cats)
                t = array2table([sensitivity; specifity; accuracy]','RowNames',cats,'VariableNames',{'sensitivity','specifity','accuracy'});
                disp(t);
            end
        end
    end
    
    methods(Static)
        function newObj = mergeVertical(datas)
            %datas = cell2mat(varargin);
            newObj = Data(vertcat(datas.data),vertcat(datas.offsets));
            newObj.offsets = vertcat(datas.offsets);
            newObj.abscissa = datas(1).abscissa;
            newObj.groupings = vertcat(datas.groupings);
            newObj.groupingCaptions = datas(1).groupingCaptions;
            newObj.target = vertcat(datas.target);
            newObj.trainingSelection = vertcat(datas.trainingSelection);
            newObj.validationSelection = vertcat(datas.validationSelection);
            newObj.testingSelection = vertcat(datas.testingSelection);
            newObj.featureCaptions = datas(1).featureCaptions;
%             newObj.selectedCycles = vertcat(datas.selectedCycles);
%             newObj.selectedFeatures = datas(1).selectedFeatures;
            newObj.cycleSelection = vertcat(datas.cycleSelection);
            newObj.featureSelection = datas(1).featureSelection;
            newObj.trainingPrediction = vertcat(datas.trainingPrediction);
            newObj.validationPrediction = vertcat(datas.validationPrediction);
            newObj.testingPrediction = vertcat(datas.testingPrediction);

%             newObj.targetType = datas(1).targetType;
            newObj.mode = datas(1).mode;

            newObj.setCaption('vertical merge');
        end
        
        function newObj = mergeHorizontal(datas,clusterMat,timeMat,tol)
            if nargin < 2
                tol = 0;
            end
            
            cycleOffsets = [];
            
            newData = [];
            for i = 1:size(clusterMat,1)
                clusterRow = clusterMat(i,:);
                [~,longestCycleIndex] = max(clusterRow.getCycleDuration());
                longestCycle = clusterRow(longestCycleIndex);
                longestCycleTimes = longestCycle.getCycleOffsets();
%                 longestCycleTimes = longestCycle.featureData.offsets;
                longestCycleTimes = ...
                    [longestCycleTimes [longestCycleTimes(2:end);...
                    longestCycleTimes(end)+longestCycle.getCycleDuration()]];

                actualCycles = longestCycle.timeToCycleNumber(longestCycle.featureData.offsets);
                longestCycleTimes = longestCycleTimes(actualCycles,:);
                
                consideredTimeRange = timeMat(i,:);
                outOfRange = (longestCycleTimes(:,1)<=consideredTimeRange(1)) |...
                    (longestCycleTimes(:,2)>=consideredTimeRange(2));
                longestCycleTimes(outOfRange,:) = [];
                cycleOffsets = [cycleOffsets;longestCycleTimes(:,1)];
                
                for j = 1:numel(clusterRow)
                    % add tolerance to account for imperfect cycle
                    % alignment
                    lct = longestCycleTimes + clusterRow(j).getCycleDuration()*[-1 1]*tol;
                    % no tolerance at the edges since this could lead to
                    % values outside the valid range and, thus, NaNs
                    lct(1,1) = longestCycleTimes(1,1); lct(end,end) = longestCycleTimes(end,end);
                    cycleNumbers = clusterRow(j).timeRangeToCycleNumber(lct);
                    newData = [newData,averageCyclesByIndex(clusterRow(j),cycleNumbers)];
                end
            end
            
            newObj = Data(horzcat(newData),longestCycle.featureData.offsets);
            newObj.abscissa = horzcat(datas.abscissa);
            newObj.groupings = dataLongestCycle.groupings;
            newObj.groupingCaptions = dataLongestCycle.groupingCaptions;
            newObj.target = dataLongestCycle.target;
            newObj.trainingSelection = dataLongestCycle.trainingSelection;
            newObj.validationSelection = dataLongestCycle.validationSelection;
            newObj.testingSelection = dataLongestCycle.testingSelection;
            newObj.featureCaptions = horzcat(datas.featureCaptions);
%             newObj.selectedCycles = dataLongestCycle.selectedCycles;
%             newObj.selectedFeatures = horzcat(datas.selectedFeatures);
            newObj.cycleSelection = dataLongestCycle.cycleSelection;
            newObj.featureSelection = horzcat(datas.featureSelection);
            newObj.trainingPrediction = dataLongestCycle.trainingPrediction;
            newObj.validationPrediction = dataLongestCycle.validationPrediction;
            newObj.testingPrediction = dataLongestCycle.testingPrediction;

%             newObj.targetType = dataLongestCycle.targetType;
            newObj.mode = dataLongestCycle.mode;

            newObj.setCaption('horizontal merge');            
        end
        
        function newObj = mergeAll(datas,clusterMat,timeMat,tol)
            if nargin < 2
                tol = 0.05;
            end
            
            d = Data.empty;
            
            for i = 1:size(clusterMat,1)
                newData = [];
                clusterRow = clusterMat(i,:);
                [longestCycleDuration,longestCycleIndex] = max(clusterRow.getCycleDuration());
                if isnan(longestCycleDuration)
                    continue;
                end
                longestCycle = clusterRow(longestCycleIndex);
                longestCycleTimes = longestCycle.getCycleOffsets();
%                 longestCycleTimes = longestCycle.featureData.offsets;
                longestCycleTimes = ...
                    [longestCycleTimes [longestCycleTimes(2:end);...
                    longestCycleTimes(end)+longestCycle.getCycleDuration()]];

                actualCycles = longestCycle.timeToCycleNumber(longestCycle.featureData.offsets);
                longestCycleTimes = longestCycleTimes(actualCycles,:);
                
                consideredTimeRange = timeMat(i,:);
                outOfRange = (longestCycleTimes(:,1)<consideredTimeRange(1)) |...
                    (longestCycleTimes(:,2)>consideredTimeRange(2));
                if all(outOfRange)
                    continue;
                end
                longestCycleTimes(outOfRange,:) = [];
                
                for j = 1:numel(clusterRow)
                    % add tolerance to account for imperfect cycle
                    % alignment
                    lct = longestCycleTimes + clusterRow(j).getCycleDuration()*[-1 1]*tol;
                    %if clusterRow(j).getCycleDuration() < 
                    % no tolerance at the edges since this could lead to
                    % values outside the valid range and, thus, NaNs
%                     lct(1,1) = longestCycleTimes(1,1); lct(end,end) = longestCycleTimes(end,end);
                    cycleNumbers = clusterRow(j).timeRangeToCycleNumber(lct);
                    [nData,newGroupings] = averageCyclesByIndex(clusterRow(j),cycleNumbers);
                    newData = [newData,nData];
                end

                d(i) = Data(newData,longestCycleTimes(:,1));
                d(i).groupings = newGroupings;
                d(i).groupingCaptions = clusterRow(1).featureData.groupingCaptions;
            end
            
            featureCaptions = string.empty;
            for i = 1:size(clusterMat,2)
                fCap = clusterMat(1,i).featureData.featureCaptions;
                featureCaptions = [featureCaptions,clusterMat(1,i).track + string('/') + fCap];
            end
            
            newObj = Data.mergeVertical(d);
            
            newObj.abscissa = 1:numel(featureCaptions);
            newObj.featureCaptions = featureCaptions;
%             newObj.selectedFeatures = featureCaptions;
            newObj.featureSelection = true(1,numel(featureCaptions));
            
            newObj.setCaption('merged');            
        end        
    end
end

function [newData,newGroupings] = averageCyclesByIndex(cluster,indices)
    % Given a cluster and a vector of indices, this function takes the
    % averages of cycle sets defined by the indices and replaces the cycle
    % set with this one average cycle. Indices is a two-column vector
    % (begin, end) and each row defines one cycle set, i.e. the output data
    % has as many rows as the indices vector. This is useful when cycles
    % with different cycle lengths shall be combined: all the quick cycles
    % that are covered by the slow cycle are averaged to one.
    %
    % TODO: implement more and more sophisticated methods, e.g. consider
    % the amount of the quick cycle covered by the slow cycle and use this
    % ratio as weight for the average.

    data = cluster.featureData.data;
    groupings = cluster.featureData.groupings;
    offsets = cluster.featureData.offsets;
    cycleNumbers = cluster.timeToCycleNumber(offsets);

    indices(any(isnan(indices),2),:) = [];
    
    % It can happen that a cycle from one cluster overlaps with a cycle
    % from another cluster that has not been computed (happens at edges of
    % cycle ranges). In that case, we must shrink the cycle range over
    % which we average until it covers only cycles that have been computed.
    while true
        tooSmall = ~ismember(indices(:,1),cycleNumbers);
        tooBig = ~ismember(indices(:,2),cycleNumbers);
        if any(tooSmall) || any(tooBig)
            indices(tooSmall,1) = indices(tooSmall,1) + 1;
            indices(tooBig,2) = indices(tooBig,2) - 1;
        else
            break;
        end
    end

    indTrans(cycleNumbers) = 1:numel(cycleNumbers);
    
    diffs = diff(indices,[],2);
    if all(diffs==0)
        rows = ismember(cycleNumbers,indices(:,1));
        newData = data(rows,:);
        newGroupings = groupings(cycleNumbers,:);
        newGroupings = newGroupings(rows,:);
        return
    end
    
    warning('Cycles do not have equal lengths and are combined by averaging shorter cycles.');
    
    indices(diffs<0,2) = indices(diffs<0,1);
    diffs(diffs<0) = 0;
    
%     if any(diffs<0)
%         error('Internal error. Cycle indices seem to be messed up.');
%     end
    
    numGroupings = zeros(size(groupings));
    newNumGroupings = zeros(size(groupings));
    for i = 1:size(groupings,2)
        numGroupings(:,i) = double(removecats(groupings(:,i)));
    end
    
    newData = zeros(size(data));
    for i = 1:size(indices,1)
        if diffs(i) > 0
            newData(indTrans(indices(i,1)),:) = sum(data(indTrans(indices(i,1)):indTrans(indices(i,2)),:),1)/diffs(i);
            for  j = 1:size(groupings,2)
                [~,newNumGroupings(indTrans(indices(i,1)),:)] = max(histcounts(numGroupings(indTrans(indices(i,1)):indTrans(indices(i,2)),:),(0:max(numGroupings(:,j)))+0.5));
            end
        end
    end
    newData = newData(indTrans(indices(:,1)),:);
    
    newGroupings = categorical();
    for i = 1:size(groupings,2)
        cats = categories(removecats(groupings(:,i)));
        idxs = newNumGroupings(:,i);
        newGroupings(:,i) = categorical(idxs,1:numel(cats),cats);
    end
    newGroupings = newGroupings(indTrans(indices(:,1)),:);
end