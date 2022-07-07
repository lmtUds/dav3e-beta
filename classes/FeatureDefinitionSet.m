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

classdef FeatureDefinitionSet < Descriptions
    properties
        featureDefinitions
    end
    
    methods
        function obj = FeatureDefinitionSet()
            obj@Descriptions();
            obj.featureDefinitions = FeatureDefinition.empty;
            obj.setCaption('feature definition set');
        end
        
        function addFeatureDefinition(obj,featureDefinitions)
            featureDefinitions = featureDefinitions(:);
            n = numel(featureDefinitions);
            obj.featureDefinitions(end+1:end+n) = featureDefinitions;
        end

        function fd = getFeatureDefinitions(obj,fdCaption)
            fd = obj.featureDefinitions;
            if nargin >= 2
                fd = fd(fd.getCaption()==fdCaption);
            end
        end
        
        function removeFeatureDefinition(obj,featureDefinitions)
            found = ismember(obj.featureDefinitions,featureDefinitions);
            obj.featureDefinitions(found) = [];
        end
                
        function [fds,headers] = compute(obj,rawData,sensor)
%             fds = FeatureDataSet();
            fds = [];
            headers = {};
            for i = 1:numel(obj.featureDefinitions)
%                 fd = obj.featureDefinitions(i).expand();
%                 for j = 1:numel(fd)
                    [fData,~,params] = obj.featureDefinitions(i).computeRaw(rawData,sensor);
%                     fData.rangeNr = i;
%                     fData.subrangeNr = j;
%                     fds.addFeatureData(fData);
%                 end
                fds = [fds,fData];
                headers = [headers,params.header];
            end
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
            fe = parsePlugin('FeatureExtraction');
            out = fe;
        end
    end    
end