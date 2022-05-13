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

function Clusters(main)
    fig = uifigure('Name','Cluster Properties',...
        'WindowStyle','modal','Visible','off');
    grid = uigridlayout(fig,[2 3],'RowHeight',{'1x', 22});
    table = uitable(grid,...
        'CellEditCallback',@(src,event)TableEdit(src,event,main,fig));
    table.Layout.Column = [1 3];
    plotBtn = uibutton(grid,'Text','Plot Tracks',...
        'ButtonPushedFcn',@(src,event) PlotTracks(src,event,main));
    plotBtn.Layout.Column = 1;
    plotBtn = uibutton(grid,'Text','Normalize Cycle Durations',...
        'ButtonPushedFcn',@(src,event) NormCycleDurations(src,event,main,table));
    plotBtn.Layout.Column = 2;
    plotBtn = uibutton(grid,'Text','Delete Clusters',...
        'ButtonPushedFcn',@(src,event) DeleteClusters(src,event,main,table));
    plotBtn.Layout.Column = 3;

    Refresh(main,table);
    fig.Visible = 'on';
    uiwait(fig)

    main.getActiveModule().onOpen();
    main.populateSensorSetTable();
    function TableEdit(src,event,main,fig)
        cluster = src.UserData(event.Indices(1));
        switch event.Indices(2)
            case 1
                captions = main.project.clusters.getCaption();
                if ismember(event.EditData,captions)
                    message = {sprintf('Cluster caption %s already used.',...
                        event.EditData),'Caption edit was reverted.'};
                    uialert(fig,message,...
                        'Caption already used','Icon','warning')
                    src.Data{event.Indices(1),event.Indices(2)} = event.PreviousData;
                    return
                else
                    cluster.setCaption(event.EditData);
                end
            case 2
                cluster.track = event.EditData;
            case 3
                cluster.offset = event.EditData;
                iOffset = cluster.getAutoIndexOffset(main.project.clusters);
                cluster.indexOffset = iOffset;                        
            case 4
                cluster.samplingPeriod = event.EditData;
        end
    end
    function Refresh(main,table)
        clusters = main.project.clusters;
        data = cell(numel(clusters),6);
        for i = 1:numel(clusters)
            data{i,1} = char(clusters(i).getCaption());
            data{i,2} = char(clusters(i).track);
            data{i,3} = clusters(i).offset;
            data{i,4} = clusters(i).samplingPeriod;
            data{i,5} = clusters(i).nCycles;
            data{i,6} = clusters(i).nCyclePoints;
        end
        table.Data = data;
        table.ColumnName = {'caption','track','offset',...
            'sampling period','cycles','cycle points'};
        table.ColumnEditable = [true true true true false false];
        table.ColumnFormat = {'char','char',...
            'numeric','numeric','numeric','numeric'};
        table.UserData = clusters;
    end
    function PlotTracks(src,event,main)
        % get the number and captions of tracks
        tracks = unique([main.project.clusters.track]);

        % get clusters for individual tracks and their boundaries
        % in the time domain
        trackClusters = cell(numel(tracks),1);
        trackTimeVecs = cell(numel(tracks),1);
        for i = 1:numel(tracks)
            trackClusters{i} = ...
                main.project.clusters([main.project.clusters.track] == tracks(i));
            timeVec = [];
            for j = 1:numel(trackClusters{i})
                cluster = trackClusters{i}(j);
                lower = cluster.offset;
                upper = cluster.offset + cluster.samplingPeriod...
                    * cluster.nCycles * cluster.nCyclePoints;
                timeVec = [timeVec lower upper];
            end
            trackTimeVecs{i} = timeVec;
        end

        % plot clusters
        track_fig = uifigure('Name','Track System',...
            'WindowStyle','modal','Visible','off');
        track_grid = uigridlayout(track_fig,[1 1]);
        ax = uiaxes(track_grid);
        title(ax,'Track System')
        xlabel(ax,'time');
        hold(ax,'on')
        % y-Coordinates of a 4 sided polygon
        % bot left, bot right, top right, top left
        yfill=[0.75,0.75,1.25,1.25];

        verticalOffset = 0;
        for i = 1:numel(tracks)
            timeVec = trackTimeVecs{i};
            for j = 1:2:size(timeVec,2)
                lower = timeVec(j);
                upper = timeVec(j+1);
                fill(ax,[lower upper upper lower],...
                    yfill+verticalOffset,rand(1,3),...
                    'DisplayName',trackClusters{i}((j-1)/2+1).caption)
            end
            verticalOffset = verticalOffset + 1;
        end
        ylim(ax,[0 numel(tracks)+1]);
        yticks(ax,1:numel(tracks));
        yticklabels(ax,tracks);
        legend(ax);
        track_fig.Visible = 'on';
        track_fig.Position(3:4) = [900,250];
    end
    function NormCycleDurations(src,event,main,table)
        clusters = main.project.clusters;
        for i = 1:numel(clusters)
            clusters(i).samplingPeriod = 1 / clusters(i).nCyclePoints;
        end
        Refresh(main,table);
    end
    function DeleteClusters(src,event,main,table)
        captions = main.project.clusters.getCaption();
        [selection, exit] = Gui.Dialogs.Select(...
            'Name','Delete Clusters','ListItems',captions);
        if ~exit
            return
        end
        main.project.clusters(ismember(captions,selection)) = [];
        Refresh(main,table);
        main.populateSensorSetTable();
    end
end