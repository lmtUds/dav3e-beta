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

classdef (Abstract) FeatureExtractorInterface < handle
    %FEATUREEXTRACTORINTERFACE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods (Abstract)
        this = train(this, rawData);
        feat = apply(this, rawData);
    end
    methods (Static)
        function position = elbowPos(curve)
            if size(curve,2) == 1 & size(curve,1)>1
                curve=curve';
            end
            if size(curve,1)>1
                warning('More than one input row provided. Only using first row');
                curve=curve(1,:);
            end
            if isempty(curve)
                position = 0;
            else
                maxAmp=max(curve);
                curve=curve./maxAmp;
                dists = zeros(size(curve));
                lineStart = [1, curve(1)];
                lineEnd = [length(curve),curve(end)];
                lineVec = lineEnd-lineStart;
                lineVec = lineVec./norm(lineVec);
                for c = 1:length(curve)
                    curveVec = [c,curve(c)];
                    lambda = (dot(lineVec,curveVec)-dot(lineVec,lineStart))./norm(lineVec);
                    distVec = lineStart+lambda*lineVec;
                    dists(c) = norm(distVec-curveVec);
                end
                [~,position]=max(dists);
            end
        end
    end
end

