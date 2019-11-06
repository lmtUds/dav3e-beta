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

classdef ALAErrTransform < FeatureExtraction.extractHelpers.SignalChainElementInterface
    %ADAPTIVELINEARAPPROXIMATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        errors = [];
        start = [];
        stop = [];
    end
    
    properties (Constant)
        idSuffix = 'ALAErrMat';
    end
    
    methods
        function step (this, data, metaInfo)
            metaInfo('ID') = [this.idSuffix, metaInfo('ID')];
            if isempty(this.id)
                this.id = metaInfo('ID');
            end
            
            if length(data) > 500
                data = data(1:500);
                %error('Downsample data before using ErrTransform.');
            end
            
            if isKey(metaInfo, 'Training') && metaInfo('Training')
                if ~isempty(this.next)
                    if isa(data, 'gpuArray')
                        data = gather(data);
                    end
                    if length(data) > 500
                        error('Downsample data before using ErrTransform.');
                    end
                    errMat = FeatureExtraction.extractHelpers.errMatTransformFast_mex(data);
                    this.next.step(errMat, metaInfo);
                end
            elseif ~isempty(this.next)
                this.next.step(data, metaInfo);
            end
        end
    end
    
    methods (Access = protected)
        function errMat = errMatTransform(~,data)
            errMat = zeros(1, sum(1:(length(data)-1)), 'like', data);
            l = cast(length(data), 'like', data);
            indRunning = cast(1, 'like', l);
            %iterate over start-points
            for i = 1:l
                sumX = i;
                sumXX = i^2;
                sumY = data(i);
                sumXY = i * data(i);
                %iterate over stop-points
                for j = i+1:l
                    sumX = sumX + j;
                    sumXX = sumXX + j^2;
                    sumY = sumY + data(j);
                    sumXY = sumXY + j*data(j);
                    num = j-i+1;
                    f = -1/num;
                    
                    b = (sumXY + f*sumY*sumX)/(sumXX + f*sumX^2);
%                     a = sum(data(i:j))/(j-i+1) - sum(i:j)/(j-i+1)*b;
%                     %a = mean(y) - b*mean(t);
%                     errMat(indRunning) = sum((b*(i:j) + a - data(i:j)).^2);
                    
                    temp = b*(i:j) - data(i:j);
                    m = sum(temp)/(j-i+1);
                    errMat(indRunning) = sum((temp-m).^2);
                    indRunning = indRunning + 1;
                end
            end
        end
        
        function [running, passive] = getMemory(this, metaInfo)
            varSize = metaInfo('varSize');
            passive = (numel(this.errors)+numel(this.sarts)+numel(this.ends)*verSize);
            running = (numel(this.errors)+5*this.stop(end))*varSize+passive;
        end
    end
end

