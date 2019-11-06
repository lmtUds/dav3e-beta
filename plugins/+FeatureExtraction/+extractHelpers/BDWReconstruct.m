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

function [ residuals, trainFeat, testFeat ] = BDWReconstruct( trainData, numCoeffs, testData )
%BFCRECONSTRUCT Summary of this function goes here
%   Detailed explanation goes here

%buid object structure
controller = FeatureExtraction.extractHelpers.SerialController([], []);
if nargin > 2
    sensor = FeatureExtraction.extractHelpers.Sensor(FeatureExtraction.extractHelpers.RamData(trainData), 'sens', FeatureExtraction.extractHelpers.RamData(testData));
else
    sensor = FeatureExtraction.extractHelpers.Sensor(FeatureExtraction.extractHelpers.RamData(trainData), 'sens');
end
dwt = FeatureExtraction.extractHelpers.WaveletTransform();
spl = FeatureExtraction.extractHelpers.SignalSplitter();
abs = FeatureExtraction.extractHelpers.Abs();
boolSel = FeatureExtraction.extractHelpers.BooleanFlagSelector('Training', true);
if nargin <2
    mvLearner = FeatureExtraction.extractHelpers.MeanValueLearner();
else
    mvLearner = FeatureExtraction.extractHelpers.MeanValueLearner(numCoeffs);%changed for DAVE; blank -> autoFind
end
featMat = FeatureExtraction.extractHelpers.RAMFeatureMat();
stackedSel = FeatureExtraction.extractHelpers.StackedSelector({mvLearner}, false);

stackedSel.addNextElement(featMat);
abs.addNextElement(mvLearner);
spl.addNextElement(stackedSel);
boolSel.addNextElement(abs);
spl.addNextElement(boolSel);
dwt.addNextElement(spl);
sensor.addNextElement(dwt);
controller.addPipeline(sensor);
% join paths after splitting like in BFCReconstruct
% join = JoinedSelector({mvLearner, stackedSel},Inf);
% mvLearner.addNextElement(join);
% stackedSel.addNextElement(join);
% join.addNextElement(featMat);

%compute features
controller.trainFeatureExtraction();
if nargin > 2
    controller.apply();
end
ext = controller.getExtractors();
trainFeat = ext{1}.getTrainData(1,1,false);
if nargin > 2
    testFeat = ext{1}.getTrainData(1,1,true);
end

%getResiduals
[~, ind] = mvLearner.getRanking();
rec = FeatureExtraction.extractHelpers.BDWReconstructor(ind, sensor);
residuals = zeros(size(trainData));
for i = 1:size(trainData, 1)
    residuals(i,:) = rec.getResiduals(i);
end

