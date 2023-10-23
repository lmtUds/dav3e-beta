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

function info = polyfitFeature()
    info.type = DataProcessingBlockTypes.FeatureExtraction;
    info.caption = 'polyfit';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','raw', 'value',false, 'internal',true),...    
        Parameter('shortCaption','iPos', 'value',[], 'internal',true),...
        Parameter('shortCaption','x', 'value',[], 'internal',true)...
        Parameter('shortCaption','header', 'value',{}, 'internal',true)...
        Parameter('shortCaption','valueLabels', 'value',{}, 'internal',true)...
        Parameter('shortCaption','order', 'value',1)...
        Parameter('shortCaption','includeOffset', 'value',false)...
        ];
    info.apply = @apply;
end

function f = computeFeature(y,x,prm)
    if prm.order == 1
        if prm.includeOffset
            [b,a] = quickSlope(y,x);
            f = [a,b];
        else
            f = quickSlope(y,x);
        end
    else
        f = zeros(size(y,1),prm.order+1);
        for i = 1:size(y,1)
            f(i,:) = polyfit(x,y(i,:),prm.order);
        end
        if ~(prm.includeOffset)
            f(:,1) = [];
        end
    end
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

function [data,params] = apply(data,params)
    if params.raw
        d = data;
    else
        d = data.data;
        x = data.abscissa;
    end    
    
    if ~isempty(params.iPos)
        pos = params.iPos;
    else
        pos = 1:size(d,2);
    end

    if ~exist('x','var')
        x = params.x;
    end
    
    f = nan(size(d,1),size(pos,1),params.order+params.includeOffset);
    cap = string.empty;
    for i = 1:size(pos,1)
        f(:,i,:) = computeFeature(...
            d(:,pos(i,1):pos(i,2)),...
            x(pos(i,1):pos(i,2)),...
            params);
        cap(i) = sprintf('polyfit_%.2f-%.2f',x(pos(i,1)),x(pos(i,2)));
    end
    params.header = cap;
    
    valueLabels = string.empty;
    if params.includeOffset
        valueLabels = string('offset');
    end
    for i = 1:params.order
        valueLabels(end+1) = string(['coeff#' num2str(i)]);
    end
    params.valueLabels = valueLabels;
    
    if params.raw
        data = f;
    else
        data.data = f;
        data.featureCaptions = cap;
        data.featureSelection = true(1,numel(cap));
    end
end