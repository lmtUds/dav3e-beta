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

function info = linearBaselineCorrection()
    info.type = DataProcessingBlockTypes.RawDataPreprocessing;
    info.caption = 'linear baseline correction';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','sampleCycles', 'value','[1,2,3]'),... 
        Parameter('shortCaption','fitCoeffs', 'value',[], 'internal',true)... 
    ];
    info.apply = @apply;
    info.train = @train;
end

function [data,paramOut] = apply(data,params)
    paramOut = struct();
    x = 1:size(data,1);
    baselines = params.fitCoeffs(:,1) .* x + params.fitCoeffs(:,2);
    data = data - baselines';
end

function params = train(data,params)
    cycles = eval(params.sampleCycles);
    y = data(cycles,:)';
    x = 1:size(y,2);
    [b,a] = quickSlope(y,x);
    params.fitCoeffs = [b,a];
end

function [b,a] = quickSlope(y, x)
    % a+b*x
    n = size(y,2);
    sumx = sum(x);
    sumy = sum(y,2);
    sumxy  = n * y * x';
    sumxsumy = sumx .* sumy;
    sumxx  = n * x * x';
    sumxsumx = sumx .* sumx;

    b = (sumxy - sumxsumy) ./ (sumxx - sumxsumx);
    if nargout == 2
       a = (sumy - b.*sumx)/n;
    end
end