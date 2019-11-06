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

classdef SignalChainElementInterface < matlab.mixin.Copyable
    %SIGNALCHAINELEMENTINTERFACE Abstract interface for an element of a
    %signal processing pipeline.
    %   This abstract class provides the interface for the basic
    %   comunication within a signal processing pipeline. This includes
    %   performing signal processing steps and providing signal Id and
    %   cycles to process.
    %   Additional tasks handeled using this interface are the retrival of
    %   training results and reports about training and data
    
    properties (Access = protected)
        id = ''; %ID of signal that is provided by this element
        % The ID depends on all signal processing steps taken so far and
        % the operation performed by this element. It is unique for each
        % signal and allows traceback to the origin of the signal.
    end
    
    properties (Access = public)
        next = []; %Next element in signal processing pipeline.
        % The next element implements SignalChainElementInterface. The ID
        % of next will be  be forwarded in the signal chain they will be
        % forwarded to the next element.
    end
    
    methods (Abstract)
        step(this, data, metaInfo)
        %Processes a single line of data and forwards results to the next
        %element
        %
        %Inputs:
        %this:     Object that implements SignalChainElementInterface and
        %          processes the data.
        %data:     Numeric row-vector containing the data to process
        %metaInfo: Containers.map object containing meta information about
        %          the processed Signal. All Keys are strings. On
        %          12.08.2016 the following keys are in use:
        %   ID:               String naming the current ID of the signal.
        %                     As the signal is processed further the id
        %                     will grow. It is unique and allows
        %                     backtracking.
        %   TotalNumCycles:   Total number of cycles that are going to be
        %                     handeled in this signal chain.
        %   Training:         Boolean flag indicating the processing mode.
        %   Selected:         Optional; Indicates which features have been
        %                     selected.
        %   RelativeCycleNum: Relative number of the processed cycle.
        %   cycleNum:         Absolute cycle num in dataset.
        %   MaxPreselectedFeat: Maximum number of features that should be
        %                     preselected.
        %   EvaluationData:   Boolean flag that is set to true for data
        %                     that is used for evaluation data, when
        %                     training and evaluation data is used instead
        %                     of cross-validation.
    end
    
    methods
        function [noteDataArray, linkDataArray] = report(this)
        %Adds Info to the document doc if this belongs to the signal path
        %specified by reducedSignalId and forwards the call to the next
        %element. This function is meant to create a training and data
        %report to give an overview of the dataanalysis and its results.
        %
        %Inputs:
        %this:            Signal chain element whos Info is added to doc.
        %doc:             Document the information is added to. The
        %                 document is a power point presentation.
        %reducedSignalId: Signal Id specifying the signal path from this
        %                 element to the end element
        %
        %Outputs:
        %info:            Current Placeholder for information that is
        %                 needed but not added to doc.
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
        end
            
        
        
        function ends = getResults(this, metaInfo)
        %Returns all elements in the signal chain that contain results.
        %metaInfo specifies if training results or computed features should
        %be returned by using the key 'Training' whoes value is boolean.
        %
        %Inputs:
        %this:     Signal chain element that specifies the pipeline to scan
        %          for results.
        %metaInfo: Containers.map object containing the following keys:
        %    Training - Boolean flag indicating wether objects containing
        %               training results or computed features should be
        %               returned
            if ~isempty(this.next)
                ends = this.next.getResults(metaInfo);
            else
                ends = {};
            end
        end
        
        function combineResults(this, id, obj)
        %Combines the results of the object specified by id, that is part of
        %the signal chain that starts with this, with the results of object
        %obj that implements SignalChainElementInterface and is of the same
        %class as the object specified by id.
        %
        %Inputs:
        %this: Signal chain element that is the start of the signal chain
        %      that contains the element specified by this.
        %id:   Id of a signal in the signal chain whoes results should be
        %      combined with the ones stored in obj.
        %obj:  Signal chain element that contains results or computed
        %      features that should be combined with the results in the
        %      object specified by id of the same type.
            if ~isempty(this.next) && length(this.id) <= length(id) && strcmp(this.id, id(end-length(this.id)+1:end))
                this.next.combineResults(id, obj);
            end
        end
        
        function ind = getUsedCycles(this, ind, metaInfo)
        %Returns a boolean array that indicates for each cycle if this
        %cycle is going to be precessed or not. Standard is to use all
        %aviable cycles unless specified elese.
        %
        %Inputs:
        %this:     Object that implements SignalChainElementInterface whos
        %          used cycles are requested.
        %ind:      Boolean vector specifying which of the cycles should be
        %          checked for usage.
        %metaInfo: Containers.map object containing the key 'Training'
        %          whoes boolean value
        %
        %Outputs:
        %ind:   boolean array specifying if the corresponding cycle is to
        %       be processed by this.
            if ~isempty(this.next)
                ind = this.next.getUsedCycles(ind, metaInfo);
            end
        end
        
        
        function id = getId(this)
        %Returns the Id of the signal that is provided by this element
        %
        %Inputs:
        %this:  Object that implements SignalChainElementInterface whos Id
        %       is requested
        %
        %Outputs:
        %id:    Signal-Id of this as string.
            id = this.id;
        end
        
        function setId(this, id)
        %Sets the id of this signal chain element to id perpended by the
        %idsuffix of the corresponding object. Also the rest of the signal
        %chain is notifyed by the id chain and adopted.
        %
        %Inputs:
        %this: Signal chain element whos signal is changed.
        %id:   String containing the new id.
            this.id = [this.idSuffix, id];
            if ~isempty(this.next)
                this.next.setId(this.id);
            end
        end
        
        function addNextElement(this, element)
        %Sets next element in the signal processing chain.
        %This function also updates the id of the next element in the
        %signal chain.
        %
        %Inputs:
        %this:    Signal chain element whos signal chain is extended.
        %element: Next signal chain elmenent in the signal chain.
            this.next = element;
            this.next.setId(this.id);
        end
        
        function all = getAllElements(this, dublicates)
        %Returns a cell array of all the SignalChainElements that are
        %contained in this signal chain with or without dublicates and this
        %element. The order is arbitrary.
        %
        %Inputs:
        %this: SignalChainElement that represents the start of the signal
        %      chain whos elements are requested.
        %dublicates: Boolean flag specifying, if dublicalte objects are
        %      wanted or not. Mainly for speedup reasons.
        %
        %Outputs:
        %all:  Cell array containing all the SignalChainElements contained
        %      in this signal chain.
            all = {this};
            if ~isempty(this.next)
                all = [all, this.next.getAllElements(true)];
            end
            
            if ~dublicates
                %remove dublicates
                ids = cellfun(@getId, all, 'UniformOutput', false);
                [~, ind] = unique(ids);
                all = all(ind);
            end
        end
            
