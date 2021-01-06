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

classdef BFCExtractor < DimensionalityReduction.autoTools.FeatureExtractorInterface & DimensionalityReduction.autoTools.CombinableInterface
    %BFCEXTRACTOR A feature extractor for best fourier coefficients (BFC)
    %   This extractor computes fourier coefficients and returns the best
    %   ones as features.
    %   By default this method will produce a feature count of 10 percent 
    %   of the cycle length if no count is provided manually.
    
    properties
        m = [];
        n = [];
        ind = [];
        
        heuristic = '';
        numFeat = [];
    end
    
    methods
        function this = BFCExtractor(varargin)
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
        
        function this = train(this, rawData)
            this.ind = [];
            
            amp = abs(fft(rawData, [], 2));
            amp = amp(:, 1:floor(size(rawData,2)/2));
            
            if isempty(this.m)
                this.m = sum(amp);
                this.n = size(rawData,1);
            else
                this.m = this.m + sum(amp);
                this.n = this.n + size(rawData, 1);
            end
            clear rawData;
        end
        
        function feat = apply(this, rawData)
            if isempty(this.ind)
                this.finishTraining();
            end
            
            coeff = fft(rawData, [], 2);
            coeff = coeff(:, 1:floor(size(rawData,2)/2));
            coeff = coeff(:, this.ind);
            
            feat = [abs(coeff), angle(coeff)];
        end
        
        function obj1 = combine(obj1, obj2)
            obj1.ind = [];
            if ~isempty(obj1.m)
                obj1.m = obj1.m + obj2.m;
                obj1.n = obj1.n + obj2.n;
            else
                obj1.m = obj2.m;
                obj1.n = obj2.n;
            end
        end
        
        function captions = getCaptions(this, featCount, prefix)
            captions = string.empty;
            for i=1:featCount/2
                captions(i) = [prefix,'_bfc_abs_',num2str(i)];
            end
            tempStr = string.empty;
            for i=1:featCount/2
                tempStr(i) = [prefix,'_bfc_angle_',num2str(i)];
            end
            captions = horzcat(captions,tempStr);
        end
        
    end
    
    methods (Access = private)
        function finishTraining(this)
            mean = this.m ./ this.n;
            [mean, idx] = sort(mean, 'descend');
            i = false(size(mean));
            if isempty(this.numFeat) && isempty(this.heuristic)
                nFeat = floor(size(mean, 2)/10);
            elseif isempty(this.heuristic)
                nFeat = this.numFeat;
            elseif strcmp(this.heuristic,'elbow')
                nFeat = FeatureExtractorInterface.elbowPos(mean);
            end
            i(idx(1:nFeat)) = true;
            this.ind = i;
        end
    end
end

