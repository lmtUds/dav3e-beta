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

classdef PCAExtractor < DimensionalityReduction.autoTools.FeatureExtractorInterface & DimensionalityReduction.autoTools.CombinableInterface
    %PCAEXTRACTOR A feature extractor for best PCA coefficients
    %   This is used to extract the best PCA coefficients for the provided
    %   raw data. The coefficients for the principal components of the raw
    %   data are computed and sorted by their explained variance.
    %   The Components that explain the most variance resemble the best.
    %   Features are computed by multiplying the raw data with the sorted
    %   coefficient matrix.
    %   By default his method will compute up to a maximum of 500 features 
    %   if no feature count is provided. If the cycle length is less than 
    %   500 the maximum number equals the cycle length.
    
    properties
        coeffs = [];     % the PCA coefficients sorted as a result of training
        expl = [];       % variance explained by each principal component
        
        count = 0;
        xiyiSum = [];
        xiSum = [];
        
        heuristic = '';
        numFeat = [];
    end
    
    properties (Constant)
        intendedLength = 500;   % highest number of principal components allowed
    end
    
    methods
        function this = PCAExtractor(varargin)
           p = inputParser;
           defHeuristic = '';
           expHeuristic = {'elbow','percent'};
           defNumFeat = [];
           addOptional(p,'heuristic',defHeuristic,...
               @(x) any(validatestring(x,expHeuristic)));
           addOptional(p,'numFeat',defNumFeat,@isnumeric);
           parse(p,varargin{:});
           this.heuristic = p.Results.heuristic;
           this.numFeat = p.Results.numFeat;
        end
        
        function [this] = train(this,rawData)
            % clear previously computed coefficients
            this.coeffs = [];
            
			if size(rawData,2) > this.intendedLength
				% downsample raw data for covariance computation
				len = cast(length(rawData), 'like', rawData);
				dsFactor = cast(round(len/this.intendedLength), 'like', rawData);
				dwnDat = resample(rawData', 1, dsFactor)';
			else
				dwnDat = rawData;
            end
            
            % update summed up covariance matrices
            if isempty(this.xiyiSum)
                this.xiSum = sum(dwnDat);
                this.xiyiSum = dwnDat'*dwnDat;
                this.count = size(dwnDat,1);
            else 
                this.xiSum = this.xiSum + sum(dwnDat);
                this.xiyiSum = this.xiyiSum + dwnDat'*dwnDat;
                this.count = this.count + size(dwnDat,1);
            end
        end
		
        function [feat, featInfo] = apply(this, rawData)
            % make sure training was finished
            if isempty(this.coeffs)
                this.finishTraining();
            end
			
			if size(rawData,2) > this.intendedLength
				% downsample raw data for covariance computation
				len = cast(length(rawData), 'like', rawData);
				dsFactor = cast(round(len/this.intendedLength), 'like', rawData);
				dwnDat = resample(rawData', 1, dsFactor)';
			else
				dwnDat = rawData;
            end
            if isempty(this.numFeat) && isempty(this.heuristic)
                feat = dwnDat*this.coeffs;
            elseif isempty(this.heuristic)
                feat = dwnDat*this.coeffs(:,1:this.numFeat);
            elseif strcmp(this.heuristic,'elbow')
                feat = dwnDat*this.coeffs(:,1:FeatureExtractorInterface.elbowPos(this.expl));
            elseif strcmp(this.heuristic,'percent')
                cutoff = floor(size(this.coeffs,2)/10);
                feat = dwnDat*this.coeffs(:,1:cutoff);
            end
        end
		
        function this = combine(this, target)
            % combine training results of target with the results of the
            % calling object
            
            % clear previously computed coefficients
            this.coeffs = [];
            
            % combine the summed up covariance matrices if classes match
            if strcmp(class(this),class(target))
				if isempty(this.xiSum)
                    this.xiSum = target.xiSum;
                    this.xiyiSum = target.xiyiSum;
                    this.count = target.count;
				else
                    this.xiSum = this.xiSum + target.xiSum;
                    this.xiyiSum = this.xiyiSum + target.xiyiSum;
                    this.count = this.count + target.count;
				end
            else
                warning(['Classes ',class(this),' and ',class(target),...
                    ' do not match and cannot be combined']);
            end
        end
        
        function captions = getCaptions(this, featCount, prefix)
            captions = string.empty;
            for i=1:featCount
                captions(i) = [prefix,'_pc_',num2str(i)];
            end
        end
        
    end
    methods (Access = private)
        function finishTraining(this)
            % compute pca of the summed up covariance matrices
            covariance = 1/this.count * (this.xiyiSum - (1/this.count)*this.xiSum'*this.xiSum);
            
            [coeff,~,explained] = pcacov(covariance);
            
            % save computed coefficients and explained curve
            this.coeffs = coeff;
            this.expl = explained;
        end
    end
end

