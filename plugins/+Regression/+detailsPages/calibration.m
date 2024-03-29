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

function updateFun = calibration(parent,project,dataprocessingblock)
    populateGui(parent,project,dataprocessingblock);
    updateFun = @()populateGui(parent,project,dataprocessingblock);
end

function populateGui(parent,project,dataprocessingblock)
    dataParam = dataprocessingblock.parameters.getByCaption('projectedData');
    if isempty(dataParam) 
        return
    end
    if ~dataprocessingblock.parameters.getByCaption('trained').value
        return
    end
%     groupingCaption = project.currentModel.fullModelData.groupingCaption;
    groupingCaption = '';
    if ~isempty(groupingCaption)
        groupingObj = project.getGroupingByCaption(groupingCaption);
        groupingColors = groupingObj.getColors();
        trainGrouping = categorical(project.currentModel.fullModelData.getSelectedGrouping('training',groupingCaption));
        testGrouping = categorical(project.currentModel.fullModelData.getSelectedGrouping('testing',groupingCaption));
    end
    try
        trainData = dataParam.getValue().training;
    catch
        return
    end
    if isfield(dataParam.getValue(),'testing')
        testData = dataParam.getValue().testing;
    else
        testData = [];
    end
    
    trainTarget = project.currentModel.fullModelData.getSelectedTarget('training');
    testTarget = project.currentModel.fullModelData.getSelectedTarget('testing');
    
    valError = project.currentModel.getErrorsForTrainedIndexSet().validation;
    testError = project.currentModel.getErrorsForTrainedIndexSet().testing;
    
    try 
        if ~isempty(dataParam.value.errorTest)
            testError = dataParam.value.errorTest;
            valError = dataParam.value.errorVal;
        end
    catch
    end
    
    trainData = dataprocessingblock.revertChain(trainData);
%     trainTarget = dataprocessingblock.revertChain(trainTarget);
    testData = dataprocessingblock.revertChain(testData);
%     testTarget = dataprocessingblock.revertChain(testTarget);
%     valError = dataprocessingblock.revertChain(valError);
    
    minLim = min([trainTarget;testTarget;trainData;testData]);
    maxLim = max([trainTarget;testTarget;trainData;testData]);
    limits = [minLim,maxLim] + [-1 1] * diff([minLim,maxLim]) * 0.1;
    
    delete(parent.Children);
    hAx = uiaxes(parent);
    hAx.Layout.Column = 1; hAx.Layout.Row = 1;
    hold(hAx,'on');
    
    red = [227,32,23] ./ 255;
    blue = [0,152,212] ./ 255;
    
    test = [];
    if ~isempty(groupingCaption)
        trainGrouping = deStar(trainGrouping);
        cats = categories(trainGrouping);
        for i = 1:numel(cats)
            t = trainTarget(trainGrouping==cats(i));
            d = trainData(trainGrouping==cats(i));
            train = plot(hAx,t,d,'ko');
            train.MarkerFaceColor = groupingColors(char(cats(i)));
            train.MarkerEdgeColor = groupingColors(char(cats(i))) / 2;
        end
        testGrouping = deStar(testGrouping);
        cats = categories(testGrouping);
        for i = 1:numel(cats)
            t = testTarget(testGrouping==cats(i));
            d = testData(testGrouping==cats(i));
            test = plot(hAx,t,d,'k^');
            test.MarkerFaceColor = groupingColors(char(cats(i)));
            test.MarkerEdgeColor = 'k';%groupingColors(char(cats(i))) / 2;
            test.LineWidth = 1;
        end
    else
%         train = plot(elements.hAx,trainTarget,trainData,'ko');
%         test = plot(elements.hAx,testTarget,testData,'r^'); 
        train = scatter(hAx,trainTarget,trainData,25,'o');
        train.MarkerFaceColor = [1 1 1] * 0.7;
        train.MarkerEdgeColor = [1 1 1] * 0.7 ./ 1.5;
        train.MarkerFaceAlpha = .2;
        
        if ~isempty(testData)
            test = scatter(hAx,testTarget,testData,50,'^'); 
            test.MarkerFaceColor = blue; % [.2 .2 .9]
            test.MarkerEdgeColor = blue ./ 2; % [.2 .2 .9]
            test.MarkerFaceAlpha = .8;
            rmseTest = plot(hAx,limits,limits + testError,'-.','Color',blue); % [.2 .2 .9]
            plot(hAx,limits,limits - testError,'-.','Color',blue); % [.2 .2 .9]
        else
            rmseTest = plot(hAx,limits,limits + testError,'-.','Color',blue); % [.2 .2 .9]
            plot(hAx,limits,limits - testError,'-.','Color',blue); % [.2 .2 .9]
        end
    end
    plot(hAx,limits,limits,'-k');
    rmseVal = plot(hAx,limits,limits + valError,'--k');
    plot(hAx,limits,limits - valError,'--k');
    xlim(hAx,limits);
    ylim(hAx,limits);
    box(hAx,'on');
    xlabel(hAx,'setpoint');
    ylabel(hAx,'prediction');
    axis(hAx,'square');
    
    if ~isempty(test)
        legend(hAx,[train rmseVal test],...
            {'training data','RMSE (validation)','testing data'},...
            'Location','NorthWest');
    elseif ~isempty(rmseTest)
        legend(hAx,[train rmseVal rmseTest],...
            {'training data','RMSE (validation)','RMSE (testing)'},...
            'Location','NorthWest');
    else
       legend(hAx,[train rmseVal],...
            {'training data','RMSE (validation)'},...
            'Location','NorthWest'); 
    end
    
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
