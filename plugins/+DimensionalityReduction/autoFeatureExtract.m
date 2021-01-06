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

% !!BETA!!
function info = autoFeatureExtract()
%Provides a collection of automated feature extractors
%   The automated feature extration methods used are:
%       ALA, BDW, BFC and PCA
%   User selection specifies the methods DAV^3E will evaluate.
    
%start by providing information and parameters
    info.type = DataProcessingBlockTypes.DimensionalityReduction;
    info.caption = 'BETA automated feature extraction';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','trained', 'value',false, 'internal',true),...    
        Parameter('shortCaption','extractors', 'internal',true),...
        Parameter('shortCaption','tracks', 'internal',true),...
        Parameter('shortCaption','trackInds', 'internal',true),...
        Parameter('shortCaption','featureCaptions', 'internal',true),...
        Parameter('shortCaption','ranks', 'internal',true),...
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
    info.detailsPages = {'ranking'};
end

function [data,params] = apply(data,params)
    if ~params.trained
        error('automated feature extraction must be trained first.');
    end
    
    % get the parameters saved in training
    extractors = params.extractors;
    tracks = params.tracks;
    trackInds = params.trackInds;
    
    features = [];
    captionSet = string.empty;
    
    % apply one extractor to its matching sensor/track data and create
    % matching captions
    for i = 1:size(extractors,2)
        ext = extractors{i};
        trackData = data.getSelectedData();
        trackData = trackData(:,trackInds(i,:));
        
        feats = ext.apply(trackData);
        
        captions = ext.getCaptions(size(feats,2),char(tracks(i)));
        
        if isempty(features)    % first iteration
            features = feats;
            captionSet = captions;
        else                    % other iterations
            features = horzcat(features,feats);
            captionSet = horzcat(captionSet, captions);
        end
    end
    % only change parameters if there is something to change to
    if ~isempty(features) && ~isempty(captionSet)
        params.featureCaptions = captionSet;
        params.ranks = 1:size(features,2);
        data.setSelectedData(features, 'captions', captionSet);
        data.setSelectedFeatures(captionSet);
    end
end

function params = train(data,params)
    % if multiple sensors/tracks were used, calculate indices for demerging
    [trackInds,tracks] = extractTracks(data.selectedFeatures());
    % create, train and save one extractor per sensor/track
    extractors = cell(1,size(trackInds,1));
    for i = 1:size(trackInds,1)
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
        else
            ext.numFeat = [];
        end
        % only use data of current sensor/track
        trackData = data.getSelectedData();
        trackData = trackData(:,trackInds(i,:));
        
        ext = ext.train(trackData);
        extractors{i} = ext;
    end
    %set parameters after training
    params.extractors = extractors;
    params.tracks = tracks;
    params.trackInds = trackInds;
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

function [inds,tracks] = extractTracks(featureNames)
    names = featureNames;
    for i = 1:size(featureNames,2)
        name = char(featureNames(i));
        slashes = strfind(name,'/');
        len = size(slashes,2);
        names(i) = name(1:slashes(len)-1);
    end
    tracks = unique(names);
    inds = true(size(tracks,2),size(featureNames,2));
    for i = 1:size(tracks,2)
        inds(i,:) = strcmp(names,tracks(i));
    end
end
