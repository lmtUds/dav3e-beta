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
    end
    
    methods
        function obj = Start(main)
            %% constructor
            obj@Gui.Modules.GuiModule(main);
        end
        
        function [panel,menu] = makeLayout(obj)
            %%
            panel = uix.Panel();
            menu = [];
            
            layout = uiextras.VBox('Parent',panel, 'Padding',20, 'Spacing',10);

            axes(layout)
            set(gca,'LooseInset',get(gca,'TightInset')) % https://undocumentedmatlab.com/blog/axes-looseinset-property
            [img,~,alpha] = imread('+Gui/+Modules/logo.png');
            image(img,'AlphaData',alpha)
            axis off
            axis image
            
            buttonLayout = uiextras.HBox('Parent',layout, 'Spacing',10);
            uicontrol('Parent',buttonLayout, 'String','Load project', ...
                    'FontSize',30,...
                    'Callback', @(varargin)obj.main.loadProject());
            uicontrol('Parent',buttonLayout, 'String','Import data', ...
                    'FontSize',30,...
                    'Callback', @(varargin)obj.importData());
                
            uicontrol(layout, 'Style','text', ...
                'String',sprintf(['\n\n\nIf you publish results obtained '...
                'with DAV³E, please cite: Manuel Bastuck, Tobias Baur,' ...
                'and Andreas Schütze: DAV3E – a MATLAB toolbox for multivariate '...
                'sensor data evaluation, J. Sens. Sens. Syst. (2018), 7, '...
                '489-506 (open access), doi: 10.5194/jsss-7-489-2018']),...
                'FontSize',12);
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
            mainPos = obj.main.hFigure.Position;
            chosenOne = choosedialog(mainPos);
            if strcmp(chosenOne,'simple')
                [file,path,filterId] = uigetfile(filterCell,'Choose files to import',oldPath,'MultiSelect','on');
                if path == 0
                    return
                end
                oldPath = path;
                if ~iscell(file)
                    file = {file};
                end

                % statusbar (Working)
                sb = statusbar(obj.main.hFigure,'Loading files...');
                set(sb.ProgressBar, 'Visible',true, 'Indeterminate',true);

                obj.getProject().importFile(fullfile(path,file),blocks(filterId).getCaption());
                obj.getProject().clusters.getCaption()
                obj.main.populateSensorSetTable();

                % statusbar (Ready)
                sb = statusbar(obj.main.hFigure,'Ready.');
                set(sb.ProgressBar, 'Visible',false, 'Indeterminate',false);
            elseif strcmp(chosenOne,'complex')
                importPaths = pathsdialog(mainPos);
                warning('No automated method available yet');
            else
                error('Unexpected return value for choosedialog()');
            end
        end
    end
end