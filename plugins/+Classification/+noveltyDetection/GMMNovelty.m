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

classdef GMMNovelty < Classification.noveltyDetection.NoveltyDetectionInterface
    %KNNNOVELTY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        gmm = [];
        K = [];
    end
    
    methods
        function this = GMMNovelty(trainData, numFeat)
            if nargin > 0
                this.trainData = trainData;
            end
            if nargin > 1
                this.nF = numFeat;
            end
            this.isNoveltyMeasure = false;
        end
        
        %ToDo: Implement functions
        function train(this, trainData)
            if nargin > 0
                this.trainData = trainData;
            end
            eva = evalclusters(this.trainData,'kmeans','gap','KList',(1:50));
            this.K = eva.OptimalK;
            this.gmm = fitgmdist(this.trainData, this.K, 'Options',statset('MaxIter',200),'CovType','diagonal', 'SharedCov',true, 'Regularize',0.01);
            this.th = this.getThreshold();
        end
        
        function [scores, class] = apply(this, data)
            scores = pdf(this.gmm, data);
            if nargout > 1
                class = scores > this.th;
            end
        end
        
        function thresh = getThreshold(this)
            if isempty(this.th)
                scores = this.apply(this.trainData);
                thresh = mean(scores) - 3*std(scores);
            else
                thresh = this.th;
            end
        end
    end
    
end

