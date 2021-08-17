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

classdef FeatureSelectorInterface < handle
    %FEATURESELECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        data = [];
        target = [];
        rank = [];
        nFeat = [];
        err = [];
        RegrOrClass = [];
        classifier = 'LDA';
    end
    
    methods
        function this = FeatureSelector (varargin)
        end
        
        function [subsInd, rank, err] = train(this, X, Y, varargin)
        end
        
        function [rank, nFeat, err] = info(this)
            if isempty(this.rank) || isempty(this.nFeat) || isempty(this.err)
                [rank, nFeat, err] = this.train(this.data, this.rank, this.nFeat);
            else
                rank = this.rank;
                nFeat = this.nFeat;
                err = this.err;
            end
        end
        
        function feat = apply(this, X)
%             subsInd = false(1, length(this.rank));
%             [~, rank] = sort(this.rank, 'descend'); %#ok<PROPLC>
%             subsInd(rank(1:this.nFeat)) = true; %#ok<PROPLC>
%             feat = X(:, subsInd);
            feat = X(:,this.rank(1:this.nFeat));
        end
        
        function show (this)
        end
        
        function [subsInd, rank, err] = trainCV(this, X, Y, varargin)
            %varargin{1} is the cvpartition to use
            if nargin <= 3
                cv = cvpartition(size(X,1), 'kfold', 10);
            else
                cv = varargin{1};
            end
            
            if nargout >= 3
                %Get Ranks computed on the training data
                f = Factory.getFactory();
                if strcmp(this.classifier, 'LDA')
                    c = f.getLDAMahalClassifier();
                elseif strcmp(this.classifier, '1NN')
                    c = f.getOneNNClassifier();
                else
                    error(['unsupported classifier: ', this.classifier]);
                end
                err = zeros(size(X,2), cv.NumTestSets);
                for i = 1:cv.NumTestSets
                    [~, rank] = this.train(X(cv.training(i),:), Y(cv.training(i)));
                    [~, rank] = sort(rank, 'descend');
                    parfor j = 1:size(X,2)
                        subsInd = false(1,size(X,2));
                        subsInd(rank(1:j)) = true;
                        c.train(X(cv.training(i), subsInd), Y(cv.training(i)));
                        pred = c.apply(X(cv.test(i), subsInd));
                        err(j,i) = sum(pred ~= Y(cv.test(i)));
                    end
                end
                err = (sum(err, 2)./size(X,1))';
            end
            
            if nargin <= 4
                [subsInd, rank] = this.train(X, Y);
            else
                [subsInd, rank] = this.train(X, Y, varargin{2});
            end
        end
    end
    
    methods (Access = protected)
        function err = evalLDA(~, X, Y)
            err = Helpers.evalLDA(X, Y);
        end
    end
    
end

