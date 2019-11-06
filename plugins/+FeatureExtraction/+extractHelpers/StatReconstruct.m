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

function features = StatReconstruct( data, numSegments )
%STATRECONSTRUCT get the statistical features of data split into numSegments Segments
%   Detailed explanation goes here
segmentSz = floor(size(data,2)/double(numSegments));
features=zeros(size(data,1),numSegments*4);
for i=1:numSegments
    for j=1:size(data,1)
        features(j,(i-1)*4+1)=mean(data(j,(i-1)*segmentSz+1:(i-1)*segmentSz+segmentSz));
        features(j,(i-1)*4+2)=std(data(j,(i-1)*segmentSz+1:(i-1)*segmentSz+segmentSz));
        features(j,(i-1)*4+3)=skewness(data(j,(i-1)*segmentSz+1:(i-1)*segmentSz+segmentSz));
        features(j,(i-1)*4+4)=kurtosis(data(j,(i-1)*segmentSz+1:(i-1)*segmentSz+segmentSz));
    end
end

end

