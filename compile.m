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

%prepare matlab path to inlcude all DAVE files
init
%define Target folder for compiled files
mkdir('../DAVEcompile');
%initialize compilation
% -e                for windows .exe without command prompt
% -m                for windows .exe with command prompt
% -v                be verbose and show info while compiling
% -a ./FOLDER       add all project files in respective folder
% -a ./*.m          add all local '.m' files
% -d                set output directory
% -a GUITOOLBOXPATH include Gui Layout Toolbox
% 
% GUITOOLBOXPATH needs to altered specific to the system DAVE is being
% compiled on. Needs to point to GUI Layout Toolbox (>2014b) from
% 'https://de.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox'
% example:'C:\Users\**User**\Documents\MATLAB\Add-Ons\Toolboxes\GUI Layout Toolbox'
mcc -e -v -a ./+Gui -a ./classes -a ./functions -a ./plugins  -a ./toolboxes -a ./*.m -a GUITOOLBOXPATH -d '../DAVEcompile' 'DAVE.m'