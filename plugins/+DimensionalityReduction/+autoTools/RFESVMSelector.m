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

classdef RFESVMSelector < DimensionalityReduction.autoTools.FeatureSelectorInterface
    %RFESVMEXTRACTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
       secondaryRank = [];
    end
    
    methods
        function this = RFESVMSelector (varargin)
            if nargin == 0
                this.classifier = 'LDA';
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
        
        function [subsInd, rank, err] = train(this, X, Y, varargin)
            if strcmp(this.RegrOrClass,'Regression')
                Y = cat2num(Y); %Regression.
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
                    Mdl = fitrlinear(X(:, subsInd), Y, 'Learner','svm', 'Regularization', 'lasso', 'Solver', 'sparsa');
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
            
            else
            
                %this.data = X;
                nOriginal = size(X,2);
                %this.target = Y;

                c = corr(X,Y);
                c = abs(c);
                [~, this.secondaryRank] = sort(c,'descend');
                ind = false(1, size(X,2));
                ind(this.secondaryRank(1:min([size(X, 2), 500]))) = true;
                %X = X(:, this.secondaryRank(1:min([size(X, 2), 500])));
                X = X(:, ind);

                X = zscore(X);
                subsInd = true(1, size(X,2));
                nSelected = size(X,2);

                numToSel = 1;
                rank = zeros(1,size(X,2));

                %delete features that have nan values
                while any(any(isnan(X(:,subsInd)))) && (nSelected > numToSel)
                    ind = find(subsInd);
                    ex = find(any(isnan(X(:,subsInd)), 1));
                    ex = ex(1);
                    subsInd(ind(ex)) = false;
                    nSelected = nSelected - 1;
                    if nargout == 2
                        rank(ind(ex)) = nSelected;
                    end
                end

                while nSelected > numToSel
                    %train linear SVM
                    %t = templateSVM('BoxConstraint',10^5, 'KernelFunction', 'linear', 'CacheSize', 'maximal','IterationLimit',100);
                    t = templateSVM('KernelFunction', 'linear','IterationLimit',20);
                    %t = templateLinear('Learner', 'svm', 'Regularization', 'lasso'); %'PassLimit',5);
                    mdl = fitcecoc(X(:,subsInd), Y, 'Coding', 'onevsone', 'Learners', t, 'Options', statset('UseParallel', true));
                    %mdl = fitcecoc(X(:,subsInd), Y, 'Coding', 'onevsall', 'Learners', t, 'Options', statset('UseParallel', true));
                    %get weight vector
                    weights = zeros(length(mdl.BinaryLearners{1}.Beta), 1);
                    for i = 1:length(mdl.BinaryLearners)
                        weights = weights + abs(mdl.BinaryLearners{i}.Beta);
                    end
                    %eliminate worst feature
                    ind = find(subsInd);
                    [~, ex] = min(weights);
                    subsInd(ind(ex)) = false;
                    nSelected = nSelected - 1;
                    if nargout >= 2
                        rank(ind(ex)) = nSelected;
                    end
                end
                [~, rank] = sort(-rank, 'descend');

                rankT =  this.secondaryRank;
                rankT(1:min([nOriginal, 500])) = rank;
                rank = rankT;

                this.rank = rank;
            end
            
            if nargout > 2 || nargin <= 4
%                 err = ones(1, min([size(X,2), 500]));
%                 parfor i = 1:length(err)
%                     sI = false(1,size(X,2));
%                     sI(this.rank(1:i)) = true;
%                     err(i) = this.evalLDA(X(:, sI), Y);
%                 en
                cv = cvpartition(Y, 'kFold', 10);
                if strcmp(this.classifier, 'LDA')
                    [ err ] = DimensionalityReduction.autoTools.Helpers.numFeatLDAMahal( X, Y, this.rank, cv );
                elseif strcmp(this.classifier, '1NN')
                    [ err ] = DimensionalityReduction.autoTools.Helpers.numFeat1NN( X, Y, this.rank, cv );
                else
                    error(['unsupported classifier: ', this.classifier]);
                end
                this.err = err;
            end
            
            subsInd = false(1,size(X,2));
            if nargin == 5
                subsInd(rank(1:varargin{2})) = true;
                this.nFeat = varargin{2};
            else
                [~, this.nFeat] = min(err);
                subsInd(rank(1:this.nFeat)) = true;
            end
        end
        
        function feat = apply(this, X)
            subsInd = false(1, length(this.rank));
            subsInd(this.rank(1:this.nFeat)) = true;
            feat = X(:, subsInd);
        end
        
        function show ()
            error('Not yet Implemented');
        end
    end
    
end

