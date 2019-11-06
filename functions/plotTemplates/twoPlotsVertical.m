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
% f.Position = f.Position([1,2,3,3]) - [0 200 0 0];

m = msgbox('Click on top plot, then OK.'); WinOnTop(m); uiwait(m);
newTopAx = copyobj(gca,f);
m = msgbox('Click on bottom plot, then OK.'); WinOnTop(m); uiwait(m);
newBottomAx = copyobj(gca,f);

topAx = subplot(2,1,1, newTopAx);
bottomAx = subplot(2,1,2, newBottomAx); 

e = findall([topAx,bottomAx]);
set(e,'UserData',[]);

set(topAx,'box','on');
title(topAx,'');
topAx.XTick = [];
%ylabel(topAx,'sensor response / µA')

set(bottomAx,'box','on');
title(bottomAx,'');
%bottomAx.XTick = 0:100:600;
%bottomAx.XTickLabel = 0:10:60;
%ylabel(bottomAx,'sensor response / µA')

%bottomAx.Position = bottomAx.Position + [0 70 0 0];

margin = 10;
f.Units = 'pixel';
topAx.Units = 'pixel';
bottomAx.Units = 'pixel';
f.Position = [f.Position([1,2]),460,420];
topAx.Position = [88.6-30 47.2+(342.3-margin)/2+margin 342.3 (342.3-margin)/2];
bottomAx.Position = [88.6-30 47.2 342.3 (342.3-margin)/2];

% fig 2516         459         560         420
% ax  73.8000   47.2000  434.0000  342.3000

% ax1
% 73.8000   47.2000  434.0000  166.0000

% ax2
% 73.8000   223.2000  434.0000  166.0000