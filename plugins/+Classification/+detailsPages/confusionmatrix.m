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
        confChart = confusionchart(confmat,order,...
            'Parent',parent,'Normalization','total-normalized');
        confChart.Layout.Row = 1;
        confChart.Layout.Column = 1;
    end
end
