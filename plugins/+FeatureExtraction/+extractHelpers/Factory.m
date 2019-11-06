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

classdef (Sealed) Factory < FeatureExtraction.extractHelpers.FactoryInterface
    %FACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static)
        function this = getFactory()
            persistent localThis;
            if isempty(localThis) || ~isvalid(localThis)
                localThis = FeatureExtraction.extractHelpers.Factory;
            end
            this = localThis;
        end
        
        function uid = getUniqueId()
            persistent num;
            if isempty(num)
                num = 0;
            end
            uid = num2str(num);
            while (uid < 4)
                uid = ['0',uid]; %#ok<AGROW>
            end
            num = num+1;
        end
    end
    
    methods (Access = private)
        function this = Factory()
        end
    end
    
    methods
        function obj = getAbs(~, varargin)
            obj = FeatureExtraction.extractHelpers.Abs(varargin{:});
        end
        
        function obj = getALADownsampler(~, varargin)
            obj = FeatureExtraction.extractHelpers.ALADownsampler();
        end
        
        function obj = getALAErrTransform(~, varargin)
            obj = FeatureExtraction.extractHelpers.ALAErrTransform();
        end
        
        function obj = getALASplit(~, varargin)
            obj = FeatureExtraction.extractHelpers.ALASplit();
        end
        
        function obj = getBooleanFlagSelector(~, varargin)
            obj = FeatureExtraction.extractHelpers.BooleanFlagSelector(varargin{:});
        end
        
        function obj = getCachedMultifileData(~, varargin)
            obj = FeatureExtraction.extractHelpers.CachedMultifileData(varargin{:});
        end
        
        function obj = getComplexAngle(~, varargin)
            obj = FeatureExtraction.extractHelpers.ComplexAngle(varargin{:});
        end
        
        function obj = getCrossValidator(~, varargin)
            obj = FeatureExtraction.extractHelpers.CrossValidator(varargin{:});
        end
        
        function obj = getCycleRange(~, varargin)
            obj = FeatureExtraction.extractHelpers.CycleRange(varargin{:});
        end
        
        function obj = getFeatureInfoSet(~, varargin)
            obj = FeatureExtraction.extractHelpers.FeatureInfoSet(varargin{:});
        end
        
        function obj = getFeatureMat(~, varargin)
            obj = FeatureExtraction.extractHelpers.FeatureMat(varargin{:});
        end
        
        function obj = getFeatureMatExtractor(~, varargin)
            obj = FeatureExtraction.extractHelpers.FeatureMatExtractor(varargin{:});
        end
        
        function obj = getFeatMatWrapper(~, varargin)
            obj = FeatureExtraction.extractHelpers.FeatMatWrapper(varargin{:});
        end
        
        function obj = getFourierTransform(~, varargin)
            obj = FeatureExtraction.extractHelpers.FourierTransform(varargin{:});
        end
        
        function obj = getGenericSecondaryFeature(~, varargin)
            obj = FeatureExtraction.extractHelpers.GenericSecondatyFeature(varargin{:});
        end
        
        function obj = getJoinedSelector(~, varargin)
            obj = FeatureExtraction.extractHelpers.JoinedSelector(varargin{:});
        end
        
        function obj = getLDAMahalClassifier(~, varargin)
            obj = FeatureExtraction.extractHelpers.LDAMahalClassifier(varargin{:});
        end
        
        function obj = getStackedSelector(~, varargin)
            obj = FeatureExtraction.extractHelpers.StackedSelector(varargin{:});
        end
        
        function obj = getMatFileData(~, varargin)
            obj = FeatureExtraction.extractHelpers.MatFileData(varargin{:});
        end
        
        function obj = getMapReduceController(~, varargin)
            obj = FeatureExtraction.extractHelpers.MapReduceController(varargin{:});
        end
        
        function obj = getMeanValueLearner(~, varargin)
            obj = FeatureExtraction.extractHelpers.MeanValueLearner(varargin{:});
        end
        
        function obj = getOneNNClassifier(~, varargin)
            obj = FeatureExtraction.extractHelpers.OneNNClassifier(varargin{:});
        end
        
        function obj = getPCA(~, varargin)
            obj = FeatureExtraction.extractHelpers.PCA(varargin{:});
        end
        
        function obj = getPDV1DataInterface(~, varargin)
            obj = FeatureExtraction.extractHelpers.PDV1DataInterface(varargin{:});
        end
        
        function obj = getPearsonPreselection(~, varargin)
            obj = FeatureExtraction.extractHelpers.PearsonPreselection(varargin{:});
        end
        
        function obj = getPearsonSelector(~, varargin)
            obj = FeatureExtraction.extractHelpers.PearsonSelector(varargin{:});
        end
        
        function obj = getRamData(~, varargin)
            obj = FeatureExtraction.extractHelpers.RamData(varargin{:});
        end
        
        function obj = getRange(~, varargin)
            obj = FeatureExtraction.extractHelpers.Range(varargin{:});
        end
        
        function obj = getRELIEFFSelector(~, varargin)
            obj = FeatureExtraction.extractHelpers.RELIEFFSelector(varargin{:});
        end
        
        function obj = getRFESVMSelector(~, varargin)
            obj = FeatureExtraction.extractHelpers.RFESVMSelector(varargin{:});
        end
        
        function obj = getRestrictedMatFileData(~, varargin)
            obj = FeatureExtraction.extractHelpers.RestrictedMatFileData(varargin{:});
        end
        
        function obj = getSensor(~, varargin)
            obj = FeatureExtraction.extractHelpers.Sensor(varargin{:});
        end
        
        function obj = getSerialController(~, varargin)
            obj = FeatureExtraction.extractHelpers.SerialController(varargin{:});
        end
        
        function obj = getSignalJoiner(~, varargin)
            obj = FeatureExtraction.extractHelpers.SignalJoiner(varargin{:});
        end
        
        function obj = getSignalSplitter(~, varargin)
            obj = FeatureExtraction.extractHelpers.SignalSplitter(varargin{:});
        end
        
        function obj = getSingleMatFileData(~, varargin)
            obj = FeatureExtraction.extractHelpers.SingleMatFileData(varargin{:});
        end
        
        function obj = getStatMom(~, varargin)
            obj = FeatureExtraction.extractHelpers.StatMom(varargin{:});
        end
        
        function obj = getUniformDistributionData(~, varargin)
            obj = FeatureExtraction.extractHelpers.UniformDistributionData(varargin{:});
        end
        
        function obj = getWaveletTransform(~, varargin)
            obj = FeatureExtraction.extractHelpers.WaveletTransform(varargin{:});
        end
        
        function obj = getCVSelFeatMat(~, varargin)
            obj = FeatureExtraction.extractHelpers.CVSelFeatMat(varargin{:});
        end
        
        function [obj, allObj] = getALASplitSelection(this, id, targetMat)
            obj = this.getALASplit();
            [sel, fo] = this.getMultitargetPearsonPreselection(id, targetMat);
            obj.addNextElement(sel);
            allObj = [{sel}, fo];
            obj.setId(id);
        end
        
        function [obj, allObj] = getALA(this, id)
            ds = this.getALADownsampler();
            errTrans = this.getALAErrTransform();
            spl = this.getALASplit();
            
            ds.addNextElement(errTrans);
            errTrans.addNextElement(spl);
            
            allObj = [{errTrans}, {spl}];
            obj = ds;
            obj.setId(id);
        end
        
        function [obj, allObj] = getCVALA(this, id, cv)
            ds = this.getALADownsampler();
            spl = this.getSignalSplitter();
            errTrans = this.getALAErrTransform();
            outSignals = cell(1, cv.NumTestSets);
            for i = 1:cv.NumTestSets
                outSignals{i} = this.getALASplit(id);
            end
            crossVal = this.getCrossValidator(cv, outSignals);
            
            full = this.getALASplit(id);
            crossVal.addNextElement(full);
            
            ds.addNextElement(spl);
            spl.addNextElement(errTrans);
            errTrans.addNextElement(crossVal);
            
            allObj = [{errTrans}, {spl}, {crossVal}, {full}, outSignals];
            obj = ds;
            obj.setId(id);
        end
        
        function [obj, allObj] = getFullALA(this, id, sensors)
            alas = cell(1, length(sensors));
            objs = cell(size(alas));
            joinObj = cell(size(alas));
            for i = 1:length(sensors)
                [alas{i}, objs{i}] = this.getALA(id);
                joinObj{i} = obj{i}{end};
            end
            joiner = this.getSignalJoiner(joinObj);
            featMat = this.getFeatMat();
            joiner.addNextElement(featMat);
            splitter = this.getSignalSplitter();
            splitter.addNextElement(alas);
            obj = splitter;
            allObj = horzcat({splitter}, alas, objs{:}, {joiner}, {featMat});
            obj.setId(id);
        end
        
        function [obj, allObj] = getMVPSelector(this, id, targetMat)
            obj = this.getSignalSplitter();
            mv = this.getMeanValueLearner();
            pearsonSelectors = cell(1, size(targetMat, 2));
            stackSel = cell(1, size(targetMat,2));
            for i = 1:size(targetMat, 2)
                pearsonSelectors{i} = this.getPearsonPreselection(targetMat(:,1), num2str(i));
                stackSel{i} = this.getStackedSelector({mv, pearsonSelectors{i}});
                obj.addNextElement(stackSel{i});
            end
            allObj = [{mv}, pearsonSelectors, stackSel];
            obj.setId(id);
        end
        
        function [obj, allObj] = getCVMVPSelector(this, id, cv, targetMat)
            allObj = {};
            outSignals = cell(1, cv.NumTestSets);
            for i = 1:cv.NumTestSets
                [outSignals{i}, furtherObj] = this.getMVPSelector(id, targetMat);
                allObj = [allObj, furtherObj]; %#ok<AGROW>
            end
            obj = this.getCrossValidator(cv, outSignals);
            [full, fo] = this.getMVPSelector(id, targetMat);
            allObj = [{full}, fo, allObj];
            obj.addNextElement(full);
            obj.setId(id);
        end
        
        function [obj, allObj] = getMultitargetPearsonPreselection(this, id, targetMat)
            obj = this.getSignalSplitter();
            allObj = cell(1, size(targetMat, 2));
            for i = 1:size(targetMat, 2)
                allObj{i} = this.getPearsonPreselection(targetMat(:, i), num2str(i));
                obj.addNextElement(allObj{i});
            end
            obj.setId(id);
        end
        
        function [obj, allObj] = getCVPearsonPreselection(this, id, cv, targetMat)
            allObj = {};
            outSignals = cell(cv.NumTestSets, 1);
            for i = 1:cv.NumTestSets
                [outSignals{i}, furtherObj] = this.getMultitargetPearsonPreselection('', targetMat);
                allObj = [allObj, furtherObj]; %#ok<AGROW>
            end
            obj = this.crossValidator(cv, outSignals);
            [full, fo] = this.getMultitargetPearsonPreselection('', targetMat);
            obj.addNextElement(full);
            allObj = [{full}, outSignals, fo, allObj];
            obj.setId(id);
        end
        
        function [obj, allObj] = getAmplitudeSpectrum(this, id, signalLength)
            obj = this.getFourierTransform();
            selected = false(1, signalLength);
            selected(1:floor(signalLength/2)) = true;
            range = this.getRange(selected, '');
            obj.addNextElement(range);
            abs = this.getAbs();
            range.addNextElement(abs);
            obj.setId(id);
            allObj = {range, abs};
        end
        
        function [obj, allObj] = getCVFFT(this, id, cv, targetMat, signalLength)
            obj = this.getFourierTransform();
            selected = false(1, signalLength);
            selected(1:floor(signalLength/2)) = true;
            range = this.getRange(selected, '');
            mainSpl = this.getSignalSplitter();
            abs = this.getAbs();
            ang = this.getComplexAngle();
            
            stackSelAbs = cell(size(targetMat, 2), cv.NumTestSets);
            stackSelAng = cell(size(stackSelAbs));
            joinedSel = cell(size(stackSelAbs));
            pearsonSelAbs = cell(size(stackSelAbs));
            pearsonSelAng = cell(size(stackSelAbs));
            mvLearners = cell(1, cv.NumTestSets);
            targetSplitsAbs = cell(1, cv.NumTestSets);
            targetSplitsAng = cell(1, cv.NumTestSets);
            for i = 1:cv.NumTestSets
                mvLearners{i} = this.getMeanValueLearner();
                targetSplitsAbs{i} = this.getSignalSplitter();
                targetSplitsAng{i} = this.getSignalSplitter();
                for j = 1:size(targetMat, 2)
                    pearsonSelAbs{j,i} = this.getPearsonPreselection(targetMat(:,j), num2str(j));
                    stackSelAbs{j,i} = this.getStackedSelector({mvLearners{i}, pearsonSelAbs{j,i}}, false);
                    targetSplitsAbs{i}.addNextElement(pearsonSelAbs{j,i});
                    targetSplitsAbs{i}.addNextElement(stackSelAbs{j,i});
                    
                    pearsonSelAng{j,i} = this.getPearsonPreselection(targetMat(:,j), num2str(j));
                    stackSelAng{j,i} = this.getStackedSelector({mvLearners{i}, pearsonSelAng{j,i}}, false);
                    targetSplitsAng{i}.addNextElement(pearsonSelAng{j,i});
                    targetSplitsAng{i}.addNextElement(stackSelAng{j,i});
                    
                    joinedSel{j,i} = this.getJoinedSelector({stackSelAbs{j,i}, stackSelAng{j,i}});
                    stackSelAbs{j,i}.addNextElement(joinedSel{j,i});
                    stackSelAng{j,i}.addNextElement(joinedSel{j,i});
                end
                targetSplitsAbs{i}.addNextElement(mvLearners{i});
            end
            cvAbs = this.getCrossValidator(cv, targetSplitsAbs);
            cvAng = this.getCrossValidator(cv, targetSplitsAng);
            
            %full Objects
            mvFull = this.getMeanValueLearner();
            targetSplitFullAbs = this.getSignalSplitter();
            targetSplitFullAng = this.getSignalSplitter();
            fullStackSelAbs = cell(1, size(targetMat, 2));
            fullStackSelAng = cell(1, size(targetMat, 2));
            fullJoinedSel = cell(1, size(targetMat, 2));
            fullPearsonSelAbs = cell(1, size(targetMat, 2));
            fullPearsonSelAng = cell(1, size(targetMat, 2));
            for i = 1:size(targetMat, 2)
                fullPearsonSelAbs{i} = this.getPearsonPreselection(targetMat(:,i), num2str(i));
                fullStackSelAbs{i} = this.getStackedSelector({mvFull, fullPearsonSelAbs{i}}, false);
                fullPearsonSelAng{i} = this.getPearsonPreselection(targetMat(:,i), num2str(i));
                fullStackSelAng{i} = this.getStackedSelector({mvFull, fullPearsonSelAng{i}}, false);
                targetSplitFullAbs.addNextElement(fullPearsonSelAbs{i});
                targetSplitFullAbs.addNextElement(fullStackSelAbs{i});
                targetSplitFullAng.addNextElement(fullPearsonSelAng{i});
                targetSplitFullAng.addNextElement(fullStackSelAng{i});
                
                fullJoinedSel{i} = this.getJoinedSelector({fullStackSelAbs{i}, fullStackSelAng{i}});
                fullStackSelAbs{i}.addNextElement(fullJoinedSel{i});
                fullStackSelAng{i}.addNextElement(fullJoinedSel{i});
            end
            targetSplitFullAbs.addNextElement(mvFull);
            cvAbs.addNextElement(targetSplitFullAbs);
            cvAng.addNextElement(targetSplitFullAng);
            
            %puting all together
            abs.addNextElement(cvAbs);
            ang.addNextElement(cvAng);
            mainSpl.addNextElement(abs);
            mainSpl.addNextElement(ang);
            range.addNextElement(mainSpl);
            obj.addNextElement(range);
            
            allObj = [{obj}, {range}, {mainSpl}, {abs}, {ang}, {cvAbs}, {cvAng}, ...
                {mvFull}, {targetSplitFullAbs}, {targetSplitFullAng},...
                fullStackSelAbs, fullStackSelAng, fullPearsonSelAbs, fullPearsonSelAng,...
                targetSplitsAbs, targetSplitsAng, mvLearners,...
                pearsonSelAbs(1:numel(pearsonSelAbs)), pearsonSelAng(1:numel(pearsonSelAng)),...
                stackSelAbs(1:numel(stackSelAbs)), stackSelAng(1:numel(stackSelAng))...
                joinedSel(1:numel(joinedSel)), fullJoinedSel(1:numel(fullJoinedSel))];
            obj.setId(id);
        end
        
        function [obj, allObj] = getFullCVFFT(this, id, cv, targetMat, signalLength, sensors)
            obj = this.getSignalSplitter();
            o = cell(size(sensors));
            allO = cell(size(o));
            joinSignals = cell(length(sensors), cv.NumTestSets+1);
            for i = 1:length(sensors)
                [o{i}, allO{i}] = this.getCVFFT(id, cv, targetMat, signalLength(i));
                obj.addNextElement(sensors{i});
                sensors{i}.addNextElement(o{i});
                count = 1;
                for j = 1:length(allO{i})
                    if isa(allO{i}{j}, 'JoinedSelector')
                        joinSignals{i, count} = allO{i}{j};
                        count = count + 1;
                    end
                end
            end
            joinedSel = cell(1, cv.NumTestSets+1);
            for i = 1:cv.NumTestSets+1
                joinedSel{i} = this.getJoinedSelector(joinSignals(:,i));
                for j = 1:length(sensors)
                    joinSignals{j, i}.addNextElement(joinedSel{i});
                end
            end
            obj.setId(id);
            ids = cellfun(@getId, joinedSel, 'UniformOutput', false);
            featMat = this.getCVSelFeatMat(ids);
            for i = 1:length(joinedSel)
                joinedSel{i}.addNextElement(featMat);
            end
            allObj = horzcat(sensors, allO{:}, joinedSel, {featMat});
        end
        
        function [obj, allObj] = getCVBDW(this, id, cv, targetMat)
            obj = this.getWaveletTransform();
            abs = this.getAbs();
            mainSpl = this.getSignalSplitter();
            boolSel = this.getBooleanFlagSelector('Training', true);
            
            mvSelectors = cell(1,cv.NumTestSets);
            pearsonSelectors = cell(size(targetMat, 2), cv.NumTestSets);
            stackedSelectors = cell(size(pearsonSelectors));
            targetSplits = cell(1, cv.NumTestSets);
            
            for i = 1:cv.NumTestSets
                mvSelectors{i} = this.getMeanValueLearner();
                targetSplits{i} = this.getSignalSplitter();
                for j = 1:size(targetMat, 2)
                    pearsonSelectors{j,i} = this.getPearsonPreselection(targetMat(:,j), num2str(j));
                    stackedSelectors{j,i} = this.getStackedSelector({mvSelectors{i}, pearsonSelectors{j,i}}, false);
                    targetSplits{i}.addNextElement(pearsonSelectors{j,i});
                    targetSplits{i}.addNextElement(stackedSelectors{j,i});
                end
            end
            cvAbs = this.getCrossValidator(cv, mvSelectors);
            cv = this.getCrossValidator(cv, targetSplits);
            
            %full Objects
            mvFull = this.getMeanValueLearner();
            targetSplitFull = this.getSignalSplitter();
            fullStackSel = cell(size(targetMat, 2), 1);
            fullPearsonSel = cell(size(targetMat, 2), 1);
            for i = 1:size(targetMat, 2)
                fullPearsonSel{i} = this.getPearsonPreselection(targetMat(:,i), num2str(i));
                fullStackSel{i} = this.getStackedSelector({mvFull, fullPearsonSel{i}}, false);
                targetSplitFull.addNextElement(fullPearsonSel{i});
                targetSplitFull.addNextElement(fullStackSel{i});
            end
            cvAbs.addNextElement(mvFull);
            cv.addNextElement(targetSplitFull);
            
            abs.addNextElement(cvAbs);
            boolSel.addNextElement(abs);
            mainSpl.addNextElement(boolSel);
            mainSpl.addNextElement(cv);
            obj.addNextElement(mainSpl);
            
            allObj = [{mainSpl}, {abs}, {boolSel}, {cv}, {cvAbs}, {targetSplitFull}, ...
                {mvFull}, fullPearsonSel', fullStackSel', {targetSplitFull}, ...
                mvSelectors, targetSplits, pearsonSelectors(1:numel(pearsonSelectors)),...
                stackedSelectors(1:numel(stackedSelectors))];
            obj.setId(id);
        end
        
        function [obj, allObj] = getFullCVBDW(this, id, cv, targetMat, sensors)
            obj = this.getSignalSplitter();
            o = cell(size(sensors));
            allO = cell(size(o));
            joinSignals = cell(length(sensors), cv.NumTestSets+1);
            for i = 1:length(sensors)
                [o{i}, allO{i}] = this.getCVBDW(id, cv, targetMat);
                obj.addNextElement(sensors{i});
                sensors{i}.addNextElement(o{i});
                count = 1;
                for j = 1:length(allO{i})
                    if isa(allO{i}{j}, 'StackedSelector')
                        joinSignals{i, count} = allO{i}{j};
                        count = count + 1;
                    end
                end
            end
            joinedSel = cell(1, cv.NumTestSets+1);
            for i = 1:cv.NumTestSets+1
                joinedSel{i} = this.getJoinedSelector(joinSignals(:,i));
                for j = 1:length(sensors)
                    joinSignals{j, i}.addNextElement(joinedSel{i});
                end
            end
            obj.setId(id);
            ids = cellfun(@getId, joinedSel, 'UniformOutput', false);
            featMat = this.getCVSelFeatMat(ids);
            for i = 1:length(joinedSel)
                joinedSel{i}.addNextElement(featMat);
            end
            allObj = horzcat(sensors, allO{:}, joinedSel, {featMat});
        end
        
        function [obj, allObj] = getStatMomExtractor(this, id, targetMat, signalLength, numRanges)
            starts = 0:numRanges-1;
            starts = starts * floor(signalLength/numRanges) + 1;
            stops = 1:numRanges;
            stops = min(signalLength, stops * ceil(signalLength/numRanges));
            
            obj = this.getSignalSplitter();
            
            ind = false(1,signalLength);
            allObj = {};
            for i = 1:length(starts)
                ind(starts(i):stops(i)) = true;
                
                r = this.getRange(ind, num2str(i));
                s = this.getStatMom();
                [p, fo] = this.getMultitargetPearsonPreselection(id, targetMat);
                
                r.addNextElement(s);
                s.addNextElement(p);
                obj.addNextElement(r);
                
                allObj = [allObj, {r, s, p}, fo]; %#ok<AGROW>
                
                ind(:) = false;
            end
            obj.setId(id);
        end
        
        function [obj, allObj] = getCVPCA(this, id, cv)
            allObj = cell(1, cv.NumTestSets);
            for i = 1:cv.NumTestSets
                allObj{i} = this.getPCA();
            end
            obj = this.getCrossValidator(cv, allObj);
            full = this.getPCA();
            obj.addNextElement(full);
            allObj = [{full}, allObj];
            obj.setId(id);
        end
    
        function [obj, allObj] = getFullTree(this, id, cv, targetMat, signalLength, numStatMomRanges)
            obj = this.getSignalSplitter();
            %ALA
            [ala, fo1] = this.getCVALA(id, cv);
            obj.addNextElement(ala);
            %BDW
            [bdw, fo2] = this.getCVBDW(id, cv, targetMat);
            obj.addNextElement(bdw);
            %FFT
            [fft, fo3] = this.getCVFFT(id, cv, targetMat, signalLength);
            obj.addNextElement(fft);
            %StatMom
            [statMom, fo4] = this.getStatMomExtractor(id, targetMat, signalLength, numStatMomRanges);
            obj.addNextElement(statMom);
            %PCA
            [pca, fo5] = this.getCVPCA(id, cv);
            for i = 1:length(fo1)
                if isa(fo1{i}, 'SignalSplitter')
                    fo1{i}.addNextElement(pca);
                    break;
                end
            end
            
            allObj = [{ala}, {bdw}, {fft}, {statMom}, {pca}, fo1, fo2, fo3, fo4, fo5];
            obj.setId(id);
        end
        
        function [obj, allObj] = getMultisensorFullTree(this, id, cv, targetMat, signalLength, numStatMomRanges, sensors)
            obj = this.getSignalSplitter();
            allObj = sensors;
            for i = 1:length(sensors)
                obj.addNextElement(sensors{i});
                [pipeline, fo] = this.getFullTree(id, cv, targetMat, signalLength(i), numStatMomRanges);
                allObj = [allObj, {pipeline}, fo]; %#ok<AGROW>
                sensors{i}.addNextElement(pipeline);
            end
            obj.setId(id);
            ids = cell(1, numel(allObj));
            for i = 1:numel(allObj)
                ids{i} = allObj{i}.getId();
            end
            
            %ALA
            objToJoin = cell(length(sensors), cv.NumTestSets+1);
            objToJoinIds = cell(length(sensors), cv.NumTestSets+1);
            signalJoiners = cell(1, cv.NumTestSets+1);
            signalJoinersIds = cell(1, cv.NumTestSets+1);
            featMats = cell(1, cv.NumTestSets+1);
            featMatsIds = cell(1, cv.NumTestSets+1);
            %get IDs and objects
            for c = 0:cv.NumTestSets
                for s = 1:length(sensors)
                    if c == 0
                        %full object
                        objToJoinIds{s, c+1} = ['ALASplitCVALAErrMatSplDsSpl', sensors{s}.getId];
                    else
                        %cross validated objects
                        objToJoinIds{s, c+1} = ['ALASplit', num2str(c), 'CVALAErrMatSplDsSpl', sensors{s}.getId];
                    end
                    ind = strcmp(ids, objToJoinIds{s, c+1});
                    objToJoin{s, c+1} = allObj{ind};
                end
            end
            %get SignalJoiners (one per cross-validation fold)
            for c = 0:cv.NumTestSets
                signalJoiners{1, c+1} = this.getSignalJoiner(objToJoin(:, c+1));
                for s = 1:length(sensors)
                    objToJoin{s, c+1}.addNextElement(signalJoiners{1, c+1});
                end
                featMats{1, c+1} = this.getFeatureMat();
                signalJoiners{1, c+1}.addNextElement(featMats{1, c+1});
                featMatsIds{1, c+1} = featMats{1, c+1}.getId();
                signalJoinersIds = signalJoiners{1, c+1}.getId();
            end
            allObj = [allObj, signalJoiners, featMats];
            ids = [ids, signalJoinersIds, featMatsIds];
            
            %BDW
            objToJoin = cell(length(sensors), cv.NumTestSets+1, size(targetMat, 2));
            objToJoinIds = cell(length(sensors), cv.NumTestSets+1, size(targetMat, 2));
            joinedSelectors = cell(1, cv.NumTestSets+1, size(targetMat,2));
            joinedSelectorsIds = cell(1, cv.NumTestSets+1, size(targetMat,2));
            cvMats = cell(1, 1, size(targetMat, 2));
            cvMatsIds = cell(1, 1, size(targetMat, 2));
            %get IDs and objects
            for t = 1:size(targetMat, 2)
                for c = 0:cv.NumTestSets
                    for s = 1:length(sensors)
                        if c == 0
                            %full object
                            objToJoinIds{s, c+1, t} = [num2str(t), 'PearsonMVStackSelSplCVSplDWTSpl', sensors{s}.getId];
                        else
                            %cross validated objects
                            objToJoinIds{s, c+1, t} = [num2str(t), 'PearsonMVStackSelSpl', num2str(c), 'CVSplDWTSpl', sensors{s}.getId];
                        end
                        ind = strcmp(ids, objToJoinIds{s, c+1, t});
                        objToJoin{s, c+1, t} = allObj{ind};
                    end
                    for s = 1:length(sensors)
                    end
                end
            end
            %get JoinedSelectors
            for t = 1:size(targetMat, 2)
                for c = 0:cv.NumTestSets
                    joinedSelectors{1, c+1, t} = this.getJoinedSelector(objToJoin(:, c+1, t));
                    for s = 1:length(sensors)
                        objToJoin{s, c+1, t}.addNextElement(joinedSelectors{1, c+1, t});
                    end
                    joinedSelectorsIds{1, c+1, t} = joinedSelectors{1, c+1, t}.getId();
                end
            end
            %get CVSelFeatMats
            for t = 1:size(targetMat, 2)
                cvMats{1, 1, t} = this.getCVSelFeatMat(joinedSelectorsIds(1, :, t));
                for c = 0:cv.NumTestSets
                    joinedSelectors{1, c+1, t}.addNextElement(cvMats{1, 1, t});
                end
                cvMatsIds{1, 1, t} = cvMats{1, 1, t}.getId();
            end
            allObj = [allObj, joinedSelectors(1:numel(joinedSelectors)),...
                squeeze(cvMats(1:numel(cvMats)))'];
            ids = [ids, joinedSelectorsIds(1:numel(joinedSelectors)),...
                squeeze(cvMatsIds(1:numel(cvMats)))'];

            %BFC
            objToJoin = cell(length(sensors), cv.NumTestSets+1, size(targetMat, 2));
            objToJoinIds = cell(length(sensors), cv.NumTestSets+1, size(targetMat, 2));
            joinedSelectors = cell(1, cv.NumTestSets+1, size(targetMat,2));
            joinedSelectorsIds = cell(1, cv.NumTestSets+1, size(targetMat,2));
            cvMats = cell(1, 1, size(targetMat, 2));
            cvMatsIds = cell(1, 1, size(targetMat, 2));
            %get IDs and objects
            for t = 1:size(targetMat, 2)
                for c = 0:cv.NumTestSets
                    for s = 1:length(sensors)
                        if c == 0
                            %full object
                            objToJoinIds{s, c+1, t} = ['JoinedSel', num2str(t), 'PearsonMVStackSelSplCVAngSplRangeFFTSpl', sensors{s}.getId];
                        else
                            %cross validated objects
                            objToJoinIds{s, c+1, t} = ['JoinedSel', num2str(t), 'PearsonMVStackSelSpl', num2str(c), 'CVAngSplRangeFFTSpl', sensors{s}.getId];
                        end
                        ind = strcmp(ids, objToJoinIds{s, c+1, t});
                        objToJoin{s, c+1, t} = allObj{ind};
                    end
                    for s = 1:length(sensors)
                    end
                end
            end
            %get JoinedSelectors to join signals from different sensors
            for t = 1:size(targetMat, 2)
                for c = 0:cv.NumTestSets
                    joinedSelectors{1, c+1, t} = this.getJoinedSelector(objToJoin(:, c+1, t));
                    for s = 1:length(sensors)
                        objToJoin{s, c+1, t}.addNextElement(joinedSelectors{1, c+1, t});
                    end
                    joinedSelectorsIds{1, c+1, t} = joinedSelectors{1, c+1, t}.getId();
                end
            end
            %get CVSelFeatMats
            for t = 1:size(targetMat, 2)
                cvMats{1, 1, t} = this.getCVSelFeatMat(joinedSelectorsIds(1, :, t));
                for c = 0:cv.NumTestSets
                    joinedSelectors{1, c+1, t}.addNextElement(cvMats{1, 1, t});
                end
                cvMatsIds{1, 1, t} = cvMats{1, 1, t}.getId();
            end
            allObj = [allObj, joinedSelectors(1:numel(joinedSelectors)),...
                squeeze(cvMats(1:numel(cvMats)))'];
            ids = [ids, joinedSelectorsIds(1:numel(joinedSelectors)),...
                squeeze(cvMatsIds(1:numel(cvMats)))'];
            
            %StatMom
            objToJoin = cell(size(targetMat, 2), numStatMomRanges, length(sensors));
            objToJoinIds = cell(size(targetMat, 2), numStatMomRanges, length(sensors));
            joinedSelectors = cell(1, size(targetMat, 2));
            joinedSelectorsIds = cell(1, size(targetMat, 2));
            featMats = cell(1, size(targetMat, 2));
            featMatsIds = cell(1, size(targetMat, 2));
            for t = 1:size(targetMat, 2)
                for r = 1:numStatMomRanges
                    for s = 1:length(sensors)
                        id = [num2str(t), 'PearsonSplStatMom', num2str(r), 'RangeSplSpl', sensors{s}.getId];
                        ind = strcmp(ids, id);
                        objToJoin{t, r, s} = allObj{ind};
                        objToJoinIds{t, r, s} = objToJoin{t, r, s}.getId();
                    end
                end
                joinedSelectors{t} = this.getJoinedSelector(reshape(objToJoin(t, :, :), 1, numStatMomRanges*length(sensors)));
                featMats{t} = this.getFeatureMat();
                joinedSelectors{t}.addNextElement(featMats{t});
                for r = 1:numStatMomRanges
                    for s = 1:length(sensors)
                        objToJoin{t, r, s}.addNextElement(joinedSelectors{t});
                    end
                end
                joinedSelectorsIds{t} = joinedSelectors{t}.getId();
                featMatsIds{t} = featMats{t}.getId();
            end
            allObj = [allObj, joinedSelectors, featMats];
            ids = [ids, joinedSelectorsIds, featMatsIds]; %#ok<NASGU>
            
            %PCA, still to come
            objToJoin = cell(length(sensors), cv.NumTestSets+1);
            objToJoinIds = cell(size(objToJoin));
            joinedSelectors = cell(1, cv.NumTestSets+1);
            joinedSelectorsIds = cell(size(joinedSelectors));
            featMat = cell(size(joinedSelectors));
            featMatIds = cell(size(joinedSelectors));
            for s = 1:length(sensors)
                for c = 0:cv.NumTestSets
                    if c == 0
                        objToJoinIds{s, c+1} = ['PCACVSplDsSpl', sensors{s}.getId()];
                    else
                        objToJoinIds{s, c+1} = ['PCA',num2str(c),'CVSplDsSpl', sensors{s}.getId()];
                    end
                    ind = strcmp(ids, objToJoinIds{s, c+1, t});
                    objToJoin{s, c+1, t} = allObj{ind};
                end
            end
            for c = 0:cv.NumTestSets
                joinedSelectors{c+1} = this.getJoinedSelector(objToJoin(:,c+1));
                for s = 1:length(sensors)
                    objToJoin{s, c+1}.addNextElement(joinedSelectors{c+1});
                end
                joinedSelectorsIds{c+1} = joinedSelectors{c+1}.getId();
                featMat{c+1} = this.getFeatureMat();
                joinedSelectors{c+1}.addNextElement(featMat{c+1});
                featMatIds{c+1} = featMat{c+1}.getId();
            end
            allObj = [allObj, joinedSelectors, featMat];
            ids = [ids, joinedSelectorsIds, featMatIds];
        end
    end
end

