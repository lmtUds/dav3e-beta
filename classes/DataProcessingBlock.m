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

classdef DataProcessingBlock < Descriptions
    properties
        infoFcn
        applyFcn
        trainFcn
        revertFcn
        resetFcn
        updateParametersFcn
        detailsPages
        requiresNumericTarget = false
        parameters
        type
        prevBlock
        nextBlock
        
        defaultCopy = false;
        upToDate = false
        saveData = false
        data
        
        empty = false
    end
    
    methods
        function obj = DataProcessingBlock(fcn)
            obj = obj@Descriptions();
            if nargin == 0
                obj.empty = true;
                return
            end
            obj.infoFcn = fcn;
            funs = fcn();
            obj.setCaption(funs.caption);
            obj.setShortCaption(funs.shortCaption);
            obj.setDescription(funs.description);
            obj.applyFcn = funs.apply;
            obj.type = funs.type;
            obj.prevBlock = DataProcessingBlock.empty;
            obj.nextBlock = DataProcessingBlock.empty;
            
            if isfield(funs,'requiresNumericTarget')
                obj.requiresNumericTarget = funs.requiresNumericTarget;
            end
            
            try
                obj.trainFcn = funs.train;
            catch
                obj.trainFcn = [];
            end
            
            try
                obj.revertFcn = funs.revert;
            catch
                obj.revertFcn = [];
            end
            
            try
                obj.resetFcn = funs.reset;
            catch
                obj.resetFcn = [];
            end
            
            try
                obj.updateParametersFcn = funs.updateParameters;
            catch
                obj.updateParametersFcn = [];
            end
            
            try
                obj.parameters = funs.parameters;
                if isempty(obj.parameters)
                    obj.parameters = Parameter.empty;
                end
            catch
                obj.parameters = Parameter.empty;
            end
            
            try
                obj.detailsPages = funs.detailsPages;
            catch
                obj.detailsPages = [];
            end
        end
        
        function s = toStruct(objArray,objmap)
            if nargin < 2
                objmap = containers.Map();
            end
            s = toStruct@Descriptions(objArray);
            for i = 1:numel(objArray)
                obj = objArray(i);
                if isKey(objmap,obj.getUUID())
                    
                end
                s(i).infoFcn = func2str(obj.infoFcn);
                s(i).prevBlock = obj.prevBlock.getUUID();
                s(i).nextBlock = obj.nextBlock.getUUID();
                s(i).defaultCopy = obj.defaultCopy;
                s(i).parameters = obj.parameters.getMapWithUUIDRefs();
            end
        end
        
        function json = jsondump(objArray)
            s = objArray.toStruct();
            json = jsonencode(s);
        end

        function dates = getModifiedDate(objArray)
            if isempty(objArray)
                dates = datetime.empty;
                return
            end
            dates = [objArray.modifiedDate];
            for i = 1:numel(objArray)
                dates(i) = max([dates(i),objArray(i).parameters.getModifiedDate()]);
            end
        end         
        
