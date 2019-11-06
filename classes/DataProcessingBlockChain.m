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

classdef DataProcessingBlockChain < Descriptions
    properties
        blocks
    end
    
    properties(Dependent)
        requiresNumericTarget
    end
    
    methods
        function obj = DataProcessingBlockChain()
            obj = obj@Descriptions();
            obj.blocks = DataProcessingBlock.empty;
        end
        
        function val = get.requiresNumericTarget(obj)
            val = false;
            for i = 1:numel(obj.blocks)
                if obj.blocks(i).requiresNumericTarget
                    val = true;
                    return
                end
            end
        end
        
        function s = toStruct(objArray)
            s = toStruct@Descriptions(objArray);
            for i = 1:numel(objArray)
                obj = objArray(i);
                s(i).blocks = obj.blocks.toStruct();
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
                dates(i) = max([dates(i),objArray(i).blocks.getModifiedDate()]);
            end
        end         
        
        function hParams = getChainHyperParameters(obj,hParams)
            if nargin < 2
                hParams = struct();
            end
            for i = 1:numel(obj.blocks)
                hParams.([char(obj.blocks(i).type) '_' char(obj.blocks(i).getShortCaption())]) = obj.blocks(i).getHyperParameters();
            end
        end
        
        function hParams = setChainHyperParameters(obj,hParams)
            for i = 1:numel(obj.blocks)
                obj.blocks(i).setHyperParameters(hParams.([char(obj.blocks(i).type) '_' char(obj.blocks(i).getShortCaption())]));
            end
        end
        
        function init(obj,data,paramIn)
            if isempty(obj)
                return
            end
            if nargin < 3
                paramIn = [];
            end
            b = obj.blocks(1).getFirstBlock();

            while ~isempty(b)
                if b.isInitBlock()
                    b.init(data,paramIn);
                    if obj.requiresNumericTarget && data.targetType ~= 'numeric'
                        ignored = data.target == '<ignore>';
                        data.setTargetType('numeric');
                        if any(isnan(data.target(~ignored)))
                            error('This model requires an all-numeric target.');
                        end
                    end
                    if ~obj.requiresNumericTarget && data.targetType ~= 'categorical'
                        data.setTargetType('categorical');
                    end
                end
                b = b.getBlockAfter();
            end
            
%             if obj.requiresNumericTarget
%                 data.setTargetType('numeric');
%             end 
        end
        
        function finalize(obj,data,paramIn)
            if isempty(obj)
                return
            end
            if nargin < 3
                paramIn = [];
            end
            b = obj.blocks(1).getLastBlock();
            
%             while ~isempty(b)
            data.trainingPrediction = b.revertChain(data.trainingPrediction,paramIn);
            data.validationPrediction = b.revertChain(data.validationPrediction,paramIn);
            data.testingPrediction = b.revertChain(data.testingPrediction,paramIn);
            data.target = b.revertChain(data.target,paramIn);
