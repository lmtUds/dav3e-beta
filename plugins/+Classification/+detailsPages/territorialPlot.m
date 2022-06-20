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

function updateFun = territorialPlot(parent,project,dataprocessingblock)
    populateGui(parent,project,dataprocessingblock);
    updateFun = @()populateGui(parent,project,dataprocessingblock);
end

function populateGui(parent,project,dataprocessingblock)
    dataParam = dataprocessingblock.parameters.getByCaption('inputData');
    if isempty(dataParam)
        return
    end
    trainData = dataParam.getValue().training;
    dims = 1:size(trainData,2);
    if numel(dims) ~= 2
        warning('Territorial plot only available for 2D.')
        return
    end
%     if numel(dims) > 2
%         warning('Showing only first two of %d dimensions.',size(data.training,2));
%         dims = dims(1:3);
%     end

    groupingCaption = project.currentModel.fullModelData.groupingCaption;
    groupingObj = project.getGroupingByCaption(groupingCaption);
    groupingColors = groupingObj.getColors();
    if isfield(dataParam.getValue(),'testing')
        testData = dataParam.getValue().testing;
    else
        testData = [];
    end

    mins = min([trainData;testData],[],1);
    maxs = max([trainData;testData],[],1);
    diffs = diff([mins;maxs],[],1);
    mins = mins - 0.1*diffs;
    maxs = maxs + 0.1*diffs;
    res = 250;
    baseVecX = linspace(mins(1),maxs(1),res)';
    baseVecY = linspace(mins(2),maxs(2),res)';
    gridData = [repmat(baseVecX,res,1), repelem(baseVecY,res)];
    classifier = dataprocessingblock.parameters.getByCaption('classifier').getValue();
    p = classifier.predict(gridData);
    cats = unique(deStar(p));
    p = reshape(p,res,res);
    
    delete(parent.Children)
    
    ax = uiaxes(parent);
    ax.Layout.Row = 1;
    ax.Layout.Column = 1;
    xlabel(ax,'DF1'); ylabel(ax,'DF2');
    hold(ax,'on');
    for i = 1:numel(cats)
        bin = p==cats(i);
        bin = padarray(bin,[1,1]);
%         e = edge(bin,'Prewitt');
        e = conv2(double(~bin),ones(3),'same') & bin;
        cc = bwconncomp(e);
%         cc.PixelIdxList
        for j = 1:numel(cc.PixelIdxList)
            if numel(cc.PixelIdxList{j}) < 10
%                 disp('continue')
                continue
            end
            [x,y] = ind2sub(size(bin),cc.PixelIdxList{j});
%             if any(all([x,y]==[91,14],2))
%                 a=1;
%             end
            x2 = x(1); y2 = y(1);
            x(1) = []; y(1) = [];
            while true
                while true
                    if isempty(x)
                        break;
                    end
                    edgePoint = [x2(end),y2(end)];
                    dists = sum(([x,y] - edgePoint).^2,2);
                    distStart = sum(([x2(1),y2(1)] - edgePoint).^2,2);
                    [minDist,idx] = min(dists);
%                     if minDist > 5
%                         x2 = []; y2 = [];
%                         break;
%                     end
                    if (numel(x2)) > 2 && (distStart <= minDist)
                        break;
                    end
                    if minDist < 100
                        x2(end+1) = x(idx); y2(end+1) = y(idx);
                    end
                    x(idx) = []; y(idx) = [];
                end
                if ~isempty(x2)
                    if numel(x2) > 50
                        x2 = x2(1:2:end);
                        y2 = y2(1:2:end);
                    end
                    u = baseVecX(x2-1);
                    v = baseVecY(y2-1);
                    ptch = patch(ax,u,v,'red');
                    try
                        ptch.FaceColor = groupingColors(char(cats(i)));
                    catch
                        ptch.FaceColor = groupingColors(char(num2str(cats(i))));
                    end
                end
                if isempty(x)
                    break;
                end
                x2 = x(1); y2 = y(1);
                x(1) = []; y(1) = [];
            end
        end
    end
    
    h = plot(ax,trainData(:,1),trainData(:,2),'ok');
    h.MarkerSize = 3;
    h.MarkerFaceColor = 'k';
    if ~isempty(testData)
        h = plot(ax,testData(:,1),testData(:,2),'ok');
        h.MarkerSize = 3;
        h.MarkerFaceColor = 'w';
    end
    
    hold(ax,'off');
    xlim(ax,[mins(1),maxs(1)]);
    ylim(ax,[mins(2),maxs(2)]);
end