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

% !!! Only works for PLSR as regressor

function updateFun = coefficients(parent,project,dataprocessingblock)
    populateGui(parent,project,dataprocessingblock);
    updateFun = @()populateGui(parent,project,dataprocessingblock);
end

function populateGui(parent,project,dataprocessingblock)
    if ~dataprocessingblock.parameters.getByCaption('trained').value
        return
    end
    try 
        coeffs = dataprocessingblock.parameters.getByCaption('beta0').getValue();
        coeffs = coeffs(:,end);
    end
    if isempty(coeffs)
        return
    end
    try
        featCap = project.currentModel.fullModelData.featureCaptions(dataprocessingblock.parameters.getByCaption('rank').value);
    catch
        featCap = project.currentModel.fullModelData.featureCaptions;
    end
    
    [~,idx] = sort(abs(coeffs),'descend');
    coeffs = coeffs(idx);
    featCap = cellstr(featCap(idx));
    X = categorical(featCap);
    X = reordercats(X,featCap);
    
    delete(parent.Children)
    hAx = uiaxes(parent);
    hAx.Layout.Column = 1; hAx.Layout.Row = 1;
    
    bar(hAx,X,coeffs);
    set(hAx,'TickLabelInterpreter','none');
    
    %set(elements.hAx,'XTickLabel',featCap);
    xtickangle(hAx,20);
    xlabel(hAx,'feature');
    ylabel(hAx,'coefficient / a.u.')
end
