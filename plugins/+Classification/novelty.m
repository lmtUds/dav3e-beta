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

function info = novelty()
    info.type = DataProcessingBlockTypes.Classification;
    info.caption = 'NoveltyDetection';
    info.shortCaption = mfilename;
    info.description = '';
    info.parameters = [...
        Parameter('shortCaption','type','value','KNN','enum',{'AEC','GMM','KDE','KNN','SVM'})...
        Parameter('shortCaption','trainScores','internal',true)...
        Parameter('shortCaption','testScores','internal',true)...
        Parameter('shortCaption','autoThreshold','value',true)...
        Parameter('shortCaption','threshold','value',0,'hidden',true)...
        Parameter('shortCaption','thresholdInt','value',0,'internal',true)...
        Parameter('shortCaption','trained', 'value',false, 'internal',true)...
        Parameter('shortCaption','classifier', 'internal',true)...
        Parameter('shortCaption','inputData', 'value',[], 'internal',true),...
        ];
    
%         Parameter('shortCaption','grouping', 'value','', 'enum',{''})...
%         Parameter('shortCaption','normalTag', 'value','find by majority', 'enum',{'find by majority'})...
%         Parameter('shortCaption','novelTag', 'value','find by majority', 'enum',{'find by majority'})...
    info.apply = @apply;
    info.train = @train;
    info.detailsPages = {'histogramNovelty','territorialPlotNovelty','rocNovelty'};
    info.updateParameters = @updateParameters;
end
function [data,params] = apply(data,params)
    if ~params.trained
        error('Classifier must first be trained.');
    end
%     data.mode
    [scores,pred ]= params.classifier.predict(data.getSelectedData());
    params.testScores = scores;
    data.setSelectedPrediction(pred);
    
    switch data.mode
        case 'training'
            params.inputData.training = data.getSelectedData();
        case 'testing'
            params.inputData.testing = data.getSelectedData();
    end  
end

function params = train(data,params)
    params.trained = true;
    params.classifier = Classification.noveltyDetection.noveltyClassifier(params.type);
%     if strcmp(params.normalTag,params.novelTag) & ~strcmp('find by majority',params.novelTag)& ~strcmp('find by majority',params.normalTag)
%        error('Pls choose distinct normal and novel tags.') 
%     end
    
    setTh  = ~params.autoThreshold;
%     setNorm= ~strcmp('find by majority',params.normalTag);
%     setNov = ~strcmp('find by majority',params.novelTag);
    
    if  setTh %& ~setNorm & ~setNov 
        params.classifier.train(data.getSelectedData(),data.getSelectedTarget(),params.threshold);
%     elseif ~setTh & setNorm & ~setNov
%         params.classifier.train(data.getSelectedData(),data.getSelectedTarget(),[],params.normalTag);
%     elseif ~setTh & setNorm & setNov
%         params.classifier.train(data.getSelectedData(),data.getSelectedTarget(),[],params.normalTag,params.novelTag);
%     elseif ~setTh & ~setNorm & setNov
%         params.classifier.train(data.getSelectedData(),data.getSelectedTarget(),[],[],params.novelTag);
%     elseif setTh & setNorm & ~setNov
%         params.classifier.train(data.getSelectedData(),data.getSelectedTarget(),params.threshold,params.normalTag);
%     elseif setTh & setNorm & setNov
%         params.classifier.train(data.getSelectedData(),data.getSelectedTarget(),params.threshold,params.normalTag,params.novelTag);
%     elseif setTh & ~setNorm & setNov
%         params.classifier.train(data.getSelectedData(),data.getSelectedTarget(),params.threshold,[],params.novelTag);
    else
        params.classifier.train(data.getSelectedData(),data.getSelectedTarget());
    end
    
    [scores,pred ]= params.classifier.predict(data.getSelectedData());
    params.trainScores = scores;
    if  params.autoThreshold
        params.thresholdInt = params.classifier.th;
    end
    data.setSelectedPrediction(pred);
end
function updateParameters(params,project)
    for i= 1:numel(params)
        if params(i).shortCaption == string('autoThreshold')
            %update all when this changes
            params(i).onChangedCallback = @()updateParameters(params,project);
            autoTh= params(i).value;
        elseif params(i).shortCaption == string('threshold')
            params(i).onChangedCallback = @()updateParameters(params,project);
            params(i).value = params(i).value;
            params(i).hidden = autoTh;
            params(i).updatePropGridField();
%         elseif params(i).shortCaption == string('grouping')
%             params(i).enum = cellstr(project.groupings.getCaption());
%             if isempty(params(i).value)
%                 params(i).value = params(i).enum{1};
%             end
%             grouping = project.getGroupingByCaption(params(i).getValue());
%             % update all parameters when this one is changed
%             params(i).onChangedCallback = @()updateParameters(params,project);
%         elseif params(i).shortCaption == string('normalTag')
%             if isempty(params(i).enum) || ~all(ismember(params(i).enum,cellstr(grouping.getCategories())))
%                 params(i).enum = ['find by majority';cellstr(grouping.getCategories())];
% %                 params(i).value = params(i).enum;
%                 params(i).updatePropGridField();
%             end
%         elseif params(i).shortCaption == string('novelTag')
%             if isempty(params(i).enum) || ~all(ismember(params(i).enum,cellstr(grouping.getCategories())))
%                 params(i).enum = ['find by majority';cellstr(grouping.getCategories())];
% %                 params(i).value = params(i).enum;
%                 params(i).updatePropGridField();
%             end
        end    
    end
end