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

classdef QDasEntryInfo < handle
    %QDASENTRYINFO contains general information for a QDasEntry object
    
    properties
        filename = {};
        K0100 = [];
        typeNum = [];
        typeString = {};
        earlyDate = {};
        K1053 = {};
        process = {};
        prodStepPre = {};
        prodDesc = {};
        prodStepSuf = {};
        K1103 = {};
        lateDate = {};
        prodLocation = {};
        personID = {};
        K1005 = {};
        altLoc = {};
        module = {};
    end
    
    methods
        function this = QDasEntryInfo(linesDfdBlock,filename)
            this.filename = filename;
            identifiers = cell(size(linesDfdBlock));
            values = cell(size(linesDfdBlock));
            for i = 1:length(linesDfdBlock)
                words = strsplit(linesDfdBlock{i}, ' ');
                splitPoint = strfind(linesDfdBlock{i}, ' ');
                splitPoint = splitPoint(1);
                identifiers{i} = linesDfdBlock{i}(1:splitPoint-1);
                values{i} = linesDfdBlock{i}(splitPoint+1:end);
%                 identifiers{i} = words{1};
%                 values{i} = words{2:end};
            end
            
            for i = 1:length(linesDfdBlock)
                switch (identifiers{i})
                    case 'K0100' %Interpretation unknown, number
                        this.K0100 = str2double(strrep(values{i}, ',', '.'));
                    case 'K1001' %Type number, number
                        this.typeNum = str2double(strrep(values{i}, ',', '.'));
                    case 'K1002' %Type string, string
                        this.typeString = values{i};
                    case 'K1004' %Early date, date string
                        this.earlyDate = values{i};
                    case 'K1053' %Interpretation unknown, zero prefix number
                        this.K1053 = values{i};
                    case 'K1081' %Process, string
                        this.process = values{i};
                    case 'K1082' %Production step prefix, string
                        this.prodStepPre = values{i};
                    case 'K1086' %Production description, string
                        this.prodDesc = values{i};
                    case 'K1100' %Production step suffix, string
                        this.prodStepSuf = values{i};
                    case 'K1103' %Interpretation unknown, string
                        this.K1103 = values{i};
                    case 'K1104' %Late date, date string
                        this.lateDate = values{i};
                    case 'K1303' %Production location, string  
                        this.prodLocation = values{i};
                    case 'K1222' %A persons Name or identifier, string
                        this.personID = values{i};
                    case 'K1005' %Interpretation unknown, string
                        this.K1005 = values{i};
                    case 'K1102' %Alternate location, string
                        this.altLoc = values{i};
                    case 'K1206' %Machine/Module, string
                        this.module = values{i};
                    otherwise
                        error(['unsuported identifier ',identifiers{i}]);
                end
            end
        end
    end
end