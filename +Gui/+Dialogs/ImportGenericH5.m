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