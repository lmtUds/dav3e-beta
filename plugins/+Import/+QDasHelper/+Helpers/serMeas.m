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

function [ serMeas ] = serMeas( measObj )
%SERMEAS Serializes the contents of a measurement object
    val = num2str(measObj.value);
    val = [strrep(val,'.',','),';'];
    ioFlag = [num2str(measObj.ioFlag),';'];
    info = [Import.QDasHelper.Helpers.serInfo(measObj.info),';'];
    
    attrs =  measObj.attributes;
    serAttr = attrs{1};
    for i=2:size(attrs,2)
        attr = attrs{i};
        if isempty(attr)
            attr=' ';
        end
        if isnumeric(attr)
            attr = num2str(attr);
            attr = strrep(attr,'.',',');
        end
        serAttr = horzcat(serAttr,';',attr);
    end
    serMeas = horzcat(val,ioFlag,info,serAttr);
end

