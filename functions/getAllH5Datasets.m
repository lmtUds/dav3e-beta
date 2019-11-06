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

function datasets = getAllH5Datasets(file,group)
    if nargin < 2
        group = '/';
    end
    datasets = {};
    info = h5info(file,group);
    for i = 1:numel(info.Groups)
        datasets = [datasets, getAllH5Datasets(file,info.Groups(i).Name)];
    end
    if numel(info.Datasets) > 0
        datasets = [datasets, string([group '/']) + string({info.Datasets.Name})];
    end
end