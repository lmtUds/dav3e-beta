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

classdef BDWExtractor < DimensionalityReduction.autoTools.FeatureExtractorInterface & DimensionalityReduction.autoTools.CombinableInterface
    %BDWEXTRACTOR A feature extractor for best daubechies wavelet coefficients (BDW)
    %   This is used to extract the best daubechies wavelet coefficients
    %   for the provided raw data.
    
    properties
        ind = [];%the indices ordering the wavelet coefficients that result from training
        m = [];  %the sum of wavelet coefficients for the ongoing training 
        n = [];  %counter
        heuristic = '';
        numFeat = [];
    end
    
    methods
        function this = BDWExtractor(varargin)
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
        
        function [this] = train(this, data)
            this.ind = [];
            % compute wavelet transformation
            wlevel = BDWExtractor.wMaxLv(size(data,2));
            % [af, df] = wfilters('db2'); Results are hardcoded below
            af = [-0.129409522550921 0.224143868041857 0.836516303737469 0.482962913144690];
            df = [-0.482962913144690 0.836516303737469 -0.224143868041857 -0.129409522550921];
            d = cell(1,wlevel);
            for i = wlevel:-1:1
                l = size(data,2)+6;
                fInd = false(1,l);
                fInd(5:2:l) = true;
                data = [data(:,[1,1,1]), data, data(:,[end, end, end])]; %#ok<AGROW>
                d{i} = filter(df, 1, data, [], 2);
                d{i} = d{i}(:,fInd);

                data = filter(af, 1, data, [], 2);
                data = data(:,fInd);
            end
            % concatenate coefficients of different levels
            data = [data, d{:}];
            
            % sum up all wavelet coefficients and store the result for
            % continued training
            if isempty(this.m)
                this.m = sum(abs(data));
                this.n = size(data,1);
            else
                this.m = this.m + sum(abs(data));
                this.n = this.n + size(data,1);
            end
        end
        
        function [feat] = apply(this,data)
            % make sure training was finished
            if isempty(this.ind)
                this.finishTraining();
            end
            
            % compute wavelet transformation
            wlevel = BDWExtractor.wMaxLv(size(data,2));
            [af, df] = wfilters('db2');

            d = cell(1,wlevel);
            for i = wlevel:-1:1
                l = size(data,2)+6;
                fInd = false(1,l);
                fInd(5:2:l) = true;
                data = [data(:,[1,1,1]), data, data(:,[end, end, end])];
                d{i} = filter(df, 1, data, [], 2);
                d{i} = d{i}(:,fInd);

                data = filter(af, 1, data, [], 2);
                data = data(:,fInd);
            end
            % concatenate coefficients of different levels
            data = [data, d{:}];
            
            feat = data(:,this.ind);
        end
        
        function this = combine(this, target)
            % combine training results of target with the results of the
            % calling object
            
            % clear previously computed coefficient order
            this.ind = [];
            
            % combine the summed up coefficients if classes match
            if strcmp(class(this),class(target))
                if isempty(this.m)
                    this.m = target.m;
                    this.n = target.n;
                else
                    this.m = this.m + target.m;
                    this.n = this.n + target.n;
                end
            else
                warning(['Classes ',class(this),' and ',class(target),...
                    ' do not match and cannot be combined']);
            end
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
    methods (Static)
        function level = wMaxLv(dataL)
            level = round(log2((dataL/3)));
        end
    end
end
