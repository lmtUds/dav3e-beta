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
        Parameter('shortCaption','deleteCycleIfExceeded', 'value',true)...
    ];
    info.apply = @apply;
end

function [data,params] = apply(data,params)
    max_values = params.maxNaNValuesInCycle;
    cycle_with_nan = find(sum(isnan(data'))>0);
    for i=cycle_with_nan
        if sum(isnan(data(i,:))) > max_values
            if params.deleteCycleIfExceeded
                data(i,:) = nan(size(data(i,:)));
                warning('backtrace','off');
                warning(['Preprocessing: could not interpolate nan values in cycle ', num2str(i), ' (cycle has more nan values than desired); it got replaced by a complete nan cycle.']);
                warning('backtrace','on');
            else
                warning('backtrace','off');
                warning(['Preprocessing: could not interpolate nan values in cycle ', num2str(i), ' (cycle has more nan values than desired); remains as is.']);
                warning('backtrace','on');
            end
        else
            data(i,:) = fillmissing(data(i,:),'linear');
        end
    end
%     sum(sum(isnan(data)))
end