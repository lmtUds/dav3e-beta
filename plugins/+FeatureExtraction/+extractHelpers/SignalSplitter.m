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

classdef SignalSplitter < FeatureExtraction.extractHelpers.SignalChainElementInterface
    %SIGNALSPLITTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        idSuffix = 'Spl';
    end
    
    methods
        function addNextElement(this, element)
            %check if element has been added before
            if isempty(this.next)
                this.next = {};
            end
            if ~any(this.next == element)
                this.next =  [this.next, {element}];
                element.setId(this.id);
            end
        end
        
        function step(this, data, metaInfo)
            metaInfo('ID') = [this.idSuffix, metaInfo('ID')];
            if isempty(this.id)
                this.id = metaInfo('ID');
            end
            for i = 1:length(this.next)
                metaInfo('ID') = this.id;
                this.next{i}.step(data, metaInfo);
            end
        end
        
        function [noteDataArray, linkDataArray] = report(this)
            noteDataArray = cell(1);
            noteDataArray{1} = {this.getId(), this.idSuffix};
            
            linkDataArray = {};
            if ~isempty(this.next)
                for i = 1:length(this.next)
                    [nDA, lDA] = this.next{i}.report();
                    noteDataArray = [noteDataArray, nDA]; %#ok<AGROW>
                    linkDataArray = [linkDataArray, {{this.getId(), this.next{i}.getId()}}, lDA]; %#ok<AGROW>
                end
            end
        end
        
        function ends = getResults(this, metaInfo)
        %Returns the end elements in the signal pipeline
            ends = {};
            if ~isempty(this.next)
                for i = 1:length(this.next)
                    elem = this.next{i}.getResults(metaInfo);
                    if ~isempty(elem)
                        ends = [ends, elem]; %#ok<AGROW>
                    end
                end
            end
            %remove dublicates;
            ids = cellfun(@getId, ends, 'UniformOutput', false);
            [~, ind] = unique(ids);
            ends = ends(ind);
        end
        
        function combineResults(this, id, obj)
            if ~isempty(this.next) && length(this.id) <= length(id) && strcmp(this.id, id(end-length(this.id)+1:end))
                for i = 1:length(this.next)
                    this.next{i}.combineResults(id, obj);
                end
            end
        end
        
        function ind = getUsedCycles(this, ind, metaInfo)
            if ~isempty(this.next)
                iTemp = ind;
                ind(:) = false;
                for i = 1:length(this.next)
                    ind = ind | this.next{i}.getUsedCycles(iTemp, metaInfo);
                end
            else
                ind(:) = true;
            end
        end
        
        function setId(this, id)
            this.id = [this.idSuffix, id];
            if ~isempty(this.next)
                for i = 1:length(this.next)
                    this.next{i}.setId(this.id);
                end
            end
        end
        
        function all = getAllElements(this, dublicates)
            all = {this};
            if ~isempty(this.next)
                temp = cell(1,length(this.next));
                for i = 1:length(this.next)
                    temp{i} = this.next{i}.getAllElements(true);
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
            if ~isempty(this.next)
                for i = 1:length(this.next)
                    this.next{i}.clearTempData(show);
                end
            end
        end
        
        function info = getFeatInfo(this, info)
            f = FeatureExtraction.extractHelpers.Factory.getFactory();
            if isempty(info)
                info = f.getFeatureInfoSet();
            end
            info.addProperty('SignalChainId', this.getId());
            
            
            %Pass on to next element
            if ~isempty(this.next)
                infos = cell(1, length(this.next));
                for i = 1:length(this.next)
                    infos{i} = this.next{i}.getFeatInfo(info.copy());
                end
                if any(cellfun(@iscell, infos))
                    infos = infos(~cellfun(@isempty, infos));
                    for i = 1:length(infos)
                        if ~iscell(infos{i})
                            infos{i} = infos(i);
                        end
                    end
                    info = horzcat(infos{:});
                else
                    info = infos(~cellfun(@isempty, infos));
                    info = reshape(info, 1, numel(info));
                end
            end
        end
    end
end

