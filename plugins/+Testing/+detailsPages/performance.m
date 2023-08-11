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

function updateFun = performance(parent,project,dataprocessingblock)
    populateGui(parent,project,dataprocessingblock);
    updateFun = @()populateGui(parent,project,dataprocessingblock);
end

function populateGui(parent,project,dataprocessingblock)
    model = project.currentModel;
    model.fullModelTrainingError;
    cap = {}; ind = {}; val = {};
    for i = 1:numel(model.hyperParameterCaptions)
        if size(model.hyperParameterValues,2)>1 && ~isempty(model.hyperParameterValues{i,2})
            cap{end+1} = model.hyperParameterCaptions{i};
            ind{end+1} = model.hyperParameterIndices(i,:);
            val{end+1} = model.hyperParameterValues(i,:);
        end
    end
    
    if iscategorical(model.datas(1).target)
        factor = 100;
        label = 'testing error / %';
    else
        factor = 1;
        label = 'RMSE';
    end
    
    red = [227,32,23] ./ 255;
    blue = [0,152,212] ./ 255;
    
    delete(parent.Children)
    ax = uiaxes(parent);
    ax.Layout.Column = 1; ax.Layout.Row = 1;
    hold(ax,'on');
%     if isempty(ind)
        b = bar(ax,...
            [model.fullModelTrainingError,...
...            model.fullModelValidationError,...
            model.fullModelTestingError] * factor);
        errors = [model.fullModelTrainingErrorStd,...
...            model.fullModelValidationErrorStd,...
            model.fullModelTestingErrorStd] * factor;
        errorbar(ax,b.XData,b.YData,errors,'k','LineStyle','none');
        ax.XTick = b.XData;
        ax.XTickLabel = {'training error','testing error'}; %,'validation error'
        ylabel(ax,label);
        if all(isnan(model.fullModelTestingError))
            ax.XTick = [1];
        end
        
%     elseif numel(ind) == 1
%         v = val{1};
%         x = [v{ind{1}}];
%         y = model.fullModelTrainingError * factor;
%         yerr = model.fullModelTrainingErrorStd * factor;
%         errorbar(ax,x,y,yerr,'ko--'); hold on;
% %         y = model.fullModelValidationError * factor;
% %         yerr = model.fullModelValidationErrorStd * factor;
% %         errorbar(ax,x,y,yerr,'rs--','color',red);
%         y = model.fullModelTestingError * factor;
%         yerr = model.fullModelTestingErrorStd * factor;
%         errorbar(ax,x,y,yerr,'b^--','color',blue);
%         c = strsplit(cap{1},'_'); xlabel(c{2});
%         ylabel(ax,label);
%         legend(ax,{'training','testing'}); %,'validation'
%         
%         errors.training = flip(model.fullModelTrainingError);
% %         errors.validation = flip(model.fullModelValidationError);
%         errors.testing = flip(model.fullModelTestingError);
%         errors.trainingStd = flip(model.fullModelTrainingErrorStd);
% %         errors.validationStd = flip(model.fullModelValidationErrorStd);
%         errors.testingStd = flip(model.fullModelTestingErrorStd);
%         
%         x = flip(x);
%         data = model.getValidatedDataForTrainedIndexSet();
%         
%         fprintf('performance:\n');
%         fprintf('min: %d\n', data.getBestParametersFromErrors('min',errors,x));
%         fprintf('minOneStd: %d\n', data.getBestParametersFromErrors('minOneStd',errors,x));
%         fprintf('minDivStd: %d\n', data.getBestParametersFromErrors('minDivStd',errors,x));
%         fprintf('elbow: %d\n', data.getBestParametersFromErrors('elbow',errors,x));
%         fprintf('trainValQuotient (0.95): %d\n', data.getBestParametersFromErrors('trainValQuotient',errors,x,0.95));
%         fprintf('trainValQuotient (0.99): %d\n\n', data.getBestParametersFromErrors('trainValQuotient',errors,x,0.99));
%         
%     else
%         v1 = val{1};
%         x = double([v1{ind{1}}]);
%         v2 = val{2};
%         y = double([v2{ind{2}}]);
%         z = model.fullModelValidationError * factor;
%         ux = unique(x);
%         uy = unique(y);
%         Z = zeros(numel(uy),numel(ux));
%         idxs = sub2ind(size(Z),double(categorical(y)),double(categorical(x)));
%         Z(idxs) = z;
%         surf(ax,ux,uy,Z);
%         c = strsplit(cap{1},'_'); xlabel(c{2});
%         c = strsplit(cap{2},'_'); ylabel(c{2});
%         zlabel(ax,label);
%         
%         half = linspace(.5,1,32)';
%         full = linspace(1,1,32)';
%         cm = flipud(([full,half,half;flipud([half,full,half])]));
%         colormap(ax,cm)
%         caxis(ax,[0 100]);
%     end
end
