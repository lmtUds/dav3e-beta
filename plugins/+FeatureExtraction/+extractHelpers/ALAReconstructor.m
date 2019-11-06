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

classdef ALAReconstructor < FeatureExtraction.extractHelpers.ReconstructorInterface
    %ALARECONSTRUCTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dsF = [];
        start = [];
        stop = [];
        sensor = [];
    end
    
    methods
        function this = ALAReconstructor(start, stop, dsFactor, sensor, target)
            if nargin > 0
                this.start = start;
                this.stop = stop;
                this.dsF = dsFactor;
                this.sensor = sensor;
                this.sensor.addNextElement(this);
            end
            if nargin > 4
                this.target = target;
            end
        end
        
        function res = getResiduals(this, cycNum)
            %get original cycle Data
            metaInfo = containers.Map('KeyType','char','ValueType','any');
            metaInfo('ID') = '';
            this.sensor.step(cycNum, metaInfo);
            data = this.originalCycle;
            
            if isempty(this.dsF)
                this.dsF = cast(round(length(data)/500), 'like', data);
            end
            
            %downsample if needed
            if ~isempty(this.dsF) && this.dsF > 0
                if isa(data, 'single')
                    data = resample(double(data), 1, this.dsF);
                else
                    data = resample(data, 1, this.dsF);
                end
            end
            
            %get fit parameter
            fitParam = zeros(1, length(this.start)*2, 'like', data);
            x = 1:cast(length(data), 'like', data);
            for i = 1:cast(length(this.start), 'like', data)
                ind = this.start(i):this.stop(i);
                [~, d] =  this.linFit(x(ind),data(ind));
                fitParam([2*i-1,2*i]) = d;
            end
            
            %reconstruct signal from fitparameters
            recData = zeros(size(data), 'like', data);
            for i = 1:length(this.start)
                ind = this.start(i):this.stop(i);
                recData(ind) = fitParam(2*i-1) + x(ind).*fitParam(2*i) - mean(x(ind))*fitParam(2*i);
            end
            
            %upsample and account for floored upsamle factors if needed
            if ~isempty(this.dsF) && this.dsF > 0
                if length(recData)*this.dsF < length(this.originalCycle)
                    usF = this.dsF + 1;
                else
                    usF = this.dsF;
                end
                if isa(recData, 'single')
                    recData = resample(double(recData), usF, 1);
                else
                    recData = resample(recData, usF, 1);
                end
                if length(recData) > length(this.originalCycle)
                    recData = recData(1:length(this.originalCycle));
                end
            end
            
            res = recData - this.originalCycle;
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
    end
    
end

