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

init

errorMsg = [...
    'Please install the GUI Layout Toolbox (>2014b) from '...
    'https://de.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox. ' ...
    'DO NOT USE MATLAB Add-Ons since this supplies the pre-2014b version! ' ...
    'You can either install the Toolbox in MATLAB (Download>Toolbox), '...
    'or put the extracted zip file (Download>Zip) in the folder "toolboxes" in DAV³E.'];

if ~exist('uiextras.BoxPanel','class')
    error(errorMsg,'I''m afraid I can''t do that.');
end

try
%     dave = Gui.Main();
    dave = Gui.MainRework();
catch ME
    if strcmp(ME.message,'No constructor ''handle.listener'' with matching signature found.')
        error(errorMsg,'I''m afraid I can''t do that.');
    else
        rethrow(ME);
    end
end
    