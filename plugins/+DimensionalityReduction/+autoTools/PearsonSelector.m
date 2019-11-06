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

classdef PearsonSelector < DimensionalityReduction.autoTools.FeatureSelectorInterface
    %PEARSONSELECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function this = PearsonSelector(varargin)
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
            this.rank = abs(corr(X, Y));
            this.rank(isnan(this.rank)) = 0;
            [~, this.rank] = sort(this.rank, 'descend');
            rank = this.rank;
            subsInd = false(1, size(X,2));
            
            if nargout > 2 || nargin <= 3
%                 err = ones(1, min([size(X,2), 500]));
%                 [~, rank] = sort(this.rank, 'descend');
%                 parfor i = 1:length(err)
%                     sI = false(1,size(X,2));
%                     sI(rank(1:i)) = true;
%                     err(i) = this.evalLDA(X(:, sI), Y);
%                 end
                cv = cvpartition(Y, 'kFold', 10);
                ind = false(size(rank));
                ind(this.rank(1:min([size(X,2), 500]))) = true;
                if strcmp(this.classifier, 'LDA')
                    [ err ] = DimensionalityReduction.autoTools.Helpers.numFeatLDAMahal( X(:,ind), Y, this.rank(1:min([size(X,2), 500])), cv );
                elseif strcmp(this.classifier, '1NN')
                    [ err ] = DimensionalityReduction.autoTools.Helpers.numFeat1NN( X(:,ind), Y, this.rank(1:min([size(X,2), 500])), cv );
                else
                    error(['unsupported classifier: ', this.classifier]);
                end
                this.err = err;
            end
            
            if nargin > 4
                subsInd(rank(1:varargin{2})) = true;
                this.nFeat = varargin{2};
            else
                [~, this.nFeat] = min(err);
                subsInd(rank(1:this.nFeat)) = true;
            end
            rank = this.rank;
        end
    end
    
end

