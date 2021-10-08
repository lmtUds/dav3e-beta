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

function [panel,updateFun] = errorTrVaTe(parent,project,dataprocessingblock)
    [panel,elements] = makeGui(parent);
    populateGui(elements,project,dataprocessingblock);
    updateFun = @()populateGui(elements,project,dataprocessingblock);
end

function [panel,elements] = makeGui(parent)
    panel = uipanel(parent);
    hAx = axes(panel); title('');
%     xlabel('nFeatures'); 
%     ylabel('RMSE');
    box on,
    set(gca,'LooseInset',get(gca,'TightInset')) % https://undocumentedmatlab.com/blog/axes-looseinset-property
    elements.hAx = hAx;
end

function populateGui(elements,project,dataprocessingblock)
    errorTr = dataprocessingblock.parameters.getByCaption('error').value.training(:,:);
    errorTrstd = dataprocessingblock.parameters.getByCaption('error').value.stdTraining(:,:);
    errorV = dataprocessingblock.parameters.getByCaption('error').value.validation(:,:);
    errorVstd = dataprocessingblock.parameters.getByCaption('error').value.stdValidation(:,:);
    errorTe = dataprocessingblock.parameters.getByCaption('error').value.testing(:,:);
    nCompPLSR = dataprocessingblock.parameters.getByCaption('projectedData').value.nComp;
    if isempty(errorTr)
        errorTr=[0];
    elseif isempty(errorV)
        errorV=[0];
    end
    x = 1:1:size(errorTr,2);
    plot(elements.hAx,x,errorTr(nCompPLSR,:),'k',x,errorV(nCompPLSR,:),'r',x,errorTe(nCompPLSR,:),'b');
    xlabel(elements.hAx,'nFeatures');
    ylabel(elements.hAx,'RMSE');
    legend(elements.hAx,'Training','Validation','Testing');
    numFeat=dataprocessingblock.parameters.getByCaption('numFeat').value;
    errTraining=errorTr(nCompPLSR,numFeat);
    errTrSTD = errorTrstd(nCompPLSR,numFeat);
    errValidation=errorV(nCompPLSR,numFeat);
    errVaSTD = errorVstd(nCompPLSR,numFeat);
    errTesting=errorTe(end,numFeat);
    fprintf('numFeat: %.1f \n nCompPLSR: %.1f \n errorTraining: %.2f \n errorTrainingStd: %.2f \n errorValidation: %.2f \n errorValidationStd: %.2f \n errorTesting: %.2f \n',...
        numFeat, nCompPLSR, errTraining, errTrSTD, errValidation, errVaSTD, errTesting);
end
