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

function [panel,updateFun] = uncertainties(parent,project,dataprocessingblock)
    [panel,elements] = makeGui(parent);
    populateGui(elements,project,dataprocessingblock);
    updateFun = @()populateGui(elements,project,dataprocessingblock);
end

function [panel,elements] = makeGui(parent)
    panel = uipanel(parent);
    hAx = axes(panel); title('');
    box on,
    set(gca,'LooseInset',get(gca,'TightInset')) % https://undocumentedmatlab.com/blog/axes-looseinset-property
    elements.hAx = hAx;
end

function populateGui(elements,project,dataprocessingblock)
    cla(elements.hAx,'reset');
    dataParam = dataprocessingblock.parameters.getByCaption('projectedData');
    if isempty(dataParam)
        return
    end
    groupingCaption = project.currentModel.fullModelData.groupingCaption;
%     groupingCaption = '';
    groupingObj = project.getGroupingByCaption(groupingCaption);
    groupingColors = groupingObj.getColors();
    trainGrouping = categorical(project.currentModel.fullModelData.getSelectedGrouping('training',groupingCaption));
    testGrouping = categorical(project.currentModel.fullModelData.getSelectedGrouping('testing',groupingCaption));

    trainData = dataParam.getValue().training;
    if isfield(dataParam.getValue(),'testing')
        testData = dataParam.getValue().testing;
    else
        testData = [];
    end
    
    trainTarget = project.currentModel.fullModelData.getSelectedTarget('training');
    testTarget = project.currentModel.fullModelData.getSelectedTarget('testing');
    
    trainData = dataprocessingblock.revertChain(trainData);
    testData = dataprocessingblock.revertChain(testData);
    
    hold(elements.hAx,'on');
    
    test = [];
    targetValues = unique([trainTarget;testTarget]);
    [~,trainGrouping] = deStar(trainGrouping);
    [~,testGrouping] = deStar(testGrouping);
    trainCats = categories(trainGrouping);
    testCats = categories(testGrouping);

    systUnc = zeros(numel(trainCats),numel(targetValues));
    randUnc = zeros(numel(trainCats),numel(targetValues));
    
    for i = 1:numel(targetValues)
        for j = 1:numel(trainCats)
            mask = (trainGrouping==trainCats(j)) & (trainTarget==targetValues(i));
            t = trainTarget(mask);
            d = trainData(mask);
            syst = mean(d) - mean(t);
            rand = std(d);
            systUnc(j,i) = syst;
            randUnc(j,i) = rand;
        end
%         for j = 1:numel(testCats)
%             t = testTarget(testGrouping==testCats(j));
%             d = testData(testGrouping==testCats(j));
%             test = plot(elements.hAx,t,d,'k^');
%             test.MarkerFaceColor = groupingColors(char(testCats(j)));
%             test.MarkerEdgeColor = 'k';%groupingColors(char(cats(i))) / 2;
%             test.LineWidth = 1;
%         end
    end
    
    yyaxis(elements.hAx,'left');
    p = plot(elements.hAx,repmat(targetValues',size(systUnc,1),1)',systUnc');
    yyaxis(elements.hAx,'right');
    plot(elements.hAx,repmat(targetValues',size(systUnc,1),1)',randUnc');
    
    legend(p,trainCats);
    
%     plot(elements.hAx,limits,limits,'-k');
%     rmseVal = plot(elements.hAx,limits,limits + valError,'--k');
%     plot(elements.hAx,limits,limits - valError,'--k');
%     xlim(elements.hAx,limits);
%     ylim(elements.hAx,limits);
%     axis(elements.hAx,'square');
%     
%     legend(elements.hAx,[train rmseVal test],...
%         {'training data','RMSE (validation)','testing data'},...
%         'Location','NorthWest');
    
%     % find limits above/below no predicted value is below/above a threshold
%     [trainData,order] = sort(trainData);
%     trainTarget = trainTarget(order);
%     upperBound = 60;
%     lowerBound = 30;
%     upperBoundReal = trainTarget(find(trainData > upperBound,1))
%     lowerBoundReal = trainTarget(find(trainData < lowerBound,1,'last'))
%     %
%     plot([1 1]*upperBound,ylim,'--k');
%     plot([1 1]*upperBoundReal,ylim,'-.k');
%     plot([1 1]*lowerBound,ylim,'--k');
%     plot([1 1]*lowerBoundReal,ylim,'-.k');
end
