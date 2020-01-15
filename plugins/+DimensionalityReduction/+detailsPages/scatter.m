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

function [panel,updateFun] = scatter(parent,project,dataprocessingblock)
    [panel,elements] = makeGui(parent);
    populateGui(elements,project,dataprocessingblock);
    updateFun = @()populateGui(elements,project,dataprocessingblock);
end

function [panel,elements] = makeGui(parent)
    panel = uipanel(parent);
    layout = uiextras.VBox('Parent',panel);
    panel2 = uipanel(layout,'BorderType','none');
    hAx = axes(panel2); title('');
    xlabel('DF1'); ylabel('DF2');
    box on,
    set(gca,'LooseInset',get(gca,'TightInset')) % https://undocumentedmatlab.com/blog/axes-looseinset-property
    elements.hAx = hAx;
    spinButton = uicontrol(layout, 'String','spin','Callback',@(varargin)spinAxes(hAx));
    elements.spinButton = spinButton;
    layout.Sizes = [-1,20];
end

function populateGui(elements,project,dataprocessingblock)
    cla(elements.hAx,'reset');
    dataParam = dataprocessingblock.parameters.getByCaption('projectedData');
    if isempty(dataParam)
        return
    end
    cumEnergy = dataprocessingblock.parameters.getByCaption('cumEnergy').getValue();
    groupingCaption = project.currentModel.fullModelData.groupingCaption;
    groupingObj = project.getGroupingByCaption(groupingCaption);
    groupingColors = groupingObj.getColors();
    trainGrouping = deStar(categorical(tryCat2num(project.currentModel.fullModelData.getSelectedGrouping('training',groupingCaption))));
    trainData = dataParam.getValue().training;
    if isfield(dataParam.getValue(),'testing')
        testData = dataParam.getValue().testing;
    else
        testData = [];
    end
    testGrouping = deStar(categorical(tryCat2num(project.currentModel.fullModelData.getSelectedGrouping('testing',groupingCaption))));
    dims = 1:size(trainData,2);
    if numel(dims) > 3
        warning('Showing only first three of %d dimensions.',numel(dims));
        dims = dims(1:3);
    end
    
    [h1,c1] = scatterPlot(elements.hAx,trainData,trainGrouping,dims,groupingColors);
    [h2,c2] = scatterPlot(elements.hAx,testData,testGrouping,dims,groupingColors);
%     h2.MarkerStyle = '^';
    set(h2,'Marker','^'); 
    c2 = c2 + string(' (testing)');
%     set(h2,'LineWidth',2);
    if numel(dims) == 2
        set(h1,'MarkerFaceAlpha',0.7);
    end
    if numel(dims) == 3
        grid(elements.hAx,'on');
        zlabel(elements.hAx,sprintf('DF3 (%0.1f %%)',100*cumEnergy(3)));
        set(elements.hAx,'View',[37.5,30]);
    end
    xlabel(elements.hAx,sprintf('DF1 (%0.1f %%)',100*cumEnergy(1)));
    ylabel(elements.hAx,sprintf('DF2 (%0.1f %%)',100*cumEnergy(2)));
    legend(elements.hAx,[h1,h2],[c1,c2]);

%     p1 = trainData(1:end-1,:);
%     p2 = trainData(2:end,:);
%     x = [trainData(1:end-1,1),trainData(2:end,1)];
%     y = [trainData(1:end-1,2),trainData(2:end,2)];
%     hold(elements.hAx,'on');
%     plot(x,y,'-k','LineWidth',0.5);
end

function [handles,captions] = scatterPlot(hAx,data,grouping,dims,groupingColors)
    handles = [];
    captions = string.empty;
    hold(hAx,'on');
    cats = categories(grouping);
    for i = 1:numel(cats)
        idx = grouping == cats{i};
        if numel(dims) == 1
            p = scatter(hAx,data(idx,dims),zeros(sum(idx),1),50,'filled');
        elseif numel(dims) == 2
            p = scatter(hAx,data(idx,dims(1)),data(idx,dims(2)),50,'filled');
        elseif numel(dims) == 3
            grid(hAx,'on');
            p = scatter3(hAx,data(idx,dims(1)),data(idx,dims(2)),data(idx,dims(3)),50,'filled');
            centroid = mean(data(idx,dims),1);
            l = plot3(hAx,centroid(1)*[1,1],centroid(2)*[1,1],[-1000,1000],'--','Color',groupingColors(cats{i}));
            l(2) = plot3(hAx,centroid(1)*[1,1],[-1000,1000],centroid(3)*[1,1],'--','Color',groupingColors(cats{i}));
            l(3) = plot3(hAx,[-1000,1000],centroid(2)*[1,1],centroid(3)*[1,1],'--','Color',groupingColors(cats{i}));
            set(l,'XLimInclude','off','YLimInclude','off','ZLimInclude','off');
        else
            error('Expected one, two, or three dimensions.');
        end
        
        if isempty(handles)
            handles = p;
            captions = string(cats{i});
        else
            handles(end+1) = p;
            captions(end+1) = cats{i};
        end
        set(p,'MarkerFaceColor',groupingColors(cats{i}),...
              'MarkerEdgeColor',groupingColors(cats{i}) / 2);
    end
%     set(handles,'MarkerEdgeAlpha',0.5,'MarkerFaceAlpha',0.7,'LineWidth',0.01);
    hold(hAx,'off');
end

function spinAxes(hAx)
    v = get(hAx,'View');
    for i = 0:1:360
        set(hAx,'View',v + [i 0]);
        pause(0.05)
    end
end