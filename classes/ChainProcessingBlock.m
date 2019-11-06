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

classdef ChainProcessingBlock < Descriptions
    properties
        processingChain
    end
    
    properties(Hidden)
        emtpy = false
    end
    
    methods
        function obj = ChainProcessingBlock(fcn,chain)
            obj = obj@Descriptions();
            if nargin == 0
                obj.empty = true;
                return
            end
            obj.processingChain = chain;
            obj.infoFcn = fcn;
            funs = fcn();
            obj.setCaption(funs.caption);
            obj.setDescription(funs.description);
            obj.applyFcn = funs.apply;
            obj.prevBlock = ChainProcessingBlock.empty;
            obj.nextBlock = ChainProcessingBlock.empty;

            try
                obj.parameters = funs.parameters;
            catch
                obj.parameters = Parameter.empty;
            end
        end
        
%         function s = toStruct(objArray)
%             s = toStruct@Descriptions(objArray);
%             for i = 1:numel(objArray)
%                 obj = objArray(i);
%                 s(i).infoFcn = func2str(obj.infoFcn);
%                 s(i).prevBlock = obj.prevBlock.getUUID();
%                 s(i).nextBlock = obj.nextBlock.getUUID();
%                 s(i).defaultCopy = obj.defaultCopy;
%                 s(i).parameters = obj.parameters.getMapWithUUIDRefs();
%             end
%         end
%         
%         function json = jsondump(objArray)
%             s = objArray.toStruct();
%             json = jsonencode(s);
%         end
        
        function data = applyMetaChain(obj,data,paramIn)
            params = obj.parameters.getStruct();
            if nargin >= 3 && ~isempty(paramIn)  % paramIn
                params = updateStruct(params,paramIn);
            end
            
            partParams = params;
            if isfield(partParams,char(obj.getCaption()))
                partParams = partParams.(char(obj.getCaption()));
            end
            
            [data,~] = obj.apply(data,partParams);
            for i = 1:numel(obj.nextBlock)
                obj.nextBlock(i).applyChain(data,params);
            end
        end
        
        function [data,params] = apply(obj,data,paramIn)
            params = obj.parameters.getStruct();
            if nargin >= 3 && ~isempty(paramIn)  % paramIn
                params = updateStruct(params,paramIn);
            end

            [data,params] = obj.applyFcn(data,params);
            obj.parameters.updateFromStruct(params);
        end
        
        function train(obj,data,paramIn)
            if isempty(obj.trainFcn)
               return 
            end
            params = obj.parameters.getStruct();
            if nargin >= 3 && ~isempty(paramIn)  % paramIn
                params = updateStruct(params,paramIn);
            end
            params = obj.trainFcn(data,params);
            obj.parameters.updateFromStruct(params);
        end
        
        function addBefore(obj,block)
            if ~any(ismember(block.prevBlock,obj))
                block.prevBlock(end+1) = obj;
            end
            if ~any(ismember(obj.nextBlock,block))
                obj.nextBlock(end+1) = block;
            end
        end
        
        function addAfter(obj,block)
            if ~any(ismember(block.nextBlock,obj))
                block.nextBlock(end+1) = obj;
            end
            if ~any(ismember(obj.prevBlock,block))
                obj.prevBlock(end+1) = block;
            end            
        end
        
        function addBetween(obj,blockBefore,blockAfter)
            pos = ismember(blockBefore.nextBlock,blockAfter);
            blockBefore.nextBlock(pos) = [];
            pos = ismember(blockAfter.prevBlock,blockBefore);
            blockAfter.prevBlock(pos) = [];
            obj.addAfter(blockBefore);
            obj.addBefore(blockAfter);
        end
        
        function b = getBlockBefore(obj)
            b = obj.prevBlock;
        end
        
        function b = getBlockAfter(obj)
            b = obj.nextBlock;
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
                    matlab.lang.makeValidName(b.parametersFromTemplate.getCaption())));
                paramMap = containers.Map(k,num2cell(b.parametersFromTemplate));
                for j = 1:numel(b.parametersFromTemplate)
                    p = paramMap(k{j});
                    p.value = s(i).parametersFromTemplate.(k{j});
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