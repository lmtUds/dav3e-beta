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

classdef Model < Descriptions
    properties
        processingChain
        innerValidation
        outerValidation
        
        hyperParameterCaptions
        hyperParameterIndices
        hyperParameterValues
        
        trainingErrors
        validationErrors
        testingErrors
        trainingErrorStds
        validationErrorStds
        testingErrorStds
        
        trainingCorrs
        validationCorrs
        testingCorrs
        trainingCorrStds
        validationCorrStds
        testingCorrStds
        
        trainedIndexSet
        fullModelData
        datas
        
        trained = false;
    end
    
    properties(Hidden)
        empty = false
    end
    
    methods
        function obj = Model(chain)
            if nargin == 0
                obj.empty = true;
                chain = DataProcessingBlockChain();
            end
            obj.processingChain = chain;
            obj.setCaption('model');
        end
        
        function reset(obj)
            obj.processingChain.resetChain()
            obj.trained = false;
            obj.fullModelData = [];
            obj.datas = [];
            obj.hyperParameterCaptions = [];
            obj.hyperParameterIndices = [];
            obj.hyperParameterValues = [];
            
            obj.trainingErrors = [];
            obj.validationErrors = [];
            obj.testingErrors = [];
            obj.trainingErrorStds = [];
            obj.validationErrorStds = [];
            obj.testingErrorStds = [];
            
            obj.trainingCorrs = [];
            obj.validationCorrs = [];
            obj.testingCorrs = [];
            obj.trainingCorrStds = [];
            obj.validationCorrStds = [];
            obj.testingCorrStds = [];
            
            obj.trainedIndexSet = [];
        end

        function pgf = makePropGridFields(obj)
            pgf = obj.processingChain.makePropGridFields();
        end
        
        function addToChain(obj,block)
            obj.processingChain.addToEnd(block);
            block.bubbleUp();
        end
        
        function removeFromChain(obj,block)
            obj.processingChain.removeFromChain(block);
        end
        
        function is = makeFullParametersIndexSet(obj,cap,ind)
            is = ones(numel(obj.hyperParameterCaptions),1);
            for i = 1:numel(cap)
                is(ismember(obj.hyperParameterCaptions,cap{i})) = ind(i);
            end
        end
        
        function is = makeVariedParametersIndexSet(obj,cap,ind)
            variedCaps = obj.getVariedHyperParameters();
            is = [];
            for i = 1:numel(cap)
                if ismember(cap{i},variedCaps)
                    is(end+1) = ind(i);
                end
            end
        end        
        
        function [cap,ind,val] = getVariedHyperParameters(obj)
            cap = {}; ind = {}; val = {};
            for i = 1:numel(obj.hyperParameterCaptions)
                if size(obj.hyperParameterValues,2)>1 && ~isempty(obj.hyperParameterValues{i,2})
                    cap{end+1} = obj.hyperParameterCaptions{i};
                    ind{end+1} = obj.hyperParameterIndices(i,:);
                    val{end+1} = obj.hyperParameterValues(i,:);
                    val{end} = val{end}(~cellfun(@isempty,val{end}));
                end
            end
        end
        
        function [data,caps,inds] = getLowestErrorData(obj)
            [~,ind,val] = obj.getVariedHyperParameters();
            if ~isempty(val)
                val = cell2mat(val{1});
                ind = ind{1};
                d = Data();
                errors.validation = obj.validationErrors;
                errors.validationStd = obj.validationErrorStds;
                minOneStdCrit = d.getBestParametersFromErrors('minOneStd',errors,val(ind));
                elbowCrit = d.getBestParametersFromErrors('elbow',errors,val(ind));
                paramVal = min([minOneStdCrit,elbowCrit]);
                idx = val(ind) == paramVal;
            else
                idx = 1;
            end

            data = obj.datas(idx);
            inds = obj.hyperParameterIndices(:,idx);
            caps = obj.hyperParameterCaptions;
        end
        
        function trainForParameterIndexSet(obj,data,caps,indices)
            hParamsUser = obj.processingChain.getChainHyperParameters();
            hParams = struct();
            indexSet = [];
            for i = 1:numel(obj.hyperParameterCaptions)
                s = strsplit(obj.hyperParameterCaptions{i},'.');
                if ismember(obj.hyperParameterCaptions{i},caps)
                    ind = indices(ismember(caps,obj.hyperParameterCaptions{i}));
                else
                    ind = 1;
                end
                hParams.(s{1}).(s{2}) = obj.hyperParameterValues{i,ind};
                indexSet(end+1) = ind;
            end
            
            obj.processingChain.resetChain();
            traindata = data.copy();
            obj.processingChain.init(traindata,hParams);
            traindata.setValidation('none');
            
            % we use two separate datasets in case the training
            % data becomes inconsistent (e.g. because the features
            % are overwritten by LDA)
            testdata = traindata.copy();
            
            % only keep the testing selection if it is single step
            % and iteration
            % otherwise ignore it and add the data to the training data
            if traindata.testingSteps > 1 || traindata.testingIterations > 1
                traindata.setTesting('none');
                testdata.setTesting('none');
            end
            
            traindata.mode = 'training';
            obj.processingChain.trainChain(traindata,hParams);

            testdata.mode = 'testing';
            obj.processingChain.applyChain(testdata,hParams);
            
            traindata.addPredictionsFrom(testdata);
            traindata.setSelectedTarget(testdata.getSelectedTarget(),'testing');
            
            obj.processingChain.setChainHyperParameters(hParamsUser);
            obj.trainedIndexSet = indexSet';
            
            b = obj.processingChain.getLastBlock();
            traindata.trainingPrediction = b.revertChain(traindata.trainingPrediction);
            traindata.testingPrediction = b.revertChain(traindata.testingPrediction);
            traindata.target = b.revertChain(traindata.target);
            obj.fullModelData = traindata;
            obj.trained = true;
        end
        
        function data = getValidatedDataForTrainedIndexSet(obj)
            idx = all(obj.hyperParameterIndices == obj.trainedIndexSet,1);
            data = obj.datas(idx);
        end
        
        function [idx,caps,inds] = getCurrentIndexSet(obj)
            idx = find(all(obj.hyperParameterIndices == obj.trainedIndexSet,1));
