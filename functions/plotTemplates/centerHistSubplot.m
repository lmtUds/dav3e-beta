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
m = msgbox('Click on right plot, then OK.'); WinOnTop(m); uiwait(m);
newRightAx = copyobj(gca,f);
m = msgbox('Click on center plot, then OK.'); WinOnTop(m); uiwait(m);
newCenterAx = copyobj(gca,f);

topAx = subplot(4,4,1:3, newTopAx);
centerAx = subplot(4,4,[5,6,7,9,10,11,13,14,15], newCenterAx); 
rightAx = subplot(4,4,[8 12 16], newRightAx); view(rightAx,90,90);

e = findall([topAx,rightAx,centerAx]);
set(e,'UserData',[]);

set(centerAx,'box','on');
xlabel(topAx,'');
ylabel(topAx,'');
topAx.XTick = [];
topAx.YTick = [];
topAx.YColor = 'w';

xlabel(rightAx,'');
ylabel(rightAx,'');
rightAx.XTick = [];
rightAx.YTick = [];
rightAx.YColor = 'w';
rightAx.XDir = 'reverse';

linkaxes([centerAx,topAx],'x');
xlim(rightAx,ylim(centerAx))
% linkaxes([centerAx,rightAx],'y');
% setappdata(rightAx, 'XLim_listeners', linkprop(centerAx,'YLim')); 
h = zoom(f);
% h.ActionPostCallback = @(hFig, hAx) set(centerAx, 'ylim', get(rightAx, 'xlim'));
h.ActionPostCallback = @(hFig, hAx) set(rightAx, 'xlim', get(centerAx, 'ylim'));

% set(topAx,'Position',get(topAx,'Position') + [0 -0.05 0 0])
% set(rightAx,'Position',get(rightAx,'Position') + [-0.04 0 0 0])

margin = 5;
f.Units = 'pixel';
topAx.Units = 'pixel';
rightAx.Units = 'pixel';
centerAx.Units = 'pixel';

left = 88.6-30; bottom = 47.2;
totalLength = 342.3;
lDiv = (totalLength - margin) / 4;
l1 = lDiv*3; l2 = lDiv*1;

f.Position = [f.Position([1,2]),500-90,420];
centerAx.Position = [left,bottom,l1,l1];
topAx.Position = [left,bottom+l1+margin,l1,l2];
rightAx.Position = [left+l1+margin,bottom,l2,l1];