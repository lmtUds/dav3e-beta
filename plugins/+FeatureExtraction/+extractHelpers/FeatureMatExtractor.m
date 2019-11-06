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

classdef FeatureMatExtractor < FeatureExtraction.extractHelpers.FeatureExtractorInterface
    %FEATUREMATEXTRACTOE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function this = FeatureMatExtractor(featMat, name, cv, targets)
            if nargin > 0
                this.featureMatrix = featMat;
                this.name = name;
                this.cv = cv;
                this.targetMat = targets;
            end
        end
        
        function data = getTrainData(this, target, cvFold, eval)
            useAll = false;
            if isempty(this.cv)
                useAll = true;
            else
                if cvFold > this.cv.NumTestSets || cvFold < 1
                    cvFold = this.cv.NumTestSets + 1;
                    useAll = true;
                end
            end
            
            data = this.featureMatrix.getFeatMat(cvFold, target, eval);
            if ~useAll
                data = data(:,this.cv.training(cvFold));
            end
            data = data';
        end
        
        function data = getTestData(this, target, cvFold)
            useAll = false;
            if cvFold > this.cv.NumTestSets || cvFold < 1
                cvFold = this.cv.NumTestSets + 1;
                useAll = true;
            end
            
%             data = this.featureMatrix.getFeatMat(cvFold, target, true);
%             if isempty(data) %eval data == training data
                data = this.featureMatrix.getFeatMat(cvFold, target, false);
%             end
            if ~useAll
                data = data(:, this.cv.test(cvFold));
            end
            data = data';
        end
        
        function numCV = getNumCVFolds(this)
            numCV = this.cv.NumTestSets;
        end
        
        function numTarget = getNumTargets(this)
            numTarget = size(this.targetMat, 2);
        end
        
        function name = getName(this)
            name = this.name;
        end
    end
    
end

