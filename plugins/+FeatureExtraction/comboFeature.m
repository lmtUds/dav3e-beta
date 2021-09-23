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

function info = comboFeature()
    info.type = DataProcessingBlockTypes.FeatureExtraction;
    info.caption = '9 fold combo Feature';
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
    %features in sequence
    %rms variance
    f = [rms(y,2) var(y,0,2)];
    %lin slope
    fTemp = [];
    for i = 1:size(y,1)
        [t1, ~] = polyfit(y(i,:),x,1);
        fTemp(i,:) = t1(1);
    end
    f = horzcat(f,fTemp);
    %peak pos
    fTemp = [];
    for i = 1:size(y,1)
        [~,loc]= findpeaks(y(i,:),'NPEAKS',1);
        if isempty(loc)
            loc = 1;
        end
        fTemp(i,:) = loc;
    end
    f = horzcat(f,fTemp);
    %max min kurtosis skewness peak2rms
    fTemp = [max(y,[],2) min(y,[],2) kurtosis(y,1,2)  skewness(y,1,2)  peak2rms(y,2)];
    f = horzcat(f,fTemp);
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
    
    f = nan(size(d,1),size(pos,1),9);
    cap = string.empty;
    for i = 1:size(pos,1)
        f(:,i,:) = computeFeature(...
            d(:,pos(i,1):pos(i,2)),...
            x(pos(i,1):pos(i,2)));
        cap(i) = sprintf('combo_%.2f-%.2f',x(pos(i,1)),x(pos(i,2)));
    end
    params.header = cap;
    labels = {'rms', 'variance', 'linSlope', 'peakPos', 'max', 'min', 'kurtosis', 'skewness', 'peak2rms'};
    valueLabels = string.empty;
    for i = 1:9
        valueLabels(end+1) = string(labels{i});
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