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

classdef RFEplsrSelector < DimensionalityReduction.autoTools.FeatureSelectorInterface
    %RFEplsrEXTRACTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function this = RFEplsrSelector(varargin)
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
            % step 1: ranking
            Y = cat2num(Y); %Regression.
            nComp = 20;
            nSelected = size(X,2); 
            numToSel = 1;
            rank = zeros(1,size(X,2));
            ind = false(1, size(X,2));
            subsInd = true(1, size(X,2));
            params.nComp = nComp;
            class = Regression.autoTools.Helpers.Helpplsr();

            while nSelected > numToSel
                [params] = class.train(X(:, subsInd),Y,params);
                
                %eliminate worst feature
                ind = find(subsInd);
                % [~, ex]= min(abs(params.weights(:,end)));
                % a=min(abs(params.beta0(:)));
                % [ex, ~] = find(a==abs(params.beta0));
                [~, ex]= min(abs(params.beta0(:,end)));
                subsInd(ind(ex)) = false;
                nSelected = nSelected - 1;
                rank(ind(ex)) = nSelected;
            end
            [~, rank] = sort(-rank, 'descend');
            rank = rank';
            this.rank = rank;

            
            if nargin > 4
                subsInd(rank(1:varargin{2})) = true;
                this.nFeat = varargin{2};
            else
                [~, this.nFeat] = min(err);
                subsInd(rank(1:this.nFeat)) = true;
            end
        end
        
    end
    
end