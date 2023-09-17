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

function updateFun = scatter(parent,project,dataprocessingblock)
    elements = makeGui(parent);
    populateGui(elements,project,dataprocessingblock);
    updateFun = @()populateGui(elements,project,dataprocessingblock);
end

function elements = makeGui(parent)
    grid = uigridlayout(parent,[2 1],'RowHeight',{'1x',22});
    grid.Layout.Column = 1; grid.Layout.Row = 1; 
    hAx = uiaxes(grid);
    hAx.Layout.Column = 1; hAx.Layout.Row = 1;
    elements.hAx = hAx;
%     spinButton = uibutton(grid,'Text','Start spin',...
%         'ButtonPushedFcn',@(src,event)spinAxes(src,event,hAx),...
%         'Interruptible',true,'BusyAction','cancel');
%     spinButton.Layout.Column = 1; spinButton.Layout.Row = 2;
%     setappdata(spinButton,'spinning',0);    % current plot spinning state
%     setappdata(spinButton,'degree',0);      % degrees covered by the spin
%     elements.spinButton = spinButton;
end

function populateGui(elements,project,dataprocessingblock)
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
    
    cla(elements.hAx,'reset');
    [h1,c1] = scatterPlot(elements.hAx,trainData,trainGrouping,dims,groupingColors);
    [h2,c2] = scatterPlot(elements.hAx,testData,testGrouping,dims,groupingColors);
%     h2.MarkerStyle = '^';
    set(h2,'Marker','^'); 
%     set(h2,'LineWidth',2);
    c2 = c2 + string(' (testing)');
    legend(elements.hAx,[h1,h2],[c1,c2]);
    xlabel(elements.hAx,sprintf('DF1 (%0.1f %%)',100*cumEnergy(1)));
    if numel(dims) == 2
        set(h1,'MarkerFaceAlpha',0.7);
        ylabel(elements.hAx,sprintf('DF2 (%0.1f %%)',100*cumEnergy(2)));
    end
    if numel(dims) == 3
        ylabel(elements.hAx,sprintf('DF2 (%0.1f %%)',100*cumEnergy(2)));
        zlabel(elements.hAx,sprintf('DF3 (%0.1f %%)',100*cumEnergy(3)));
        set(elements.hAx,'View',[37.5,30]);
        grid(elements.hAx,'on');
    end
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

function spinAxes(src,~,hAx)
    % obtain current spinning state
    spinning = getappdata(src,'spinning');
    
    if spinning
        setappdata(src,'spinning',0);       %set state to paused
        src.Text = 'Resume spin';    %alter the label
        drawnow;
    else %so not spinning
        setappdata(src,'spinning',1);       %set state to spinning
        src.Text = 'Pause spin';     %alter the label
        
        % continue to spin until 360 degrees have been covered
        for i = getappdata(src,'degree'):1:360
            setappdata(src,'degree',i); 
            % check current spinning state to cope with button interruption
            if ~getappdata(src,'spinning')  
                break
            end
            set(hAx,'View',[i 90]);
            pause(0.05)
        end
        
        % after a full 360 degree spin restore the starting state
        if i == 360
            src.Text = 'Start spin';
            setappdata(src,'degree',0);
            setappdata(src,'spinning',0);
        end
    end
end