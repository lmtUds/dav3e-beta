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

function [destarred,stars] = deStar(cat)
    if iscategorical(cat)
        cats = categories(cat);
        res = regexpi(cats,'^(.*?)(\**)$','tokens');
        res = [res{:}]; %res = [res{:}]; res = res(1:2:end);
        destarred = cat;
        stars = cat;
        for i = 1:numel(res)
            destarred = mergecats(destarred,{res{i}{1},[res{i}{1},res{i}{2}]});
            if isempty(res{i}{2})
                stars = mergecats(stars,[res{i}{1},res{i}{2}],'none');
            else
                stars = mergecats(stars,[res{i}{1},res{i}{2}],res{i}{2});
            end
        end
        destarred = removecats(destarred);
        stars = removecats(stars);
        
    elseif iscell(cat)
        res = regexpi(cat,'^(.*?)(\**)$','tokens');
        res = [res{:}]; %res = [res{:}]; res = res(1:2:end);
        destarred = {};
        stars = {};
        for i = 1:numel(res)
            destarred{i} = res{i}{1};
            if isempty(res{i}{2})
                stars{i} = 'none';
            else
                stars{i} = res{i}{2};
            end
        end
        
    elseif ischar(cat)
        res = regexpi(cat,'^(.*?)(\**)$','tokens');
        destarred = res{1}{1};
        if isempty(res{1}{2})
            stars = 'none';
        else
            stars = res{1}{2};
        end
        
    elseif isstring(cat)
        res = regexpi(cat,'^(.*?)(\**)$','tokens');
        destarred = res{1}(1);
        if isempty(res{1}(2))
            stars = 'none';
        else
            stars = res{1}(2);
        end
    end
end