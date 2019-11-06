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

classdef ALADownsampler < FeatureExtraction.extractHelpers.SignalChainElementInterface
    %ALADOWNSAMPLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dsFactor = [];
        filter = [];
        downsampleIndices = [];
        delay = [];
        l = [];
    end
    
    properties (Constant)
        idSuffix = 'Ds';
        %Intended signal Length after downsampling
        intendedLength = 500;
    end
    
    methods
        function step(this, data, metaInfo)
            metaInfo('ID') = [this.idSuffix, metaInfo('ID')];
            if isempty(this.id)
                this.id = metaInfo('ID');
            end
            
            if isempty(this.l)
                this.l = cast(length(data), 'like', data);
                this.dsFactor = cast(round(this.l/this.intendedLength), 'like', data);
                if isa(data, 'gpuArray')
                    this.l = cast(length(data), classUnderlying(data));
                    this.dsFactor = cast(round(this.l/this.intendedLength), classUnderlying(data));
                    [~, this.filter] = resample(ones(size(data)), 1, double(this.dsFactor));
                    this.filter = cast(this.filter, classUnderlying(data));
                    this.delay = gpuArray(cast(mean(grpdelay(this.filter,1)), classUnderlying(data)));
                    this.filter = gpuArray(this.filter);
                    this.downsampleIndices = this.delay+1:this.dsFactor:size(data,2)+this.delay;
                    this.dsFactor = gpuArray(cast(this.dsFactor, classUnderlying(data)));
                end
            end
            
            if ~isempty(this.next)
                if length(data) > this.intendedLength
                    if isempty(this.filter)
                        if isa(data, 'single')
                            this.next.step(single(resample(double(data), 1, this.dsFactor)), metaInfo);
                        else
                            this.next.step(resample(data, 1, this.dsFactor), metaInfo);
                        end
                    else
                        %data = filter(this.filter, 1, [data, gpuArray.zeros(1, this.delay, classUnderlying(data))]); %#ok<CPROPLC>
                        data = data(this.downsampleIndices);
                        this.next.step(data, metaInfo);
                    end
                elseif ~isempty(this.next)
                    this.next.step(data, metaInfo);
                end
            end
        end
        
        
        function [running, passive] = getMemory(~, metaInfo)
            varSize = metaInfo('varSize');
            passive = (numel(this.dsFactor)+numel(this.filter)+numel(this.downsampleIndices)+numel(this.l)+numel(this.delay))*varSize;
            running = (this.dsFactor+1)*numel(this.downsampleIndices)*varSize+passive;
        end
        
        function info = getFeatInfo(this, info)
            f = FeatureExtraction.extractHelpers.Factory.getFactory();
            if isempty(info)
                info = f.getFeatureInfoSet();
            end
            
            if isempty(this.dsFactor)
                n = info.getNumFeat();
                this.dsFactor = round(n/this.intendedLength);
            end
            
            if ~isempty(this.dsFactor)
                n = info.getNumFeat();
                %keep properties
                info.removeFeature(n/this.dsFactor+1:info.getNumFeat());
                
                %add downsampling infos
                info.addProperty('Downsampling', true);
                info.addProperty('DownsamplingFactor', this.dsFactor);
                info.addProperty('SignalChainId', this.getId());
                %info.addProperty('MeasurementPoint', num2cell(1:n/this.dsFactor));
            end
            info.addProperty('SignalChainId', this.getId());
            
            %Pass on to next element
            if ~isempty(this.next)
                info = this.next.getFeatInfo(info);
            end
        end
    end
    
end

