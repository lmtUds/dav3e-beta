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

function [ioStates,entries] = isIOentries(entries)
%ISIOENTRIES Checks whether the given entries fulfill tolerances
%   Detailed explanation goes here
    ioStates = true(size(entries));
    for i=1:size(entries,1)
       flag = true;
       meas = entries{i}.measurements;
       if ~strcmp(entries{i}.measurements{1}.attributes{1},'0')& ~isempty(entries{i}.measurements{1}.attributes{1})
           ioStates(i) = false;
           entries{i}.ioFlag = false;
           continue
       end
       for j = 1:size(meas,2)
           flag = and(flag,Import.QDasHelper.Helpers.isIOmeas(meas{j}));
       end
       ioStates(i) = flag;
       entries{i}.ioFlag = flag;
    end
end

