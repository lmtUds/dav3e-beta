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

function updateFun = histogramNovelty(parent,project,dataprocessingblock)
    populateGui(parent,project,dataprocessingblock);
    updateFun = @()populateGui(parent,project,dataprocessingblock);
end

function populateGui(parent,project,dataprocessingblock)
    dataParam = dataprocessingblock.parameters.getByCaption('inputData');
    if isempty(dataParam)
        return
    end
    groupingCaption = project.currentModel.fullModelData.groupingCaption;
%     groupingCaption = 'naphthalene_all';
    groupingObj = project.getGroupingByCaption(groupingCaption);
    %groupingObj = project.getGroupingByCaption(project.currentModel.fullModelData.groupingCaption);
    groupingColors = groupingObj.getColors();
    trainGrouping = categorical(tryCat2num(project.currentModel.fullModelData.getSelectedGrouping('training',groupingCaption)));
    testGrouping = categorical(tryCat2num(project.currentModel.fullModelData.getSelectedGrouping('testing',groupingCaption)));
    dims = 1;
    autoFlag = dataprocessingblock.parameters.getByCaption('autoThreshold').getValue();
    if autoFlag
        threshold = dataprocessingblock.parameters.getByCaption('thresholdInt').getValue();
    else
        threshold = dataprocessingblock.parameters.getByCaption('threshold').getValue();
    end
    trainScores = dataprocessingblock.parameters.getByCaption('trainScores').getValue();
    testScores = dataprocessingblock.parameters.getByCaption('testScores').getValue();
    minLimTe = min(testScores); maxLimTe = max(testScores);
    minLimTr = min(trainScores); maxLimTr = max(trainScores);

    delete(parent.Children);
    
    tl = tiledlayout(parent,numel(dims),1);
    tl.Layout.Row = 1; tl.Layout.Column = 1;
    [h1,c1] = histPlot(tl,threshold,trainGrouping,dims,...
        groupingColors,[minLimTr;maxLimTr],trainScores);
    
    [h2,c2] = histPlot(tl,threshold,testGrouping,dims,...
        groupingColors,[minLimTe;maxLimTe],testScores);
    
    c2 = c2 + string(' (testing)');
    for i = 1:size(c1,2)
        nov = string(dataprocessingblock.parameters.getByCaption('classifier').getValue().novelTag);
        nor = string(dataprocessingblock.parameters.getByCaption('classifier').getValue().normalTag);
        if strcmp(c1(i),nov)
            c1(i) = c1(i)+ string(' (novel)');
        elseif strcmp(c1(i),nor)
            c1(i) = c1(i)+ string(' (normal)');
        end
    end
    legend([h1,h2],[c1,c2]);
end

function [handles,captions] = histPlot(tileLayout,threshold,grouping,dims,...
                                        groupingColors,limits,scores)
    handles = [];
    captions = string.empty;
    for i = 1:numel(dims)
        hsAx = nexttile(tileLayout,i);
        hold(hsAx,'on');
        xlabel(hsAx,'novelty scores')
        ylabel(hsAx,'counts');
        cats = categories(deStar(grouping));
        for j = 1:numel(cats)
            idx = grouping == cats{j};
            p = histogram(hsAx,scores(idx,i),...
                linspace(limits(1,i),limits(2,i),50));
            line(hsAx,[threshold threshold],get(hsAx,'YLim'),...
                'Color',[1 0 0],'DisplayName','Threshold')
            if i == 1
                if isempty(handles)
                    handles = p;
                    captions = string(cats{j});
                else
                    handles(end+1) = p;
                    captions(end+1) = cats{j};
                end
            end
            set(p,'FaceColor',groupingColors(cats{j}));
        end
        hold(hsAx,'off');
    end
end
