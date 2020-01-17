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

classdef Licenses < handle
    properties
        f
        files
    end
    
    methods
        function obj = Licenses()
            obj.f = figure('Name','About','Units','pixel',...
                'menubar','none','toolbar','none');
            layout = uiextras.VBox('Parent',obj.f);
            
            if isdeployed
                obj.files = {...
                    'GUI Layout Toolbox',[ctfroot '/DAVE/toolboxes/GUILayoutToolbox/license.txt'];...
                    'statusbar',[ctfroot '/DAVE/toolboxes/statusbar/license.txt'];...
                    'javaclass',[ctfroot '/DAVE/toolboxes/PropertyGrid/javaclass.txt'];...
                    'javaStringArray',[ctfroot '/DAVE/toolboxes/PropertyGrid/javaStringArray.txt'];...
                    'distinguishable_colors',[ctfroot '/DAVE/functions/licenses/distinguishable_colors.txt'];...
                    'findjobj',[ctfroot '/DAVE/functions/licenses/findjobj.txt'];...
                    'plotConfMat',[ctfroot '/DAVE/functions/licenses/plotConfMat.txt'];...
                    'WinOnTop',[ctfroot '/DAVE/functions/licenses/WinOnTop.txt'];...
                    };
            else
                obj.files = {...
                    'GUI Layout Toolbox','./toolboxes/GUILayoutToolbox/license.txt';...
                    'statusbar','./toolboxes/statusbar/license.txt';...
                    'javaclass','./toolboxes/PropertyGrid/javaclass.txt';...
                    'javaStringArray','./toolboxes/PropertyGrid/javaStringArray.txt';...
                    'distinguishable_colors','./functions/licenses/distinguishable_colors.txt';...
                    'findjobj','./functions/licenses/findjobj.txt';...
                    'plotConfMat','./functions/licenses/plotConfMat.txt';...
                    'WinOnTop','./functions/licenses/WinOnTop.txt';...
                    };
            end
            
            
            tabgroup = uitabgroup(layout);
            for i = 1:size(obj.files,1)
                tab = uitab(tabgroup,'title',obj.files{i,1});
                tabLayout = uiextras.VBox('Parent',tab);
                licenseText = fileread(obj.files{i,2});
                jTextArea = javax.swing.JTextArea(licenseText);
                sp = javax.swing.JScrollPane(jTextArea);
                [jScrollPane,hScrollPane] = javacomponent(sp,[0,0,1,1],tabLayout);
            end
            
            obj.f.Position = obj.f.Position + [0 0 1 1];
        end
    end
end