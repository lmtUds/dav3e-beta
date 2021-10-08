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

function varargout = gitHelper(GitPath,varargin)
% THIS FUNCTION WAS ADAPTED FROM
% https://stackoverflow.com/a/42272702
%
% GIT Execute a git command.
%
% GITHELPER <ARGS>, when executed in command style, executes the git command and
% displays the git outputs at the MATLAB console.
% ARG1 needs to be the path to a git executable.
%
% STATUS = GITHELPER(ARG1, ARG2,...), when executed in functional style, executes
% the git command and returns the output status STATUS.
% ARG1 needs to be the path to a git executable.
%
% [STATUS, CMDOUT] = GITHELPER(ARG1, ARG2,...), when executed in functional
% style, executes the git command and returns the output status STATUS and
% the git output CMDOUT.
% ARG1 needs to be the path to a git executable.

% Check output arguments.
nargoutchk(0,2)

% Construct the git command. Surround the provided path with double
% quotation marks to comply with Windows policy.
winExePath = ['"',GitPath,'"'];
cmdstr = strjoin([winExePath, varargin]);

% Execute the git command.
[status, cmdout] = system(cmdstr);

switch nargout
    case 0
        disp(cmdout)
    case 1
        varargout{1} = status;
    case 2
        varargout{1} = status;
        varargout{2} = cmdout;
end
end

