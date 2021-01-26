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

function grad = colorGradientHSV(color,color2,steps)
%     color1 = color1 / 255;
%     color2 = color2 / 255;
    hsvColor = rgb2hsv(color);
    hsvColor2 = rgb2hsv(color2);
%     grad = [...
%         repmat(hsvColor(1),steps,1),...
%         linspace(0.1,1,steps)',...
%         linspace(0.9,hsvColor(3),steps)'];
    grad = [linspace(hsvColor(:,1),hsvColor2(:,1),steps)',...
        linspace(hsvColor(:,2),hsvColor2(:,2),steps)',...
        linspace(hsvColor(:,3),hsvColor2(:,3),steps)'];
    grad = hsv2rgb(grad);
end