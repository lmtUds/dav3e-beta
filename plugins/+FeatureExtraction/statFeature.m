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

function info = statFeature()
    info.type = DataProcessingBlockTypes.FeatureExtraction;
    info.caption = 'Statistical Moments';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','raw', 'value',false, 'internal',true),...    
        Parameter('shortCaption','iPos', 'value',[], 'internal',true),...
        Parameter('shortCaption','x', 'value',[], 'internal',true)...
        Parameter('shortCaption','header', 'value',{}, 'internal',true)...
        Parameter('shortCaption','valueLabels', 'value',{}, 'internal',true)...
        Parameter('shortCaption','autoSegment','value',false)...
        Parameter('shortCaption','numSegments','value',int32(4))...
        ];
    info.apply = @apply;
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
    
    f = cell(1,size(pos,1));
    cap = string.empty;
    maxFeatLength=-inf;
    for i = 1:size(pos,1)
        if params.autoSegment
            feature= computeFeature(d(:,pos(i,1):pos(i,2)));
            f{i} =feature;
        else
            feature = computeFeature(d(:,pos(i,1):pos(i,2)),params.numSegments);
            f{i} = feature;
        end
        if size(feature,2)>maxFeatLength
            maxFeatLength = size(feature,2);
        end
        cap(i) = sprintf('STAT_%.2f-%.2f',x(pos(i,1)),x(pos(i,2)));
    end
    feats = nan(size(d,1),size(pos,1),maxFeatLength);
    for j=1:size(d,1)
        for i = 1:size(pos,1)
            feats(j,i,:)=f{i}(j,:);
        end
    end
    params.header = cap;
    
    valueLabels = string.empty;
    if ~params.autoSegment
        for i=1:params.numSegments
           valueLabels(end+1) = string(['statMean#' num2str(i)]); 
           valueLabels(end+1) = string(['statSdev#' num2str(i)]);
           valueLabels(end+1) = string(['statSkew#' num2str(i)]); 
           valueLabels(end+1) = string(['statKurt#' num2str(i)]);
        end
    else
        for i=1:(maxFeatLength/4)
           valueLabels(end+1) = string(['statMean#' num2str(i)]); 
           valueLabels(end+1) = string(['statSdev#' num2str(i)]);
           valueLabels(end+1) = string(['statSkew#' num2str(i)]); 
           valueLabels(end+1) = string(['statKurt#' num2str(i)]);
        end
    end
    params.valueLabels = valueLabels;
    
    if params.raw
        data = feats;
    else
        data.data = feats;
        data.featureCaptions = cap;
        data.featureSelection = true(1,numel(cap));
    end
end

function feature = computeFeature(data,segments)
    if nargin<2
        feature = FeatureExtraction.extractHelpers.StatReconstruct( data,10);
    else
        feature = FeatureExtraction.extractHelpers.StatReconstruct( data, segments);
    end
end