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
helpVar = data.trainingSelection;
    for c = 1:cv.NumTestSets
    %     tic
        try
            data.trainingSelection = cell2mat(cv.training(c));
            data.validationSelection = cell2mat(cv.test(c));
            trTar = data.target(data.trainingSelection);
            teTar = data.target(data.validationSelection);
        catch
            data.trainingSelection(helpVar) = cv.training(c);
            data.validationSelection(helpVar) = cv.test(c);
            trTar = data.target(data.trainingSelection);
            teTar = data.target(data.validationSelection);
        end
        %brute force
        for i = 1:size(rank,1)
            params.trained = false;
            [params] = class.train(data,[],params,rank(1:i));
            for j = 1:nComp
                params.nComp = j; 
                if i >= j
                    data.mode = 'training';
                    [~ , params] = class.apply(data,params,rank(1:i));
                    data.mode = 'validation';
                    [~ , params2] = class.apply(data,params,rank(1:i));
                    errTr=sqrt(mean((params.pred-trTar).^2));
                    errVa=sqrt(mean((params2.pred-teTar).^2));
                    err.training(j,i) = err.training(j,i) + errTr;
                    err.validation(j,i) = err.validation(j,i) + errVa;  % regression
                    foldErrTr(j,i,c) = errTr;
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
    this.nFeat = idx;
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
    % data.trainingSelection(:) = true;      % reset trainingSelection
    % data.trainingSelection(data.testingSelection) = false;
    dat = data.data(this.projectedData.trainingSelection,:);
   
    if strcmp(this.classifier, 'plsr')
        [ptest] = class.train(data,[],params,sort(rank(1:this.nFeat))); % compute plsr-params for optimal number of feature
        if idxnComp>length(ptest.offset)
            idxnComp=length(ptest.offset);
        end
        predTr = dat(:,sort(rank(1:this.nFeat))) * ptest.beta0(:,idxnComp) + ptest.offset(idxnComp); % train plsr on training data
        tar = data.data(this.projectedData.testingSelection,:);
        predTe = tar(:,sort(rank(1:this.nFeat))) * ptest.beta0(:,idxnComp) + ptest.offset(idxnComp); % train plsr on testing data

        this.beta0 = ptest.beta0;
        this.offset = ptest.offset;
        this.projectedData.testing = predTe;
        this.projectedData.errorTest = sqrt(mean((predTe-data.target(data.testingSelection)).^2)); % compute RMSE for testing
        this.projectedData.errorVal = err.validation(idxnComp,this.nFeat);
        % train PLSR on testing data for trend of testing error (errorTrVaTe) 
        for i=1:(numel(rank))
            [ptest] = class.train(data,[],params,rank(1:i));
%             if idxnComp > length(ptest.offset)
%                 xnComp = length(ptest.offset);
%             else
%                 xnComp = idxnComp;
%             end
            for j=1:this.nComp
                if i < j
                    xnComp = i;
                else
                    xnComp = j;
                end
                predTe = tar(:,rank(1:i)) * ptest.beta0(1:i,xnComp) + ptest.offset(xnComp);
                errTest(j,i) = sqrt(mean((predTe-data.target(data.testingSelection)).^2));
            end
        end
    elseif strcmp(this.classifier, 'svr')
        [ptest] = class.train(data,[],params,sort(rank(1:this.nFeat))); % compute plsr-params for optimal number of feature

        predTr = predict(ptest.mdl,dat(:,sort(rank(1:this.nFeat)))); % train plsr on training data
        % predTr = dat(:,sort(rank(1:this.nFeat)))*ptest.mdl.Beta+ptest.mdl.Bias;
        tar = data.data(this.projectedData.testingSelection,:);
        predTe = predict(ptest.mdl,tar(:,sort(rank(1:this.nFeat)))); % train plsr on testing data

        this.projectedData.testing = predTe;
        this.projectedData.errorTest = sqrt(mean((predTe-data.target(data.testingSelection)).^2)); % compute RMSE for testing
        this.projectedData.errorVal = err.validation(this.nFeat);
        
        this.mdl = ptest.mdl;
        % train PLSR on testing data for trend of testing error (errorTrVaTe) 
        for i=1:(numel(rank))
            [ptest] = class.train(data,[],params,rank(1:i));
            predTe = predict(ptest.mdl,tar(:,rank(1:i)));
            errTest(i) = sqrt(mean((predTe-data.target(data.testingSelection)).^2));
        end
    else
        error('Something wrong with Regression in numFeatMulti');
    end
    
    this.err.testing = errTest;
    this.projectedData.nComp = idxnComp;
    this.projectedData.training = predTr;
end