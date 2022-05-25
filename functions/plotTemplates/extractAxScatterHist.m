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

function extractAxScatterHist(MainFig)
%EXTRACTAXSTACKED Extracts three Axes of MainFig into a uiFigure with a center, top and right ax
    fig = uifigure('Name','Plot Extraction: Scatter+Hist','Visible','off');
    fig.Position(1:2) = fig.Position(1:2)-250;
    fig.Position(3:4) = [650 650];
    grid = uigridlayout(fig,[4 4],'Padding',[5 5 5 5]);
    axCenter = copyobj(MainFig.CurrentAxes,grid);
    axCenter.Layout.Row = [2 4]; axCenter.Layout.Column = [1 3];
    
    msg = 'Click top plot, then Ok';
    uialert(MainFig,msg,'Plot Extraction: Scatter+Hist','Icon','info',...
        'Modal',false,'CloseFcn',@(Fig,Struct)addTopAx(Fig,grid,fig))
    
    function addTopAx(MainFig,grid,fig)
        axTop = copyobj(MainFig.CurrentAxes,grid);
        axTop.Layout.Row = 1; axTop.Layout.Column = [1 3];
        
        msgR = 'Click right plot, then Ok';
        uialert(MainFig,msgR,'Plot Extraction: Scatter+Hist','Icon','info',...
            'Modal',false,'CloseFcn',@(Fig,Struct)addRightAx(Fig,grid,fig))
    end
    function addRightAx(MainFig,grid,fig)
        axRight = copyobj(MainFig.CurrentAxes,grid);
        axRight.Layout.Row = [2 4]; axRight.Layout.Column = 4;
        axRight.View = [90 90];
        fig.Visible = 'on';
    end
end

