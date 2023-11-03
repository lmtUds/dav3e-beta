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

function extractAxStacked(MainFig)
%EXTRACTAXSTACKED Extracts two Axes of MainFig into a default one uiFigure with stacked axes
    fig = uifigure('Name','Plot Extraction: vert. Stack','Visible','off');
    grid = uigridlayout(fig,[2 1],'Padding',[0 0 0 0]);
    ax = copyobj(MainFig.CurrentAxes,grid);
    ax.Layout.Row = 1; ax.Layout.Column = 1;
    
    msg = 'Click second plot, then Ok';
    uialert(MainFig,msg,'Plot Extraction: vert. Stack','Icon','info',...
        'Modal',false,'CloseFcn',@(Fig,Struct)addSecondAx(Fig,grid,fig))
    
    function addSecondAx(MainFig,grid,fig)
        ax2 = copyobj(MainFig.CurrentAxes,grid);
        ax2.Layout.Row = 2; ax2.Layout.Column = 1;
        fig.Visible = 'on';
    end
end

