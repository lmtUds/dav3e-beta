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

classdef NCASelector < Regression.autoTools.FeatureSelectorInterface
    %NCASELECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function this = NCASelector(varargin)
            if nargin == 0
                this.classifier = 'PLSR';
                this.data = [];
                this.target = [];
                this.rank = [];
                this.nFeat = [];
            elseif nargin == 1
                this.classifier = varargin{1};
                this.data = [];
                this.target = [];
                this.rank = [];
                this.nFeat = [];
            elseif nargin == 3
                this.classifier = varargin{1};
                this.data = varargin{2};
                this.target = varargin{3};
                this.rank = [];
                this.nFeat = [];
            elseif nargin == 5
                this.classifier = varargin{1};
                this.data = varargin{2};
                this.target = varargin{3};
                this.rank = varargin{4};
                this.nFeat = varargin{5};
            else
                error('Invalid argument number');
            end
        end
        
        function [subsInd, rank] = train(this, data)
            % step 0: testing
            if strcmp(this.Testing, 'groups')
                sel = data.getGroupingByName(this.groupingTest);
                sel2 = string(sel);
                for i = 1:length(this.groupsTest)
                    data.trainingSelection(strcmp(this.groupsTest(i), sel2))=false;
                    data.testingSelection(strcmp(this.groupsTest(i), sel2))=true;
                end
            elseif this.groupbasedTest == 0 && strcmp(this.Testing, 'holdout')
                cvTest = cvpartition(data.target, 'HoldOut', this.percentTest/100);
                data.trainingSelection = cvTest.training;
                data.testingSelection = cvTest.test;
            elseif this.groupbasedTest == 1 && strcmp(this.Testing, 'holdout')
                % actualTargetT = data.target;
                selT = data.availableSelection;
                gT = data.getGroupingByName(this.groupingTest);
                tT = categories(removecats(gT(selT)));
                cvTest = cvpartition(numel(tT),'HoldOut',this.percentTest/100);

                trainSelT = cvTest.training;
                testSelT = cvTest.test;
                if this.groupbasedTest == 1
                    trainSelNewT = true(size(tT));
                    testSelNewT = false(size(tT));
                    if isnumeric(tT)
                        trainSelNewT = double(trainSelNewT);
                        testSelNewT = double(testSelNewT);
                    end
                    gT = data.getGroupingByName(this.groupingTest);
                    gT = gT(selT);
                    for cidxT = 1:numel(tT)
                        trainSelNewT(gT==tT(cidxT)) = trainSelT(cidxT);
                        testSelNewT(gT==tT(cidxT)) = testSelT(cidxT);
                    end
                    trainSelFinal = false(size(data.cycleSelection,1),1);
                    trainSelFinal(selT) = trainSelNewT;
                    testSelFinal = false(size(data.cycleSelection,1),1);
                    testSelFinal(selT) = testSelNewT;
                    
                    data.trainingSelection = logical(trainSelFinal);
                    data.testingSelection = logical(testSelFinal);
                    
%                     testSelFinal = false(size(obj.testingSelection,1),1);
%                     testSelFinal(sel) = testSel;
%                     obj.testingSelection(:,teststep,testit) = testSelFinal;
                end
            elseif strcmp(this.Testing, 'none')
            else
                 error('Something wrong with Testing')
            end
            this.projectedData.trainingSelection = data.trainingSelection;
            this.projectedData.validationSelection = data.validationSelection;
            this.projectedData.testingSelection = data.testingSelection;          
            % step 1: ranking
            X = data.getSelectedData();
            Y = data.getSelectedTarget();
            Y = cat2num(Y); %Regression.
            subsInd = false(1,size(X,2));
            mdl = fsrnca(X,Y,'solver','lbfgs');
            [~, rank] = sort(mdl.FeatureWeights, 'descend');
            this.rank = rank;
            
            % step 2: integrated Validation, copy from classes\Data.m
            if this.groupbasedVal == 0
                cv = cvpartition(Y, 'kFold', 10);
            elseif this.groupbasedVal == 1
                actualTarget = Y;
                availSel = data.availableSelection;
                testSel = data.testingSelection;
                sel = ~testSel & availSel;
                g = data.getGroupingByName(this.groupingVal);
                t = categories(removecats(g(sel)));
                c = cvpartition(numel(t),'kFold',10);

                for valstep = 1:c.NumTestSets
                    trainSel = c.training(valstep);
                    valSel = c.test(valstep);
                    if this.groupbasedVal == 1
                        trainSelNew = true(size(actualTarget));
                        valSelNew = false(size(actualTarget));
                        if isnumeric(actualTarget)
                            trainSelNew = double(trainSelNew);
                            valSelNew = double(valSelNew);
                        end
                        g = data.getGroupingByName(this.groupingVal);
                        g = g(sel);
                        for cidx = 1:numel(t)
                            trainSelNew(g==t(cidx)) = trainSel(cidx);
                            valSelNew(g==t(cidx)) = valSel(cidx);
                        end
                        trainSel = trainSelNew;
                        valSel = valSelNew;
                    end
                    trainSelFinal = false(size(X,1),1);
                    trainSelFinal(sel) = trainSel;
                    cv.training{valstep} = trainSelFinal; 

                    validationSelFinal = false(size(X,1),1);
                    validationSelFinal(sel) = valSel;
                    cv.test{valstep} = validationSelFinal;
                    cv.NumTestSets = c.NumTestSets;
                end

            else
                error('Something wrong with Validation')
            end
            
            % step 3: regression
            if strcmp(this.classifier, 'plsr')
                 class = Regression.autoTools.Helpers.Helpplsr();
                 [ this ] = Regression.autoTools.Helpers.numFeatMulti(data, this.rank(1:min([size(X,2),500])), cv, class, this);
            elseif strcmp(this.classifier, 'svr')
                 class = Regression.svr();
                 this.nComp = 1;
                 [ this ] = Regression.autoTools.Helpers.numFeatMulti(data, this.rank(1:min([size(X,2), 500])), cv, class, this);
            else
                error(['unsupported classifier: ', this.classifier]);
            end
            
            subsInd = this.nFeat;
        end
    end  
end