%         function hParams = getChainHyperParameters(obj,hParams)
%             if nargin < 2
%                 hParams = struct();
%             end
%             hParams.(char(obj.getShortCaption())) = obj.getHyperParameters();
%             for i = 1:numel(obj.nextBlock)
%                 hParams = obj.nextBlock(i).getChainHyperParameters(hParams);
%             end
%         end
        
        function hParams = getHyperParameters(obj)
            internal = [obj.parameters.internal];
            hParams = obj.parameters(~internal).getStruct();
        end
        
        function setHyperParameters(obj,hParams)
            hidden = [obj.parameters.hidden];
            obj.parameters(~hidden).updateFromStruct(hParams);
        end
        
        function trainChain(obj,data,paramIn)
            if isempty(obj)
                return
            end            
            params = obj.parameters.getStruct();
            if nargin >= 3 && ~isempty(paramIn)  % paramIn
                exptectedField = [char(obj.type) '_' char(obj.getShortCaption())];
                if isfield(paramIn,exptectedField)
                    partParams = paramIn.(exptectedField);
                else
                    partParams = paramIn;
                end
                params = updateStruct(params,partParams);
            else
                paramIn = struct();
            end
            
            obj.train(data,params);
            data = obj.apply(data);
            for i = 1:numel(obj.nextBlock)
                obj.nextBlock(i).trainChain(data,paramIn);
            end
        end
        
        function data = applyChain(obj,data,paramIn)
            if isempty(obj)
                return
            end
            params = obj.parameters.getStruct();
            if nargin >= 3 && ~isempty(paramIn)  % paramIn
                exptectedField = [char(obj.type) '_' char(obj.getShortCaption())];
                if isfield(paramIn,exptectedField)
                    partParams = paramIn.(exptectedField);
                else
                    partParams = paramIn;
                end
                params = updateStruct(params,partParams);
            else
                paramIn = struct();
            end

            [data,~] = obj.apply(data,params);
            for i = 1:numel(obj.nextBlock)
                data = obj.nextBlock(i).applyChain(data,paramIn);
            end
        end

        function numData = revertChain(obj,numData,paramIn)
            if isempty(obj)
                return
            end
            params = obj.parameters.getStruct();
            if nargin >= 3 && ~isempty(paramIn)  % paramIn
                exptectedField = [char(obj.type) '_' char(obj.getShortCaption())];
                if isfield(paramIn,exptectedField)
                    partParams = paramIn.(exptectedField);
                else
                    partParams = paramIn;
                end
                params = updateStruct(params,partParams);
            else
                paramIn = struct();
            end
            
            numData = obj.revert(numData,params);
            for i = 1:numel(obj.prevBlock)
                numData = obj.prevBlock(i).revertChain(numData,paramIn);
            end
        end
        
        function val = isInitBlock(obj)
            if (obj.type == DataProcessingBlockTypes.Validation) || ...
                   (obj.type == DataProcessingBlockTypes.Testing) || ...
                   (obj.type == DataProcessingBlockTypes.Annotation) || ...
                   (obj.type == DataProcessingBlockTypes.DataReduction) || ...
                   (obj.type == DataProcessingBlockTypes.TargetPreprocessing)
               val = true;
               return
            end
            val = false;
        end        
        
        function [data,params] = apply(obj,data,paramIn,copy)
            if isa(data,'Data') && data.hasIrreversibleChanges
                error('Data has irreversible changes. Try copying the original.')
            end
            params = obj.parameters.getStruct();
            if nargin >= 3 && ~isempty(paramIn)  % paramIn
                params = updateStruct(params,paramIn);
            end
            if nargin < 4  % copy
                copy = obj.defaultCopy;
            end
            
            if obj.isInitBlock()
                return
            end
            if isempty(obj)
                return
            end            
            
            if copy
                data = data.copy();
            end
            [data,params] = obj.applyFcn(data,params);
            obj.parameters.updateFromStruct(params);
        end

        function train(obj,data,paramIn)
            if isa(data,'Data') && data.hasIrreversibleChanges
                error('Data has irreversible changes. Try copying the original.')
            end        
            params = obj.parameters.getStruct();
            if nargin >= 3 && ~isempty(paramIn)  % paramIn
                params = updateStruct(params,paramIn);
            end
            
            if obj.isInitBlock()
                return
            end
            if isempty(obj) || isempty(obj.trainFcn)
               return 
            end            
            
            params = obj.trainFcn(data,params);
            obj.parameters.updateFromStruct(params);
        end
        
        function reset(obj)
            params = obj.parameters.getStruct();

            if isempty(obj) || isempty(obj.resetFcn)
               return 
            end            
            
            params = obj.resetFcn(params);
            obj.parameters.updateFromStruct(params);
        end        
        
        function numData = revert(obj,numData,paramIn)
            if isempty(obj) || isempty(obj.revertFcn)
                return
            end
            params = obj.parameters.getStruct();
            if nargin >= 3 && ~isempty(paramIn)  % paramIn
                params = updateStruct(params,paramIn);
            end
            
            numData = obj.revertFcn(numData,params);
        end
        
        function init(obj,data,paramIn)
            if isa(data,'Data') && data.hasIrreversibleChanges
                error('Data has irreversible changes. Try copying the original.')
            end         
            field = [char(obj.type) '_' char(obj.getShortCaption())];
            params = obj.parameters.getStruct();
            if nargin >= 3 && ~isempty(paramIn) && isfield(paramIn,field)  % paramIn
                params = updateStruct(params,paramIn.(field));
            end

            if isempty(obj) || isempty(obj.applyFcn)
               return 
            end            
            
            [~,params] = obj.applyFcn(data,params);
            obj.parameters.updateFromStruct(params);     
        end
        
        function updateParameters(obj,project)
            if isempty(obj) || isempty(obj.updateParametersFcn)
               return 
            end
            obj.updateParametersFcn(obj.parameters,project);
        end
        
        function [panel,updateFun] = createDetailsPage(obj,caption,parent,project)
            fullpath = [char(obj.type) '.detailsPages.' caption];
            [panel,updateFun] = eval([fullpath '(parent,project,obj);']);
        end
        
        function addBefore(obj,targetBlock)
            if ~isempty(obj.prevBlock) || ~isempty(obj.nextBlock)
                error('Block is already in a chain. Remove with removeFromChain before adding.');
            end
            obj.prevBlock = targetBlock.prevBlock;
            if ~isempty(targetBlock.prevBlock)
                targetBlock.prevBlock.nextBlock = obj;
            end
            targetBlock.prevBlock = obj;
            obj.nextBlock = targetBlock;
        end
        
        function addAfter(obj,targetBlock)
            if ~isempty(obj.prevBlock) || ~isempty(obj.nextBlock)
                error('Block is already in a chain. Remove with removeFromChain before adding.');
            end
            obj.nextBlock = targetBlock.nextBlock;
            if ~isempty(targetBlock.nextBlock)
                targetBlock.nextBlock.prevBlock = obj;
            end
            targetBlock.nextBlock = obj;
            obj.prevBlock = targetBlock;
        end
        
