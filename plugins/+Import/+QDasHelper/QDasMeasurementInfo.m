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

classdef QDasMeasurementInfo < handle
    %QDASMEASUREMENTINFO contains boundary values and physical context for a QDasMeasurement object
    
    properties
        measNumber = [];
%         K2001 = [];
        interpretation = '';
        K2004 = [];
        K2022 = [];
        idealValue = [];
        lowerBound = [];
        upperBound = [];
        maxLowerDeviation = [];
        maxUpperDeviation = [];
        unit = '';
        K2060 = [];
        altIdealVal = [];
    end
    
    methods
        function this = QDasMeasurementInfo(linesDfdBLock)
            identifiers = cell(size(linesDfdBLock));
            values = cell(size(linesDfdBLock));
            for i = 1:length(linesDfdBLock)
                words = strsplit(linesDfdBLock{i}, ' ');
                identParts = strsplit(words{1}, '/');
                identifiers{i} = identParts{1};
                values{i} = strjoin(words(2:end), ' ');
            end
            
            for i = 1:length(linesDfdBLock)
                switch (identifiers{i})
                    case 'K2001' %ascending indexing for number of measurements, number
                        this.measNumber = str2double(strrep(values{i}, ',', '.'));
                    case 'K2002' %Meaning measurement value, string
                        this.interpretation = values{i};
                    case 'K2004' %Interpretation unknown
                        this.K2004 = str2double(strrep(values{i}, ',', '.'));
                    case 'K2022' %Interpretation unknown
                        this.K2022 = str2double(strrep(values{i}, ',', '.'));
                    case 'K2100' %Intended optimal value, number
                        this.idealValue = str2double(strrep(values{i}, ',', '.'));
                    case 'K2110' %Lower value bound to be considered io, number
                        this.lowerBound = str2double(strrep(values{i}, ',', '.'));
                    case 'K2111' %Upper value bound to be considered io, number
                        this.upperBound = str2double(strrep(values{i}, ',', '.'));
                    case 'K2112' %Maximum lower deviation to be considered io, number
                        this.maxLowerDeviation = str2double(strrep(values{i}, ',', '.'));
                    case 'K2113' %Maximum upper deviation to be considered io, number
                        this.maxUpperDeviation = str2double(strrep(values{i}, ',', '.'));
                    case 'K2142' %Measurement unit, string
                        this.unit = values{i};
                    case 'K2060' %Interpretation unknown, number
                        this.K2060 = str2double(strrep(values{i}, ',', '.'));
                    case 'K2101' %Alternate optimal value, number
                        this.altIdealVal = str2double(strrep(values{i}, ',', '.'));
                    otherwise
                        error(['unsuported identifier ',identifiers{i}]);
                end
            end
        end
    end
    
end

