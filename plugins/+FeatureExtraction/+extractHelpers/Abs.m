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

classdef Abs < FeatureExtraction.extractHelpers.SignalChainElementInterface
    %ABS Signal chain element that computes the magnitude of the input
    %signal
    %   This signal chain element forward the absolte value or the complex
    %   magnitude respectively to the next element.
    %   Despite of adding the ID-Suffix to the signal id this element does
    %   not provide any reports or information.
    
    properties (Constant)
        idSuffix = 'Abs'; % ID-Suffix for computing absolute value
    end
    
    methods
        function step(this, data, metaInfo)
            metaInfo('ID') = [this.idSuffix, metaInfo('ID')];
            if isempty(this.id)
                this.id = metaInfo('ID');
            end
            if ~isempty(this.next)
                data = abs(data);
                this.next.step(data, metaInfo);
            end
        end
        
        function [running, passive] = getMemory(~, metaInfo)
            varSize = metaInfo('varSize');
            passive = 0;
            running = sigLen*3*varSize;
        end
        
        function info = getFeatInfo(this, info)
            f = Factory.getFactory();
            if isempty(info)
                info = f.getFeatureInfoSet();
            end
            
            info.addProperty('SignalChainId', this.getId());
            info.addProperty('FeatureType', 'absolute');
            
            %Pass on to next element
            if ~isempty(this.next)
                info = this.next.getFeatInfo(info);
            end
        end
    end
end