%         function new = copy(this)
%         %Create a deep copy of this elment. For more details see
%         %CopyableHandleInterface.m
%         %
%         %Inputs:
%         %this: Signal Chain Elment that is deep copied.
%             new = feval(class(this));
%             
%             warning('off', 'MATLAB:structOnObject');
%             p = fieldnames(struct(this));
%             for i = 1:length(p)
%                 try
%                     if isa(struct(this).(p{i}), 'CopyableHandleInterface')
%                         new.(p{i}) = this.(p{i}).copy();
%                     else
%                         new.(p{i}) = struct(this).(p{i});
%                     end
%                 catch ME
%                     if ~strcmp(ME.identifier, 'MATLAB:class:SetProhibited')
%                         throw(ME);
%                     end
%                 end
%             end
%         end 
        
        function clearTempData(this, show)
        %Finishs training and clears temporary data from objects. Example:
        %for the computation of the mean value this function computes the
        %mean value and deletes sum and count. Call this function to save
        %memory after training of feature 
        %
        %Inputs:
        %this: Object whos temporary data is erased.
            if ~isempty(this.next)
                this.next.clearTempData(show);
            end
        end
        
        function info = getFeatInfo(this, info)
            f = Factory.getFactory();
            if isempty(info)
                info = f.getFeatureInfoSet();
            end
            
            info.addProperty('SignalChainId', this.getId());
            
            %Pass on to next element
            if ~isempty(this.next)
                info = this.next.getFeatInfo(info);
            end
        end
    end
end

