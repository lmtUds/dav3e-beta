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

function info = automatedSelection()
%Provides a collection of automated feature selectors
%   The automated feature selection methods used are:
%       RFESVM, RELIEFF and Pearson Correlation
%   User selection specifies the methods DAV^3E will evaluate.
    
%start by providing information and parameters
    info.type = DataProcessingBlockTypes.Regression;
    info.caption = 'automated Selection';
    info.shortCaption = mfilename;
    info.description = ['Automated Feature Selection in 3 Steps with integrated Regression: ', ...
        '0. Rank the features with the selected method', ...
        '1. Sort dataset in training and validation', ...
        '2. For hyperparamater optimization (number of features or/and PLSR-component) build', ...
        'models with i=1...n features (Bottum-Up) and compute RMSE and standard deviation for each model', ...
        '3. Define the optimal parameters with the appropriate criterion'];
    info.parameters = [...
        Parameter('shortCaption','trained', 'value',false, 'internal',true),... 
        Parameter('shortCaption','rank', 'internal',true),... 
        Parameter('shortCaption','error', 'internal',true),... 
        Parameter('shortCaption','featureCaptions', 'internal',true),... 
        Parameter('shortCaption','methods', 'value','RFESVR', 'enum',{'RFESVR','RReliefF','Pearson','NCA','RFEplsr','RFEleastsquares'}),...
        Parameter('shortCaption','numFeat','internal',true),...
        Parameter('shortCaption','Validation','value','kFold'),...
        Parameter('shortCaption','groupbasedVal','value',true),...
        Parameter('shortCaption','groupingVal','value','', 'enum',{''}),...
        Parameter('shortCaption','evaluator','value','plsr','enum',{'plsr', 'svr'}),...
        Parameter('shortCaption','nCompPLSR','value',int32(20), 'enum',int32(1:20), 'selectionType','multiple'),...
        Parameter('shortCaption','criterion','value','MinOneStd+OptNComp','enum',{'Elbow','Min', 'MinOneStd','MinOneStd+OptNComp' , 'All'}),...
        Parameter('shortCaption','beta0','internal',true),...
        Parameter('shortCaption','offset','internal',true),...
        Parameter('shortCaption','mdl','internal',true),...
        Parameter('shortCaption','projectedData','internal',true),...%just for display  
        ];
%         Keep these for potential later use
%         Parameter('shortCaption','RFESVM', 'value',int32(1),'editable',false),...                                   %just for display
%         Parameter('shortCaption','RELIEFF', 'value',int32(2),'editable',false),...                                  %just for display
%         Parameter('shortCaption','Pearson', 'value',int32(3),'editable',false)...                                   %just for display
%         Parameter('shortCaption','methods','value','RFESVM','enum',{'RFESVM','RELIEFF','Pearson'},'selectionType','multiple'),...

%         Parameter('shortCaption','RFESVR', 'value',int32(1),'editable',false),...                                   %just for display
%         Parameter('shortCaption','RReliefF', 'value',int32(2),'editable',false),...                                  %just for display
%         Parameter('shortCaption','Pearson', 'value',int32(3),'editable',false),...                                   %just for display
%         Parameter('shortCaption','NCA', 'value',int32(4),'editable',false),...
%         Parameter('shortCaption','RFEplsr', 'value',int32(5),'editable',false),...
%         Parameter('shortCaption','RFEleastsquares', 'value',int32(6),'editable',false),...

    info.apply = @apply;
    info.train = @train;
    info.updateParameters = @updateParameters;
    info.detailsPages = {'ranking','errorTrVaTe', 'error3D', 'selectedFeatures', 'coefficients', 'predictionOverTime', 'calibration','correlation'};
    info.requiresNumericTarget = true;
end

function [data,params] = apply(data,params)
    if ~params.trained
        error('automated Methods must first be trained.');
    end
    %get the saved ranking from previous training
    rank = params.rank;
    %get the number of features to choose;may be set manualy or via training
    numFeat = params.numFeat;
    %accquire unselected feature captions
    selFeat = data.selectedFeatures();
    %select the best numFeat Captions matching the ranking
    data.setSelectedFeatures(selFeat(rank(1:numFeat)));
    %select the best numFeat Captions matching the ranking
    params.featureCaptions = selFeat(rank(1:numFeat));
    %apply optimized model to data
    params.nComp = params.projectedData.nComp;
    Regression.(params.evaluator)().apply(data,params);
end

function params = train(data,params)
    %translate integer indexing of methods
