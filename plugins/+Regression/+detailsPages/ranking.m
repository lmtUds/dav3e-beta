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

function [panel,updateFun] = ranking(parent,project,dataprocessingblock)
    [panel,elements] = makeGui(parent);
    populateGui(elements,project,dataprocessingblock);
    updateFun = @()populateGui(elements,project,dataprocessingblock);
end

function [panel,elements] = makeGui(parent)
    panel = uipanel(parent);
    layout = uiextras.VBox('Parent',panel);
    panel2 = uipanel(layout,'BorderType','none');
    %hAx = axes(panel2); title('');
    %xlabel('DF1'); ylabel('DF2');
    %box on,
    %set(gca,'LooseInset',get(gca,'TightInset')) % https://undocumentedmatlab.com/blog/axes-looseinset-property
    %elements.hAx = hAx;
       
    elements.table = uitable(panel2,'ColumnName',{'rank', 'id', 'feature'},...
        'Units', 'Normalized', 'Position',[0, 0, 1, 1]);
    set(elements.table,'ColumnWidth',{40, 40, 450});
    
    %spinButton = uicontrol(layout, 'String','spin','Callback',@(varargin)spinAxes(hAx));
    %elements.spinButton = spinButton;
    %layout.Sizes = [-1,20];
end

function populateGui(elements,project,dataprocessingblock)
    rank = dataprocessingblock.parameters.getByCaption('rank').value(:);
    features = dataprocessingblock.parameters.getByCaption('featureCaptions').value;
    T = table((1:numel(features))', rank(1:numel(features)), features');
    elements.table.Data = cellstr(T{:,:});
end
