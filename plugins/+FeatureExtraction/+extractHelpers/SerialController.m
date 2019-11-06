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

classdef SerialController < FeatureExtraction.extractHelpers.ControllerInterface
    %SERIALCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        idSuffix = 'Contr'
    end
    
    methods
        function this = SerialController(cv, targetMat)
            if nargin > 0
                this.cv = cv;
                this.targetMat = targetMat;
            end
        end
        
        function trainFeatureExtraction(this)
            if isempty(this.pipelines)
                return;
            end
            
            results = cell(length(this.pipelines),1);
            for i = 1:length(this.pipelines)
            %get the number of cycles to process
                numCyc = this.pipelines{i}.getNumberOfCycles(); 
            %get the cycles that are actually ued
                usedCycMetaInfo = containers.Map({'Training'},true);
                usedCyc = this.pipelines{i}.getUsedCycles(true(numCyc, 1), usedCycMetaInfo);
            %create initial metadata and id
                metadata = containers.Map();
                metadata('ID') = [this.idSuffix, num2str(i)];
                metadata('Training') = true;
                metadata('TotalNumCycles') = sum(usedCyc);
                metadata('MaxPreselectedFeat') = 500;
            %MAP
                ind = 1:numCyc;
                ind = ind(usedCyc);
                relNum = 1;
                for j = ind
                    metadata('ID') = [this.idSuffix, num2str(i)];
                    metadata('RelativeCycleNum') = relNum;
                    this.pipelines{i}.step(j, metadata);
                    relNum = relNum + 1;
                end
                %request computations for all cycles used
                %get the end nodes
                %results{i} = this.pipelines{i}.getResults();
            end
            %Reduce
                %finish the training of the endnodes and combine data
            
            %MAP
                %compute feature matrices
            for i = 1:length(this.pipelines)
            %get the number of cycles to process
                numCyc = this.pipelines{i}.getNumberOfCycles(); 
            %get the cycles that are actually ued
                usedCycMetaInfo = containers.Map({'Training'},[false]);
                usedCyc = this.pipelines{i}.getUsedCycles(true(numCyc, 1), usedCycMetaInfo);
            %create initial metadata and id
                metadata = containers.Map();
                metadata('ID') = [this.idSuffix, num2str(i)];
                metadata('Training') = false;
                metadata('TotalNumCycles') = sum(usedCyc);
                metadata('MaxPreselectedFeat') = 500;
                
                ind = 1:numCyc;
                ind = ind(usedCyc);
                relNum = 1;
                for j = ind
                    metadata('ID') = [this.idSuffix, num2str(i)];
                    metadata('RelativeCycleNum') = relNum;
                    this.pipelines{i}.step(j, metadata);
                    relNum = relNum + 1;
                end
                
                %results{i} = this.pipelines{i}.getResults();
            end
                %Reduce
                %combine feature matrices
            this.extractionTrained = true;
        end
        
        function apply(this)
            i = 1;
            %get the number of cycles to process
                numCyc = this.pipelines{i}.getNumberOfCycles(true); 
            %get the cycles that are actually ued
                usedCycMetaInfo = containers.Map({'Training'},[false]);
                usedCycMetaInfo('EvaluationData') = true;
                usedCyc = this.pipelines{i}.getUsedCycles(true(numCyc, 1), usedCycMetaInfo);
            %create initial metadata and id
                metadata = containers.Map();
                metadata('ID') = [this.idSuffix, num2str(i)];
                metadata('Training') = false;
                metadata('TotalNumCycles') = sum(usedCyc);
                metadata('MaxPreselectedFeat') = 500;
                metadata('EvaluationData') = true;
                
                ind = 1:numCyc;
                ind = ind(usedCyc);
                relNum = 1;
                for j = ind
                    metadata('ID') = [this.idSuffix, num2str(i)];
                    metadata('RelativeCycleNum') = relNum;
                    this.pipelines{i}.step(j, metadata);
                    relNum = relNum + 1;
                end
        end
        
        function addPipeline(this, pl)
            this.pipelines = [this.pipelines, {pl}];
            pl.setId([this.idSuffix, num2str(length(this.pipelines))]);
        end
    end
    
end

