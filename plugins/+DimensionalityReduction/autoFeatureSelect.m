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

function info = autoFeatureSelect()
%Provides a collection of automated feature selectors
%   The automated feature selection methods used are:
%       RFESVM, RELIEFF and Pearson Correlation
%   User selection specifies the methods DAV^3E will evaluate.
    
%start by providing information and parameters
    info.type = DataProcessingBlockTypes.DimensionalityReduction;
    info.caption = 'automated feature selection';
    info.shortCaption = mfilename;
    info.description = ['Feature selection methods for classification an regression cases.', ...
        'Ranking for Classification can be done with the methods (RFESVM, RELIEFF, Pearson)', ...
        'with a fixed number of features or with an automated optimization of the number of features.', ...
        'Ranking for Regression can be done with all methods, but only with a fixed number of features.', ...
        'For the automated optimization of the number of features use "automatedSelection" in the section "Regression"'];
    info.parameters = [...
        Parameter('shortCaption','trained', 'value',false, 'internal',true),...    
        Parameter('shortCaption','ranks', 'internal',true),... 
        Parameter('shortCaption','featureCaptions', 'internal',true),... 
        Parameter('shortCaption','methods', 'value',int32(1), 'enum',int32(1:6), 'selectionType','multiple'),...
        Parameter('shortCaption','autoNumFeat','value',true),...
        Parameter('shortCaption','RegrOrClass','value','Classification','enum',{'Classification','Regression'})...
        Parameter('shortCaption','numFeat', 'value',int32(3), 'enum',int32(1:50), 'selectionType','multiple'),...
        Parameter('shortCaption','evaluator','value','LDA','enum',{'LDA','1NN'})...
        Parameter('shortCaption','RFESVM', 'value',int32(1),'editable',false),...                                   %just for display
        Parameter('shortCaption','RELIEFF', 'value',int32(2),'editable',false),...                                  %just for display
        Parameter('shortCaption','Pearson', 'value',int32(3),'editable',false)...                                   %just for display  
        Parameter('shortCaption','NCA', 'value',int32(4),'editable',false),...                                   %just for display
        Parameter('shortCaption','RFEplsr', 'value',int32(5),'editable',false),...                                  %just for display
        Parameter('shortCaption','RFEleastsquares', 'value',int32(6),'editable',false)... 
        ];
%         Keep these for potential later use
%         Parameter('shortCaption','RFESVM', 'value',int32(1),'editable',false),...                                   %just for display
%         Parameter('shortCaption','RELIEFF', 'value',int32(2),'editable',false),...                                  %just for display
%         Parameter('shortCaption','Pearson', 'value',int32(3),'editable',false)...                                   %just for display
%         Parameter('shortCaption','methods','value','RFESVM','enum',{'RFESVM','RELIEFF','Pearson'},'selectionType','multiple'),...
    info.apply = @apply;
    info.train = @train;
    info.updateParameters = @updateParameters;
    info.detailsPages = {'scatter', 'ranking','selectedFeatures'};
end

function [data,params] = apply(data,params)
    if ~params.trained
        error('automated Methods must first be trained.');
    end
    %get the saved ranking from previous training
    ranks = params.ranks;
    %get the number of features to choose;may be set manualy or via training
    numFeat = params.numFeat;
    %accquire unselected feature captions
    selFeat = data.selectedFeatures();
    %select the best numFeat Captions matching the ranking
    data.setSelectedFeatures(selFeat(ranks(1:numFeat)));
end

function params = train(data,params)
    %translate integer indexing of methods
    switch params.methods
        case 1
            method = 'RFESVM';
        case 2
            method = 'RELIEFF';
        case 3
            method = 'Pearson';
        case 4
            method = 'NCA';
        case 5
            method = 'RFEplsr';
        case 6
            method = 'RFEleastsquares';
        otherwise
            method = 'wrong';
    end
    if params.autoNumFeat && strcmp(params.RegrOrClass, 'Regression')
        error('For autoNumFeat in case of Regression, use the autoSelection-method from section "Regression"');
    elseif strcmp(params.RegrOrClass, 'Classification') && (strcmp(method, 'NCA') || strcmp(method, 'RFEplsr') || strcmp(method, 'RFEleastsquares'))
        error('This method is only for Regression');
    end
    %compute the ranking by the desired method
    [ranks,params] = rankByMethod(data,params,method);
    %set parameters after training
    params.ranks = ranks;
    params.trained = true;
    %accquire unselected feature captions
    selFeat = data.selectedFeatures();
    %select the best numFeat Captions matching the ranking
    params.featureCaptions = selFeat(ranks(1:params.numFeat));
end

