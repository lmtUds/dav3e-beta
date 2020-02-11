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

function info = autoFeatureExtract()
%Provides a collection of automated feature extractors
%   The automated feature extration methods used are:
%       ALA, BDW, BFC and PCA
%   User selection specifies the methods DAV^3E will evaluate.
    
%start by providing information and parameters
    info.type = DataProcessingBlockTypes.DimensionalityReduction;
    info.caption = 'automated feature extraction';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','trained', 'value',false, 'internal',true),...    
        Parameter('shortCaption','extractor', 'internal',true),...
        Parameter('shortCaption','featureCaptions', 'internal',true),... 
        Parameter('shortCaption','methods', 'value',int32(1), 'enum',int32(1:3), 'selectionType','multiple'),...
        Parameter('shortCaption','autoNumFeat','value',true),...
        Parameter('shortCaption','numFeat', 'value',int32(3), 'enum',int32(1:50), 'selectionType','multiple'),...
        Parameter('shortCaption','ALA', 'value',int32(1),'editable',false),...                                   %just for display
        Parameter('shortCaption','BDW', 'value',int32(2),'editable',false),...                                  %just for display
        Parameter('shortCaption','BFC', 'value',int32(3),'editable',false)...                                   %just for display
        Parameter('shortCaption','PCA', 'value',int32(4),'editable',false)...                                   %just for display
        ];
    info.apply = @apply;
    info.train = @train;
    info.updateParameters = @updateParameters;
    info.detailsPages = {'scatter', 'ranking'};
end

function [data,params] = apply(data,params)
    if ~params.trained
        error('automated feature extraction must be trained first.');
    end
    
    ext = params.extractor;
    
    feats = ext.apply(data.getSelectedData());
    
    %TODO: Update data to consist of computed features and set labels
    %accordingly to resemble the used extraction method
    
end

function params = train(data,params)
    %translate integer indexing of methods
    switch params.methods
        case 1
            method = 'ALA';
            ext = DimensionalityReduction.autoTools.ALAExtractor();
        case 2
            method = 'BDW';
            ext = DimensionalityReduction.autoTools.BDWExtractor();
        case 3
            method = 'BFC';
            ext = DimensionalityReduction.autoTools.BFCExtractor();
        case 4
            method = 'PCA';
            ext = DimensionalityReduction.autoTools.PCAExtractor();
        otherwise
            method = 'wrong';
    end
    % set manually specified feature count
    if ~params.autoNumFeat
        ext.numFeat = params.numFeat;
    end
    
    ext = ext.train(data.getSelectedData());
    %set parameters after training
    params.extractor = ext;
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
        elseif params(i).shortCaption == string('methods')
        end
    end
end
