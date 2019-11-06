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

classdef Sensor < FeatureExtraction.extractHelpers.SignalChainElementInterface
    %SENSOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dataInt = [];
        evalData = [];
        uid = '';
    end
    
    properties (Constant)
        idSuffix = 'Sens';
    end
    
    methods
        function this = Sensor(dataInterface, uid, evalData)
            if nargin > 0
                this.uid = uid;
                this.dataInt = dataInterface;
            end
            if nargin > 2
                this.evalData = evalData;
            end
        end
        
        function step(this, data, metaInfo)
            metaInfo('ID') = [this.uid, this.idSuffix, metaInfo('ID')];
            if isempty(this.id)
                this.id = metaInfo('ID');
            end
            if ~isempty(this.next)
                metaInfo('cycleNum') = data;
                if isKey(metaInfo, 'EvaluationData') && metaInfo('EvaluationData') && ~isempty(this.evalData)
                    if isa(data, 'gpuArray')
                        data = gpuArray(cast(this.evalData.getCycle(data), classUnderlying(data)));
                    else
                        data = cast(this.evalData.getCycle(data), 'like', data);
                    end
                else
                    if isa(data, 'gpuArray')
                        data = gpuArray(cast(this.dataInt.getCycle(data), classUnderlying(data)));
                    else
                        data = cast(this.dataInt.getCycle(data), 'like', data);
                    end
                end
                this.next.step(data, metaInfo);
            end
        end

        function [noteDataArray, linkDataArray] = report(this)
            noteDataArray = cell(1);
            noteDataArray{1} = {this.getId(), [this.uid, this.idSuffix]};
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
        
        function numCyc = getNumberOfCycles(this, varargin)
            if nargin > 1 && varargin{1}
                numCyc = this.evalData.getNumberOfCycles();
            else
                numCyc = this.dataInt.getNumberOfCycles();
            end
        end
        
        function setId(this, id)
            this.id = [this.uid, this.idSuffix, id];
            if ~isempty(this.next)
                this.next.setId(this.id);
            end
        end
        
        function info = getFeatInfo(this, info)
            f = FeatureExtraction.extractHelpers.Factory.getFactory();
            info = f.getFeatureInfoSet();
            
            %keep general info
            info.addProperty('SignalChainId', this.getId());
            info.addProperty('MeasurementPoint', num2cell(1:length(this.dataInt.getCycle(1))));
            info.addProperty('Sensor', this.getId());
            
            %Pass on to next element
            if ~isempty(this.next)
                info = this.next.getFeatInfo(info);
            end
        end
    end
    
end

