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

classdef ControllerInterface < matlab.mixin.Copyable
    %CONTROLLERINTERFACE Each signal chain starts with a Controller.
    %   The controllert controlls the programm flow during data
    %   processing. This includes process controll for training the single
    %   feature preselectors, extraction of features and application of the
    %   trained pipeline to new data.
    
    properties
        pipelines = {};
        cv = [];
        targetMat = [];
        extractionTrained = false;
        selectionTrained = false;
        selectorMat = {};
        classifierMat = {};
        errorMat = [];
        confMats = {};
        classifier = 'LDA'; %either LDA or 1NN
    end
    
    methods
        trainFeatureExtraction(this);
        %Trains a signal chain. Training happens in two steps. The first
        %step trains all signal chain elements that need to be trained. The
        %second step computes the most important features. The signal
        %chains that are the ones added to the list of pipelines of this
        %object using addPipeline. The programm flow depends on the type of
        %controller.
        %
        %Inputs:
        %this: Controller that performs the training.
        
        function errorMat = trainFeatureSelection(this)
        %Trains feature selection on the features that were extracted using
        %the signal chain in this.pipelines.
        %
        %Inputs:
        %this: Controller that performs the training.
            f = Factory.getFactory();
       
            if ~this.extractionTrained
                this.trainFeatureExtraction;
            end
            extractors = this.getExtractors();
            
            %pretrain RFESVM in parallel
