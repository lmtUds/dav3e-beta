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

classdef Start < Gui.Modules.GuiModule
    properties
        caption = 'Start'
        mainFigure
    end
    
    methods
        function obj = Start(main)
            %% constructor
            obj@Gui.Modules.GuiModule(main);
        end
        
        function [moduleLayout,moduleMenu] = makeLayout(obj,uiParent,mainFigure)
            %%
            % we use a grid layout with 3 rows of decreasing height
            moduleLayout = uigridlayout(uiParent,[3 1],...
                'Visible','off',...
                'RowHeight',{'3x','2x','1x'},...
                'RowSpacing',7);
            moduleMenu = [];
                        
            img = uiimage(moduleLayout);
            img.Layout.Row = 1;
            img.ImageSource = '+Gui/+Modules/logo.png';
            
            buttonLayout = uigridlayout(moduleLayout,[1 2]);
            buttonLayout.Layout.Row = 2;
            
            loadButton = uibutton(buttonLayout,...
                'Text','Load project',...
                'FontSize',30,...
                'ButtonPushedFcn',@(varargin)obj.main.loadProject());
            loadButton.Layout.Column = 1;
            
            importButton = uibutton(buttonLayout,...
                'Text','Import Data',...
                'FontSize',30,...
                'ButtonPushedFcn',@(varargin)obj.importData());
            importButton.Layout.Column = 2;
                
            citeLabel = uilabel(moduleLayout);
            citeLabel.Layout.Row = 3;
            citeLabel.Text = ['If you publish results obtained ',...
                'with DAV³E, please cite: Manuel Bastuck, Tobias Baur,', ...
                'and Andreas Schütze: DAV3E – a MATLAB toolbox for multivariate ',...
                'sensor data evaluation, J. Sens. Sens. Syst. (2018), 7, ',...
                '489-506 (open access), doi: 10.5194/jsss-7-489-2018'];
            citeLabel.FontSize = 12;
            citeLabel.WordWrap = 'on';
            citeLabel.HorizontalAlignment = 'center';
            
            obj.mainFigure = mainFigure;
        end

        function importData(obj)
            persistent oldPath
            
            if ~exist('oldPath','var')
                oldPath = pwd;
            end
            filterCell = {};
            
            if isempty(obj.getProject())
                obj.main.project = Project();
            end
            methods = obj.getProject().getAvailableImportMethods(true);
            captions = keys(methods);
            for i = 1:numel(captions)
                blocks(i) = DataProcessingBlock(methods(captions{i}));
                extParam = blocks(i).parameters.getByCaption('extensions');
                filterCell{i,1} = strjoin(extParam.getValue(),';');
                filterCell{i,2} = char(blocks(i).getCaption());
            end
            [file,path,filterId] = uigetfile(filterCell,'Choose files to import',oldPath,'MultiSelect','on');
            % swap invisible shortly to regain window focus after
            % uigetfile
            obj.mainFigure.Visible = 'off';
            obj.mainFigure.Visible = 'on';

            if path == 0
                return
            end
            oldPath = path;
            if ~iscell(file)
                file = {file};
            end

            % statusbar (Working)
            prog = uiprogressdlg(obj.main.hFigure,...
                'Title','Loading Files','Indeterminate','on');
            drawnow

            %perform the actual data import
            obj.getProject().importFile(fullfile(path,file),blocks(filterId).getCaption());
            obj.getProject().clusters.getCaption();
            %check for track clashes and put all sensors on separate tracks
            %clashes are likely as all data is
            %put on the same "default" track on import
            obj.resolveTracks();

            %fill the sensor data table
            obj.main.populateSensorSetTable();

            % statusbar (Ready)
            close(prog)
        end
        
        function resolveTracks(obj)
            %rename duplicate tracks by enumerating all duplicates with the
            %same base track name
            
            %extract track names
            tracks = arrayfun(@(x) x.track, obj.getProject().clusters);
            if ~iscolumn(tracks)
                tracks = tracks';
            end
            %as long as duplicates remain we need to alter names
            while numel(unique(tracks)) ~= numel(tracks)
                %loop through unique track names to find duplicate groups
                uTracks = unique(tracks);
                for i = 1:numel(uTracks)
%                    occ = contains(tracks,uTracks(i));
                   occ = matches(tracks,uTracks(i));
                   if sum(occ) > 1 %if really a duplicate
                       %enumerate all duplicates in the group by appending an
                       %increasing number
                       tracks(occ) = strcat(tracks(occ),string(1:sum(occ))');
                   end
                end
            end
            %set the new track names in the data structure
            for i = 1:length(tracks)
               obj.getProject().clusters(i).track = tracks(i); 
            end            
        end
    end
end