%         function addBetween(obj,blockBefore,blockAfter)
%             pos = ismember(blockBefore.nextBlock,blockAfter);
%             blockBefore.nextBlock(pos) = [];
%             pos = ismember(blockAfter.prevBlock,blockBefore);
%             blockAfter.prevBlock(pos) = [];
%             obj.addAfter(blockBefore);
%             obj.addBefore(blockAfter);
%         end
        
        function addToEnd(obj,chainBlock)
            obj.addAfter(chainBlock.getLastBlock());
        end
        
        function bubbleUp(obj)
            while true
                if isempty(obj.prevBlock)
                    return
                end
                if obj.prevBlock.type > obj.type
                    obj.moveBefore(obj.prevBlock);
                else
                    return
                end
            end
        end

        function moveBefore(obj,block)
            if isempty(block)
                return
            end
            if ~ismember(obj,block.getAllBlocksInChain())
                error('Block cannot be moved to a different chain.');
            end
            obj.removeFromChain();
            obj.addBefore(block);
        end
        
        function moveAfter(obj,block)
            if isempty(block)
                return
            end
            if ~ismember(obj,block.getAllBlocksInChain())
                error('Block cannot be moved to a different chain.');
            end            
            obj.removeFromChain();
            obj.addAfter(block);
        end
        
