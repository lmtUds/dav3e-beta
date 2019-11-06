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

classdef PCAReconstructor < FeatureExtraction.extractHelpers.ReconstructorInterface
    %PCARECONSTRUCTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        coeff = [];
        m = [];
        dsF = [];
        sensor = [];
    end
    
    methods
        function this = PCAReconstructor(coeff, mean, dsF, sensor, target)
            if nargin > 0
                this.coeff = coeff;
                this.m = mean;
                this.dsF = dsF;
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
            
            %getPCA coefficients
            data = data - this.m;
            coeff = data * this.coeff; %#ok<PROPLC>
            
            %rconstruct data from coefficients
            recData = sum(bsxfun(@times, coeff, this.coeff), 2)'; %#ok<PROPLC>
            recData = recData + this.m;
            
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
    
end

