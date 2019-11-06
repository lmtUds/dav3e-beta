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

classdef Binary < handle
    properties (SetAccess=private)
        file
        data
        nRows
        nColumns
        inMemory
        format = 'double';
        iteration
    end
    properties(SetAccess=private,Transient)
        memoryMap
    end
    
    methods
        function obj = Binary(file,nRows,nColumns)
            obj.memoryMap = memmapfile(file,'Format',{'double',[nRows nColumns 1],'data'});
            obj.file = file;
            obj.nRows = nRows;
            obj.nColumns = nColumns;
            obj.inMemory = false;
            
            obj.iteration.currentPart = 0;
            obj.iteration.maxPart = 0;
            obj.iteration.idxs = [];
        end
        
        function s = getMemorySize(obj)
            switch obj.format
                case 'double'
                    bytes = 8;
                otherwise
                    error('undefined format');
            end
            s = obj.nRows * obj.nColumns * bytes;
        end
        
        function reset(obj)
            [n,idx] = obj.parts();
            obj.iteration.currentPart = 0;
            obj.iteration.maxPart = n;
            obj.iteration.idxs = idx;
        end
        
        function [data,n] = getNextPart(obj)
            if ~obj.hasNextPart()
                error('No next part available. Try reset().');
            end
            obj.iteration.currentPart = obj.iteration.currentPart + 1;
            n = obj.iteration.currentPart;
            data = obj.getPart(n);
        end
        
        function data = getPart(obj,n)
            idx = obj.iteration.idxs(n,:);
            data = obj.getRow(idx(1):idx(2));
        end
        
        function val = hasNextPart(obj)
            val = obj.iteration.currentPart < obj.iteration.maxPart;
        end
        
        function [n,idx] = parts(obj)
            m = memory;
            availMem = m.MaxPossibleArrayBytes * 0.8;
            n = ceil(obj.getMemorySize() / availMem);
            
            if nargout >= 2
                idx = round(linspace(1,obj.nRows,n+1))';
                idx = [idx(1:end-1),idx(2:end)-1];
                idx(end) = obj.nRows;
            end
        end
        
        function loadToMemory(obj)
            [n,idx] = obj.parts();
            if n > 1
                obj.unloadFromMemory();
                error('Cannot load multi-part objects into memory.');
            end
            obj.data = obj.memoryMap.Data.data(idx(1,1):idx(1,2));
            obj.inMemory = true;
        end
        
        function unloadFromMemory(obj)
            obj.data = [];
            obj.inMemory = false;
        end
        
        function r = getRow(obj,idx)
            if obj.inMemory
                r = obj.data(idx,:);
            else
                r = obj.memoryMap.Data.data(idx,:);
            end
        end
        
        function c = getColumn(obj,idx)
            if obj.inMemory
                c = obj.data(:,idx);
            else
                c = obj.memoryMap.Data.data(:,idx);
            end
        end
    end
    
    methods(Static)
        function obj = loadobj(obj)
            obj.memoryMap = memmapfile(obj.file,'Format',{'double',[obj.nRows obj.nColumns 1],'data'});
            if obj.inMemory
                obj.loadToMemory();
            end
        end
    end
end