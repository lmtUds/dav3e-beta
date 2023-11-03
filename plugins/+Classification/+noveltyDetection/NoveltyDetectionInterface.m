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

classdef NoveltyDetectionInterface < handle
    %NOVELTYDETECTIONINTERFACE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nF = [];
        trainData = [];
        th = [];
        isNoveltyMeasure = [];
    end
    
    methods
        function nF = numFeat(this)
            nF = this.nF;
        end
        
        train(this, trainData);
        apply(this, data);
        getThreshold(this);
        
        function setThreshold(this, t)
            this.th = t;
        end
        
        function plotTerritorial(this, data, normal)
            classify = @(a)apply(this,a);
            territorialPlot(data, double(normal), @(a)double(getSecondOutput(classify, a)), 1000);
        end
        
        function plotProgression(this, data)
            figure;
            scores = this.apply(data);
            plot(scores, 'LineWidth', 2);
            line(get(gca, 'XLim'), [this.th, this.th], 'Color', 'black');
            legend({'Scores', 'Threshold'}, 'Location', 'best');
            ylabel('score', 'FontSize', 16)
        end
        
        function plotHistogram(this, data, trueLables)
            [scores, class] = this.apply(data);
            [~, edges] = histcounts(scores, 50);
            if nargin > 2 && ~isempty(trueLables)
                lables = trueLables;
            else
                lables = class;
            end
            uniqueLables = unique(lables);
            figure;
            hold on;
            for i = 1:numel(uniqueLables)
                histogram(scores(lables == uniqueLables(i)), edges);
            end
            line([this.th, this.th], get(gca, 'YLim'), 'Color', 'black');
            legend({'novel','normal', 'threshold'});
            ylabel('count', 'FontSize', 16);
            xlabel('score (au)', 'FontSize', 16);
        end
        
        function plotHistogramCV (this, data, cv)
            [scores] = this.apply(data);
            scoresCV = zeros(size(scores));
            for i = 1:cv.NumTestSets
                nd = feval(class(this));
                nd.train(data(cv.training(i),:));
                scoresCV(cv.test(i)) = nd.apply(data(cv.test(i),:));
            end
            
            [~, edges] = histcounts([scores; scoresCV], 50);
            figure;
            hold on;
            histogram(scores, edges);
            histogram(scoresCV, edges);
            
            line([this.th, this.th], get(gca, 'YLim'), 'Color', 'black');
            legend({'data','cross-validated data', 'threshold'});
            ylabel('count', 'FontSize', 16);
            xlabel('score (au)', 'FontSize', 16);
        end
        
        function T = plotROC(this, data, normal, parent)
            scores = this.apply(data);
            [X,Y,T,AUC,OPTROCPT] = perfcurve(normal , scores, ~this.isNoveltyMeasure);
            T = T(X == OPTROCPT(1) & Y == OPTROCPT(2));
            
            delete(parent.Children);            
            ax = uiaxes(parent);
            ax.Layout.Row = 1; ax.Layout.Column = 1;
            hold(ax, 'on');
            plot(ax,X,Y, 'LineWidth', 2);
            scatter(ax,OPTROCPT(1), OPTROCPT(2), 'o', 'MarkerEdgeColor', 'red', 'LineWidth', 2);
            legend(ax,{['ROC-Curve (AUC: ', num2str(AUC),')'],...
                ['optimal operating point (t = ', num2str(T),')']},...
                'Location', 'best');
            xlabel(ax,'False positive rate');
            ylabel(ax,'True positive rate');
        end
    end
    
end