%             selMat = cell(size(this.targetMat, 2), this.cv.NumTestSets + 1, length(extractors), 1);
%             t = repmat((1:size(this.targetMat,2))', 1, this.cv.NumTestSets + 1, length(extractors));
%             c = repmat(1:(this.cv.NumTestSets+1), size(this.targetMat, 2), 1, length(extractors));
%             e = reshape(1:length(extractors), 1,1,length(extractors));
%             e = repmat(e, size(this.targetMat, 2), this.cv.NumTestSets + 1, 1);
%             trainL = cell(numel(t), 1);
%             for i = 1:numel(t)
%                 if c(i) <= this.cv.NumTestSets
%                     trainL{i} = this.targetMat(this.cv.training(c(i)), t(i));
%                 else
%                     trainL{i} = this.targetMat(:, t(i));
%                 end
%             end
%             ind = randperm(numel(t));
%             for i = 1:numel(t)
%                 selMat{i} = f.getRFESVMSelector(this.classifier); %#ok<PFBNS>
%                 selMat{i}.train(extractors{e(ind(i))}.getTrainData(t(ind(i)), c(ind(i)), false), trainL{ind(i)} ); %#ok<PFBNS>
%             end
%             selMat(ind) = selMat;
            
            %train feature selection
            this.selectorMat = cell(size(this.targetMat, 2), this.cv.NumTestSets + 1, length(extractors), 3);
%             this.selectorMat(:,:,:,1) = selMat;
            this.classifierMat = cell(size(this.selectorMat));
            predErr = zeros(size(this.selectorMat));
            for t = 1:size(this.targetMat, 2)
                for c = 1:this.cv.NumTestSets+1
                    for e = 1:length(extractors)
                        if c <= this.cv.NumTestSets
                            trainLables = this.targetMat(this.cv.training(c), t);
                            testLables = this.targetMat(this.cv.test(c), t);
                        else
                            trainLables = this.targetMat(:, t);
                            testLables = this.targetMat(:, t);
                        end
                        
                        if strcmp(this.classifier, 'LDA')
                            this.classifierMat{t,c,e,1} = f.getLDAMahalClassifier();
                            this.classifierMat{t,c,e,2} = f.getLDAMahalClassifier();
                            this.classifierMat{t,c,e,3} = f.getLDAMahalClassifier();
                        elseif strcmp(this.classifier, '1NN')
                            this.classifierMat{t,c,e,1} = f.getOneNNClassifier();
                            this.classifierMat{t,c,e,2} = f.getOneNNClassifier();
                            this.classifierMat{t,c,e,3} = f.getOneNNClassifier();
                        else
                            error(['Unsupported classifier: ', this.classifier]);
                        end
                        
                        this.selectorMat{t,c,e,1} = f.getRFESVMSelector(this.classifier);
                        this.selectorMat{t,c,e,1}.train(extractors{e}.getTrainData(t, c, false), trainLables);
                        trainRFESVM = this.selectorMat{t,c,e,1}.apply(extractors{e}.getTrainData(t,c,false));
                        this.classifierMat{t,c,e,1}.train(trainRFESVM, trainLables);
                        testRFESVM = this.selectorMat{t,c,e,1}.apply(extractors{e}.getTestData(t,c));
                        predRFESVM = this.classifierMat{t,c,e,1}.apply(testRFESVM);
                        predErr(t,c,e,1) = sum(testLables ~= predRFESVM);
%                        predErr(t,c,e,1) = length(testLables);
                        
                        this.selectorMat{t,c,e,2} = f.getRELIEFFSelector(this.classifier);
                        this.selectorMat{t,c,e,2}.train(extractors{e}.getTrainData(t, c, false), trainLables);
                        trainRELIEFF = this.selectorMat{t,c,e,2}.apply(extractors{e}.getTrainData(t,c, false));
                        this.classifierMat{t,c,e,2}.train(trainRELIEFF, trainLables);
                        testRELIEFF = this.selectorMat{t,c,e,2}.apply(extractors{e}.getTestData(t,c));
                        predRELIEFF = this.classifierMat{t,c,e,2}.apply(testRELIEFF);
                        predErr(t,c,e,2) = sum(testLables ~= predRELIEFF);
                        
                        this.selectorMat{t,c,e,3} = f.getPearsonSelector(this.classifier);
                        this.selectorMat{t,c,e,3}.train(extractors{e}.getTrainData(t, c,false), trainLables);
                        trainPearson = this.selectorMat{t,c,e,3}.apply(extractors{e}.getTrainData(t,c,false));
                        this.classifierMat{t,c,e,3}.train(trainPearson, trainLables);
                        testPearson = this.selectorMat{t,c,e,3}.apply(extractors{e}.getTestData(t,c));
                        predPearson = this.classifierMat{t,c,e,3}.apply(testPearson);
                        predErr(t,c,e,3) = sum(testLables ~= predPearson);
                    end
                end
            end
            
            cvErr = sum(predErr(:,1:this.cv.NumTestSets,:,:), 2);
            %ToDo: not all cycles used????
            cvErr = cvErr./size(this.targetMat, 1);
            %t e 3
            %find minimal e for every t
            [minErrE, minIndE] = min(cvErr, [], 3);
            %minErrE = squeeze(minErrE);
            %minIndE = squeeze(minIndE);
            [minErrMeth, minIndMeth] = min(minErrE, [], 4);
            
            for i = 1:length(minErrMeth)
                disp(['The minimum error achieved for target ', num2str(i), ' is ', num2str(minErrMeth(i)*100), '%.']);
                meth = '';
                switch(minIndMeth(i))
                    case 1
                        meth = 'RFESVM';
                    case 2
                        meth = 'RELIEFFF';
                    case 3
                        meth = 'Pearson';
                end
                disp(['It was achieved using a combination of ', extractors{minIndE(minIndMeth(i))}.name, ' and ', meth]);
            end
            
            errorMat = cvErr;
            this.errorMat = cvErr;
            this.selectionTrained = true;
        end
        
        apply(this);
        %Applys new data to the signal chain. This function is currently a
        %stub and not implemented by any controllers. It will be used in
        %future extensions of the program.
        %
        %Inputs:
        %this: Controller whoes signal chain is applied
        
        function addPipeline(this, pl)
        %Adds the signal chain (pipeline) whoes training and feature
        %extraction is to be controlled to the controller. All function
        %calls will be applied to the cell of signal chain element pl. It
        %is technically possible to add multiple pipelines but controllers
        %will only work on the first one.
        %
        %Inputs:
        %this:  Controller that is meant to controll the signal chain
        %pl:    Cell containing an object that implements
        %       SignalChainElementInterface and is the first one in the
        %       signal chain that is to be controlled by this.
            this.pipelines = [this.pipelines, {pl}];
            this.pipelines{end}.setId([this.idSuffix, num2str(length(this.pipelines))]);
        end
        
        function removePipeline(this, pl)
        %Removes the signal chain element specified by pl from the list of
        %pipelines of this object.
        %
        %Iputs:
        %this:  Controller from whoes pipeline pl is removed.
        %pl:    Object that has previously added to this and is now to be
        %       removed from pipelines.
            ind = false(length(this.pipelines), 1);
            ind(this.pipelines == pl) = true;
            this.pipelines(ind) = [];
        end
        
%         function new = copy(this)
%         %Creates deep copy of this. For more details see
%         %CopyableHandleInterface.m
%         %
%         %Inputs:
%         %this: ControllerInterface that is deep copied.
%         %
%         %Outputs:
%         %new:  Deep copy of this.
%             new = feval(class(this));
%             
%             warning('off', 'MATLAB:structOnObject');
%             p = fieldnames(struct(this));
%             for i = 1:length(p)
%                 try
%                     if isa(this.(p{i}), 'CopyableHandleInterface')
%                         new.(p{i}) = this.(p{i}).copy();
%                     else
%                         new.(p{i}) = this.(p{i});
%                     end
%                 catch ME
%                     if ~strcmp(ME.identifier, 'MATLAB:class:SetProhibited')
%                         throw(ME);
%                     end
%                 end
%             end
%         end
        
        function extractors = getExtractors(this)
        %Returns an array of FeatureExtractors that each represent one
        %faeture extraction and the correspondingly extracted results.
        %
        %Inputs:
        %this: ControllerInterface that controls the SignalElementChain
        %      from which the extractors should be returned.
        %
        %Outputs:
        %extractors: Array of FeatureExtractors
            
            %1. get Results from pipeline
            metaInfo = containers.Map;
            metaInfo('Training') = false;
            results = this.pipelines{1}.getResults(metaInfo);
            
            %2. get unique evaluation paths
            ids = cell(size(results));
            idsNumberFree = cell(size(ids));
            for i = 1:numel(ids)
                ids{i} = results{i}.getId();
                noNumber = false(size(ids{i}));
                for j = 1:length(noNumber)
                    if ~isempty(strfind('0123456789.,-', ids{i}(j)))
                        noNumber(j) = false;
                    else
                        noNumber(j) = true;
                    end
                end
                idsNumberFree{i} = ids{i}(noNumber);
            end
            uniquePaths = unique(idsNumberFree);
            numPaths = length(uniquePaths);
            
            %3.Create FeatMatWrappers for each path
            f = FeatureExtraction.extractHelpers.Factory.getFactory();
            wrapper = cell(1, numPaths);
            for i = 1:numPaths
                ind = strcmp(idsNumberFree, uniquePaths{i});
                wrapper{i} = f.getFeatMatWrapper(results(ind));
            end
            
            %Create Feature Extractors
            extractors = cell(1, numPaths);
            for i = 1:numPaths
                extractors{i} = f.getFeatureMatExtractor(wrapper{i}, uniquePaths{i}, this.cv, this.targetMat);
            end
        end
        
        function confMats = getConfusionMat(this)
            if ~this.extractionTrained
                error('Cannot compute confusion Matrices: Feature Extraction not trained');
            end
            if ~this.selectionTrained
                error('Cannot compute confusion Matrices: Feature Selection not trained');
            end
            
            ext = this.getExtractors();
            confMats = cell(size(this.targetMat,2), 1, length(ext), 3);
            for t = 1:size(this.targetMat,2)
                target = this.targetMat(:,t);
                order = unique(target);
                for c = 1:this.cv.NumTestSets
                    ind = this.cv.test(c);
                    for e = 1:length(ext)
                        testData = ext{e}.getTestData(t, c);
                        testTarget = target(ind);
                        for s = 1:3
                            if isempty(confMats{t,1,e,s})
                                confMats{t,1,e,s} = zeros(length(order));
                            end
                            testPredict = this.classifierMat{t,c,e,s}.apply(this.selectorMat{t,c,e,s}.apply(testData));
                            
                            confMats{t,1,e,s} = confMats{t,1,e,s} + confusionmat(testTarget, testPredict, 'order', order);
                        end
                    end
                end
            end
%             
%             sel = this.selectorMat(:,this.cv.NumTestSets+1, :, :);
%             class = this.classifierMat(:, this.cv.NumTestSets+1, :, :);
%             extractors = this.getExtractors();
%             this.confMats = cell(size(sel));
%             for i = 1:numel(this.confMats)
%                 [t, a, e, b] = ind2sub(size(sel), i);
%                 feat = extractors{e}.getTrainData(t, this.cv.NumTestSets+1, false);
%                 pred = class{i}.apply(sel{i}.apply(feat));
%                 this.confMats{i} = confusionmat(this.targetMat(:,t), pred);
%             end
%             confMats = this.confMats;
        end
        
        function rec = getReconsturctors(this, sensors, target)
            allObj = this.pipelines{1}.getAllElements(false);
            ids = cellfun(@getId, allObj, 'UniformOutput', false);
            %[~, cvNum, ~] = cellfun(@this.splitId, ids, 'UniformOutput', false);
            %allObjCV(~isempty(cvNum)) = [];
            %idsCV = cellfun(@getId, allObjCV, 'UniformOutput', false);
            
            rec = cell(length(sensors), 4);
            
            numPCs = floor(500/length(sensors)) * ones(1, length(sensors));
            numPCs(1:rem(500, length(sensors))) = numPCs(1:rem(500, length(sensors))) + 1;
            
            for i = 1:length(sensors)
                %assuming same order of sensors as in construction of full
                %tree
                if isa(this.pipelines{1},'Sensor')
                    sens = this.pipelines{1};
                else
                    sens = this.pipelines{1}.next{i};
                end
                sensId = sens.getId();
                sensObjInd = cellfun(@(a)strcmp(a(max([1,end-length(sensId)+1]):end), sensId) ,ids);
                sensObj = allObj(sensObjInd);
                sensObjIds = ids(sensObjInd);
                [~, cvNum, ~] = cellfun(@this.splitId, sensObjIds, 'UniformOutput', false);
                sensObjCV = sensObj(cellfun(@isempty, cvNum));
                %sensObjCVIds = sensObjIds(isempty(cvNum));
                
                %ALA
                dsInd = cellfun(@(a)isa(a, 'ALADownsampler'), sensObj);
                ds = sensObj{dsInd};
                dsFactor = ds.dsFactor;
                alaInd = cellfun(@(a)isa(a, 'ALASplit'), sensObjCV);
                ala = sensObjCV{alaInd};
                alaStart = ala.start;
                alaStop = ala.stop;
                if nargin == 2
                    rec{i,1} = FeatureExtraction.extractHelpers.ALAReconstructor(alaStart, alaStop, dsFactor, sensors{i}.copy());
                elseif nargin > 2
                    rec{i,1} = FeatureExtraction.extractHelpers.ALAReconstructor(alaStart, alaStop, dsFactor, sensors{i}.copy(), target);
                end
                
                %PCA
                pcaInd = cellfun(@(a)isa(a, 'PCA'), sensObjCV);
                pca = sensObjCV{pcaInd};
                if numPCs(i) > size(pca.coeff,2)
                    numPCs(i) = size(pca.coeff,2);
                end
                coeff = pca.coeff(:, 1:numPCs(i));
                pcaMean = pca.m;
                if nargin == 2
                    rec{i,2} = FeatureExtraction.extractHelpers.PCAReconstructor(coeff, pcaMean, dsFactor, sensors{i}.copy());
                elseif nargin > 2
                    rec{i,2} = FeatureExtraction.extractHelpers.PCAReconstructor(coeff, pcaMean, dsFactor, sensors{i}.copy(), target);
                end
                
                %BDW
                stackSelInd = cellfun(@(a)isa(a, 'StackedSelector'), sensObjCV);
                stackSel = sensObjCV(stackSelInd);
                stackSelBDWInd = cellfun(@(a)~isempty(strfind(a.getId(),'DWT')),stackSel);
                stackSelBDW = stackSel{stackSelBDWInd};
                [~, bdwSel, ~] = stackSelBDW.getRanking();
                if nargin == 2
                    rec{i,3} = FeatureExtraction.extractHelpers.BDWReconstructor(bdwSel, sensors{i}.copy());
                elseif nargin > 2
                    rec{i,3} = FeatureExtraction.extractHelpers.BDWReconstructor(bdwSel, sensors{i}.copy(), target);
                end 
                
                %BFC
                stackSelBFCInd = cellfun(@(a)~isempty(strfind(a.getId(),'FFT')),stackSel);
                stackSelBFCInd = stackSelBFCInd & cellfun(@(a)~isempty(strfind(a.getId(),'Abs')),stackSel);
                stackSelBFC = stackSel{stackSelBFCInd};
                [~, bfcSel, ~] = stackSelBFC.getRanking();
                if nargin == 2
                    rec{i,4} = FeatureExtraction.extractHelpers.BFCReconstructor(bfcSel, sensors{i}.copy());
                elseif nargin > 2
                    rec{i,4} = FeatureExtraction.extractHelpers.BFCReconstructor(bfcSel, sensors{i}.copy(), target);
                end
            end
        end
        
        function fourTimesPlot(this, sensors, target)
            if nargin == 2
                rec = this.getReconsturctors(sensors);
            elseif nargin > 2
                rec = this.getReconsturctors(sensors, target);
            end
            plots = cellfun(@FourTimesPlot, rec, 'UniformOutput', false);
            try
                numCyc = this.pipelines{1}.getNumberOfCycles(false);
            catch
                numCyc = this.pipelines{1}.next{1}.getNumberOfCycles(false);
            end
            arrayfun(@(a)cellfun(@(b)b.update(a), plots), 1:numCyc);
            cellfun(@show, plots);
        end
    end
    
    methods (Access=protected)
        function confMat = confusionMatrix(feat, sel, class, target)
            pred = class.apply(sel.apply(feat));
            confMat = confsionmat(target, pred);
        end
        
        function [prefix, cvNum, rest] = splitId(~, id)
            k = strfind(id, 'CV');
            if ~isempty(k) && k(1) == 1
                %if id is from a CVSelFeatMat
                k(1) = [];
            end
            if isempty(k)
                %if not cross-validated
                prefix = id;
                cvNum = [];
                rest = '';
                return;
            end
            rest = id(k(1):end);
            numStr = '';
            for i = k(1)-1:-1:1
                if ~any(strcmp(id(i), {'0','1','2','3','4','5','6','7','8','9'}))
                    break;
                else
                    numStr = [id(i), numStr]; %#ok<AGROW>
                end
            end
            cvNum = str2double(numStr);
            if isnan(cvNum)
                cvNum = [];
            end
            prefix = id(1:i);
        end
    end
end

