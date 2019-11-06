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

classdef QDasMeasurement < handle
    %QDASMEASUREMENT Container for a single measurement value in Qdas format
    %   VALUE       states the measured value
    %   ATTRIBUTES  contains associated attributes to the measurement
    %   INFO        contains a QDasMeasurementInfo object that states boundary
    %               values and other physical context
    
    properties
        value = [];
        attributes = {};
        info = {};
        ioFlag = [];
    end
    
    methods
        function this = QDasMeasurement(asciiString, measInfo)
            this.info = measInfo;
            dc4 = '';
            [segments,~] = strsplit(asciiString,dc4,'CollapseDelimiters',false);
            this.value = str2double(segments{1});
            this.attributes = segments(2:end);
        end
        function ioState = isIO()
           if ~isempty(this.ioFlag)
               ioState = this.ioFlag;
           else
               ioState = Import.QDasHelper.Helpers.isIOmeas(this);
               this.ioFlag = ioState;
           end 
        end
    end
    
end