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

classdef RELIEFFSelector < DimensionalityReduction.autoTools.FeatureSelectorInterface
    %RELIEFFSELECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function this = RELIEFFSelector(varargin)
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
            %this.data = X;
            %this.target = Y;
            if strcmp(this.RegrOrClass,'Regression')
                Y = cat2num(Y); %Regression.
                [idx, ~] = relieff(X,Y,10,'method','regression');
                rank = idx';
                %rank = -rank;
                [~, rank] = sort(rank, 'descend');
                this.rank = rank;
            else
                X = zscore(X);

                %Check, if there are at least four samples per group
                %(each one has three nearest neightbours)
                groups = unique(Y);
                numPerGroup = zeros(length(groups),1);
                for i = 1:length(groups)
                    try
                        numPerGroup(i) = sum(Y == groups(i));
                    catch
                        numPerGroup(i) = sum(strcmp(Y,groups{i}));
                    end
                end
                n = min(numPerGroup);
                nNN = 3;
                if n <= 1
                    error('empty group in reliefFUni');
                elseif n <= 3
                    nNN = n - 1;
                end

                rank = zeros(1, size(X,2));
                for g = 1:length(groups)
                    %Nearest Miss
                    idxMiss = knnsearch( X(Y ~= groups(g),:), X(Y == groups(g),:), 'K', nNN, 'D', 'cityblock', 'NSMethod', 'kdtree');

                    %Nearest Hits
                    idxHit = knnsearch( X(Y == groups(g),:), X(Y == groups(g),:), 'K', nNN+1, 'D', 'cityblock', 'NSMethod', 'kdtree');
                    idxHit = idxHit(:, 2:end);

                    for i = 1:nNN
                        rank = rank + sum(abs(X(Y == groups(g),:) - X(idxMiss(:,i),:)), 1) - sum(abs(X(Y == groups(g),:) - X(idxHit(:,i),:)), 1);
                    end
                end


%             %Old, univariate RELIEFF
%             numCyc = size(X,1);
%             rank = zeros(1, size(X,2));
%             for i = 1:size(X,2)
%                 missesSum = 0;
%                 hitsSum = 0;
%                 data = X(:,i);
%                 for j = 1:length(groups)
%                     hit = Y == groups(j);
%                     %six nearest hits, because nearest hit is always the
%                     %point itself
%                     [~, dHit] = knnsearch(data(hit), data(hit), 'K', 6, 'Distance', 'chebychev');
%                     [~, dMiss] = knnsearch(data(~hit), data(hit), 'K', 6, 'Distance', 'chebychev');
%                     hitsSum = hitsSum + sum(sum(dHit));
%                     missesSum = missesSum + sum(sum(dMiss));
%                 end
%                 rank(i) = missesSum/hitsSum;
%             end


                %rank = -rank;
                [~, rank] = sort(rank, 'descend');
                this.rank = rank;
            end
            
            if nargout > 2 || nargin <= 4
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
    end
    
end

