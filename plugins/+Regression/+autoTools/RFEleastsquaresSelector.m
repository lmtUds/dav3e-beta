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

classdef RFEleastsquaresSelector < Regression.autoTools.FeatureSelectorInterface
    %RFEleaastsquaresEXTRACTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function this = RFEleastsquaresSelector(varargin)
            if nargin == 0
                this.classifier = 'plsr';
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
            this.projectedData.trainingSelection = data.trainingSelection;
            this.projectedData.validationSelection = data.validationSelection;
            this.projectedData.testingSelection = data.testingSelection;
            % step 1: ranking
            X = data.getSelectedData();
            Y = data.getSelectedTarget();
            Y = cat2num(Y); %Regression.
            nComp = this.nComp;
            nSelected = size(X,2); 
            numToSel = 1;
            rank = zeros(1,size(X,2));
            ind = false(1, size(X,2));
            subsInd = true(1, size(X,2));

            while nSelected > numToSel
                %train linear SVM
                %Mdl = fitrsvm(X(:, subsInd), Y);
                %fitrlinear faster than fitrsvm
               % Mdl = fitrlinear(X(:, subsInd), Y);
                Mdl = fitrlinear(X(:, subsInd), Y, ...
                    'Learner','leastsquares', 'Regularization', ...
                    'ridge', 'Solver', 'lbfgs');
                %Mdl = fitrgp(X(:, subsInd), Y);
                %Mdl = fitrsvm(X(:, subsInd), Y, 'KernelFunction', 'gaussian')

                %eliminate worst feature
                ind = find(subsInd);
                [~, ex] = min(abs(Mdl.Beta));
                subsInd(ind(ex)) = false;
                nSelected = nSelected - 1;

                rank(ind(ex)) = nSelected;
            end
            [~, rank] = sort(-rank, 'descend');
            rank = rank';
            this.rank = rank;
            
            % step 2: integrated Validation, copy from classes\Data.m
            if this.groupbasedVal == 0
                cv = cvpartition(Y, 'kFold', 10);
            elseif this.groupbasedVal == 1
                availSel = data.availableSelection;
                testSel = data.testingSelection;
                sel = ~testSel & availSel;
                actualTarget = data.target(sel);
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
                    trainSelFinal = false(size(data.trainingSelection,1),1);
                    trainSelFinal(sel) = trainSel;
                    cv.training{valstep} = trainSelFinal; 

                    validationSelFinal = false(size(data.validationSelection,1),1);
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

