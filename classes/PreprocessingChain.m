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

classdef PreprocessingChain < Descriptions
    properties
        chainBlock
    end
    properties (Dependent)
        preprocessings
    end
    
    methods
        function obj = PreprocessingChain()
            obj.setCaption('preprocessing chain');
            obj.chainBlock = DataProcessingBlock.empty;
        end
        
        function val = get.preprocessings(obj)
            val = obj.chainBlock.getAllBlocksInChain();
        end
        
        function dates = getModifiedDate(objArray)
            if isempty(objArray)
                dates = datetime.empty;
                return
            end
            dates = [objArray.modifiedDate];
            for i = 1:numel(objArray)
                dates(i) = max([dates(i),objArray(i).preprocessings.getModifiedDate()]);
            end
        end         
        
        function appendPreprocessing(obj,nameArray)
            availMethods = obj.getAvailableMethods();
            nameArray = string(nameArray);
            for i = 1:numel(nameArray)
                name = nameArray(i);
                dpb = DataProcessingBlock(availMethods(char(name)));
                if isempty(obj.chainBlock)
                    obj.chainBlock = dpb;
                else
                    dpb.addToEnd(obj.chainBlock);
                end
            end
            obj.modified();
        end
        
        function removePreprocessing(obj,blockArray)
            for i = 1:numel(blockArray)
                block = blockArray(i);
                pp = obj.preprocessings;
                n = numel(pp);
                if n > 1
                    % if the entry block to this chain is the block to be
                    % deleted, first set another block as entry block
                    if block == obj.chainBlock
                        for j = 1:n
                            if pp(j) ~= block
                                obj.chainBlock = pp(j);
                                break
                            end
                        end
                    end
                    block.removeFromChain();
                else
                    obj.chainBlock = DataProcessingBlock.empty;
                end
            end
            obj.modified();
        end
        
        function pgf = makePropGridFields(obj)
            pp = obj.preprocessings;
            pgf = PropGridField.empty;
            for i = 1:numel(pp)
                pgf(end+1) = pp(i).makePropGridField();
            end
        end
        
        function train(obj,data)
            obj.chainBlock.getFirstBlock().trainChain(data);
        end
        
        function data = apply(obj,data)
            data = obj.chainBlock.getFirstBlock().applyChain(data);
        end
    end
    
    methods (Static)
        function out = getAvailableMethods(force)
            persistent fe
            if ~exist('force','var')
                force = false;
            end
            if ~isempty(fe) && ~force
                out = fe;
                return
            end
            fe = parsePlugin('RawDataPreprocessing');
            out = fe;
        end
    end
end