%             data = obj.datas(idx);
            inds = obj.hyperParameterIndices(:,idx);
            caps = obj.hyperParameterCaptions;
        end
        
        function errors = getErrorsForTrainedIndexSet(obj)
            idx = all(obj.hyperParameterIndices == obj.trainedIndexSet,1);
            errors.training = obj.trainingErrors(idx);
            errors.validation = obj.validationErrors(idx);
            errors.testing = obj.testingErrors(idx);
            errors.trainingStd = obj.trainingErrorStds(idx);
            errors.validationStd = obj.validationErrorStds(idx);
            errors.testingStd = obj.testingErrorStds(idx);
        end
        
        function cCorr = getCorrForTrainedIndexSet(obj)
            idx = all(obj.hyperParameterIndices == obj.trainedIndexSet,1);
            cCorr.training = obj.trainingCorrs(idx);
            cCorr.validation = obj.validationCorrs(idx);
            cCorr.testing = obj.testingCorrs(idx);
            cCorr.trainingStd = obj.trainingCorrStds(idx);
            cCorr.validationStd = obj.validationCorrStds(idx);
            cCorr.testingStd = obj.testingCorrStds(idx);
        end
        
        function checkChain(obj)
            types = cellstr([obj.processingChain.blocks.type]);
            if any(ismember({'Validation','Testing'},types))
                if ~any(ismember({'Classification','Regression'},types))
                    error('Validation and testing require a classifier or regressor.');
                end
            end
        end
        
        function train(obj,data,params)
            if nargin < 3 || isempty(params)
                params = struct();
            end
            
            obj.checkChain();
            data = data.copy();
            obj.processingChain.resetChain();
            
            hParams = obj.processingChain.getChainHyperParameters();
            chainHyperParameters = hParams;
            hParams = updateStruct(hParams,params);
            
            % collect all parameters from the struct in a single cell
            fields1 = fieldnames(hParams);
            p = struct2cell(hParams);
            fields2 = cellfun(@fieldnames,p,'uni',false);
%             fields1 = repelem(fields1,cellfun(@numel,fields2));
            p = cellfun(@struct2cell,p,'uni',false);
