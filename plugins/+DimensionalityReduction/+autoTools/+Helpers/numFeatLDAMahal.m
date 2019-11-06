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

function [ err ] = numFeatLDAMahal( data, classes, rank, cv )
%NUMFEATLDAMAHAL Summary of this function goes here
%   Detailed explanation goes here

groups = unique(classes);
dim = length(groups) - 1;
rankIndex = rank;
err = zeros(1,size(data,2));
data = zscore(data);

%iterate over cv-folds
for c = 1:cv.NumTestSets
%     c
    trainData = data(cv.training(c),:);
    trainData = trainData - sum(trainData)./sum(cv.training(c));
    testData = data(cv.test(c),:);
    testData = testData - sum(trainData)./sum(cv.training(c));
    testTarget = classes(cv.test(c));
    
    withinSSCP = zeros(size(trainData,2));
    covarianz = cell(size(groups));
    gm = cell(size(groups));
    for g = 1:length(groups)
        if iscell(groups) 
            ind = strcmp(classes(cv.training(c)), groups(g));
        else
            ind = classes(cv.training(c)) == groups(g);
        end
        gm{g} = mean(trainData(ind,:));
        withinSSCP = withinSSCP + (trainData(ind,:)-gm{g})' * (trainData(ind,:)-gm{g});
        covarianz{g} = cov(trainData(ind,:));
    end
    betweenSSCP = trainData' * trainData - withinSSCP;
    clear trainData;
    
    %iterate over the numbers of features;
%     fprintf('Progress:\n');
%     fprintf(['\n' repmat('.',1,size(testData,2)) '\n\n']);
    parfor n = 1:size(testData,2)
%         fprintf('\b|\n');
        try
            ind = false(1,size(testData,2));
            ind(rankIndex(1:n)) = true;

            withinSSCPRed = withinSSCP(ind, ind);
            betweenSSCPRed = betweenSSCP(ind, ind);
            covarRed = cellfun(@(a){a(ind,ind)}, covarianz);
            testD = testData(:,ind);

            warning('off', 'all');
            [proj, ~] = eig(withinSSCPRed\betweenSSCPRed);
            proj = proj(:, 1:min(n,dim));
            scale = sqrt(diag(proj' * withinSSCPRed * proj) ./ (sum(cv.training(c))-length(groups)));
            proj = bsxfun(@rdivide, proj, scale');

            testDataProj = testD * proj;
            mahalDist = Inf(size(testD,1), length(groups));
            icovar = cellfun(@(a){inv(proj' * (a * proj))}, covarRed);
            for g = 1:length(groups)
                m = gm{g}(ind)*proj;
                mahalDist(:,g) = sum(((testDataProj-m)*icovar{g}) .* (testDataProj-m), 2);
            end
            [~, pred] = min(mahalDist, [], 2);
            if ischar(groups)
                err(n) = err(n) + sum(~stccmp(groups{pred}, testTarget));
            else
                err(n) = err(n) + sum(groups(pred) ~= testTarget);
            end
        catch
            err(n) = err(n) + size(testData,1);
        end
    end
end

err = err / size(data, 1);
end

