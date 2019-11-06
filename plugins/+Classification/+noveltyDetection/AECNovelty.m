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

classdef AECNovelty < Classification.noveltyDetection.NoveltyDetectionInterface
    %KNNNOVELTY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        autoenc = [];
    end
    
    methods
        function this = AECNovelty(trainData, numFeat)
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
            train = this.trainData';
            neuron = floor((size(train,1))^(0.05));
            this.autoenc = trainAutoencoder(train,neuron,'MaxEpochs',500);
            nntraintool('close');
            this.th = this.getThreshold();
        end
        
        function [scores, class] = apply(this, data)
            test = data';
            test_autoencode = predict(this.autoenc,test);
            scores = sqrt(sum((test_autoencode-test).^2, 1))';
            if nargout > 1
                class = scores < this.th;
            end
        end
        
        function thresh = getThreshold(this)
            test = this.trainData';
            test_autoencode = predict(this.autoenc,test);
            scores = sqrt(sum((test_autoencode-test).^2, 1))';
            thresh = 2 * mean(scores);
        end
    end
    
end

