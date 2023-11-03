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

% !!! Only works if "mean" and/or "polyfit" as feature extraction methods
% are used

function updateFun = selectedFeatures(parent,project,dataprocessingblock)
    elements = makeGui(parent,project,dataprocessingblock);
    populateGui(elements,project,dataprocessingblock);
    updateFun = @()populateGui(elements,project,dataprocessingblock);
end

function elements = makeGui(parent,project,dataprocessingblock)
    grid = uigridlayout(parent,[2 1],'RowHeight',{'1x', 22});
    grid.Layout.Column = 1; grid.Layout.Row = 1;
    
    hAx = uiaxes(grid);
    hAx.Layout.Column = 1; hAx.Layout.Row = 1;
    elements.hAx = hAx;
    
    dropdown = uidropdown(grid,...
        'Items',project.currentCluster.sensors.getCaption(),...
        'ValueChangedFcn',@(varargin)populateGui(elements,project,dataprocessingblock));
    dropdown.Layout.Column = 1; dropdown.Layout.Row = 2;
    elements.dropdown = dropdown;
end

function populateGui(elements,project,dataprocessingblock)
    try
        selSens = elements.dropdown.Value;

        for i=1:length(project.currentCluster.sensors)
            sensor = project.currentCluster.sensors(1, i);
            if strcmp(sensor.caption,selSens)
                newsensor = sensor;
            end
        end

        getGroup=single(project.currentCluster.featureData.groupings);
        setGroup=getGroup(:,1);
        setGroup(~isnan(setGroup))=1;
        setGroup(isnan(setGroup))=0;
        setGroup=logical(setGroup);

        allData=newsensor.data;
        redDat=allData(setGroup,:);

        x1 = 1:1:newsensor.cluster.nCyclePoints;
        x = x1.*newsensor.cluster.samplingPeriod;

    %     plot(elements.hAx,x,redDat(1,:));
    %     xlabel(elements.hAx,'time');
    %     ylabel(elements.hAx,'data a.u.');
    %     
        redDat2 = 1./redDat;
        redDat3 = log10(redDat2);
        lowerBound = min(redDat3(~isinf(redDat3)),[],'all');
        upperBound = max(redDat3(~isinf(redDat3)),[],'all');
        minfill = lowerBound - abs(lowerBound) * 0.1;
        maxfill = upperBound + abs(upperBound) * 0.1;
        
        featCap=project.currentModel.fullModelData.featureCaptions;
        yfill=[minfill,minfill,maxfill,maxfill]';
        
        try
            str = featCap';
            str1 = str(contains(str,'mean'));
            str2 = split(str1,'mean_');
            iPosmean = double(split(str2(:,2),'-'));

            indMean = find(contains(featCap,'mean')&contains(featCap,selSens));

            selMean=project.currentModel.fullModelData.featureSelection(indMean(1):indMean(end))';
            selR1=iPosmean(selMean,:);

            xfillm=[selR1(:,1),selR1(:,2),selR1(:,2),selR1(:,1)]';
        
            f = fill(elements.hAx,xfillm,yfill,[1 1 .6]);
%             f.EdgeColor=[.5 .5 .5];
            hold(elements.hAx,'on');
        end
        
        try
            str = featCap';
            str1 = str(contains(str,'polyfit'));
            str2 = split(str1,'/');
            str3 = split(str2(:,3),'_');
            iPospoly = double(split(str3(:,2),'-'));

            indPoly = find(contains(featCap,'polyfit')&contains(featCap,selSens));

            selPoly=project.currentModel.fullModelData.featureSelection(indPoly(1):indPoly(end))';
            selR2=iPospoly(selPoly,:); 

            xfillp=[selR2(:,1),selR2(:,2),selR2(:,2),selR2(:,1)]';
   
            f = fill(elements.hAx,xfillp,yfill,[1 .6 .6]);
%             f.EdgeColor=[.5 .5 .5];
            hold(elements.hAx,'on');
        end
        
        try
            [~,row,~] = intersect(selR1(:,1),selR2(:,1));
            selR3=iPosmean(selMean,:);
            selR3=selR3(row,:);

            xfillmp=[selR3(:,1),selR3(:,2),selR3(:,2),selR3(:,1)]';
        
            f=fill(elements.hAx,xfillmp,yfill,[0 1 0]);
%             f.EdgeColor=[.5 .5 .5];
        end

        plot(elements.hAx,x,redDat3(1,:),'color','b');
        xlabel(elements.hAx,'time');
        ylabel(elements.hAx,'data a.u.');
        ylim(elements.hAx,[minfill maxfill]);
        fprintf('\n \n Mean: yellow \n Polyfit: red \n Mean&Polyfit: green \n \n');
        hold(elements.hAx,'off');

    %     plot(elements.hAx,x,errorTr(nCompPLSR,:),'k',x,errorV(nCompPLSR,:),'r',x,errorTe(end,:),'b');
    %     xlabel('time');
    %     ylabel('data a.u.');
    %     legend(elements.hAx,'Training','Validation','Testing');
    end
end
