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

classdef BooleanFlagSelector < FeatureExtraction.extractHelpers.SignalChainElementInterface
    %BOOLEANFLAGSELECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        val = [];
        name = '';
    end
    
    properties (Constant)
        idSuffix = 'FlagSel';
    end
    
    methods
        function this = BooleanFlagSelector(name, val)
            if nargin > 0
                this.val = val;
                this.name = name;
            end
        end
        
        function step(this, data, metaInfo)
            metaInfo('ID') = [this.idSuffix, metaInfo('ID')];
            if isempty(this.id)
                this.id = metaInfo('ID');
            end
            if isKey(metaInfo, this.name) && metaInfo(this.name) == this.val
                this.next.step(data, metaInfo);
            end
        end
        
        function ind = getUsedCycles(this, ind, metaInfo)
            if isKey(metaInfo, this.name) && metaInfo(this.name) == this.val
                ind = this.next.getUsedCycles(ind, metaInfo);
            else
                ind(:) = false;
            end
        end
        
        function info = getFeatureInfo(this, info)
            if isempty(info)
                f = FeatureExtraction.extractHelpers.Factory.getFactory();
                info = f.getFeatureInfoSet();
            end
            
            if info.isProperty('BoolFlagName')
                n = info.getProperty('BoolFlagName');
                n = n{1};
                v = info.getProperty('BoolFlagValue');
                v = v{1};
                n = horzcat(n{:}, this.name);
                v = horzcat(v{:}, this.val);
            else
                n = {this.name};
                v = {this.val};
            end
            info.addProperty('BoolFlagName', n);
            info.addProperty('BoolFlagValue', v);
            info.addProperty('SignalChainId', this.getId());
            
            %Pass on to next element
            if ~isempty(this.next)
                info = this.next.getFeatInfo(info);
            end
        end
    end
    
end

