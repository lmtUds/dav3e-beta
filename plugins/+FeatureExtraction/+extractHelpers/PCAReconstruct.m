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

function [ residuals, trainFeat, testFeat ] = PCAReconstruct( trainData, numCoeffs, testData )
%BFCRECONSTRUCT Summary of this function goes here
%   Detailed explanation goes here

%buid object structure
controller = FeatureExtraction.extractHelpers.SerialController([], []);
if nargin > 2
    sensor = FeatureExtraction.extractHelpers.Sensor(FeatureExtraction.extractHelpers.RamData(trainData), 'sens', FeatureExtraction.extractHelpers.RamData(testData));
else
    sensor = FeatureExtraction.extractHelpers.Sensor(FeatureExtraction.extractHelpers.RamData(trainData), 'sens');
end
if nargin <2
    pca = FeatureExtraction.extractHelpers.PCA();
else
    pca = FeatureExtraction.extractHelpers.PCA(numCoeffs);%changed for DAVE; blank -> autoFind
end
ds = FeatureExtraction.extractHelpers.ALADownsampler();
featMat = FeatureExtraction.extractHelpers.RAMFeatureMat();

pca.addNextElement(featMat);
ds.addNextElement(pca);
sensor.addNextElement(ds);
controller.addPipeline(sensor);

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
rec = FeatureExtraction.extractHelpers.PCAReconstructor(pca.coeff, pca.m, ds.dsFactor, sensor);
residuals = zeros(size(trainData));
for i = 1:size(trainData, 1)
    residuals(i,:) = rec.getResiduals(i);
end

