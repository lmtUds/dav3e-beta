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

classdef RAMFeatureMat < FeatureExtraction.extractHelpers.SignalChainElementInterface & FeatureExtraction.extractHelpers.FeatureMatrixInterface
    %FEATUREMAT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        idSuffix = 'RAMFeatMat'
    end
    
    properties (Access = public)
        featMat = [];
        evalData = [];
        cycleInd = 0;
        cycleIndEval = 0;
        cycleNums = [];
        cycleNumsEval = [];
    end
    
    methods
        function step(this, data, metaInfo)
            metaInfo('ID') = [this.idSuffix, metaInfo('ID')];
            if isempty(this.id)
                this.id = metaInfo('ID');
            end
            if isKey(metaInfo, 'EvaluationData') && metaInfo('EvaluationData')
                mat = this.evalData;
                this.cycleIndEval = this.cycleIndEval + 1;
                if ~isempty(mat)
                    if isempty(this.cycleNumsEval)
                        this.cycleNumsEval = metaInfo('cycleNum');
                    elseif this.cycleNumsEval(end) ~= metaInfo('cycleNum')
                        this.cycleNumsEval(end+1) = metaInfo('cycleNum');
                    end
                        
                end
                cycInd = this.cycleIndEval;
            else
                mat = this.featMat;
                this.cycleInd = this.cycleInd + 1;
                if ~isempty(mat) && this.cycleNums(end) ~= metaInfo('cycleNum')
                    this.cycleNums(end+1) = metaInfo('cycleNum');
                end
                cycInd = this.cycleInd;
            end
            
            if isempty(mat)
                if isKey(metaInfo, 'EvaluationData') && metaInfo('EvaluationData')
                    this.cycleNumsEval = metaInfo('cycleNum');
                    mat = this.evalData;
                else
                    this.cycleNums = metaInfo('cycleNum');
                    mat = this.featMat;
                end
                
                if isa(data, 'gpuArray')
                    temp = gather(data);
                else
                    temp = data;
                end
                
                if isKey(metaInfo, 'ChunkSize')
                    mat(:,:) = zeros(size(data, 2), metaInfo('ChunkSize'), 'like', temp);
                elseif isKey(metaInfo, 'TotalNumCycles')
                    mat(:,:) = zeros(size(data, 2), metaInfo('TotalNumCycles'), 'like', temp);
                else
                    mat(:,:) = zeros(size(data'), 'like', temp);
                end
            end
            
            if isa(data, 'gpuArray')
                mat(:, cycInd) = gather(data)';
            else
                mat(:, cycInd) = data';
            end
            
            if isKey(metaInfo, 'EvaluationData') && metaInfo('EvaluationData')
                this.evalData = mat;
            else
                this.featMat = mat;
            end
            
            if ~isempty(this.next)
                if isKey(metaInfo, 'EvaluationData') && metaInfo('EvaluationData')
                    this.next.step(this.evalData(:,:)', metaInfo);
                else
                    this.next.step(this.featMat(:,:)', metaInfo);
                end
            end
        end
        
        function ends = getResults(this, metaInfo)
        %Returns the end elements in the signal pipeline
            ends = {};
            if ~isempty(this.next)
                ends = this.next.getResults(metaInfo);
            end
            if isKey(metaInfo, 'Training') && ~metaInfo('Training') && ~isempty(this.featMat)
                ends = [ends, {this}];
            end
        end
        
        function combineResults(this, id, obj)
            if ~isempty(this.next) && length(this.id) <= length(id) && strcmp(this.id, id(end-length(this.id)+1:end))
                this.next.combineResults(id, obj);
            end
            error('not yet supported!')
        end
        
        function d = getFeatMat(this, cv, target, eval)
            if cv ~= 1
                error('FeatureMat does not depend on the cross-validation-fold.')
            end
            if target ~= 1
                error('FeatureMat does not depend on the target.');
            end
            if eval
                d = this.evalData;
            else
            	d = this.featMat;
            end
        end
        
        function delete(this)
            this.featMat = [];
            this.evalData = [];
            %delete(this.filename);
        end
    end
end