%                 b = b.getBlockBefore();
%             end            
            
        end
        
        function trainChain(obj,data,paramIn)
            if isempty(obj)
                return
            end
            if nargin < 3
                paramIn = [];
            end
            block = obj.blocks(1).getFirstBlock();
            block.trainChain(data,paramIn);
            data.hasIrreversibleChanges = data.irreversibleChangeWasMade;
        end
        
        function data = applyChain(obj,data,paramIn)
            if isempty(obj)
                return
            end
            if nargin < 3
                paramIn = [];
            end
            block = obj.blocks(1).getFirstBlock();
            block.applyChain(data,paramIn);
            data.hasIrreversibleChanges = data.irreversibleChangeWasMade;
        end
        
        function resetChain(obj)
            if isempty(obj)
                return
            end
            for i = 1:numel(obj.blocks)
                obj.blocks(i).reset();
            end
        end        
        
        function blocks = getBlocksInOrder(obj)
            if isempty(obj.blocks)
                blocks = DataProcessingBlock.empty;
                return
            end
            blocks = obj.blocks(1).getFirstBlock();
            block = blocks.getBlockAfter();
            while ~isempty(block)
                blocks(end+1) = block;
                block = block.getBlockAfter();
            end
        end
        
        function updateChainParameters(obj,project)
            if isempty(obj) || isempty(obj.blocks)
                return
            end
            block = obj.blocks(1).getFirstBlock();
            while ~isempty(block)
                block.updateParameters(project);
                block = block.nextBlock;
            end
        end
        
        function addBlockBefore(obj,block,targetBlock)
            if ~isempty(block.prevBlock) || ~isempty(block.nextBlock)
                error('Block is already in a chain. Remove with removeFromChain before adding.');
            end
            block.prevBlock = targetBlock.prevBlock;
            if ~isempty(targetBlock.prevBlock)
                targetBlock.prevBlock.nextBlock = block;
            end
            targetBlock.prevBlock = block;
            block.nextBlock = targetBlock;
            obj.blocks(end+1) = block;
        end
        
        function addBlockAfter(obj,block,targetBlock)
            if ~isempty(block.prevBlock) || ~isempty(block.nextBlock)
                error('Block is already in a chain. Remove with removeFromChain before adding.');
            end
            block.nextBlock = targetBlock.nextBlock;
            if ~isempty(targetBlock.nextBlock)
                targetBlock.nextBlock.prevBlock = block;
            end
            targetBlock.nextBlock = block;
            block.prevBlock = targetBlock;
            obj.blocks(end+1) = block;
        end

        function addToEnd(obj,block)
            if ~isempty(obj.blocks)
                block.addAfter(obj.blocks(1).getLastBlock());
            end
            obj.blocks(end+1) = block;
        end
        
        function bubbleUp(obj,block)
            while true
                if isempty(block.prevBlock)
                    return
                end
                if block.prevBlock.type > block.type
                    block.moveBefore(block.prevBlock);
                else
                    return
                end
            end
        end

        function moveBlockBefore(obj,block,targetBlock)
            if isempty(targetBlock)
                return
            end
            if ~ismember(obj,targetBlock.getAllBlocksInChain())
                error('Block cannot be moved to a different chain.');
            end
            block.removeFromChain();
            block.addBefore(targetBlock);
        end
        
        function moveBlockAfter(obj,block,targetBlock)
            if isempty(targetBlock)
                return
            end
            if ~ismember(obj,targetBlock.getAllBlocksInChain())
                error('Block cannot be moved to a different chain.');
            end            
            block.removeFromChain();
            block.addAfter(targetBlock);
        end   

        function val = canMoveUp(obj,block)
            if isempty(block.prevBlock)
                val = false;
            elseif block.prevBlock.type < block.type
                val = false;
            else
                val = true;
            end
        end

        function val = canMoveDown(obj,block)
            if isempty(block.nextBlock)
                val = false;
            elseif block.nextBlock.type > block.type
                val = false;
            else
                val = true;
            end
        end
        
        function moveUp(obj,block)
            block.moveBefore(block.prevBlock);
        end
        
        function moveDown(obj,block)
            block.moveAfter(block.nextBlock);
        end
        
        function removeFromChain(obj,block)
            block.removeFromChain();
            obj.blocks(obj.blocks==block) = [];
        end
        
        function b = getBlockBefore(obj,block)
            b = block.prevBlock;
        end
        
        function b = getBlockAfter(obj,block)
            b = block.nextBlock;
        end
        
        function blocks = getAllBlocksInChain(obj)
            if isempty(obj) || isempty(obj.blocks)
                blocks = DataProcessingBlock.empty;
                return
            end
            blocks = obj.blocks(1).getFirstBlock().getAllBlocksInChain();
        end
        
        function b = getFirstBlock(obj)
            if isempty(obj.blocks)
                b = DataProcessingBlock.empty;
                return
            end
            b = obj.blocks(1).getFirstBlock();
        end
        
        function b = getLastBlock(obj)
            if isempty(obj.blocks)
                b = DataProcessingBlock.empty;
                return
            end
            b = obj.blocks(1).getLastBlock();
        end

        function pgf = makePropGridFields(obj)
            b = obj.getAllBlocksInChain();
            pgf = PropGridField.empty;
            for i = 1:numel(b)
                pgf(end+1) = b(i).makePropGridField();
            end
        end     
    end
    
    methods(Static)
        function chains = fromStruct(s)
            chains = DataProcessingBlockChain.empty;
            for i = 1:numel(s)
                c = DataProcessingBlockChain();
                c.blocks = DataProcessingBlock.fromStruct(s(i).blocks);
                chains(end+1) = c;
            end
            fromStruct@Descriptions(s,chains)
        end

        function ranges = jsonload(json)
            data = jsondecode(json);
            ranges = DataProcessingBlockChain.fromStruct(data);
        end
    end
end