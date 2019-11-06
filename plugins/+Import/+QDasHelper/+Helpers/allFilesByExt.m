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

function [ fullPath, namesOnly ] = allFilesByExt( rootDir, extension )
%ALLFILESBYEXT finds all files of a given extension contained in rootDir or its sub directories
%   RETURN two cell arrays fullPath containing the full relational path from rootDir to the
%   files; namesOnly containing just the file names
%   EXTENSION needs to inlclude the dot e.g. '.pdf'
rootContent = dir(rootDir);
fullPath = cell(1);
namesOnly = cell(1);
for i=3:size(rootContent,1)
    if rootContent(i).isdir
       [paths, names] = Import.QDasHelper.Helpers.allFilesByExt([rootDir,'/',rootContent(i).name],extension);
       fullPath = vertcat(fullPath,paths);
       namesOnly = vertcat(namesOnly,names);
    else
        if ~isempty(strfind(rootContent(i).name,extension))
            paths = [rootDir,'/',rootContent(i).name];
            names = rootContent(i).name;
            fullPath = vertcat(fullPath,paths);
            namesOnly = vertcat(namesOnly,names);
        end
    end
end
fullPath = fullPath(~cellfun(@isempty,fullPath));
namesOnly = namesOnly(~cellfun(@isempty,namesOnly));
end

