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

function [ serInfo ] = serInfo( infoObj )
%SERINFO Serializes contents of any Information object
    infoFields = fields(infoObj);
    datVec = cell(size(infoFields));
    for i = 1:size(infoFields,1)
        dat = eval(['infoObj.',infoFields{i}]);
        if isempty(dat)
            dat=' ';
        end
        if isnumeric(dat)
            dat = num2str(dat);
            dat = strrep(dat,'.',',');
        end
        if i== size(infoFields,1)
            datVec{i} = dat;
        else
            datVec{i} = [dat,';'];
        end
    end
    serInfo = datVec{1};
    for i=2:size(datVec,1)
        serInfo = horzcat(serInfo,datVec{i});
    end
end

