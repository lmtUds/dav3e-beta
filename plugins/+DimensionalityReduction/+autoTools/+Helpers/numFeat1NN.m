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

function [ err ] = numFeat1NN( data, classes, rank, cv )
%NUMFEATLDAMAHAL Summary of this function goes here
%   Detailed explanation goes here

% err = zeros(1,size(data,2));
% data = zscore(data);
% parfor n = 1:size(data,2)
%     featInd = false(1, size(data,2));
%     featInd(rank(1:n)) = true;
%     
%     mdl = fitcecoc(data(:, featInd), classes, 'CVPartition', cv, 'Learners', 'knn');
%     err(n) = kfoldLoss(mdl);
% end
% end

err = zeros(1,size(data,2));
data = zscore(data);

for c = 1:cv.NumTestSets
    %standardize data?
    trainData = single(data(cv.training(c), :));
    testData = single(data(cv.test(c),:));
    
    trainTarget = repmat(classes(cv.training(c)), 1, size(testData, 1));
    t = classes(cv.training(c));
    testTarget = classes(cv.test(c));
    
    d = zeros(size(trainData,1), size(testData,1), 'single');
    ind = repmat(single(1:size(trainData,1))', 1, size(testData,1));
    [m,nP]=size(d);
    indCol = repmat(1:nP,m,1);
    idx = sub2ind([m nP],ind,indCol);
    for n = 1:size(trainData, 2)
        try
            newd = (trainData(:,rank(n)) - testData(:,rank(n))').^2;
            d = d + newd(idx);
            [d, ind] = sort(d);
            idx = sub2ind([m nP],ind,indCol);
            trainTarget = trainTarget(idx);
            
            %make prediction
            err(n) = err(n) + sum(testTarget ~= mode(trainTarget(1:5, :))');
            
            
%             id = knnsearch(trainData(:, rank(1:n)), testData(:, rank(1:n)));
%             err(n) = err(n) + sum(trainTarget(id) ~= testTarget;
            
            

            %way too slow
%              template = templateKNN('NumNeighbors', 5, 'Standardize', false);
%              mdl = fitcecoc(trainData(:, rank(1:n)), t, 'learners', template);
%              err(n) = err(n) + sum(mdl.predict(testData(:, rank(1:n))) ~= testTarget);
        catch
            err(n) = err(n) + length(testTarget);
        end
    end
end

err = err./size(data, 1);