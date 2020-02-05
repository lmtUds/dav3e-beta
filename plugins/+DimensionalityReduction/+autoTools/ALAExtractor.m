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

classdef ALAExtractor < DimensionalityReduction.autoTools.FeatureExtractorInterface & DimensionalityReduction.autoTools.CombinableInterface
    %ALAEXTRACTOR A feature extractor for ALA features
    %   This is used to extract features via the ALA method. Therefore
    %   cycles are divided into several intervals. Slope and mean for each
    %   interval are then combined to form the extracted features.
    
    properties
        errVec = [];
		l = [];
		start = [];
		stop = [];
        
        numFeat = [];
    end
    
    properties (Constant)
        intendedLength = 500;   % highest number of principal components allowed
    end
    
    methods
        function this = ALAExtractor(varargin)
           p = inputParser;
           defNumFeat = [];
           addOptional(p,'numFeat',defNumFeat,@isnumeric);
           parse(p,varargin{:});
           this.numFeat = p.Results.numFeat;
        end
		function [this] = train(this,rawData)
            % clear previously computed coefficients
            this.start = [];
            this.stop = [];
            
			if size(rawData,2) > this.intendedLength
				% downsample raw data for covariance computation
				len = cast(length(rawData), 'like', rawData);
				dsFactor = cast(round(len/this.intendedLength), 'like', rawData);
				dwnDat = resample(rawData', 1, dsFactor)';
			else
				dwnDat = rawData;
			end
            
			%compute error matrix
			for i = 1:size(dwnDat,1)
				if i == 1
					errVec = this.errMatTransformFast_mex(dwnDat(i,:));
				else
					errVec = errVec + this.errMatTransformFast_mex(dwnDat(i,:));
				end
			end
            
			this.l = size(dwnDat,2);
			
            % update summed up error vector
            if isempty(this.errVec)
                this.errVec = errVec;
            else 
                this.errVec = this.errVec + errVec;
            end
        end
		
		function fitParam = apply(this, rawData)
			if isempty(this.start)
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
			
			%Compute linear fit parameter
			fitParam = zeros(size(dwnDat,1), length(this.start)*2, 'like', dwnDat);
			x = 1:cast(length(dwnDat), 'like', dwnDat);
			for i = 1:cast(length(this.start), 'like', dwnDat)
				ind = this.start(i):this.stop(i);
				for n = 1:size(dwnDat,1)
					[~, d] =  this.linFit(x(ind),dwnDat(n, ind));
					fitParam(n,[2*i-1,2*i]) = d;
				end
			end
		end
		
		function this = combine(this, other)
			this.start = [];
			this.stop = [];
			
			if isempty(this.errVec)
				this.errVec = other.errVec;
				this.l = other.l;
			else
				this.errVec = this.errVec + other.errVec;
			end
		end
    end
	
	methods(Access = private)
		function finishTraining(this)
			
			errMat = Inf(this.l, 'like', this.errVec);
			%from-to matrix
			errMat(tril(true(this.l),-1)) = this.errVec;
            errMat = errMat';
			
			if isa(errMat, 'gpuArray')
                errMat = gather(errMat);
            end
			if isempty(this.numFeat)
                [~, splits, e] = this.findSplits(errMat);
            elseif this.numFeat >=4
                numSplits = floor(this.numFeat/2)-1;
                [~, splits, e] = this.findSplits(errMat,numSplits);
            else
                disp('specifiy higher numFeat so splitting is relevant')
            end
            this.start = cast([1,splits], 'like', this.errVec);
            this.stop = cast([splits, this.l], 'like', this.errVec);
            
            if any(isinf(this.start)) || any(isinf(this.stop))
                error('Failed to find linear segments');
            end
		end
	end
	
	methods(Static)
		%ToDo: Umschreiben für Matrizen
		function errMat = errMatTransformFast_mex( data )
			%ERRMATTRANSFORMFAST Summary of this function goes here
			%   Detailed explanation goes here
			len = length(data);
			errMat = zeros(1, (len*(len-1)/2));
			indRunning = 1;
			%iterate over start-points
			for i = 1:len
				sumX = i;
				sumXX = i^2;
				sumY = data(i);
				sumYY = data(i)^2;
				sumXY = i * data(i);
				%iterate over stop-points
				for j = i+1:len
					sumX = sumX + j;
					sumXX = sumXX + j^2;
					sumY = sumY + data(j);
					sumYY = sumYY + data(j)^2;
					sumXY = sumXY + j*data(j);
					num = j-i+1;
					f = -1/num;
					
					p1 = sumXX - sumX^2/num;
					p2 = 2*sumX*sumY/num - 2*sumXY;
					p3 = sumYY - sumY^2/num;
					b = (sumXY - sumX*sumY/num)/(sumXX - sumX^2/num);
					errMat(indRunning) = p1*b^2+p2*b+p3;
					
					indRunning = indRunning + 1;
				end
			end
        end
        
    end
    
    methods(Access = private)
        function [R2, data] = linFit(~, x, y)
            xm = sum(x,2)/size(x,2);
            ym = sum(y,2)/size(y,2);
            xDiff = (x-repmat(xm,1,size(x,2)));
            b = sum((xDiff).*(y-repmat(ym,1,size(y,2))), 2)./sum((xDiff).^2,2);
            a = ym - b.*xm;
            R2 = 0;
            for i = 1:size(y,1)
                R2 = R2 + sum((y(i,:) - (a(i) + b(i) * x(i,:))).^2);
            end
            data = [ym,b];
        end
		
        function [ err, splits, dat ] = findSplits( this, errMat, numSplits )
        %FINDSPLITS Summary of this function goes here
        %   Detailed explanation goes here
            maxSplits = 70;
            n = length(errMat);
            spl = Inf(maxSplits,n);
            errors = Inf(maxSplits,n); %#ok<PROPLC>
            for q = 1:maxSplits
                for i = 1:n-q
                    if q == 1
                        sumRes = errMat(i,:) + errMat(:,n)';
                    else
                        sumRes = errors(q-1,:) + errMat(i,:); %#ok<PROPLC>
                    end
                    [errors(q,i),spl(q,i)] = min(sumRes); %#ok<PROPLC>
                end
            end

            dat = errors(:,1)'; %#ok<PROPLC>
            sqErr = this.getFitErrorMatrix(dat, {'this.linFit'});
            maxSplits = 3;
            n = length(sqErr);
            splTemp = Inf(maxSplits,n);
            errorsTemp = Inf(maxSplits,n);
            for q = 1:maxSplits
                for i = 1:n-q
                    if q == 1
                        sumRes = sqErr(i,:) + sqErr(:,n)';
                    else
                        sumRes = errorsTemp(q-1,:) + sqErr(i,:);
                    end
                    [errorsTemp(q,i),splTemp(q,i)] = min(sumRes);
                end
            end
            splits = zeros(1,maxSplits);
            splits(1) = splTemp(maxSplits,1);
            for i = maxSplits-1:-1:1
                splits(maxSplits - i + 1) = splTemp(i, splits(maxSplits - i));
            end

            if nargin < 3
                numSplits = splits(end);
            end
            splits = zeros(1,numSplits);
            err = errors(numSplits,1); %#ok<PROPLC>
            splits(1) = spl(numSplits,1);
            for i = numSplits-1:-1:1
                splits(numSplits - i + 1) = spl(i, splits(numSplits - i));
            end
        end
		
		function [sqErr, functions] = getFitErrorMatrix(this, dat, varargin)
            dat = sum(dat,1);
            x = 1:size(dat,2);

            fitFunctions = varargin{1};

            N = size(dat,2);
            sqErr = Inf(N);
            functions = cell(N);

            combos = this.nchoose2(1:N);
            sqErrTemp = Inf(1,size(combos,1));
            funTemp = zeros(1,size(combos,1));
            for i = 1:size(combos,1)
                sqTT = Inf(1,length(fitFunctions));
                for j = 1:length(fitFunctions)
                    for k = 1:size(dat,1)
                        xu = x(combos(i,1):combos(i,2));
                        yu = dat(k,combos(i,1):combos(i,2));
                        err = this.linFit(xu, yu);
                        if sqTT(j) == Inf
                            sqTT(j) = err;
                        else
                            sqTT(j) = sqTT(j) + err;
                        end
                    end
                end
                [sqErrTemp(i), funTemp(i)] = min(sqTT);
            end
            for i = 1:size(combos,1)
                functions(combos(i,1),combos(i,2)) = fitFunctions(funTemp(i));
                sqErr(combos(i,1),combos(i,2)) = sqErrTemp(i);
            end
        end
		
        function [ combos ] = nchoose2( ~, nums,varargin )
        %FNCHOOSEK Summary of this function goes here
        %   Detailed explanation goes here
            N = length(nums);
            combos = zeros(nchoosek(N,2),2);
            for i = 1:N-1
                start = nchoosek(N, 2) - nchoosek(N - i + 1, 2) + 1; %#ok<PROPLC>
                if N-i == 1
                    fin = length(combos);
                else
                    fin = nchoosek(N, 2) - nchoosek(N-i, 2);
                end
                combos(start:fin, 1) = nums(i); %#ok<PROPLC>
                combos(start:fin, 2) = nums(i+1:end); %#ok<PROPLC>
            end
        end
	end
    
end
