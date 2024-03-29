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

function updateFun = confusionmatrix(parent,project,dataprocessingblock)
    populateGui(project,parent);
    updateFun = @()populateGui(project,parent);
end

function populateGui(project,parent)
    [target,pred] = project.currentModel.getValidatedDataForTrainedIndexSet().getTargetAndValidatedPrediction();
    
    [confmat,order] = confusionmat(target,pred);
    if ~isempty(confmat)
        delete(parent.Children)
        confChart = confusionchart(confmat',order,...
            'Parent',parent);
        % confChart.Normalization = 'column-normalized';
        % confChart.RowSummary = 'row-normalized';
        confChart.ColumnSummary = 'column-normalized';
        colorFactor = 0.75;
        confChart.DiagonalColor = [0 1 0]*colorFactor;
        confChart.OffDiagonalColor = [1 0 0]*colorFactor;
        confChart.XLabel = 'Target: True Class'; confChart.YLabel = 'Output: Predicted Class';
        confChart.Title = sprintf('Accuracy: %.2f%%', 100*trace(confmat)/sum(confmat(:)));  %adapted from https://github.com/vtshitoyan/plotConfMat/blob/master/plotConfMat.m, Copyright (c) 2018 Vahe Tshitoyan, MIT License
        % sortClasses(confChart,sort(categories(order)));
        confChart.Layout.Row = 1;
        confChart.Layout.Column = 1;
    end
end
