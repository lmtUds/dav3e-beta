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

function info = interpolateNaN()
    info.type = DataProcessingBlockTypes.RawDataPreprocessing;
    info.caption = 'interpolate nan values';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','maxNaNValuesInCycle', 'value',int32(100)),... 
    ];
    info.apply = @apply;
end

function [data,params] = apply(data,params)
    max_values = params.maxNaNValuesInCycle;
    cycle_with_nan = find(sum(isnan(data'))>0);
    for i=1:length(cycle_with_nan)
        if sum(isnan(data(i,:))) > max_values
           warning(['nan cycle: ', i])
        end
        data(cycle_with_nan(i),:) = fillmissing(data(cycle_with_nan(i),:),'linear');
    end
    sum(sum(isnan(data)))
    

end