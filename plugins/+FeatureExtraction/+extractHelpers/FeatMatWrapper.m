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

classdef FeatMatWrapper < FeatureExtraction.extractHelpers.FeatureMatrixInterface
    %FEATMATWRAPPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sigChainElements = {}
        %in general this is a numCV x numTargets cell matrix

        featMatsDependTarget = false;
        featMatsDependCV = false;
    end
    
    methods
        function this = FeatMatWrapper(sigChainElements)
            if nargin > 0
                this.sigChainElements = this.arrangeSigChainElements(sigChainElements);
                this.featMatsDependTarget = this.sigChainElements{1}.doesDependTarget();
                this.featMatsDependCV = this.sigChainElements{1}.doesDependCV();
                if size(this.sigChainElements, 1) > 1
                    this.dependCV = true;
                end
                if size(this.sigChainElements, 2) > 1
                    this.dependTarget = true;
                end
            end
        end
        
        function d = getFeatMat(this, cv, target, eval)
            if this.dependTarget
                callObjTarget = target;
            else
                callObjTarget = 1;
            end
            if this.dependCV
                callObjCV = cv;
            else
                callObjCV = 1;
            end
            obj = this.sigChainElements{callObjCV, callObjTarget};
            
            if this.featMatsDependTarget
                callNumTarget = target;
            else
                callNumTarget = 1;
            end
            if this.featMatsDependCV
                callNumCV = cv;
            else
                callNumCV = 1;
            end
            
            d = obj.getFeatMat(callNumCV, callNumTarget, eval);
        end
    end
    
    methods(Access = private)
        function sortedElements = arrangeSigChainElements(this, sigChainElements)
            %in general this is a numCV x numTargets cell matrix
            ids = cell(1, numel(sigChainElements));
            cvInd = cell(size(ids));
            preselInd = cell(size(ids));
            for i = 1:numel(sigChainElements)
                id= sigChainElements{i}.getId();
                cvInd{i} = strfind(id, 'CV');
                preselInd{i} = strfind(id, 'Pearson');
                ids{i} = id;
            end
            usesCV = any(~cellfun(@isempty, cvInd));
            if isa(sigChainElements{1}, 'CVSelFeatMat')
                usesCV = false;
            end
            usesPresel = any(~cellfun(@isempty, preselInd));
            
            %care for easy case
            if ~usesCV && ~usesPresel
                sortedElements = sigChainElements;
                return;
            end
            
            %only depending on target or CVSelFeatMata
            if ~usesCV && usesPresel
                targetNum = zeros(size(ids));
                for i = 1:numel(ids)
                    targetNum(i) = this.getTargetNum(ids{i});
                end
                sortedElements = cell(1, numel(ids));
                sortedElements(:) = sigChainElements(targetNum);
                return;
            end
            
            %only depending on cv
            if usesCV && ~ usesPresel
                cvNum = zeros(size(ids));
                for i = 1:numel(ids)
                    cvNum(i) = this.getCVNum(ids{i});
                end
                numCV = max(cvNum);
                cvNum(cvNum == 0) = numCV + 1;
                sortedElements = cell(numel(ids), 1);
                sortedElements(:) = sigChainElements(cvNum);
            end
            
            %depending on target and cv (no CVSelFeatMat)
            if usesCV && usesPresel
                cvNum = zeros(size(ids));
                targetNum = zeros(size(ids));
                for i = 1:numel(ids)
                    cvNum(i) = this.getCVNum(ids{i});
                    targetNum(i) = this.getTargetNum(ids{i});
                end
                numCV = max(cvNum);
                cvNum(cvNum == 0) = numCV + 1;
                numTarget = max(targetNum);
                sortedElements = cell(numCV + 1, numTarget);
                sortedElements(:) = sigChainElements(sub2ind(size(sortedElements), cvNum, targetNum));
                return;
            end
        end
        
        function cvNum = getCVNum(this, str)
            %returns 0 for objects trained on the full dataset and
            %CVSelFeatMats
            if strcmp(str(1:9), 'CVFeatMat')
                cvNum = 0;
                return;
            end
            
            ind = strfind(str, 'CV');
            cvNum = this.getNumberBeforeInd(str, ind);
            if isempty(cvNum)
                cvNum = 0;
            end
        end
        
        function targetNum = getTargetNum (this, str)
            %returns zero, if not target dependend
            ind = strfind(str, 'Pearson');
            if isempty(ind)
                targetNum = 0;
                return;
            end
            targetNum = this.getNumberBeforeInd(str, ind);
        end
        
        function [num, ind] = getNumberBeforeInd(~, str, ind)
            %number is the extracted number
            %ind is the index in str where the number starts
            
            if ind == 1
                num = [];
                ind = 0;
                return;
            end
            %1. get length of number
            len = 0;
            for i = ind-1:-1:1
                if strfind('0123456789,.-', str(i))
                    len = len + 1;
                else
                    break;
                end
            end
            if len == 0
                num = [];
                ind = [];
                return;
            end
            ind = ind - len;
            str = str(ind:end);
            num = sscanf(str, '%d');
        end
    end
    
end

