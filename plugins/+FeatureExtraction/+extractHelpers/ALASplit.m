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

classdef ALASplit < FeatureExtraction.extractHelpers.SignalChainElementInterface
    %ADAPTIVELINEARAPPROXIMATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        errors = [];
        start = [];
        stop = [];
        numSplits = [];
    end
    
    properties (Constant)
        idSuffix = 'ALASplit';
    end
    
    methods
        function this = ALASplit(numSplits)
            if nargin > 0
                this.numSplits = numSplits;
            end
        end
        
        function step (this, data, metaInfo)
            metaInfo('ID') = [this.idSuffix, metaInfo('ID')];
            if isempty(this.id)
                this.id = metaInfo('ID');
            end
            
            if isempty(this.errors)
                this.errors = zeros(size(data), 'like', data);
            end
            
            if isKey(metaInfo, 'Training') && metaInfo('Training')
                this.errors = this.errors + data;
            else
                %finish training if needed
                if isempty(this.start)
                    this.clearTempData(false);
                end
                
                %Compute linear fit parameter
                fitParam = zeros(1, length(this.start)*2, 'like', data);
                x = 1:cast(length(data), 'like', data);
                for i = 1:cast(length(this.start), 'like', data)
                    ind = this.start(i):this.stop(i);
                    [~, d] =  this.linFit(x(ind),data(ind));
                    fitParam([2*i-1,2*i]) = d;
                end
                
                %pass on linear fit parameter to next element
                if ~isempty(this.next)
                    this.next.step(fitParam, metaInfo);
                end
            end
        end
        
        function combineResults(this, id, obj)
            if ~isempty(this.next) && length(this.id) <= length(id) && strcmp(this.id, id(end-length(this.id)+1:end))
                this.next.combineResults(id, obj);
            end
            if strcmp(id, this.id)
                if isempty(this.errors)
                    this.errors = obj.errors;
                else
                    this.errors = this.errors + obj.errors;
                end
            end
        end
        
        function ends = getResults(this, metaInfo)
            ends = {};
            if isKey(metaInfo, 'Training') && metaInfo('Training') && ~isempty(this.errors)
                s = this.copy();
                s.next = {};
                ends = {s};
            end
            if ~isempty(this.next)
                ends = [ends, this.next.getResults(metaInfo)];
            end
        end
        
        function [running, passive] = getMemory(this, metaInfo)
            varSize = metaInfo('varSize');
            passive = (numel(this.errors)+numel(this.sarts)+numel(this.ends)*verSize);
            running = (numel(this.errors)+5*this.stop(end))*varSize+passive;
        end
        
        function clearTempData(this, show)
            if ~isempty(this.numSplits)
                numSplits = this.numSplits;
            end
            l = find(length(this.errors) == ([1:500].^2 - [1:500])./2); %#ok<NBRAK>
            if isempty(l)
                error('maximum length of processed data is 500!');
            end
            errMat = Inf(l, 'like', this.errors);
            index = zeros(sum(sum(triu(true(size(errMat)), 1))), 2);
            runningI = 1;
            for i = 1:l
                for j = i+1:l
                    index(runningI, 1) = i;
                    index(runningI, 2) = j;
                    runningI = runningI + 1;
                end
            end
            errMat(sub2ind(size(errMat), index(:,1), index(:,2))) = this.errors;
            
            if isa(errMat, 'gpuArray')
                errMat = gather(errMat);
            end
            if nargin < 3 && ~exist('numSplits', 'var')
                [~, splits, e] = this.findSplits(errMat);
            else
                [~, splits, e] = this.findSplits(errMat, numSplits);
            end
            this.start = cast([1,splits], 'like', this.errors);
            this.stop = cast([splits, l], 'like', this.errors);
            
            if any(isinf(this.start)) || any(isinf(this.stop))
                error('Failed to find linear segments');
            end
            
            this.errors = [];
            
            if ~isempty(this.next)
                this.next.clearTempData(show);
            end
            
            if show
                %show training results
                figure;
                hold on;
                plot(e, 'LineWidth', 2);
                xlabel('Number of Splits', 'FontSize', 16);
                ylabel('Achieved approximation error [au]', 'FontSize', 16);
                title(this.getId(), 'FontSize', 16);
                set(gcf, 'PaperPositionMode', 'auto');
                drawnow();
                line([length(splits), length(splits)], get(gca, 'YLim'), 'LineWidth', 2, 'color', 'black');
                if exist('TrainingPlots', 'dir') ~= 7
                    mkdir('TrainingPlots');
                end
                drawnow();
                savefig(['TrainingPlots/', this.getId()]);
                print(['TrainingPlots/', this.getId()], '-dpng', '-r300');
                close;
            end
        end
        
        function info = getFeatInfo(this, info)
            f = FeatureExtraction.extractHelpers.Factory.getFactory();
            if isempty(info)
                info = f.getFeatureInfoSet();
            end
            info.removeProperty('MeasurementPoint');
            info.removeFeature(length(this.start)*2+1:info.getNumFeat())
            
            type = cell(1, length(this.start) * 2);
            intervall = cell(1, length(this.start) * 2);
            for i = 1:2:length(this.start)*2-1
                type{i} = 'mean';
                type{i+1} = 'slope';
                intervall{i} = [this.start((i+1)/2),this.stop((i+1)/2)];
                intervall{i+1} = [this.start((i+1)/2),this.stop((i+1)/2)];
            end
            info.addProperty('FeatureType', type);
            info.addProperty('Interval', intervall);
            info.addProperty('SignalChainId', this.getId());
            
            %Pass on to next element
            if ~isempty(this.next)
                info = this.next.getFeatInfo(info);
            end
        end
    end
    
    methods (Access = protected)
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

