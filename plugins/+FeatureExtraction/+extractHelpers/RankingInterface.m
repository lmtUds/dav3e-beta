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

classdef RankingInterface < FeatureExtraction.extractHelpers.SignalChainElementInterface
    %RANKINGINTERFACE SignalChainElement that provides scores for
    %usefullness of features.
    %   This interface is implemented by all objects that represent
    %   preselection algorithms. The step function of all elements that
    %   implement RankingInterface is supposed to pass on only the most
    %   relevant features after training. The getRanking function provides
    %   access to the ranks, the  indices of the highest ranked features
    %   and the number of features to select according to the respective
    %   algorithm.
    
    properties (Access = protected)
        ranking = []; %Feature-Ranking vector for all Features
        % 1xNumFeatures numeric matrix containing ranks for entries in the
        % measurement vector processed by step (see
        % SignalChainElementInterface). By definition a higher value means
        % higher relevance of the feature.
    end
    
    methods (Abstract)
        [rank, ind, numToSelect] = getRanking(this) % Interface to access ranking for feature selection.
        % Provides Access to the ranking property for feature selection.
        %
        % Input:
        % this: RankingInterface whoes ranking property is used.
        %
        % Output:
        % rank:        Feature ranking for the data processed by step. By
        %              definition a higher value means higher relevance.
        % ind:         1xNumToSelect Boolean vector for logically indexing
        %              the selected features with highest relevance.
        % numToSelect: Number of features that should be selected using
        %              RankingInterface this.
    end
    
end

