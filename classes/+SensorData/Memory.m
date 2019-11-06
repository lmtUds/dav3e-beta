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

classdef Memory
    properties (SetAccess=private)
        data
        nRows
        nColumns
    end
    
    methods
        function obj = Memory(data) %Memory(data,nRows,nColumns)
            %d = data(:);
            obj.nRows = size(data,1);
            obj.nColumns = size(data,2);
            obj.data = data;
        end
        
        function s = getMemorySize(obj)
            d = obj.data;
            w = whos('d');
            s = w.bytes;
        end
        
        function reset(obj)
            %
        end
        
        function [data,n] = getNextPart(obj)
            data = obj.data;
            n = 1;
        end
        
        function data = getPart(obj,n)
            data = obj.data;
        end
        
        function val = hasNextPart(obj)
            val = false;
        end
        
        function [n,idx] = parts(obj)
            n = 1;
            idx = [1,size(obj.data,1)];
        end

        function loadToMemory(obj)
            %
        end
        
        function unloadFromMemory(obj)
            %
        end
        
        function r = getRow(obj,idx)
            r = obj.data(idx,:);
        end
        
        function c = getColumn(obj,idx)
            c = obj.data(:,idx);
        end
    end
end