%             fields2 = vertcat(fields2{:});
            p = vertcat(p{:});
            
            % combvec (see later) can only deal with numbers, so we create
            % a value cell and make the values vector point to elements of
            % this cell
            classes = cellfun(@class,p,'uni',false);
            values = {};
            for i = 1:numel(p)
                switch classes{i}
                    case 'char'
                        values{i,1} = p{i};
                        p{i} = 1;
                    case 'cell'
%                         temp = categorical(p{i});
%                         values{i} = categories(temp);
%                         p{i} = double(temp);
                        values{i,1} = p{i};
                        p{i} = 1;
%                     case 'logical'
%                         values(i,1:2) = {false,true};
%                         p{i} = double(p{i}) + 1;
                    otherwise
                        uniqueVals = unique(p{i});
                        values(i,1:numel(uniqueVals)) = num2cell(uniqueVals);
                        [~,p{i}] = ismember(p{i},uniqueVals);
                end
                p{i} = reshape(p{i},1,numel(p{i}));
            end
            
            % sort to have high values first, so we can potentially save
            % some training runs when training for fewer variables comes
            % "for free" (like in LDA, PLSR, ...)
            p = cellfun(@(x)sort(x,'descend'),p,'uni',false);
            % create a list with all combinations of parameters
            hParamTable = combvec(p{:});

            % save function handles so as not to pass the whole obj to
            % parfor later
            chain = obj.processingChain;
            chaintrainfun = @chain.trainChain;
            chainapplyfun = @chain.applyChain;
            
            % just for convenience (input to testingIterationLoop)
            s = struct('hParamTable',hParamTable,...
                    'fields1',{fields1}, 'fields2',{fields2},...
                    'classes',{classes}, 'values',{values});

            % these copies do not take up space as long as they are not
            % altered (lazy copy on write), so we do not have to do this
            % within parfor
            obj.processingChain.init(data,hParams);
            if ~data.testIntegrity()
                error('Datasets overlap!');
            end
            
            d = Data();
            for i = 1:size(hParamTable,2)
                d(i) = data.copy();
            end
            
            % Parameters hold a handle to their PropGridField, a Java
            % object which is not serializable by parfor
            % So, for now, we remove all handles here and put them back in
            % when the parfor is finished
            % TODO: better concept...
            parameters = Parameter.empty;
            pgfs = PropGridField('',0); pgfs = pgfs(false);
            changeCallbacks = {};
            for i = 1:numel(chain.blocks)
                params = chain.blocks(i).parameters;
                for j = 1:numel(params)
                    if ~isempty(params(j).propGridField)
                        parameters(end+1) = params(j);
                        pgfs(end+1) = params(j).propGridField;
                        changeCallbacks{end+1} = params(j).onChangedCallback;
                        params(j).propGridField = [];
                        params(j).onChangedCallback = [];
                    end
                end
            end            
            
            % the actual cross-validation
            tic
            try
                d = obj.testingIterationLoop(chaintrainfun,chainapplyfun,d,s);
            catch ME
                warning('Something went wrong.');
                disp(ME)
            end
            toc
            
            % put the PropGridField handles back (see above)
            for i = 1:numel(parameters)
                parameters(i).propGridField = pgfs(i);
                parameters(i).onChangedCallback = changeCallbacks{i};
            end
            
            % compute errors
            for i = 1:numel(d)
                obj.processingChain.finalize(d(i),hParams);
                x = d(i).computeErrors();
                errors(i) = x;
%                 fprintf('\n');
%                 disp(x)
                x = d(i).computePearsonCorrelation();
                corrCoeffs(i) = x;
