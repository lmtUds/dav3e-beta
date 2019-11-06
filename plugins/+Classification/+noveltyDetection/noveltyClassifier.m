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

classdef noveltyClassifier < handle
    properties
        novType = [];
        detector = [];
        novelTag = [];
        normalTag = [];
        th = [];
    end
    
    methods
        function this = noveltyClassifier(type)
            this.novType = type;
            switch type
                case 'AEC'
                    this.detector = Classification.noveltyDetection.AECNovelty();
                case 'GMM'
                    this.detector = Classification.noveltyDetection.GMMNovelty();
                case 'KDE'
                    this.detector = Classification.noveltyDetection.KDENovelty();
                case 'KNN'
                    this.detector = Classification.noveltyDetection.KNNNovelty();
                case 'SVM'
                    this.detector = Classification.noveltyDetection.SVMNovelty();
                otherwise
                    warning('invalid novelty detector')
            end
        end
        
        function [] = train(this, data, target,varargin)
            switch nargin
                case 3
                    this.detector.train(data);
                    uni = unique(target);
                    this.normalTag = this.majorityTag(uni,target);
                    uni = uni(~(this.normalTag == uni));
                    if ~isempty(uni)
                        this.novelTag =  this.majorityTag(uni,target);
                    else
                        this.novelTag = categorical(string('<ignore>'));
                    end
                case 4
                    this.detector.train(data);
                    if ~isempty(varargin{1})
                        this.detector.th = varargin{1};
                    else
                        this.novelTag = categorical(string('<ignore>'));
                    end
                    uni = unique(target);
                    this.normalTag = this.majorityTag(uni,target);
                    uni = uni(~(this.normalTag == uni));
                    if ~isempty(uni)
                        this.novelTag =  this.majorityTag(uni,target);
                    end
                case 5                   
                    this.detector.train(data);
                    if ~isempty(varargin{1})
                        this.detector.th = varargin{1};
                    end
                    uni = unique(target);
                    if ~isempty(varargin{2})
                        this.normalTag = varargin{2};
                    else
                        this.normalTag = this.majorityTag(uni,target);
                    end
                    uni = uni(~(this.normalTag == uni));
                    this.novelTag =  this.majorityTag(uni,target);
                case 6                   
                    this.detector.train(data);
                    if ~isempty(varargin{1})
                        this.detector.th = varargin{1};
                    end
                    uni = unique(target);
                    if ~isempty(varargin{2})
                        this.normalTag = varargin{2};
                    else
                        uni = uni(~(varargin{3} == uni));
                        this.normalTag = this.majorityTag(uni,target);
                    end
                    uni = uni(~(this.normalTag == uni));
                    if ~isempty(varargin{3})
                        this.novelTag = varargin{3};
                    else
                        this.novelTag =  this.majorityTag(uni,target);
                    end
                otherwise
            end
        end
        function [scores,class] = predict(this,data)
            [scores, class] = this.detector.apply(data);
            this.th = this.detector.th;
            pred = categorical();
            pred(class) = this.normalTag;
            pred(~class)= categorical(string('<ignore>'));
%             pred(~class)= this.novelTag;
                       
            class = categorical(pred);
        end
    end
    methods(Static)
        function tag = majorityTag(uniqueTags,target)
            c = 0;
            ind = 1;
            for i = 1:size(uniqueTags,1)
                if sum(uniqueTags(i)==target)> c
                    ind = i;
                    c = sum(uniqueTags(i)==target);
                end
            end
            tag = uniqueTags(ind);
        end
    end
end