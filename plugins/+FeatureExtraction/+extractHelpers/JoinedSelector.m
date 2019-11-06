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


classdef JoinedSelector < FeatureExtraction.extractHelpers.SignalChainElementInterface & FeatureExtraction.extractHelpers.RankingInterface
    %JOINEDSELECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sigToJoin = {};
        ids = {};
        signalUpdated = logical.empty(1,0);
        receivedSignals = 0;
        receivedSignalData = {};
        ranks = {};
        initialized = false;
        maxSelect = 500;
        infoUpdates = [];
        receivedInfos = {};
        selected = {};
        i = [];
        n = [];
        r = [];
    end
    
    properties (Constant)
        idSuffix = 'JoinedSel'
    end
    
    methods
        function this = JoinedSelector(SignalsToJoin, numToSelect)
            if nargin > 0
                this.sigToJoin = SignalsToJoin;
                this.signalUpdated = false(length(SignalsToJoin), 1);
                this.receivedInfos = cell(1, length(SignalsToJoin));
            end
            if nargin > 1
                this.maxSelect = numToSelect;
            end
        end
        
        function [rank, ind, numToSelect] = getRanking(this)
            if isempty(this.r)
                [rank, ind, numToSelect] = this.sigToJoin{1}.getRanking();
                %ToDo: skip if this.rankings has been initialized
                for i = 2:length(this.sigToJoin)
                    [rank2, ind2, numToSelect2] = this.sigToJoin{i}.getRanking();
                    rank = [rank, rank2]; %#ok<AGROW>
                    ind = [ind, ind2]; %#ok<AGROW>
                    numToSelect = numToSelect + numToSelect2;
                end
                numToSelect = min([numToSelect, this.maxSelect]);
                rank = rank(ind);
                [~, rankInd] = sort(rank, 'descend');
                if isa(rank, 'gpuArray')
                    ind = false(1, length(rank), 'gpuArray');
                    ind(rankInd(1:numToSelect)) = true;
                else
                    ind = false(1, length(rank));
                    ind(rankInd(1:numToSelect)) = true;
                end
                this.r = rank;
                this.i = ind;
                this.n = numToSelect;
            else
                rank = this.r;
                ind = this.i;
                numToSelect = this.n;
            end
        end
        
        function step(this, data, metaInfo)
            id = metaInfo('ID');
            if isempty(this.id)
                this.id = [this.idSuffix, metaInfo('ID')];
            end
            metaInfo('ID') = this.id;
            
            if isempty(this.maxSelect) && isKey(metaInfo, 'MaxPreselectedFeat')
                this.maxSelect = metaInfo('MaxPreselectedFeat');
            elseif isempty(this.maxSelect)
                this.maxSelect = 500;
            end
            
            if metaInfo('Training')
                return;
            end
            
            signalIDs = cell(1, length(this.sigToJoin));
            for i = 1:length(this.sigToJoin)
                signalIDs{i} = this.sigToJoin{i}.id;
            end
            ind = strcmp(signalIDs, id);
            if sum(ind) > 1
                disp(signalIDs');
                disp(this.id);
            end
            
            if ~this.initialized
                this.updateInitialisation( ind, data, id, metaInfo);
            else
                this.updateData( ind, data, metaInfo);
            end
        end
        
        function [noteDataArray, linkDataArray] = report(this)
            if isempty(this.infoUpdates)
                this.infoUpdates = 0;
            end
            
            this.infoUpdates = this.infoUpdates + 1;
            
            if all(this.infoUpdates >= length(this.sigToJoin))
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
                this.infoUpdates = 0;
            else
                noteDataArray = {};
                linkDataArray = {};
            end
        end
        
        function info = getFeatInfo(this, info)
            if isempty(info)
                error('JoinedSelector cannot be the first element in feature extraction.');
            end
            
            %find out which signal called this function
            signalIDs = cell(1, length(this.sigToJoin));
            for i = 1:length(this.sigToJoin)
                signalIDs{i} = this.sigToJoin{i}.getId();
            end
            id = info.getProperty('SignalChainId');
            if iscell(id)
                id = id{1};
            end
            ind = strcmp(signalIDs, id);
            this.receivedInfos{ind} = info;
            info.addProperty('SignalChainId', this.getId());
            
            if all(~cellfun(@isempty, this.receivedInfos))
                info = this.receivedInfos{1};
                for i = 2:length(this.receivedInfos) %#ok<PROPLC>
                    info.join(this.receivedInfos{i}); %#ok<PROPLC>
                end
                [~, index] = this.getRanking();
                info.removeFeature(~index);
            else
                info = [];
            end
            
            %Pass on to next element
            if ~isempty(this.next) && ~isempty(info)
                info = this.next.getFeatInfo(info);
                this.receivedInfos = cell(size(this.sigToJoin));
            end
        end
    end
    
    methods(Access = private)
        function updateInitialisation(this, ind, data, id, metaInfo)
            this.receivedSignals = this.receivedSignals + 1;
            this.ids{ind} = id;
            this.signalUpdated(ind) = true;
            this.ranks{ind} = this.sigToJoin{ind}.getRanking();
            this.receivedSignalData{ind} = data;
            this.selected{ind} = metaInfo('Selected');
            if all(this.signalUpdated)
                this.initialized = true;
                this.updateData(ind, data, metaInfo)
            end
        end
        
        function updateData(this, ind, data, metaInfo)
            this.receivedSignals = this.receivedSignals + 1;
            this.signalUpdated(ind) = true;
            this.receivedSignalData{ind} = data;
            if this.receivedSignals >= length(this.sigToJoin)
                if ~isempty(this.next)
                    %build data
                    %ToDo: optimize with horzcat
                    d = this.receivedSignalData{1};
                    for i = 2:length(this.receivedSignalData) %#ok<PROPLC>
                        d = [d, this.receivedSignalData{i}]; %#ok<PROPLC,AGROW>
                    end
                    [~, index, ~] = this.getRanking();
                    %forward call
                    i = horzcat(this.selected{:}); %#ok<PROPLC>
                    i(i) = index; %#ok<PROPLC>
                    metaInfo('Selected') = i; %#ok<PROPLC>
                    this.next.step(d(index), metaInfo);
                end
                %reset data Collection
                this.receivedSignals = 0;
                this.signalUpdated = false(length(this.receivedSignals), 1);
                this.receivedSignalData = cell(length(this.receivedSignals), 1);
            end
        end
    end
    
end

