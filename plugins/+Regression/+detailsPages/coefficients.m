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

function [panel,updateFun] = coefficients(parent,project,dataprocessingblock)
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
    coeffs = dataprocessingblock.parameters.getByCaption('beta0').getValue();
    coeffs = coeffs(:,end);
    if isempty(coeffs)
        return
    end
    % get features from annotation block (should always be the first one)
    featCap = dataprocessingblock.getFirstBlock().parameters.getByCaption('features').getValue();
    [~,idx] = sort(abs(coeffs),'descend');
    coeffs = coeffs(idx);
    featCap = cellstr(featCap(idx));
    bar(elements.hAx,coeffs);
    set(elements.hAx,'TickLabelInterpreter','none');
    set(elements.hAx,'XTickLabel',featCap);
    xtickangle(elements.hAx,20);
    xlabel('feature');
    ylabel('coefficient / a.u.')
end
