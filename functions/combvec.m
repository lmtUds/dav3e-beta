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

function combmat = combvec(varargin)
    n = numel(varargin);
    if n <= 0
        combmat = [];
        return
    end
    
    m = 1;
    numElems = [];
    for i = 1:numel(varargin)
        m = m * numel(varargin{i});
        numElems(i) = numel(varargin{i});
        varargin{i} = reshape(varargin{i},1,numElems(i));
    end
    combmat = zeros(n,m);

    for i = n:-1:1
        row = repelem(varargin{i},(m/numElems(i))/prod(numElems(i+1:n)));
        row = repmat(row,1,m/prod(numElems(1:i)));
        combmat(i,:) = row;
    end
end