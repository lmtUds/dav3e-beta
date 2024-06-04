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

function [ this ] = numFeatMulti(data, rank, cv, class, this)
%NUMFEATMULTI Summary of this function goes here
%   Detailed explanation goes here
    if numel(rank)<this.nComp
        nComp = numel(rank);
        warning('nComp is greater than number of features, so nComp is set to number of features');
    else
        nComp = this.nComp;
    end
    
    params.nComp = nComp;
    params.trained = false;
    err.training = zeros(nComp,size(rank,1),'single');
    err.validation = zeros(nComp,size(rank,1),'single');
    % sstot = zeros(nComp,size(rank,1),'single');
    % ssres = zeros(nComp,size(rank,1),'single');
    cacheMode = data.mode;
    cacheTrainingSelection = data.trainingSelection;
    selFeat = data.selectedFeatures();

    for c = 1:cv.NumTestSets
    %     tic
        try
            data.trainingSelection = cell2mat(cv.training(c));
            data.validationSelection = cell2mat(cv.test(c));
            trTar = data.target(data.trainingSelection);
            teTar = data.target(data.validationSelection);
        catch
            data.trainingSelection(cacheTrainingSelection) = cv.training(c);
            data.validationSelection(cacheTrainingSelection) = cv.test(c);
            trTar = data.target(data.trainingSelection);
            teTar = data.target(data.validationSelection);
        end
        %brute force
        for i = 1:size(rank,1)
            params.trained = false;
            data.mode = 'training';
            data.setSelectedFeatures(selFeat(rank(1:i)));
            [params] = class.train(data,params);
            for j = 1:nComp
                params.nComp = j; 
                if i >= j
                    data.mode = 'training';
                    [~ , params] = class.apply(data,params);
                    errTr=sqrt(mean((params.projectedData.training-trTar).^2));
                    err.training(j,i) = err.training(j,i) + errTr;
                    foldErrTr(j,i,c) = errTr;
                    data.mode = 'validation';
                    [~ , params] = class.apply(data,params);
                    errVa=sqrt(mean((params.projectedData.validation-teTar).^2));
                    err.validation(j,i) = err.validation(j,i) + errVa;  % regression
                    foldErrVa(j,i,c) = errVa;
%                     n(j,i)=numel(teTar);
%                     sstot(j,i)=sstot(j,i)+sum((params2.pred-mean(params2.pred)).^2);
%                     ssres(j,i)=ssres(j,i)+sum((params2.pred-teTar).^2);
                end
            end
        end      
    end
    foldErrTr(foldErrTr==0) = NaN;
    foldErrVa(foldErrVa==0) = NaN;
    
    for i=1:size(rank,1)
        for j=1:nComp
            err.stdTraining(j,i) = std(foldErrTr(j,i,:));
            err.stdValidation(j,i) = std(foldErrVa(j,i,:));
        end
    end
    err.training = err.training ./ c;
    err.validation = err.validation ./ c;                 % regression 
%     sstot = sstot./c;
%     ssres = ssres./c;
    err.training(err.training==0) = NaN;
    err.validation(err.validation==0) = NaN;

    data.mode = cacheMode;
    data.trainingSelection = cacheTrainingSelection;
    data.setSelectedFeatures(selFeat);
    
    %% Wahl Kriterium
    if strcmp(this.criterion, 'Elbow')
        y = err.validation(end,:);
        x = 1:1:(numel(rank));
        p1 = [x(1),y(1)];
        p2 = [x(end),y(end)];
        dpx = p2(1) - p1(1);
        dpy = p2(2) - p1(2);
        dp = sqrt(sum((p2-p1).^2));
        dists = abs(dpy*x - dpx*y + p2(1)*p1(2) - p2(2)*p1(1)) / dp;
        [~,idx] = max(dists);
        idxnComp = this.nComp;
    elseif strcmp(this.criterion, 'Min')
         minErr = min(err.validation(:));
         [~, idx] = find(err.validation==minErr);
         idxnComp = this.nComp;
    elseif strcmp(this.criterion, 'MinOneStd')
        minErr = min(err.validation(:));
        [row1, col1] = find(err.validation==minErr);
        ind=err.validation;
        ind(ind<(minErr+err.stdValidation(row1(1),col1(1))))=false;
        ind(ind>(minErr+err.stdValidation(row1(1),col1(1))))=true;
        ind = logical(ind);

        matrix=(1:1:(numel(rank))).*double(1:1:this.nComp)';
        matrix(ind)=NaN;
        minMatrix = min(matrix(:));
        [idxnComp,idx] = find(matrix==minMatrix);
        idx = min(idx);
        idxnComp = min(idxnComp);
    elseif strcmp(this.criterion, 'MinOneStd+OptNComp')    
        if contains(class.shortCaption,'svr')
            error('Use MinOneStd as criterion when using SVR.')
        end
        [m,ind] = min(err.validation(:,:));
        [row,col] = find(err.validation==min(err.validation(:)));
        minOneStd = err.validation(row,col)+err.stdValidation(row,col);
        [~,col1] = find(m<minOneStd);
        idx = col1(1);
        idxnComp = ind(idx);
    elseif strcmp(this.criterion, 'All')
        idx = size(err.validation,2);
        idxnComp = this.nComp;
    else
        [~, idx] = min(err.validation);
        idxnComp = this.nComp;
    end
    this.nFeat = idx(end);
    this.err = err;
