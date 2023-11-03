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

classdef Descriptions < handle
    properties
        caption = string('');
        description = string('');
        shortCaption = string('');
        tag = string('');
        uuid
        creationDate
        modifiedDate
        userData
    end
    
    methods
        function obj = Descriptions(noMetaData)
            if nargin == 1 && noMetaData
                return
            end
            obj.createMetaData();
        end
        
        function createMetaData(obj)
            obj.uuid = string(char(java.util.UUID.randomUUID));
            obj.uuid  = string('u') + strrep(obj.uuid,'-','');
            obj.creationDate = datetime('now');
            obj.modifiedDate = obj.creationDate;
        end

        function s = toStruct(objArray,varargin)
            for i = 1:numel(objArray)
                obj = objArray(i);
                s(i).uuid = obj.uuid;
                s(i).creationDate = obj.creationDate;
                s(i).modifiedDate = obj.getModifiedDate();
                s(i).caption = obj.caption;
                s(i).shortCaption = obj.shortCaption;
                s(i).description = obj.description;
                s(i).tag = obj.tag;
            end
        end
        
        function setCaption(objArray,caption)
            caption = string(caption);
            for i = 1:numel(objArray)
                objArray(i).caption = caption(i);
                if isempty(char(objArray(i).shortCaption))
                    objArray(i).shortCaption = matlab.lang.makeValidName(char(caption(i)));
                end
            end
        end
        
        function captions = getCaption(objArray)
            if isempty(objArray)
                captions = string('');
                return
            end
            captions = [objArray.caption];
        end
        
        function types = getType(objArray)
            if isempty(objArray)
                types = string('');
                return
            end
            types = string([objArray.type]);
        end

        function setShortCaption(objArray,shortCaption)
            shortCaption = string(shortCaption);
            for i = 1:numel(objArray)
                if ~isempty(char(shortCaption(i))) && ~isvarname(char(shortCaption(i)))
                    error('Short caption must be a valid MATLAB identifier.');
                end
                objArray(i).shortCaption = shortCaption(i);
            end
        end
        
        function shortCaptions = getShortCaption(objArray)
            if isempty(objArray)
                shortCaptions = string('');
                return
            end
            shortCaptions = [objArray.shortCaption];
        end        
        
        function setDescription(obj,description)
            obj.description = string(description);
        end
        
        function descriptions = getDescription(objArray)
            if isempty(objArray)
                descriptions = string('');
                return
            end
            descriptions = [objArray.description];
        end        
        
        function setTag(objArray,tag)
            tag = string(tag);
            for i = 1:numel(objArray)
                objArray(i).tag = tag(i);
            end
        end
        
        function tag = getTag(objArray)
            if isempty(objArray)
                tag = string('');
                return
            end
            tag = [objArray.tag];
        end
        
        function uuids = getUUID(objArray)
            if isempty(objArray)
                uuids = string('');
                return
            end
            uuids = [objArray.uuid];
        end
        
        function dates = getCreationDate(objArray)
            if isempty(objArray)
                dates = datetime.empty;
                return
            end
            dates = [objArray.creationDate];
        end
        
        function dates = getModifiedDate(objArray)
            if isempty(objArray)
                dates = datetime.empty;
                return
            end
            dates = [objArray.modifiedDate];
        end
        
        function modified(objArray)
            [objArray.modifiedDate] = deal(datetime('now'));
        end
    end
    
    methods(Static)
        function objArray = fromStruct(s,objArray,varargin)
            if (nargin < 2) || isempty(objArray)
                objArray = Descriptions();
            end
            for i = 1:numel(objArray)
                objArray(i).uuid = string(s(i).uuid);
                objArray(i).creationDate = datetime(s(i).creationDate);
                objArray(i).modifiedDate = datetime(s(i).modifiedDate);
                objArray(i).caption = string(s(i).caption);
            end
        end
    end
end