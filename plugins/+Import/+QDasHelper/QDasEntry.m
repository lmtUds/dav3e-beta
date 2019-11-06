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

classdef QDasEntry < handle
    %QDASENTRY container for a single entry(e.g. part) in a QDas File
    %   UNIQUEID        states the unique running number for the part, if present
    %   IOFLAG          states whether all measurements remained inside
    %                   specified boundaries
    %   INFO            contains a QDasEntryInfo object containing general information
    %   MEASUREMENTS    contains an array of measurements linked to the part
    
    properties
        uniqueID = [];
        ioFlag = [];
        info = [];
        measurements = [];
    end
    
    methods
        function this = QDasEntry(measurements, entryInfo,uniqueID)
            this.measurements = measurements;
            this.info = entryInfo;
            this.uniqueID = uniqueID;
        end
        function ioState = isIO(this)
           if ~isempty(this.ioFlag)
               ioState = this.ioFlag;
           else
               [ioState,~] = Import.QDasHelper.Helpers.isIOentries({this});
               this.ioFlag = ioState;
           end
        end
        function measVals = getMeasVals(this)
            measVals = double(size(this.measurements));
            for i=1:size(this.measurements,2)
                measVals(i) = this.measurements{i}.value;
            end
            attrInd = cellfun(@attrEvalColumn ,this.measurements(1:end-1));
            measVals = measVals(attrInd);
            
            function attrFlag = attrEvalColumn(meas)
                attrs = meas.attributes;
                comp = strcmp(attrs,'256');
                attrFlag = ~any(comp);
            end
        end
        function ignoreFlag = getIgnore(this)
            attrInd = cellfun(@attrEval ,this.measurements);
            ignoreFlag = any(~attrInd);
            
            function attrFlag = attrEval(meas)
                attrs = meas.attributes;
                comp = strcmp(attrs,'255');
                attrFlag = ~any(comp);
            end
        end
        function measIo = getMeasIO(this)
            measIo = false(size(this.measurements));
            for i=1:size(this.measurements,2)
                measIo(i) = this.measurements{i}.ioFlag;
            end
        end
        function bounds = getBounds(this)
            meas = this.measurements;  
            bounds= zeros(3,size(meas,2));
            for m = 1:size(meas,2)
                currMeas = meas{m};
                currVal = currMeas.value;
                currInfo = currMeas.info;
                if ~isempty(currInfo.lowerBound) & ~isempty(currInfo.upperBound)
                    currLow = currInfo.lowerBound;
                    currHigh = currInfo.upperBound;
                elseif ~isempty(currInfo.idealValue) & ~isempty(currInfo.maxLowerDeviation) & ~isempty(currInfo.maxUpperDeviation)
                    currLow = currInfo.idealValue + currInfo.maxLowerDeviation;
                    currHigh = currInfo.idealValue + currInfo.maxUpperDeviation;
                elseif ~isempty(currInfo.altIdealVal) & ~isempty(currInfo.maxLowerDeviation) & ~isempty(currInfo.maxUpperDeviation)
                    currLow = currInfo.altIdealVal + currInfo.maxLowerDeviation;
                    currHigh = currInfo.altIdealVal + currInfo.maxUpperDeviation;
                else
                    currLow = nan;
                    currHigh = nan;
                    currVal = nan;
                end
                bounds(1,m) = currLow;
                bounds(2,m) = currVal;
                bounds(3,m) = currHigh;
            end
        end
    end
    
end
