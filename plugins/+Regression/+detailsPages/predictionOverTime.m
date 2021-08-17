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

function [panel,updateFun] = predictionOverTime(parent,project,dataprocessingblock)
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
    
    hold(elements.hAx,'on');
    setpoint = plot(elements.hAx,trainOffsets,trainTarget,'--k','LineWidth',1.5);
    plot(elements.hAx,testOffsets,testTarget,'--r','LineWidth',1.5);
    trainPrediction = plot(elements.hAx,trainOffsets,trainData,'-k','LineWidth',0.1);
    testPrediction = plot(elements.hAx,testOffsets,testData,'-r','LineWidth',0.1);
    
    legData = [setpoint trainPrediction];
    legCap = {'actual','prediction (training)'};
    if ~isempty(testPrediction)
        legData = [legData, testPrediction];
        legCap = [legCap, 'prediction (testing)'];
    end
    
    legend(elements.hAx,legData,legCap,'Location','NorthWest');
    hold(elements.hAx,'off');
end