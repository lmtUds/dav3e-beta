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

classdef ImportGenericH5 < handle
    properties
        main
        f
        jSlider, hSlider
        hListbox
        hButton
        datasetNames
        atoms
        groupMap
    end
    
    methods
        function obj = ImportGenericH5(main,datasetNames)
            [map, exit] = obj.ImportGenericH5New(datasetNames);
            obj.main = main;
            obj.f = figure('Name','H5 Clusters','WindowStyle','modal');
            layout = uiextras.VBox('Parent',obj.f);
            
            obj.datasetNames = datasetNames;
            [atoms,nMin,nMax] = obj.getPathAtoms(datasetNames);
            obj.atoms = atoms;
            
            s = javax.swing.JSlider(nMin,nMax,nMax);
            s.setMajorTickSpacing(1);
            s.setMinorTickSpacing(1);
            [obj.jSlider,obj.hSlider] = javacomponent(s,[0,0,1,1],layout);
            set(obj.jSlider, 'PaintLabels',false, 'PaintTicks',true);
            hjSlider = handle(obj.jSlider, 'CallbackProperties');
            hjSlider.StateChangedCallback = @(varargin) obj.sliderDragged;
            
            obj.hListbox = uicontrol(layout,'style','listbox',...
                'max',inf);
            obj.hButton = uicontrol(layout,'string','OK',...
                'callback',@(varargin) obj.okButtonClicked);
            obj.sliderDragged();
            
            layout.Sizes = [30,-1,30];
        end
        
        function [GroupMap, Exit] = ImportGenericH5New(obj,datasetNames)            
            GroupMap = containers.Map();
            Exit = 0;
            fig = uifigure('Name','H5 Clusters','WindowStyle','modal',...
                'Visible','off');
            grid = uigridlayout(fig,[4 1],'RowHeight',{22,'1x','4x',22});
            
            infoLabel = uilabel(grid,'Text','Select extraction depth',...
                'HorizontalAlignment','center');
            infoLabel.Layout.Row = 1;
                        
            obj.datasetNames = datasetNames;
            [atoms,nMin,nMax] = PathAtoms(datasetNames);
            
            slider = uislider(grid,'Limits',[nMin nMax],'Value',nMax,...
                'MajorTicks',nMin:1:nMax,'MinorTicks',[]);
            slider.Layout.Row = 2;
            
            listBox = uilistbox(grid,'Multiselect','on');
            listBox.Layout.Row = 3;
            slider.ValueChangedFcn = @(src,event)...
                Dragged(src,event,listBox,atoms);
            
            okButton = uibutton(grid,'Text','Ok',...
                'ButtonPushedFcn',@(src,event)...
                    Ok(src,event,slider,listBox,datasetNames,atoms));
            okButton.Layout.Row = 4;
            
            Dragged(slider,[],listBox,atoms);
            
            fig.Visible = 'on';
            uiwait(fig)
            function [atoms,nMin,nMax] = PathAtoms(datasetNames)
                atoms = regexp(datasetNames, '/', 'split');
                nums = cellfun(@numel,atoms);
                nMin = 1;
                nMax = min(nums);
            end
            function [roots,n] = Roots(atoms,n)
                roots = cell(1,numel(atoms));
                for i = 1:numel(atoms)
                    a = atoms{i};
                    roots{i} = strjoin(a(1:n),'/');
                end
                [roots,~,idx] = unique(string(roots));
                n = histcounts(idx,'BinMethod','integers');
            end
            function Dragged(src,event,list,atoms)
                [roots,n] = Roots(atoms,src.Value);
                s = cell(1,numel(n));
                for i = 1:numel(n)
                    s{i} = sprintf('%s (%d)',roots{i},n(i));
                end
                list.Items = s;
                list.Value = s;
            end
            function Ok(src,event,slider,listBox,datasetNames,atoms)                
                roots = Roots(atoms,slider.Value);
                roots = roots(ismember(listBox.Items,listBox.Value));
                for i = 1:numel(roots)
                    idx = logical(cell2mat(strfind(datasetNames,roots{i})));
                    GroupMap(roots{i}) = datasetNames(idx);
                end
                Exit = 1;
                close(fig);
            end
        end

        function [roots,n] = getRoots(obj,n)
            roots = {};
            for i = 1:numel(obj.atoms)
                a = obj.atoms{i};
                roots{end+1} = strjoin(a(1:n),'/');
            end
            [roots,~,idx] = unique(string(roots));
            n = histc(idx, 1:numel(roots));
        end 
        
        function sliderDragged(obj)
            n = obj.jSlider.getValue();
            [roots,n] = obj.getRoots(n);
            s = {};
            for i = 1:numel(n)
                s{end+1} = sprintf('%s (%d)',roots{i},n(i));
            end
            obj.hListbox.String = s;
            obj.hListbox.Value = 1:numel(n);
        end
        
        function okButtonClicked(obj)
            roots = obj.getRoots(obj.jSlider.getValue());
            roots = roots(obj.hListbox.Value);
            m = containers.Map();
            for i = 1:numel(roots)
                idx = logical(cell2mat(strfind(obj.datasetNames,roots{i})));
                m(roots{i}) = obj.datasetNames(idx);
            end
            obj.groupMap = m;
            close(obj.f);
        end
    end
    
    methods (Static)
        function [atoms,nMin,nMax] = getPathAtoms(datasetNames)
            atoms = regexp(datasetNames, '/', 'split');
            nums = cellfun(@numel,atoms);
            nMin = 1;
            nMax = min(nums);
        end
    end
end