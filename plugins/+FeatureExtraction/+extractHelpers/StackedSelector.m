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

classdef StackedSelector < FeatureExtraction.extractHelpers.SignalChainElementInterface & FeatureExtraction.extractHelpers.RankingInterface
    %JOINEDSELECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        selectors = {};
        updateSel = true;
        r = [];
        i = [];
        n = [];
    end
    
    properties (Constant)
        idSuffix = 'StackSel';
    end
    
    methods
        function this = StackedSelector(selectors, varargin)
            if nargin > 0
                this.selectors = selectors;
            end
            if nargin > 1
                this.updateSel = varargin{1};
            else
                this.updateSel = true;
            end
        end
        
        function step(this, data, metaInfo)
            metaInfo('ID') = [this.idSuffix, metaInfo('ID')];
            if isempty(this.id)
                this.setId(metaInfo('ID'))
            end
            
            if this.updateSel && isKey(metaInfo, 'Training') && metaInfo('Training')
                for i = 1:length(this.selectors) %#ok<PROPLC>
                    metaInfo('ID') = this.id;
                    this.selectors{i}.step(data, metaInfo); %#ok<PROPLC>
                end
            end
            
            metaInfo('ID') = this.id;
            if ~isempty(this.next) && (isKey(metaInfo, 'Training') && ~metaInfo('Training'))
                %pass on signal with current seletion
                if isempty(this.i)
                    [~, ind, ~] = this.getRanking();
                else
                    ind = this.i;
                end
                metaInfo('Selected') = ind;
                this.next.step(data(ind), metaInfo);
            end
        end
        
        function [ranking, ind, numToSel] = getRanking(this)
            if isempty(this.i)
                [ranking, ind, numToSel] = this.selectors{1}.getRanking();
    %             indGlobal = 1:size(ranking,2);
    %             [~, ind] = sort(ranking, 'descend');
    %             indGlobal = indGlobal(ind(1:numToSel));
    %             
                for i = 2:length(this.selectors) %#ok<PROP>
                    [ranking2, ~, numToSel2] = this.selectors{i}.getRanking(); %#ok<PROP>
                    numToSel2 = min([numToSel2, numToSel]);
                    [~, ind2] = sort(ranking2(ind), 'descend');
                    index = false(1, size(ind2, 2));
                    if isa(ind2, 'gpuArray')
                        index = gpuArray(index);
                    end
                    index(ind2(1:numToSel2)) = true;
                    ind(ind) = index;
    %                 index = find(ind);
    %                 ind(index(ind2(numToSel2+1:end))) = false;
                    ranking = ranking2;
                    numToSel = numToSel2;
                end

                this.r = ranking;
                this.i = ind;
                this.n = numToSel;
            else
                ranking = this.r;
                ind = this.i;
                numToSel = this.n;
            end
        end
        
        function [noteDataArray, linkDataArray] = report(this)
            noteDataArray = cell(1);
            noteDataArray{1} = {this.getId(), this.idSuffix};
            if isempty(this.next)
                linkDataArray = {};
            else
                linkDataArray = cell(1);
                linkDataArray{1} = {this.getId(), this.next.getId()};
                [nDA, lDA] = this.next.report();
                noteDataArray = [noteDataArray, nDA];
                linkDataArray = [linkDataArray, lDA];
            end
            %Links to selectors:
            %If selectors should be updated they have to be included
            %here -> add Objects only if neccesarious
            if this.updateSel
               for i = 1:length(this.selectors) %#ok<PROP>
                    [nDA, lDA] = this.selectors{i}.report(); %#ok<PROP>
                    noteDataArray = [noteDataArray, nDA]; %#ok<AGROW>
                    linkDataArray = [linkDataArray, lDA]; %#ok<AGROW>
                end
            end
            %If selectors should not be updated only the links are
            %missing -> Always add links
            for i = 1:length(this.selectors) %#ok<PROP>
                linkDataArray{end+1} = {this.selectors{i}.getId(), this.getId()}; %#ok<AGROW,PROP>
            end
        end
        
        function setId(this, id)
            this.id = [this.idSuffix, id];
            selSuffix = '';
            for i = 1:length(this.selectors) %#ok<PROPLC>
                if this.updateSel
                    this.selectors{i}.setId(this.id); %#ok<PROPLC>
                end
                suffix = this.selectors{i}.idSuffix; %#ok<PROPLC>
                fullId = this.selectors{i}.getId(); %#ok<PROPLC>
                k = strfind(fullId, suffix);
                selSuffix = [fullId(1:k+length(suffix)-1) , selSuffix]; %#ok<AGROW>
            end
            this.id = [selSuffix, this.id];
            if ~isempty(this.next)
                this.next.setId(this.id);
            end
        end
        
        function ends = getResults(this, metaInfo)
        %Returns the end elements in the signal pipeline
            ends = {};
            if ~isempty(this.next)
                ends = this.next.getResults(metaInfo);
            end
            if this.updateSel
                for i = 1:length(this.selectors) %#ok<PROPLC>
                    temp = this.selectors{i}.getResults(metaInfo); %#ok<PROPLC>
                    for j = 1:length(temp)
                        ends = [ends, temp(j)]; %#ok<AGROW>
                    end
                end
            end
        end
        
        function combineResults(this, id, obj)
            if length(this.id) <= length(id) && strcmp(this.id, id(end-length(this.id)+1:end))
                if ~isempty(this.next)
                    this.next.combineResults(id, obj);
                end
            end
            if this.updateSel
                for i = 1:length(this.selectors) %#ok<PROPLC>
                    this.selectors{i}.combineResults(id, obj); %#ok<PROPLC>
                end
            end
        end
        
        function all = getAllElements(this, dublicates)
            all = {this};
            if ~isempty(this.next)
                all = [all, this.next.getAllElements(true)];
            end
            
            if ~isempty(this.selectors)
                temp = cell(1, length(this.selectors));
                for i = 1:length(this.selectors) %#ok<PROPLC>
                    temp{i} = this.selectors{i}.getAllElements(true); %#ok<PROPLC>
                end
                all = horzcat(all, temp{:});
            end
            
            if ~dublicates
                %remove dublicates
                ids = cellfun(@getId, all, 'UniformOutput', false);
                [~, ind] = unique(ids);
                all = all(ind);
            end
        end
        
        function clearTempData(this, show)
            if this.updateSel
                for i = 1:length(this.selectors) %#ok<PROPLC>
                    this.selectors{i}.clearTempData(show); %#ok<PROPLC>
                end
            end
                    
            if ~isempty(this.next)
                this.next.clearTempData(show);
            end
        end
        
        function info = getFeatInfo(this, info)
            [ranking, ind] = this.getRanking;
            f = FeatureExtraction.extractHelpers.Factory.getFactory();
            if isempty(info)
                info = f.getFeatureInfoSet();
            end
            
            ids = cellfun(@getId, this.selectors, 'UniformOutput', false);
            id = info.getProperty('SignalChainId');
            id = id{1};
            if any(strcmp(ids, id))
                info = [];
            else
                info.addProperty('SignalChainId', this.getId());
            end
            info.removeFeature(~this.i);
            info.addProperty('Correlation', num2cell(ranking(ind)));
            
            %Pass on to next element
            if ~isempty(this.next) && ~isempty(info)
                info = this.next.getFeatInfo(info);
            end
        end
    end
    
end

