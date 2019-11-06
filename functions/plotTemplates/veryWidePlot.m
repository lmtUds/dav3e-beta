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

f = figure;

m = msgbox('Click on the plot, then OK.'); WinOnTop(m); uiwait(m);
if hasLegend(gca,gcf)
    newH = copyobj([gca legend],f);
    newAx = newH(1); newL = newH(2);
else
    newAx = copyobj(gca,f);
end

axes(newAx);
hAx = gca;

e = findall(hAx);
set(e,'UserData',[]);

set(hAx,'box','on');
title(hAx,'');

f.Units = 'pixel';
hAx.Units = 'pixel';
bottomAx.Units = 'pixel';
f.Position = [f.Position([1,2]),460+342.3,420-342.3/4*3];
hAx.Position = [88.6-30 47.2 342.3*2 342.3/4];

function found = hasLegend(hAx,hFig)
    lh = findall(hFig,'Type','Legend');
    found = true;
    for i = 1:numel(lh)
        if hAx == lh(i).PlotChildren(1).Parent
            return
        end
    end
    found = false;
end
