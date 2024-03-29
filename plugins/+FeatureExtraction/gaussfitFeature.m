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

function info = gaussfitFeature()
    info.type = DataProcessingBlockTypes.FeatureExtraction;
    info.caption = 'gaussfit';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','raw', 'value',false, 'internal',true),...    
        Parameter('shortCaption','iPos', 'value',[], 'internal',true),...
        Parameter('shortCaption','x', 'value',[], 'internal',true)...
        Parameter('shortCaption','header', 'value',{}, 'internal',true)...
        Parameter('shortCaption','valueLabels', 'value',{}, 'internal',true)...
        ];
    info.apply = @apply;
end

function f = computeFeature(y,x,prm)
    f = zeros(size(y,1),3);
    for i = 1:size(y,1)
        try
            ft = fit(x',y(i,:)','gauss1',...
                'lower',[0,x(1),0], 'upper',[inf,x(2),inf]);
            f(i,:) = [ft.a1,ft.b1,ft.c1];
        catch
            warning('Could not fit.')
            f(i,:) = nan;
        end
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
    
    f = nan(size(d,1),size(pos,1),3);
    cap = string.empty;
    for i = 1:size(pos,1)
        f(:,i,:) = computeFeature(...
            d(:,pos(i,1):pos(i,2)),...
            x(pos(i,1):pos(i,2)),...
            params);
        cap(i) = sprintf('gaussfit_%.2f-%.2f',x(pos(i,1)),x(pos(i,2)));
    end
    params.header = cap;
    
    valueLabels = [string('a'),string('b'),string('c')];
    params.valueLabels = valueLabels;
    
    if params.raw
        data = f;
    else
        data.data = f;
        data.featureCaptions = cap;
        data.featureSelection = true(1,numel(cap));
    end
end