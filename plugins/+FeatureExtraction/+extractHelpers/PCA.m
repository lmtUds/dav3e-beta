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

classdef PCA < FeatureExtraction.extractHelpers.RankingInterface
    %PCA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        xiyiSum = [];
        xiSum = [];
        ind1 = [];
        ind2 = [];
        count = 0;
        coeff = [];
        m = [];
        numFeat = [];
    end
    
    properties (Constant)
        idSuffix = 'PCA';
    end
    
    methods
        function this = PCA(numFeat)
            if nargin > 0
                this.numFeat = numFeat;
            end
        end
        
        function step(this, data, metaInfo)
            metaInfo('ID') = [this.idSuffix, metaInfo('ID')];
            if isempty(this.id)
                this.id = metaInfo('ID');
            end
            
            if isa(data, 'gpuArray')
                data = gather(data);
            end
            
            if ~isKey(metaInfo, 'Training')
                error('"Training" not defined in MetaInfo');
            end
            
            if metaInfo('Training')
                this.count = this.count + 1;
                if isempty(this.xiSum)
                    this.xiSum = zeros(size(data));
                end
                if isempty(this.m)
                    this.m = data;
                else
                    this.m = this.m + data;
                end
                this.xiSum = this.xiSum + data;
                if isempty(this.ind1)
                    i = reshape(1:length(data)^2, length(data), length(data));
                    i = i(triu(true(length(data)),0));
                    [this.ind1, this.ind2] = ind2sub([length(data), length(data)], i);
                    this.ind1 = int16(this.ind1);
                    this.ind2 = int16(this.ind2);
                    clear i;
                end
                if isempty(this.xiyiSum)
                    this.xiyiSum = zeros(size(this.ind1))';
                end
                this.xiyiSum = this.xiyiSum + data(this.ind1).*data(this.ind2);
            else
                metaInfo('Selected') = true(1,size(this.coeff, 1));
                if isempty(this.coeff)
                    this.clearTempData(false);
                end
                if ~isempty(this.next)
                    this.next.step(data * this.coeff, metaInfo);
                end
            end
        end
        
        function ends = getResults(this, metaInfo)
        %Returns the end elements in the signal pipeline
            ends = {};
            if ~isempty(this.next)
                ends = this.next.getResults(metaInfo);
            end
            if isKey(metaInfo, 'Training') && metaInfo('Training') && ~isempty(this.xiSum)
                s = this.copy();
                s.next = {};
                ends = [ends, {s}];
            end
        end
        
        function combineResults(this, id, obj)
            if ~isempty(this.next) && length(this.id) <= length(id) && strcmp(this.id, id(end-length(this.id)+1:end))
                this.next.combineResults(id, obj);
            end
            
            if strcmp(this.id, id)
                if isempty(this.xiSum)
                    this.xiSum = obj.xiSum;
                    this.xiyiSum = obj.xiyiSum;
                    this.count = obj.count;
                    this.m = obj.m;
                else
                    this.xiSum = this.xiSum + obj.xiSum;
                    this.xiyiSum = this.xiyiSum + obj.xiyiSum;
                    this.count = this.count + obj.count;
                    this.m = this.m + obj.m;
                end
                if isempty(this.ind1)
                    this.ind1 = obj.ind1;
                    this.ind2 = obj.ind2;
                end
                if isempty(this.coeff)
                    this.coeff = obj.coeff;
                end
            end
        end
        
        function [ranking, ind, numToSelect] = getRanking(this)
            ranking = -(1:size(this.coeff, 2));
            ind = true(1, size(this.coeff, 2));
            numToSelect = size(this.coeff, 2);
        end
        
        function clearTempData(this, show)
            %compute covariance Matrix
            covariance = ones(length(this.xiSum));
            covariance(sub2ind(size(covariance), this.ind1, this.ind2)) = 1/this.count * (this.xiyiSum + (-1/this.count)*this.xiSum(this.ind1).*this.xiSum(this.ind2));
            covariance(sub2ind(size(covariance), this.ind2, this.ind1)) = 1/this.count * (this.xiyiSum + (-1/this.count)*this.xiSum(this.ind1).*this.xiSum(this.ind2));
            if any(any(isnan(covariance)))
                covariance(isnan(covariance)) = 0;
                disp(['covariance filled with zeros in: ',this.id]);
            end
            [this.coeff, ~, explained] = pcacov(covariance);
            this.coeff = single(this.coeff);
%            this.coeff = cast(this.coeff, 'like', this.xiSum);
            
            this.m = this.m ./ this.count;
            clear covariance;
            this.xiyiSum = [];
            this.xiSum = [];
            this.ind1 = [];
            this.ind2 = [];
            this.count = 0;
            
            if ~isempty(this.numFeat)
                this.coeff = this.coeff(:,1:this.numFeat);
            end
            
            if ~isempty(this.next)
                this.next.clearTempData(show);
            end
            
            if show
                %show explained variance 
                figure;
                hold on;
                plot(explained, 'LineWidth', 2);
                xlabel('Principal Component', 'FontSize', 16);
                ylabel('Variance explained by PC [%]', 'FontSize', 16);
                title([this.getId(), 'Var'], 'FontSize', 16);
                set(gcf, 'PaperPositionMode', 'auto');
                drawnow();
                if exist('TrainingPlots', 'dir') ~= 7
                    mkdir('TrainingPlots');
                end
                savefig(['TrainingPlots/', this.getId(), 'Var']);
                print(['TrainingPlots/', this.getId(), 'Var'], '-dpng', '-r300');
                close;

                %show first principal Component
                figure;
                hold on;
                plot(this.coeff(:,1), 'LineWidth', 2);
                xlabel('Cycle Point', 'FontSize', 16);
                ylabel('Coefficient of PC1 [au]', 'FontSize', 16);
                title([this.getId(), 'PC1'], 'FontSize', 16);
                set(gcf, 'PaperPositionMode', 'auto');
                savefig(['TrainingPlots/', this.getId(), 'PC1']);
                print(['TrainingPlots/', this.getId(), 'PC1'], '-dpng', '-r300');
                close;
            end
        end
        
        function info = getFeatInfo(this, info)
            f = FeatureExtraction.extractHelpers.Factory.getFactory();
            if isempty(info)
                info = f.getFeatureInfoSet();
            end
            
            %keep general info
            info.removeProperty('MeasurementPoint');
            info.addProperty('PCA', true);
            info.addProperty('CoefficientNumber', num2cell(1:size(this.coeff, 2)));
            info.addProperty('SignalChainId', this.getId());
            
            [~, ind] = this.getRanking();
            info.removeFeature(~ind);
            
            %Pass on to next element
            if ~isempty(this.next)
                info = this.next.getFeatInfo(info);
            end
        end
    end
    
end

