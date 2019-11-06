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

classdef WaveletTransform < FeatureExtraction.extractHelpers.SignalChainElementInterface
    %WAVELETTRANSFORM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        wlevel = [];
        df = [];
        af = [];
        l = [];
    end
    
    properties (Constant)
        idSuffix = 'DWT';
    end
    
    methods
        function step(this, data, metaInfo)
            metaInfo('ID') = [this.idSuffix, metaInfo('ID')];
            if isempty(this.id)
                this.id = metaInfo('ID');
            end
            
            if isempty(this.wlevel) || isempty(this.af)
                this.wlevel = wmaxlev(length(data), 'db2');
                [this.af, this.df] = wfilters('db2');
                if isa(data, 'gpuArray')
                    this.af = gpuArray(this.af);
                    this.df = gpuArray(this.df);
                end
            end
            
            if ~isempty(this.next)
                %perform wavelet transform
                d = cell(1,this.wlevel);
                if isa(data, 'gpuArray')
                    for i = this.wlevel:-1:1
                        l = length(data)+6;
                        ind = false(1,l, 'gpuArray');
                        ind(gpuArray.colon(5, 2, l)) = true;
                        data = [data([1,1,1]), data, data([end, end, end])];%[data, zeros(1, del)];
                        d{i} = filter(this.df, 1, data);
                        d{i} = d{i}(ind);

                        data = filter(this.af, 1, data);
                        data = data(ind);
                    end
                else
                    for i = this.wlevel:-1:1
                        l = length(data)+6;
                        ind = false(1,l);
                        ind(5:2:l) = true;
                        data = [data([1,1,1]), data, data([end, end, end])];%[data, zeros(1, del)];
                        d{i} = filter(this.df, 1, data);
                        d{i} = d{i}(ind);

                        data = filter(this.af, 1, data);
                        data = data(ind);
                    end
                end

                %data = wavedec(data, wmaxlev(length(data),'db2'), 'db2');
                data = [data, d{:}];
                this.next.step(data, metaInfo);
                this.l = length(data);
            end
        end
        
        function info = getFeatInfo(this, info)
            f = FeatureExtraction.extractHelpers.Factory.getFactory();
            if isempty(info)
                info = f.getFeatureInfoSet();
            end
            
            n = info.getNumFeat();
            this.wlevel = wmaxlev(n, 'db2');
            [d, L] = wavedec(ones(1,n), this.wlevel, 'db2');
            
            wLevel = cell(1, length(L)-1);
            for i = 1:length(wLevel)
                wLevel{i} = repmat({this.wlevel-i+1}, 1, L(i));
            end
            
            %keep general info
            info.removeProperty('MeasurementPoint');
            infoNew = f.getFeatureInfoSet();
            names = info.getPropertyName();
            for i = 1:length(names)
                val = info.getProperty(names{i});
                infoNew.addProperty(names{i}, repmat(val{1}, 1, length(d)));
            end
            
            info.addProperty('WaveletLevel', horzcat(wLevel{:}));
            info.addProperty('SignalChainId', this.getId());
            info.addProperty('CoefficientNumber', num2cell(1:length(d)));
            info.addProperty('WaveletTransform', true);
            val = info.getProperty('Sensor');
            info.addProperty('Sensor', val{1});
            
            %Pass on to next element
            if ~isempty(this.next)
                info = this.next.getFeatInfo(info);
            end
        end
    end
end

