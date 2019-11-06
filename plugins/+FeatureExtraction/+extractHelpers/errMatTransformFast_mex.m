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

function errMat = errMatTransformFast_mex( data )
%ERRMATTRANSFORMFAST Summary of this function goes here
%   Detailed explanation goes here
    l = length(data);
    errMat = zeros(1, (l*(l-1)/2));
    indRunning = 1;
    %iterate over start-points
    for i = 1:l
        sumX = i;
        sumXX = i^2;
        sumY = data(i);
        sumYY = data(i)^2;
        sumXY = i * data(i);
        %iterate over stop-points
        for j = i+1:l
            sumX = sumX + j;
            sumXX = sumXX + j^2;
            sumY = sumY + data(j);
            sumYY = sumYY + data(j)^2;
            sumXY = sumXY + j*data(j);
            num = j-i+1;
            f = -1/num;
            
            p1 = sumXX - sumX^2/num;
            p2 = 2*sumX*sumY/num - 2*sumXY;
            p3 = sumYY - sumY^2/num;
            b = (sumXY - sumX*sumY/num)/(sumXX - sumX^2/num);
            errMat(indRunning) = p1*b^2+p2*b+p3;
            
            indRunning = indRunning + 1;
        end
    end
end

