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

function info = automatedMethods()
%Provides a collection of automated feature selectors
%   The automated feature selection methods used are:
%       RFESVM, RELIEFF and Pearson Correlation
%   User selection specifies the methods DAV^3E will evaluate.
    
%start by providing information and parameters
    info.type = DataProcessingBlockTypes.DimensionalityReduction;
    info.caption = 'auto Methods';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','trained', 'value',false, 'internal',true),...    
        Parameter('shortCaption','ranks', 'internal',true),... 
        Parameter('shortCaption','methods', 'value',int32(1), 'enum',int32(1:3), 'selectionType','multiple'),...
        Parameter('shortCaption','autoNumFeat','value',true),...
        Parameter('shortCaption','numFeat', 'value',int32(3), 'enum',int32(1:50), 'selectionType','multiple'),...
        Parameter('shortCaption','evaluator','value','LDA','enum',{'LDA','1NN'})...
        Parameter('shortCaption','RFESVM', 'value',int32(1),'editable',false),...                                   %just for display
        Parameter('shortCaption','RELIEFF', 'value',int32(2),'editable',false),...                                  %just for display
        Parameter('shortCaption','Pearson', 'value',int32(3),'editable',false)...                                   %just for display  
        ];
%         Keep these for potential later use
%         Parameter('shortCaption','RFESVM', 'value',int32(1),'editable',false),...                                   %just for display
%         Parameter('shortCaption','RELIEFF', 'value',int32(2),'editable',false),...                                  %just for display
%         Parameter('shortCaption','Pearson', 'value',int32(3),'editable',false)...                                   %just for display
%         Parameter('shortCaption','methods','value','RFESVM','enum',{'RFESVM','RELIEFF','Pearson'},'selectionType','multiple'),...
    info.apply = @apply;
    info.train = @train;
    info.updateParameters = @updateParameters;
    info.detailsPages = {'scatter'};
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
        otherwise
            method = 'wrong';
    end
    %compute the ranking by the desired method
    ranks = rankByMethod(data,params,method);
    %set parameters after training
    params.ranks = ranks;
    params.trained = true;
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

function ranks  = rankByMethod(data,params,method)
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
            mySel = DimensionalityReduction.autoTools.RFESVMSelector();
            dTarget = double(data.getSelectedTarget());
            [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget,[],params.numFeat);
        end
    elseif method == string('RELIEFF')
        disp(method);
        if params.autoNumFeat
            mySel = DimensionalityReduction.autoTools.RELIEFFSelector(params.evaluator);
            dTarget = double(data.getSelectedTarget());
            [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget);
            params.numFeat = sum(subsInd);
        else 
            mySel = DimensionalityReduction.autoTools.RELIEFFSelector();
            dTarget = double(data.getSelectedTarget());
            [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget,[],params.numFeat);
        end
    elseif method == string('Pearson')
        disp(method);
        if params.autoNumFeat
            mySel= DimensionalityReduction.autoTools.PearsonSelector(params.evaluator);
            dTarget = double(data.getSelectedTarget());
            [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget);
            params.numFeat = sum(subsInd);
        else 
            mySel = DimensionalityReduction.autoTools.PearsonSelector();
            dTarget = double(data.getSelectedTarget());
            [subsInd,ranks] = mySel.train(data.getSelectedData(),dTarget,[],params.numFeat);
        end    
    else
        error('Invalid method specified, cannot compute feature ranks');
    end
end