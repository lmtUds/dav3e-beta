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

classdef MeanValueLearner < FeatureExtraction.extractHelpers.SignalChainElementInterface & FeatureExtraction.extractHelpers.RankingInterface
    %MEANVALUELEARNER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        idSuffix = 'MV'
    end
    
    properties (Access = public)
        sum = [];
        count = 0;
        ind = [];
        lastProcessed = 0;
        numToSelect = [];
    end
    
    methods
        function this = MeanValueLearner(numFeat)
            if nargin > 0
                this.numToSelect = numFeat;
            end
        end
        
        function step(this, data, metaInfo)
            metaInfo('ID') = [this.idSuffix, metaInfo('ID')];
            if isempty(this.id)
                this.id = metaInfo('ID');
            end
            if isempty(this.sum)
                this.sum = zeros(size(data), 'like', data);
            end
            if isKey(metaInfo, 'cycleNum') && this.lastProcessed ~= metaInfo('cycleNum')
                if isKey(metaInfo, 'Training') && metaInfo('Training')
                    temp = this.sum;
                    this.sum = [];
                    temp = temp + data;
                    this.sum = temp;
                    this.count = this.count + 1;
                end
                if ~isempty(this.next) && isKey(metaInfo, 'Training') && ~metaInfo('Training')
                    if isempty(this.ind)
                        this.clearTempData(false);
                    end
                    metaInfo('Selected') = this.ind;
                    this.next.step(data(this.ind), metaInfo);
                end
                if isKey(metaInfo, 'cycleNum')
                    this.lastProcessed = metaInfo('cycleNum');
                end
            end
        end
        
        function [ranking, ind, numToSelect] = getRanking(this)
            if isempty(this.numToSelect)
                numToSelect = floor(size(this.sum, 2)/10);
                this.numToSelect = numToSelect;
            else
                numToSelect = this.numToSelect;
            end
            if isempty(this.ind)
                if isa(this.sum, 'gpuArray')
                    ranking = abs(this.sum./gpuArray(this.count));
                    if nargout > 1
                        ind = false(1, size(ranking,2), 'gpuArray');
                        [~, rs] = sort(ranking, 'descend');
                        ind(rs(gpuArray.colon(1, this.numToSelect))) = true;
                    end
                else
                    ranking = abs(this.sum./this.count);
                    if nargout > 1
                        ind = false(1, size(ranking,2));
                        [~, rs] = sort(ranking, 'descend');
                        ind(rs(1:this.numToSelect)) = true;
                    end
                end
            else
                ranking = this.ind;
                ind = this.ind;
                numToSelect = sum(this.ind); %#ok<CPROP>
            end
        end
        
        function ends = getResults(this, metaInfo)
        %Returns the end elements in the signal pipeline
            ends = {};
            if ~isempty(this.next)
                ends = this.next.getResults(metaInfo);
            end
            if isKey(metaInfo, 'Training') && metaInfo('Training') && ~isempty(this.sum)
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
                if isempty(this.sum)
                    this.sum = obj.sum;
                    this.count = obj.count;
                else
                    this.sum = this.sum + obj.sum;
                    this.count = this.count + obj.count;
                end
            end
        end
        
        function clearTempData(this, show)
            if isempty(this.numToSelect)
                n = floor(size(this.sum,2)/10);
            else
                n = this.numToSelect;
            end
            if isa(this.sum, 'gpuArray')
                r = this.sum./gpuArray(this.count);
                [v, index] = sort(r, 'descend');
                this.ind = false(1, size(index,2), 'gpuArray');
                this.ind(index(gpuArray.colon(1, n))) = true;
            else
                r = this.sum./this.count;
                [v, index] = sort(r, 'descend');
                this.ind = false(1, size(index,2));
                this.ind(index(1:n)) = true;
            end
            
            if show
                %show plot of sorted r with selection thresholds
                figure;
                hold on;
                plot(v, 'LineWidth', 2);
                xlabel('Coefficient rank', 'FontSize', 16);
                ylabel('Average coefficient value [au]', 'FontSize', 16);
                title(this.getId(), 'FontSize', 16);
                set(gcf, 'PaperPositionMode', 'auto');
                drawnow();
                line([length(v)/10, length(v)/10], get(gca, 'YLim'), 'LineWidth', 2, 'color', 'black');
                threshold = v(round(length(v)/10));
                line(get(gca, 'XLim'), [threshold, threshold], 'LineWidth', 2, 'color', 'black');
                if exist('TrainingPlots', 'dir') ~= 7
                    mkdir('TrainingPlots');
                end
                drawnow();
                savefig(['TrainingPlots/', this.getId(), 'Sort']);
                print(['TrainingPlots/', this.getId(), 'Sort'], '-dpng', '-r300');
                close;
                
                %show plot of unsorted r with selection thresholds.
                figure;
                hold on;
                plot(r, 'LineWidth', 2);
                xlabel('Coefficient number', 'FontSize', 16);
                ylabel('Average coefficient value [au]', 'FontSize', 16);
                title(this.getId(), 'FontSize', 16);
                set(gcf, 'PaperPositionMode', 'auto');
                drawnow();
                line(get(gca, 'XLim'), [threshold, threshold], 'LineWidth', 2, 'color', 'black');
                drawnow();
                savefig(['TrainingPlots/', this.getId()]);
                print(['TrainingPlots/', this.getId()], '-dpng', '-r300');
                close;
            end
            
            this.sum = [];
            this.count = [];
            
            if ~isempty(this.next)
                this.next.clearTempData(show);
            end
        end
        
        function info = getFeatInfo(this, info)
            if isempty(info)
                f = FeatureExtraction.extractHelpers.Factory.getFactory();
                info = f.getFeatureInfoSet();
            else
                info.removeFeature(~this.ind)
            end
            info.addProperty('SignalChainId', this.getId());
            
            %Pass on to next element
            if ~isempty(this.next)
                info = this.next.getFeatInfo(info);
            else
                %delete, not to irritate stacked selector
                info = [];
            end
        end
    end
    
end

