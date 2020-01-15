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

function info = differentiate()
    info.type = DataProcessingBlockTypes.RawDataPreprocessing;
    info.caption = 'differentiate';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','framelength', 'value',int32(5)),... %must be odd
        Parameter('shortCaption','timebase', 'value',0.01),... %or 0.3 for SniffChecker
%         Parameter('shortCaption','filtertype', 'ARRAY?:step/gaussian','1'),... 
    ];
    info.apply = @apply;
end

function [data,paramOut] = apply(data,params)
    paramOut = struct();
    m = (params.framelength-1)/2;
    t = params.timebase;
    tm = ((1:size(data,1))-1)*t;
    h = [ones(m,1)',0,-ones(m,1)']/double(m)/t;
    temp = nan(size(data));
    temp((m+1):end-(m),:) = convn(data',h,'valid')'./mean(conv(tm',h,'valid'));
    data = temp;
end