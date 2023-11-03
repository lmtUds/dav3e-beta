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

function updateFun = predictionOverTime(parent,project,dataprocessingblock)
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
    trainOffsets = project.currentModel.fullModelData.getSelectedCycleOffsets('training');
    testOffsets = project.currentModel.fullModelData.getSelectedCycleOffsets('testing');
    
    % remove jumps (and actual timing information) from offsets
    [~,idx] = sort([trainOffsets;testOffsets]);
    trainOffsets = find(idx<=numel(trainOffsets));
    testOffsets = find(idx>numel(trainOffsets));
    trainOffsets(diff(trainOffsets) > 1) = nan;
    testOffsets(diff(testOffsets) > 1) = nan;
    
    trainSel = project.currentModel.fullModelData.trainingSelection;
    testSel = project.currentModel.fullModelData.testingSelection;
    find(diff(trainSel | testSel) > 0);

    trainData = dataParam.getValue().training;
    if isfield(dataParam.getValue(),'testing')
        testData = dataParam.getValue().testing;
    else
        testData = [];
    end
    trainTarget = project.currentModel.fullModelData.getSelectedTarget('training');
    testTarget = project.currentModel.fullModelData.getSelectedTarget('testing');
    
    try
        trainData = dataprocessingblock.revertChain(trainData);
        testData = dataprocessingblock.revertChain(testData);
    end
    
    delete(parent.Children);
    hAx = uiaxes(parent);
    hAx.Layout.Column = 1; hAx.Layout.Row = 1;
    
    hold(hAx,'on');
    setpoint = plot(hAx,trainOffsets,trainTarget,'--k','LineWidth',1.5);
    plot(hAx,testOffsets,testTarget,'--r','LineWidth',1.5);
    trainPrediction = plot(hAx,trainOffsets,trainData,'-k','LineWidth',0.1);
    testPrediction = plot(hAx,testOffsets,testData,'-r','LineWidth',0.1);
    
    legData = [setpoint trainPrediction];
    legCap = {'actual','prediction (training)'};
    if ~isempty(testPrediction)
        legData = [legData, testPrediction];
        legCap = [legCap, 'prediction (testing)'];
    end
    
    legend(hAx,legData,legCap,'Location','NorthWest');
    hold(hAx,'off');
end