function updateParameters(params,project)
    for i = 1:numel(params)
        if params(i).shortCaption == string('autoNumFeat')
            %update all when this changes
            params(i).onChangedCallback = @()updateParameters(params,project);
            autoNumFeat= params(i).value;
        elseif params(i).shortCaption == string('numFeat')
            params(i).hidden = autoNumFeat;
            params(i).updatePropGridField();
        elseif params(i).shortCaption == string('evaluator')
            params(i).hidden = ~autoNumFeat;
            params(i).updatePropGridField();
        elseif params(i).shortCaption == string('methods')
        end
    end
end

function [ranks,params]  = rankByMethod(data,params,method)
%compute feature ranking for later selection
%ranking is done based on the selected method
    ranks = ones(size(data.getSelectedData(),2),1);
    if method == string('RFESVM')
        disp(method);
        if params.autoNumFeat
            mySel= DimensionalityReduction.autoTools.RFESVMSelector(params.evaluator);
            dTarget = double(data.getSelectedTarget());
            [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget);
            params.numFeat = sum(subsInd);
        else 
            if strcmp(params.RegrOrClass, 'Regression')
                mySel = DimensionalityReduction.autoTools.RFESVMSelector();
                mySel.RegrOrClass = params.RegrOrClass;
                dTarget = double(data.getSelectedTarget());
                [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget,[],params.numFeat);
            elseif strcmp(params.RegrOrClass, 'Classification')
                mySel = DimensionalityReduction.autoTools.RFESVMSelector();
                dTarget = double(data.getSelectedTarget());
                [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget,[],params.numFeat);
            else
                error('Invalid RegrOrClass specified, cannot compute feature ranks');
            end
        end
    elseif method == string('RELIEFF')
        disp(method);
        if params.autoNumFeat
            mySel = DimensionalityReduction.autoTools.RELIEFFSelector(params.evaluator);
            dTarget = double(data.getSelectedTarget());
            [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget);
            params.numFeat = sum(subsInd);
        else 
            if strcmp(params.RegrOrClass, 'Regression')
                mySel = DimensionalityReduction.autoTools.RELIEFFSelector();
                mySel.RegrOrClass = params.RegrOrClass;
                dTarget = double(data.getSelectedTarget());
                [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget,[],params.numFeat);
            elseif strcmp(params.RegrOrClass, 'Classification')
                mySel = DimensionalityReduction.autoTools.RELIEFFSelector();
                dTarget = double(data.getSelectedTarget());
                [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget,[],params.numFeat);
            else
                error('Invalid RegrOrClass specified, cannot compute feature ranks');
            end
            
        end
    elseif method == string('Pearson')
        disp(method);
        if params.autoNumFeat
            mySel= DimensionalityReduction.autoTools.PearsonSelector(params.evaluator);
            dTarget = double(data.getSelectedTarget());
            [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget);
            params.numFeat = sum(subsInd);
        else 
            if strcmp(params.RegrOrClass, 'Regression')
                mySel = DimensionalityReduction.autoTools.PearsonSelector();
                mySel.RegrOrClass = params.RegrOrClass;
                dTarget = double(data.getSelectedTarget());
                [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget,[],params.numFeat);
            elseif strcmp(params.RegrOrClass, 'Classification')
                mySel = DimensionalityReduction.autoTools.PearsonSelector();
                dTarget = double(data.getSelectedTarget());
                [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget,[],params.numFeat);
            else
                error('Invalid RegrOrClass specified, cannot compute feature ranks');
            end
            
        end 
    elseif method == string('NCA')
        disp(method);
        if ~params.autoNumFeat && strcmp(params.RegrOrClass, 'Regression') 
            mySel = DimensionalityReduction.autoTools.NCASelector();
            dTarget = double(data.getSelectedTarget());
           [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget,[],params.numFeat); 
        else
            error('Something went wrong with NCA');
        end
    elseif method == string('RFEplsr')
        disp(method);
        if ~params.autoNumFeat && strcmp(params.RegrOrClass, 'Regression') 
            mySel = DimensionalityReduction.autoTools.RFEplsrSelector();
            dTarget = double(data.getSelectedTarget());
            [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget,[],params.numFeat);
        else
            error('Something went wrong with RFEplsr');
        end
    elseif method == string('RFEleastsquares')
        disp(method);
        if ~params.autoNumFeat && strcmp(params.RegrOrClass, 'Regression') 
            mySel = DimensionalityReduction.autoTools.RFEleastsquaresSelector();
            dTarget = double(data.getSelectedTarget());
            [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget,[],params.numFeat);
        else
            error('Something went wrong with RFEleastsquares');
        end
    else
        error('Invalid method specified, cannot compute feature ranks');
    end
end