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

classdef QDasReader < handle
    %QDASREADER object to read and return structured data from QDas files
    %   IMPORTFILE      reads any QDas compliant data file and imports its entries
    %                   matching pair of DATA and INFO file required
    %   IMPORTFOLDER    extracts all entries from all QDas files in the stated folder
    %                   matching pairs of DATA and INFO files required
    
    properties
    end
    
    methods
        function [entries] = importFile(this,dataPath,infoPath)
            infoLines = strsplit(fileread(infoPath),'\r\n')';
            infoLines = infoLines(cellfun(@(x) ~isempty(x),infoLines));
            infoInd = cellfun(@(x) isempty(regexpi(x,'\d/\d+\s')),infoLines);
%             infoInd = cellfun(@(x) isempty(strfind(x,'/')),infoLines);
            infoPrefix = infoLines(infoInd);
            infoSuffix = infoLines(~infoInd);
            entryInfo = Import.QDasHelper.QDasEntryInfo(infoPrefix, infoPath);
            
            %measCount =cellfun(@(x) str2num(x(Helpers.arrayHead(strfind(x,'/'))+1)),infoSuffix);
            measCount = zeros(size(infoSuffix));
            for i = 1:length(measCount)
                descrStr = strsplit(infoSuffix{i}, ' ');
                descrStr = descrStr{1};
                numstr = strsplit(descrStr, '/');
                numstr = numstr{2};
                measCount(i) = str2double(numstr);
            end
            
            measNum = 0;
            steps = [];
            for i =1:size(measCount,1)
                if measCount(i) ~= measNum
                   measNum = measCount(i);
                   steps = [steps,i]; 
                end
            end
            measInfos = cell(1,size(steps,2));
            for i = 1:size(steps,2)
                if i == size(steps,2)
                    measInfos{i} = Import.QDasHelper.QDasMeasurementInfo(infoSuffix(steps(i):end));
                else
                    measInfos{i} = Import.QDasHelper.QDasMeasurementInfo(infoSuffix(steps(i):steps(i+1)-1));
                end
            end
            
            dataLines = strsplit(fileread(dataPath),'\r\n')';
            dataLines = dataLines(cellfun(@(x) ~isempty(x),dataLines));
            dataInd = cellfun(@(x) isempty(strfind(x,'K00')),dataLines);
            tagLines = dataLines(~dataInd);
            valLines = dataLines(dataInd);
            entries = cell(size(valLines,1),1);
            for i =1:size(valLines,1)
                si = '';
                segments = strsplit(valLines{i},si,'CollapseDelimiters',false);
                measurements = cell(1,size(steps,2));
                for j = 1:size(steps,2)
                    asciiString = segments{j};
                    measurements{j} = Import.QDasHelper.QDasMeasurement(asciiString, measInfos{j});
                end
                if isempty(tagLines) | isempty(tagLines{i})
                    entries{i} = Import.QDasHelper.QDasEntry(measurements, entryInfo,[]);
                else
                    splitLine = strsplit(tagLines{i},' ');
                    uniTag = splitLine{2};
                    entries{i} = Import.QDasHelper.QDasEntry(measurements, entryInfo,uniTag);
                end
                [~,temp] = Import.QDasHelper.Helpers.isIOentries(entries(i));
                entries{i} = temp{:};
            end
            
        end
        function [entries] = importFolder(this,folderPath)
            infoFormatCount = 1;
            infoFiles = cell(infoFormatCount,1);
            for i = 1:infoFormatCount
               switch i
                   case 1
                       infoExt = '.dfd';
                   otherwise
                       error('unexpected loop index');
               end
               infoFiles{i} = Import.QDasHelper.Helpers.allFilesByExt(folderPath,infoExt);
            end
            infoFiles = vertcat(infoFiles{:});
            
            dataFormatCount = 1;
            dataFiles = cell(dataFormatCount,1);
            for i = 1:dataFormatCount
                switch i
                    case 1
                        dataExt = '.dfx';
                    otherwise
                       error('unexpected loop index');
                end
               dataFiles{i} = Import.QDasHelper.Helpers.allFilesByExt(folderPath,dataExt);
            end
            dataFiles = vertcat(dataFiles{:});
            
            if size(dataFiles,1)~=size(infoFiles)
                error('Not enough data/info files for paired evaluation');
            end
            entries = cell(size(dataFiles,1),1);
            parfor i = 1:size(dataFiles,1)
                try
                    entries{i} = this.importFile(dataFiles{i},infoFiles{i});
                catch e
                    disp(['import of files ',dataFiles{i},' ',infoFiles{i},' failed']);
                    disp(e);
                end
            end
            entries = entries(cellfun(@(x) ~isempty(x),entries));
            entries = vertcat(entries{:});
        end
    end 
end