%         function moveBetween(obj,blockBefore,blockAfter)
%             if isempty(blockBefore) || isempty(blockAfter)
%                 return
%             end
%             obj.prevBlock = [];
%             obj.nextBlock = [];
%             obj.addBetween(blockBefore,blockAfter);
%         end        

        function val = canMoveUp(obj)
            if isempty(obj.prevBlock)
                val = false;
            elseif obj.prevBlock.type < obj.type
                val = false;
            else
                val = true;
            end
        end

        function val = canMoveDown(obj)
            if isempty(obj.nextBlock)
                val = false;
            elseif obj.nextBlock.type > obj.type
                val = false;
            else
                val = true;
            end
        end
        
        function moveUp(obj)
            obj.moveBefore(obj.prevBlock);
        end
        
        function moveDown(obj)
            obj.moveAfter(obj.nextBlock);
        end
        
        function removeFromChain(obj)
            if ~isempty(obj.prevBlock)
                obj.prevBlock.nextBlock = obj.nextBlock;
            end
            if ~isempty(obj.nextBlock)
                obj.nextBlock.prevBlock = obj.prevBlock;
            end
            obj.nextBlock = DataProcessingBlock.empty;
            obj.prevBlock = DataProcessingBlock.empty;
        end
        
        function b = getBlockBefore(obj)
            b = obj.prevBlock;
        end
        
        function b = getBlockAfter(obj)
            b = obj.nextBlock;
        end
        
        function blocks = getAllBlocksInChain(obj)
            if isempty(obj)
                blocks = DataProcessingBlock.empty;
                return
            end
            b = getFirstBlock(obj);
            blocks = b;
            while ~isempty(b.nextBlock)
                blocks = [blocks,b.nextBlock];
                b = b.nextBlock;
            end
        end
        
        function b = getFirstBlock(obj)
            b = obj;
            if isempty(b)
                b = DataProcessingBlock.empty;
                return
            end
            while ~isempty(b.prevBlock)
                b = b.prevBlock;
            end
        end
        
        function b = getLastBlock(obj)
            b = obj;
            if isempty(b)
                b = DataProcessingBlock.empty;
                return
            end
            while ~isempty(b.nextBlock)
                b = b.nextBlock;
            end            
        end
        
        function pgf = makePropGridField(obj)
            pgf = PropGridField(char(obj.getCaption()),'',...
                    'UserData',obj,...
                    'Editable',false,...
                    'Category',char(obj.type));
            pgf.setMatlabObj(obj);
            for i = 1:numel(obj.parameters)
                if obj.parameters(i).internal
                    continue
                end
                prm = obj.parameters(i);
%                 prmpgf = PropGridField(char(prm.getCaption()),prm.getValueCaptions(),...
%                     'enum',prm.getEnumCaptions());
%                 prmpgf.setMatlabObj(prm);
                prmpgf = prm.makePropGridField();
                pgf.addChild(prmpgf);
            end
        end        
        
        function p = getByCaption(objArray,caption)
            p = objArray(objArray.getCaption() == caption);
        end
    end
    
    methods(Static)
        function blocks = fromStruct(s)
            blocks = DataProcessingBlock.empty;
            for i = 1:numel(s)
                b = DataProcessingBlock(str2func(s(i).infoFcn));
                b.prevBlock = s(i).prevBlock;
                b.nextBlock = s(i).nextBlock;
                b.defaultCopy = s(i).defaultCopy;
                
                % tedious because MATLAB parses from JSON to struct only,
                % which is a problem if a map had keys which are not valid
                % MATLAB identifiers -> they are made valid
                % so we simulate that process to find out which parameter
                % value should be set and hope that no name clash occurs
                k = cellstr(matlab.lang.makeUniqueStrings(...
                    matlab.lang.makeValidName(cellstr(b.parameters.getCaption()))));
                paramMap = containers.Map(k,num2cell(b.parameters));
                for j = 1:numel(b.parameters)
                    p = paramMap(k{j});
                    p.value = s(i).parameters(k{j});
                end
                blocks(end+1) = b;
            end
            fromStruct@Descriptions(s,blocks)
        end

        function ranges = jsonload(json)
            data = jsondecode(json);
            ranges = DataProcessingBlock.fromStruct(data);
        end
    end
end