%                 fprintf('\n');
%                 disp(x)
            end
            toc
            
            % get hParam captions in a form like, e.g., "DimensionalityReduction_lda.nDF"
            c = [];
            for i = 1:numel(fields1)
                f2 = fields2{i};
                for j = 1:numel(f2)
                    c = [c, string(fields1{i}) + string('.') + string(f2{j})];
                end
            end
            
            % set parameters back to what they were
            % while running, they are always updated to reflect the latest
            % config, however, eventually, we want them back to what the
            % user selected, especially when dealing with multiple values
            % for one parameters (eg. multiple numbers of DFs in LDA)
            obj.processingChain.setChainHyperParameters(chainHyperParameters);
            
            obj.datas = d;
            obj.hyperParameterCaptions = cellstr(c');
            obj.hyperParameterIndices = hParamTable;
            obj.hyperParameterValues = values;
            
            obj.trainingErrors = [errors.training];
            obj.validationErrors = [errors.validation];
            obj.testingErrors = [errors.testing];
            obj.trainingErrorStds = [errors.trainingStd];
            obj.validationErrorStds = [errors.validationStd];
            obj.testingErrorStds = [errors.testingStd];
            
            obj.trainingCorrs = [corrCoeffs.training];
            obj.validationCorrs = [corrCoeffs.validation];
            obj.testingCorrs = [corrCoeffs.testing];
            obj.trainingCorrStds = [corrCoeffs.trainingStd];
            obj.validationCorrStds = [corrCoeffs.validationStd];
            obj.testingCorrStds = [corrCoeffs.testingStd];

            if exist('ME','var')
                rethrow(ME);
            end
        end
        
        function data = testingIterationLoop(obj,trainFun,applyFun,data,s)
            testingStepLoop = @obj.testingStepLoop;
            n = data(1).testingIterations;
            if n > 1
                d(n,numel(data)) = Data();
                for i = 1:numel(data)
                    d(:,i) = data(i).copy(n);
                end
                for i = 1:n
                    [d(i,:).testingIteration] = deal(i);
                end
%                 ticBytes(gcp);
                for i = 1:n  % PARFOR
                    d(i,:) = testingStepLoop(trainFun,applyFun,d(i,:),s,i);
                end
%                 tocBytes(gcp);
                for i = 1:numel(data)
                    for j = 1:data(1).testingSteps
                        for k = 1:data(1).validationIterations
                            for l = 1:data(1).validationSteps
                                [d(:).testingStep] = deal(j);
                                [d(:).validationIteration] = deal(k);
                                [d(:).validationStep] = deal(l);
                                [d(:).mode] = deal('training');
                                data(i).addPredictionsFrom(d(:,i));
                                [d(:).mode] = deal('validation');
                                data(i).addPredictionsFrom(d(:,i));
                                [d(:).mode] = deal('testing');
                                data(i).addPredictionsFrom(d(:,i));
                            end
                        end
                    end
                end
            else
                data = testingStepLoop(trainFun,applyFun,data,s,1);
            end
        end
        
        function data = testingStepLoop(obj,trainFun,applyFun,data,s,testIter)
            validationIterationLoop = @obj.validationIterationLoop;
            n = data(1).testingSteps;
            if n > 1
                try
                    isparallel = ~isempty(getCurrentTask());
                catch
                    isparallel = false;
                end
                if ~isparallel
                    d(n,numel(data)) = Data();
                    for i = 1:numel(data)
                        data(i).testingIteration = testIter;
                        d(:,i) = data(i).copy(n);
                    end
                    for i = 1:n
                        [d(i,:).testingStep] = deal(i);
                    end
                    for i = 1:n  % PARFOR
                        d(i,:) = validationIterationLoop(trainFun,applyFun,d(i,:),s,testIter,i);
                    end
                    for i = 1:numel(data)
                        for k = 1:data(1).validationIterations
                            for l = 1:data(1).validationSteps
                                [d(:,i).validationIteration] = deal(k);
                                [d(:,i).validationStep] = deal(l);
                                [d(:,i).mode] = deal('training');
                                data(i).addPredictionsFrom(d(:,i));
                                [d(:,i).mode] = deal('validation');
                                data(i).addPredictionsFrom(d(:,i));
                                [d(:,i).mode] = deal('testing');
                                data(i).addPredictionsFrom(d(:,i));
                            end
                        end
                    end
                else
                    for i = 1:n
                        data = validationIterationLoop(trainFun,applyFun,data,s,testIter,i);
                    end
                end
            else
                data = validationIterationLoop(trainFun,applyFun,data,s,testIter,1);
            end
        end
        
        function data = validationIterationLoop(obj,trainFun,applyFun,data,s,testIter,testStep)
            validationStepLoop = @obj.validationStepLoop;
            n = data(1).validationIterations;
            if n > 1
                try
                    isparallel = ~isempty(getCurrentTask());
                catch
                    isparallel = false;
                end
                if ~isparallel
                    d(n,numel(data)) = Data();
                    for i = 1:numel(data)
                        data(i).testingIteration = testIter;
                        data(i).testingStep = testStep;
                        d(:,i) = data(i).copy(n);
                    end
                    for i = 1:n
                        [d(i,:).validationIteration] = deal(i);
                    end
                    for i = 1:n  % PARFOR
                        d(i,:) = validationStepLoop(trainFun,applyFun,d(i,:),s,testIter,testStep,i);
                    end
                    for i = 1:numel(data)
                        for l = 1:data(1).validationSteps
                            [d(:).validationStep] = deal(l);
                            [d(:).mode] = deal('training');
                            data(i).addPredictionsFrom(d(:,i));
                            [d(:).mode] = deal('validation');
                            data(i).addPredictionsFrom(d(:,i));
                            [d(:).mode] = deal('testing');
                            data(i).addPredictionsFrom(d(:,i));
                        end
                    end
                else
                    for i = 1:n
                        data = validationStepLoop(trainFun,applyFun,data,s,testIter,testStep,i);
                    end
                end
            else
                data = validationStepLoop(trainFun,applyFun,data,s,testIter,testStep,1);
            end
        end
        
        function data = validationStepLoop(obj,trainFun,applyFun,data,s,testIter,testStep,valIter)
            hyperParametersLoop = @obj.hyperParametersLoop;
            n = data(1).validationSteps;
            if n > 1
                try
                    isparallel = ~isempty(getCurrentTask());
                catch
                    isparallel = false;
                end
                if ~isparallel
                    d(n,numel(data)) = Data();
                    for i = 1:numel(data)
                        data(i).testingIteration = testIter;
                        data(i).testingStep = testStep;
                        data(i).validationIteration = valIter;
                        d(:,i) = data(i).copy(n);
                    end
                    for i = 1:n
                        [d(i,:).validationStep] = deal(i);
                    end
                    for i = 1:n % PARFOR
                        d(i,:) = hyperParametersLoop(trainFun,applyFun,d(i,:),s,testIter,testStep,valIter,i);
                    end
                    for i = 1:numel(data)
                        [d(:).mode] = deal('training');
                        data(i).addPredictionsFrom(d(:,i));
                        [d(:).mode] = deal('validation');
                        data(i).addPredictionsFrom(d(:,i));
                        [d(:).mode] = deal('testing');
                        data(i).addPredictionsFrom(d(:,i));
                    end
                else
                    for i = 1:n
                        data = hyperParametersLoop(trainFun,applyFun,data,s,testIter,testStep,valIter,i);
                    end
                end
            else
                data = hyperParametersLoop(trainFun,applyFun,data,s,testIter,testStep,valIter,1);
            end
        end
        
        function data = hyperParametersLoop(obj,trainFun,applyFun,data,s,testIter,testStep,valIter,valStep)
            % declutter variables before parfor
            fields1 = s.fields1;
            fields2 = s.fields2;
            hParamTable = s.hParamTable;
            values = s.values;
            
            % prepare data copies before parfor
%             dValCopy = Data();
%             for i = 1:size(hParamTable,2)
%                 dValCopy(i) = data(i).copy();
%                 dValCopy(i).mode = 'validation';
%             end
%             res = nan(1,size(hParamTable,2),2);
            
            for i = 1:size(hParamTable,2)  % PARFOR
                % take a column from the list and reassign the parameters
                % into the options struct
                d = data(i);
                
                theseParams = struct();
                c = 1;
                for x = 1:numel(fields1)
                    f = fields2{x};
                    s = struct();
                    params = hParamTable(:,i);
                    for y = 1:numel(f)
%                         s.(f{y}) = params(c);
                        v = values(c,:);
                        s.(f{y}) = v{params(c)};
                        c = c + 1;
                    end
                    theseParams.(fields1{x}) = s;
                end
                
                dTrain = d.copyPart('training',valStep,valIter,testStep,testIter);
                dVal = d.copyPart('validation',valStep,valIter,testStep,testIter);
                dTest = d.copyPart('testing',valStep,valIter,testStep,testIter);

                % train with parameters and evaluate errors
                trainFun(dTrain,theseParams);
                applyFun(dVal);
                applyFun(dTest);

                d.addPredictionsFrom(dTrain);
                d.addPredictionsFrom(dVal);
                d.addPredictionsFrom(dTest);
                
                data(i) = d;
            end
        end

        function plotErrors(obj,hParamCap1,varargin)
            ip = inputParser();
            ip.addRequired('hParamCap1')
            ip.addOptional('hParamCap2',[]);
            ip.addOptional('mode','training');
            ip.addOptional('fixValues',struct('dummyMethod_',struct('dummyParam_',0)));
            ip.parse(hParamCap1,varargin);
            ip = ip.Results;
            
            fields1 = fieldnames(ip.fixValues);
            p = struct2cell(ip.fixValues);
            fields2 = cellfun(@fieldnames,p,'uni',false);
            p = cellfun(@struct2cell,p);
            p = vertcat(p{:});
            c = [];
            for i = 1:numel(fields1)
                c = [c, string(fields1{i}) + string('.') + string(fields2{i})];
            end
            
            idx = ismember(c,hParamCap1);
            c(idx) = [];
            p(idx) = [];
            
            hParamTable = obj.hyperParameterValues;
            for i = 1:numel(c)
                idx = ismember(obj.hyperParameterCaptions,c{i});
                del = hParamTable(idx,:) ~= p(i);
                hParamTable(:,del) = [];
            end
            
            hParamPos1 = ismember(obj.hyperParameterCaptions,hParamCap1);
            hParamVals1 = hParamTable(hParamPos1,:);
            
            if isempty(ip.hParamCap2)
                hParamPos2 = [];
                hParamVals2 = [];
            else
                hParamPos2 = ismember(obj.hyperParameterCaptions,ip.hParamCap2);
                hParamVals2 = hParamTable(hParamPos2,:);
            end
            
            figure
            if ~isempty(hParamVals2)
                [p1,~,x] = unique(hParamVals1);
                [p2,~,y] = unique(hParamVals2);
                z = nan(numel(p1),numel(p2));
                lidx = sub2ind(size(z),x,y);
                
                zVec = mean(obj.trainingErrors,1);
                z(lidx) = zVec;
                h = surf(p1,p2,z');
                h.FaceAlpha = 0.8;
%                 alpha 0.8

                hold on
                zVec = mean(obj.validationErrors,1);
                z(lidx) = zVec;
                h = surf(p1,p2,z');
                h.FaceAlpha = 0.8;
%                 alpha 0.8
                
                xlabel(ip.hParamCap1);
                ylabel(ip.hParamCap2);
                zlabel('error');
            else
                [p1,~,x] = unique(hParamVals1);
                y = mean(obj.trainingErrors,1);
                y = y(x);
                plot(p1,y);
                
                hold on
                y = mean(obj.validationErrors,1);
                y = y(x);
                plot(p1,y);
                
                y = mean(obj.testingErrors,1);
                y = y(x);
                plot(p1,y);
                
                xlabel(ip.hParamCap1);
                ylabel('error')
            end
        end

        function apply(obj,data,params)
            if nargin < 3 || isempty(params)
                params = struct();
            end
            d = data.copy();
            obj.processingChain.applyChain(d,params)
        end
    end
    
    methods (Static)
        function out = getAvailableMethods(force)
            persistent fe
            if ~exist('force','var')
                force = false;
            end
            if ~isempty(fe) && ~force
                out = fe;
                return
            end
            fe.Annotation = parsePlugin('Annotation');
            fe.DataReduction = parsePlugin('DataReduction');
            fe.FeaturePreprocessing = parsePlugin('FeaturePreprocessing');
            fe.TargetPreprocessing = parsePlugin('TargetPreprocessing');
            fe.DimensionalityReduction = parsePlugin('DimensionalityReduction');
            fe.Classification = parsePlugin('Classification');
            fe.Regression = parsePlugin('Regression');
            fe.Validation = parsePlugin('Validation');
            fe.Testing = parsePlugin('Testing');
            out = fe;
        end
    end
end