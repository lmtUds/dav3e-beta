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

function [panel,updateFun] = histogramNovelty(parent,project,dataprocessingblock)
    [panel,elements] = makeGui(parent);
    populateGui(elements,project,dataprocessingblock);
    updateFun = @()populateGui(elements,project,dataprocessingblock);
end

function [panel,elements] = makeGui(parent)
    panel = uipanel(parent);
    layout = uiextras.VBox('Parent',panel);
    panel2 = uipanel(layout,'BorderType','none');
%     hAx = axes(panel2); title('');
%     xlabel('DF1'); ylabel('DF2');
%     box on,
%     set(gca,'LooseInset',get(gca,'TightInset')) % https://undocumentedmatlab.com/blog/axes-looseinset-property
%     elements.hAx = hAx;
    elements.axesPanel = panel2;
end

function populateGui(elements,project,dataprocessingblock)
%     cla(elements.hAx,'reset');
    delete(elements.axesPanel.Children);
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
    minLimTe = min(testScores);
    maxLimTe = max(testScores);
    minLimTr = min(trainScores);
    maxLimTr = max(trainScores);
    [h1,c1] = histPlot(elements.axesPanel,threshold,trainGrouping,dims,groupingColors,[minLimTr;maxLimTr],trainScores);
    [h2,c2] = histPlot(elements.axesPanel,threshold,testGrouping,dims,groupingColors,[minLimTe;maxLimTe],testScores);
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

function [handles,captions] = histPlot(panel,threshold,grouping,dims,groupingColors,limits,scores)
    handles = [];
    captions = string.empty;
    for i = 1:numel(dims)
        hsAx = subplot(numel(dims),1,i,'Parent',panel);
%         legend(hsAx,'off');
%         cla(hsAx);
        hold(hsAx,'on');
        cats = categories(deStar(grouping));
        for j = 1:numel(cats)
            idx = grouping == cats{j};
            p = histogram(scores(idx,i),linspace(limits(1,i),limits(2,i),50));
            line([threshold threshold],get(hsAx,'YLim'),'Color',[1 0 0],'DisplayName','Threshold')
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
%         set(handles,'MarkerEdgeColor',[1,1,1],'MarkerEdgeAlpha',0.7,'MarkerFaceAlpha',0.7);
%         xlabel(sprintf('DF%d (%0.1f %%)',dims(i),scores(i)));
        xlabel('novelty scores')
        ylabel('counts');
        hold(hsAx,'off');
    end
end