%     try
%         this.beta0 = params.beta0;
%         this.offset = params.offset;
%     end
    % manual input of nComp and nFeat
%     idxnComp = 19; this.nFeat = 20;
    
    %% Weitere Berechnungen
    % rank = this.rank;
    % testing with the computed number of features before and save
    % results
    errTest = zeros(idxnComp,size(rank,1),'single');
    if strcmp(this.classifier, 'plsr')
        % train PLSR on testing data for trend of testing error (errorTrVaTe) 
        for i=1:(numel(rank))
            teParams.trained = false;
            teParams.nComp = idxnComp;
            data.mode = 'training';
            data.setSelectedFeatures(selFeat(rank(1:i)));
            [teParams] = class.train(data,teParams);
            for j=1:teParams.nComp
                if i < j
                    teParams.nComp = i;
                else
                    teParams.nComp = j;
                end
                data.mode = 'training';
                [~ , teParams] = class.apply(data,teParams);
%                 errTrain(j,i) = sqrt(mean((teParams.projectedData.training-data.target(data.trainingSelection)).^2));
    
                data.mode = 'testing';
                [~ , teParams] = class.apply(data,teParams);
                errTest(j,i) = sqrt(mean((teParams.projectedData.testing-data.target(data.testingSelection)).^2));
                
                if (j==idxnComp) && (i==this.nFeat)
                    predTr = teParams.projectedData.training;
                    predTe = teParams.projectedData.testing; 
                    this.beta0 = teParams.beta0;
                    this.offset = teParams.offset;
%                     this.projectedData.errorTrain = sqrt(mean((teParams.projectedData.training-data.target(data.trainingSelection)).^2));
                    this.projectedData.errorTrain = sqrt(mean((teParams.projectedData.training-data.target(~data.testingSelection&data.availableSelection)).^2));
                    this.projectedData.errorTest = sqrt(mean((teParams.projectedData.testing-data.target(data.testingSelection)).^2));
                end
            end
        end
        
        this.projectedData.errorVal = err.validation(idxnComp,this.nFeat);


    elseif strcmp(this.classifier, 'svr')
        % train SVR on testing data for trend of testing error (errorTrVaTe) 
        for i=1:(numel(rank))
            teParams.trained = false;
            data.mode = 'training';
            data.setSelectedFeatures(selFeat(rank(1:i)));
            [teParams] = class.train(data,teParams);

            data.mode = 'training';
            [~ , teParams] = class.apply(data,teParams);

            data.mode = 'testing';
            [~ , teParams] = class.apply(data,teParams);
            errTest(i) = sqrt(mean((teParams.projectedData.testing-data.target(data.testingSelection)).^2));
            
            if i==this.nFeat
                predTr = teParams.projectedData.training;
                predTe = teParams.projectedData.testing; 
                this.mdl = teParams.mdl;
                this.projectedData.errorTrain = sqrt(mean((teParams.projectedData.training-data.target(~data.testingSelection&data.availableSelection)).^2));
                this.projectedData.errorTest = sqrt(mean((teParams.projectedData.testing-data.target(data.testingSelection)).^2));
            end
        end
        
        this.projectedData.errorVal = err.validation(this.nFeat);
    else
        error('Something wrong with Regression in numFeatMulti');
    end
    
    data.setSelectedFeatures(selFeat);
    data.mode = cacheMode;
    this.err.testing = errTest;
    this.projectedData.testing = predTe;
    this.projectedData.nComp = idxnComp;
    this.projectedData.training = predTr;
end