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

function [ioState] = isIOmeas(measurement)
%ISIOMEAS Check if a measurement is within tolerances
        info = measurement.info;
        val = measurement.value;
        idealValue = info.idealValue;
        lowerBound = info.lowerBound;
        upperBound = info.upperBound;
        maxLowerDeviation = info.maxLowerDeviation;
        maxUpperDeviation = info.maxUpperDeviation;
        altIdealVal = info.altIdealVal;
        if ~isempty(upperBound)& ~isempty(lowerBound)
            ioState = val >= lowerBound & val<=upperBound;
        elseif ~isempty(idealValue)& ~isempty(maxLowerDeviation)& ~isempty(maxUpperDeviation)
            ioState = val >= idealValue+maxLowerDeviation & val <= idealValue+maxUpperDeviation;
        elseif ~isempty(altIdealVal)& ~isempty(maxLowerDeviation)& ~isempty(maxUpperDeviation)
            ioState = val >= altIdealVal+maxLowerDeviation & val <= altIdealVal+maxUpperDeviation;
        else
            ioState = true;
%             warning('Insufficient tolerances specified. IO state set to true.');
        end
        measurement.ioFlag = ioState;
end