%     switch params.methods
%         case 1
%             method = 'RFESVR';
%         case 2
%             method = 'RReliefF';
%         case 3
%             method = 'Pearson';
%         case 4
%             method = 'NCA';
%         case 5
%             method = 'RFEplsr';
%         case 6
%             method = 'RFEleastsquares';
%         otherwise
%             method = 'wrong';
%     end
    
    method = params.methods;
    %compute the ranking by the desired method
    [rank, numFeat, error, beta0, offset, mdl, projectedData] = rankByMethod(data,params,method);
    %set parameters after training
    params.rank = rank;
    params.trained = true;
    params.numFeat = numFeat;
    params.error = error;
    params.beta0 = beta0;
    params.offset = offset;
    params.mdl = mdl;
    params.projectedData = projectedData;
end

function updateParameters(params,project)
 grouping_captions = project.mergedFeatureData.groupingCaptions;
 groupings = project.mergedFeatureData.groupings; 
    for i = 1:numel(params)
        % validation
        if params(i).shortCaption == string('groupbasedVal')
            % update all parameters when this one is changed
            params(i).onChangedCallback = @()updateParameters(params,project);
            groupbasedVal = params(i).value;
        elseif params(i).shortCaption == string('groupingVal')
            params(i).enum = cellstr(grouping_captions);
            if isempty(params(i).value)
                params(i).value = params(i).enum{1};
            end
            params(i).hidden = ~groupbasedVal;
        % evaluator
        elseif params(i).shortCaption == string('evaluator')
            params(i).onChangedCallback = @()updateParameters(params,project);
            plsr=strcmp(params(i).value, 'plsr');
        elseif params(i).shortCaption == string('nCompPLSR')
            params(i).hidden = ~plsr;
        end
    end
end

function [rank, numFeat, error, beta0, offset, mdl, projectedData]  = rankByMethod(data,params,method)
%compute feature ranking for later selection
%ranking is done based on the selected method
    rank = ones(size(data.getSelectedData(),2),1);
    if method == string('RFESVR')
        disp(method);
        mySel= Regression.autoTools.RFESVRSelector(params.evaluator);
        mySel.nComp = params.nCompPLSR;
        mySel.criterion = params.criterion;
        mySel.Validation = params.Validation;
        mySel.groupbasedVal = params.groupbasedVal;
        mySel.groupingVal = params.groupingVal;
        [subsInd,rank] = mySel.train(data);
    elseif method == string('RReliefF')
        disp(method);
        mySel = Regression.autoTools.RELIEFFSelector(params.evaluator);
        mySel.nComp = params.nCompPLSR;
        mySel.criterion = params.criterion;
        mySel.Validation = params.Validation;
        mySel.groupbasedVal = params.groupbasedVal;
        mySel.groupingVal = params.groupingVal;
        [subsInd,rank] = mySel.train(data);
    elseif method == string('Pearson')
        disp(method);
        mySel= Regression.autoTools.PearsonSelector(params.evaluator);
        mySel.nComp = params.nCompPLSR;
        mySel.criterion = params.criterion;
        mySel.Validation = params.Validation;
        mySel.groupbasedVal = params.groupbasedVal;
        mySel.groupingVal = params.groupingVal;
        [subsInd,rank] = mySel.train(data);
     elseif method == string('NCA')
        disp(method);
        mySel= Regression.autoTools.NCASelector(params.evaluator);
        mySel.nComp = params.nCompPLSR;
        mySel.criterion = params.criterion;
        mySel.Validation = params.Validation;
        mySel.groupbasedVal = params.groupbasedVal;
        mySel.groupingVal = params.groupingVal;
        [subsInd,rank] = mySel.train(data);
      elseif method == string('RFEplsr')
        disp(method);
        mySel= Regression.autoTools.RFEplsrSelector(params.evaluator);
        mySel.nComp = params.nCompPLSR;
        mySel.criterion = params.criterion;
        mySel.Validation = params.Validation;
        mySel.groupbasedVal = params.groupbasedVal;
        mySel.groupingVal = params.groupingVal;
        [subsInd,rank] = mySel.train(data);
      elseif method == string('RFEleastsquares')
        disp(method);
        mySel= Regression.autoTools.RFEleastsquaresSelector(params.evaluator);
        mySel.nComp = params.nCompPLSR;
        mySel.criterion = params.criterion;
        mySel.Validation = params.Validation;
        mySel.groupbasedVal = params.groupbasedVal;
        mySel.groupingVal = params.groupingVal;
        [subsInd,rank] = mySel.train(data);
    else
        error('Invalid method specified, cannot compute feature ranks');
    end
     numFeat = subsInd;
     error = mySel.err;
     beta0 = mySel.beta0;
     offset = mySel.offset;
     mdl = mySel.mdl;
     projectedData = mySel.projectedData;
end