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

classdef FactoryInterface < handle
    %FACTORYINTERFACE Interface for all factory methods for all objects
    %provided by this program.
    %   The FactoryInterface is the implementation of the dependency
    %   inversion principle. It allows objects, that need to have an object
    %   of a specific type to depend on an abstract interface. This
    %   Interface provides all functions needed to create and assamble
    %   objects and therefore seperates program structure from
    %   functionality.
    
    properties
    end
    
    methods (Access = protected)
        function this = FactoryInterface
        end
    end
    
    methods (Static, Abstract)
        getFactory();
        %Method to get the Factory that offers all the factory methods.
        %Since there can be only one Factory per worker this function has
        %to be static.
        
        getUniqueId();
        %Returns a short number string that is unique and can be used to
        %identyfy sensors, cvpartitions or Ranges.
    end
    
    methods (Abstract)
        %All factory methods follow the same calling syntax that is:
        %obj = get<Classname>(varargin{}).
        
        getAbs(this, varargin);
        %Gets a signal chain element that applies the abs function to the
        %processed signal.
        %
        %Inputs: none
        %
        %Outputs:
        %obj: Abs object.
        
        getALADownsampler(this, varargin);
        %Gets an object that downsamples the processed signal to
        %approximately 500 points. Use this object to reduce signal length
        %before applying ALAErrTransform and ALASplit. A standard signal
        %chain to apply ALA would be
        %Sensor->ALADownsampler->ALAErrMat->CrossVal->ALASplit->FeatureMat
        %
        %Inputs: none
        %
        %Outputs:
        %obj: ALADownsampler object.
        
        getALAErrTransform(this, varargin);
        %Gets an object that transform a signal into an array of fit errors
        %that can be used to construct the fitErrorMatrix needed to
        %perform ALA.  A standard signal chain to apply ALA would be
        %Sensor->ALADownsampler->ALAErrMat->CrossVal->ALASplit->FeatureMat
        %
        %Inputs: none
        %
        %Outputs:
        %obj: ALAErrTransform object.
        
        getALASplit(this, varargin);
        %Gets and object that performs the ALA split. During training the
        %incoming fitErrorMatrix is summed up to take into account the
        %errors of all cycles. The first time a non-training cycle is
        %processed the best split points will be computed and from there on
        %the linear fit parameters mean value and slope between splitpoints
        %are passed on as extracted features. A standard signal chain to 
        %apply ALA would be
        %Sensor->ALADownsampler->ALAErrMat->CrossVal->ALASplit->FeatureMat
        %
        %Inputs: none
        %
        %Outputs:
        %obj: ALASplit object.
       
        getBooleanFlagSelector(this, varargin);
        %Gets a signal chain element that passes on a cycle based on a
        %boolean flag in metaInfo having the specified value. Value and
        %name of the boolean flag are specified as constructor argument.
        %The same flag is checked, if the BooleanFlagSelector is asked for
        %the requested cycles.
        %
        %Inputs:
        %name: String specifying the name of the boolean flag.
        %val:  Value the flag is supposed to have to be passed on.
        %
        %Outputs:
        %obj:  BooleanFlagSelector object.
        
        getCachedMultifileData(this, varargin);
        %Gets a DataInterface for sensor data that is distributed over
        %multiple files. The DataInterface treats every file as independent
        %data chunk and caches each file in main memory to speed up disk
        %access.
        %
        %Inputs:
        %files:     Cell array of strings containing full or relative paths
        %           to the singel files.
        %indices:   Indexing vector for each cycle that specifies the file
        %           number that contains the respective cycle. Example:
        %           Cycle i is contained in file files{indices(i)}.
        %offsets:   Vector of cycle offsets for each file. Example: the
        %           absolute cycle number of the ith cycle in file j is
        %           offests(j)+i.
        %
        %Outputs:
        %obj:       CachedMultifileData object.
        
        getComplexAngle(this, varargin);
        %Gets the angle of a complex vector and forwards it to the next
        %element.
        %
        %Inputs: none
        %
        %Outputs:
        %obj:       ComplexAngle object.
        
        getCrossValidator(this, varargin);
        %Create a SignalChainElement that performs crossvalidation by
        %supporting an array of output signals and training every signal on
        %a different fold. Each incoming cycle is only passed on to the
        %folds that include this cycle in their training. The respective
        %splits of the dataset are specified by a cvpartition object
        %(MATLAB native). The regular next element is still aviable and is
        %trained on the all training cycles and can act as reference.
        %
        %Inputs:
        %cv:            cvpartition object specifying how to split the
        %               training cycles. For further info see MATLAB docu.
        %outSignals:    Cell array of identical SignalChainElements
        %               representing the elements that process the cycles
        %               of different folds. Its length is identical to
        %               cv.NumTestSets.
        %
        %Outputs:
        %obj:           CrossValidatior object.
        %
        %The operation principle of this object might change in future
        %releases when using MapReduceController.
        
        
        getCVSelFeatMat(this, varargin);
        %Create a SignalChainElement that combines results from different
        %cross-validation folds with identical signal path and stores them
        %efficiently. All features that are identical for multiple folds
        %are stored only once. So far there is no interface to retrive
        %this data. Instead the properties are publicly accessable.
        %
        %Inputs:
        %ids:   Cell array of strings specifying the ids of the signals that
        %       are to be combined by this object.
        %
        %Outputs:
        %obj:   CVSelFeatMat object.
        
        getCycleRange(this, varargin);
        %Create a SignalChainElement that acts like a cycle range by
        %passing on only specified cycles. This object enables both
        %continous and discontinous ranges.
        %
        %Inputs:
        %selectedCycles: Boolean array specifyinig if the cycle
        %                corresponding to the entry in this vector should
        %                be passed on or not. The array has to have the
        %                same length as the total number of processed
        %                signals
        %udi:            String that is pasted between idSuffix and the
        %                rest of the id to ensure the id being unique. This
        %                feature is not yet impelemted
        %
        %Outputs:
        %obj:            CycleRange object.
        
        getFeatureInfoSet(this, varargin);
        %Creates a FeatureInfoSet that can be used to store informations
        %about features and their extraction method. The returned
        %FeatureInfoSet implements FeatureInfoSetInterface.
        %
        %Inputs: none
        %
        %Outputs:
        %featInfo: FeatureInfoSet object.
        
        getFeatureMat(this, varargin);
        %Creates a SignalChainElementInterface that stores feature vectors
        %from a single source. Features can be retrived as matrix after
        %training. The property featMat is public and contains one feature
        %per row and one cycle per column.
        %
        %Inputs: none
        %
        %Outputs:
        %obj: FeatureMat object.
        
        getFeatureMatExtractor(this, varargin)
        %Creates a FeatureExtractor that maps FeatureMatrix objects that
        %have been created using Big-Data feature extraction to the
        %FeatureExtractorInterface.
        %
        %Inputs:
        %featMat:  FeatureMatrixInterface that stores the features that were
        %          extracted using the method represented by this FeatureMatExtractor
        %name:     Name of the feature extraction method that is
        %          represented by this FeatureMatExtractor.
        %cv:       cvpatition object that represents the applied
        %          cross-validation.
        %targets:  numCycles x numTargets matrix containing the used
        %          target vectors.
        %
        %Outputs:
        %this:     FeatureMatrixExtractor object.
        
        getMatFileData(this,varargin)
        %Creates a MatFileData that implements DataInterface and represents
        %data that is stored in a .mat file in a variable that is named
        %'data'. The matrix shape of data is numFeat x numCyc.
        %
        %Inputs:
        %filename: Name of the .mat file that contains the data matrix
        %
        %Outputs:
        %this:     MatFileData object.
        
        getFeatMatWrapper(this, varargin);
        %Creates a Wrapper that wraps one or multiple FeatMats or
        %CVSelFeatMats to one FeatureMatrixInterface.
        %
        %Inputs:
        %sigChainElements: A numCV x NumTargets cell array of
        %                  SignalChainElements that implement
        %                  FeatureMatrixInterface. If the Featrue matrices
        %                  do not depend on cross-validation-fold or target
        %                  the size in the corresponding dimension is one.
        %
        %Outputs:
        %obj:              FeatMatWrapper object.
        
        getFourierTransform(this, varargin);
        %Creates a SignalChainElementInterface that performs FFT on
        %incoming data.
        %
        %Input: none
        %
        %Outputs:
        %obj: FourierTransform object.
        
        getGenericSecondaryFeature(this, varargin);
        %Creates a SignalChainElementInterface that acts as a generic
        %feature and supports multiple inputs. The functionality is defined
        %by a userdefined function fun with the following syntax:
        %outSignal = fun(data, metaInfo) where outSignal is an array of
        %output data that is passed on to the next elment, data is a cell
        %array of numerical arrays where each cell contains the input data
        %from one input spource in the order specified by ids. metaInfo is
        %the containers.Map object containing flags and metadata. For more
        %info see ControllerInterface.
        %
        %Inputs:
        %ids: Cell array of strings containing the ids of the input signals
        %     that are to be processed. The order of ids specifies the
        %     order of the signals in 'data'.
        %fun: Function handle to the function that performs the data
        %     processing.
        
        getJoinedSelector(this, varargin);
        %Creates a RankingInterface that joins the most relevant features
        %from multiple RankingInterfaces into a single output signal. The
        %joined SignalChainElements that implement RankingInterface have to
        %be of the same class to make relevance scores compareable. The
        %order of features in the joined signal is the same as in the
        %individual signals and the order of the signals is the same as in
        %SignalsToJoin.
        %
        %Inputs:
        %SignalsToJoin: Cell array of SignalChainElements that implement
        %               RankingInterface and are all of the same class.
        %               This array contains the SignalChainElements whoes
        %               signals are to be joined.
        %
        %Outputs:
        %obj:           JoinedSelector object.
        
        getLDAMahalClassifier(this, varargin);
        %Creates a Classifier that performs LDA on the features and
        %classifies data according to the Mahalanobis distance to the group
        %centers. The point is classified to the nearest class in terms of
        %Mahalanobis distance to the group center.
        %
        %Inputs:
        %data:    NumPoints x NumFeatures Training data the classifier can
        %         be trained on.
        %target:  NumPoints Grouping vector specifying group membership of
        %         the triaining data points.
        %projLDA: Already known LDA projection matrix.
        %
        %Outputs:
        %this:    LDAMahalanobisClassifier object.
        
        getRestrictedMatFileData(this, varargin)
        %Creates a RestrictedMatFileData that implements DataInterface. It
        %represents data that is stored in a .mat file in a numFeat x
        %numCyc matrix named data, that is not completly used. The used
        %cycles are specified on construction. Indexing is performed after
        %the used cycles are selected. So requesting the first cycle will
        %return the first used cycle.
        %
        %Inputs:
        %fileName: Name of the .mat file that contains the data.
        %used:     Boolean vector whos length is equal to the number of
        %          columns of data. It specifies for each cycle wether it
        %          is used or not.
        %
        %Outputs:  RestrictedMatFileData object.
        
        getStackedSelector(this, varargin);
        %Creates a SignalChainElementInterface that implements
        %RankingInterface and combines the rankings of two or more
        %adifferent SignalChainElements that implement RankingInterface.
        %The rankings are applied consecutively meaning ranking one is
        %applied and features are extracted respectively. Afterwards the
        %next ranking is applied to the remaining features and so on.
        %All feature selectors stacked here have to select less features
        %that their precessor.
        %
        %Inputs:
        %selectors: Cell array of SignalChainElements that implement
        %           RankingInterface and are combined by this element. The
        %           order of the  results specifies the order in which the
        %           selectors are aplied to the feature vector.
		%update:    Boolean flag specifying wether the StackedSelector
        %           should update the selectors (true) or the selectors
        %           are updated externaly.
        %
        %Outputs:
        %obj:       StackedSelector object.
        
        getMapReduceController(this, varargin);
        %Creates a ControllerInterface that applies two runs of MapReduce
        %to train feature extraction and compute results.
        %
        %Inputs: none
        %
        %Outputs:
        %obj: MapReduceController
        
        getMeanValueLearner(this, varargin);
        %Creates SignalChainElementInterface that implements
        %RankingInterface and selects the 10% features with highest mean
        %value. It is used for signals where a higher mean value
        %corresponds to higher signal energy represented by the feature.
        %
        %Inputs: none
        %
        %Outputs:
        %obj: MeanValueLearner object.
        
        getOneNNClassifier(this, varargin);
        %Creates a Classifier object that uses one nearest neighbour with
        %euclidean distance for classification.
        %
        %Inputs: none
        %
        %Outputs:
        %obj: OneNNClassifierObject
        
        getPCA(this, varargin);
        %Creates SignalChainElementInterface that performs PCA after
        %training. During training no data is forwarded to the next
        %element. After training the projection on the principal components
        %is forwarded as new data. This object also implements selector
        %Interface that ranks the PCs descending with the order of their
        %appearance.
        %
        %Inputs: none
        %
        %Outputs:
        %obj:  PCA object.
        
        getPDV1DataInterface(this, varargin);
        %Creates a Data Interface for test bench data (Version 1.0) that
        %interfaces sensor sn of the dataset that is cached by
        %PDV1CycleBuffer cb.
        %
        %Inputs:
        %sn: Number of the sensor in that dataset cached by cb
        %cb: PDV1CycleBuffer that buffers data from the interfaced dataset
        %    to speed up disk access.
        %
        %Outputs:
        %obj: PDV1DataInterface object, that interfaces sensor sn from
        %     CycleBuffer cb.
        
        getPearsonPreselection(this, varargin);
        %Creates SignalChainElementInterface that implements
        %RankingInterface and performs feature selection by selecting the
        %500 features with highest absolute Pearson-Correlation to a
        %specified target.
        %
        %Inputs:
        %target: Numerical column vector containing the target towards the
        %        correlation is computed. The length of target is the
        %        number of overall processed cycles.
        %uid:    String that is inserted between idSuffix and the id of the
        %        previous signal to keep signal ids unique in case of
        %        multiple targets
        %
        %Outputs:
        %obj: PearsonPreselection object.
        
        getPearsonSelector(this, varargin);
        %Returns a FeatureSelector that slects Features using Pearson
        %correlation to the target for feature selection.
        %
        %Inputs:
        %classifier: Name of classifier to use. Currently supported: LDA,
        %        1NN
        %data:   NumPoints x NumFeatures numerical matrix representing the
        %        training data. (optional)
        %target: Numerical grouping array of length NumPoints representing
        %        the classification target. (optional)
        %rank:   Numerical Vector of length NumFeatures that sets an
        %        already known feature ranking to prevent retraining.
        %        (optional)
        %nFeat:  Number of features that are to be selected by this
        %        selector. (optional)
        %
        %Outputs:
        %this:   PearsonSelector object that implements
        %        FeatureSelectorInterface
        
        getRamData(this, varargin);
        %Creates a dataInterface that interfaces data stored in main
        %memory. Using RamData the BigData algorithms can also be applied
        %to small amounts of data.
        %
        %Inputs:
        %data: Data matrix containing the data to evaluate
        %      (NumCycles x NumFeatrues numerical matrix).
        %
        %Outputs:
        %obj:  RamData object.
        
        getRange(this, varargin);
        %SignalChainElementInterface that represents a feature range and
        %passes on only certain sections of the feature vector. This object
        %supports discontious ranges.
        %
        %Inputs:
        %selectedPoints: Boolean vector of the same length as the data that
        %                is processed by this element specifying wich
        %                features are to be passed on to the next element.
        %                The order of the features is not chaged.
        %uid:            String that is inserted between idSuffix and the
        %                id of the previous signal to keep signal ids
        %                unique in case of multiple targets
        %
        %Outputs:
        %obj:            Range object.
        
        getRELIEFFSelector(this, varargin)
        %Returns a FeatureSelector that slects Features using univariate
        %REFLIEFF for feature selection.
        %
        %Inputs:
        %classifier: Name of classifier to use. Currently supported: LDA,
        %        1NN
        %data:   NumPoints x NumFeatures numerical matrix representing the
        %        training data. (optional)
        %target: Grouping Array of length NumPoints representing the
        %        classification target. (optional)
        %rank:   Numerical Vector of length NumFeatures that sets an
        %        already known feature ranking to prevent retraining.
        %        (optional)
        %nFeat:  Number of features that are to be selected by this
        %        selector. (optional)
        %
        %Outputs:
        %this:   RELIEFFSelector object that implements
        %        FeatureSelectorInterface
        
        getRFESVMSelector(this, varargin)
        %Returns a FeatureSelector that slects Features using Recursive
        %Feature Elimination Support Vector Machines for feature selection.
        %
        %Inputs:
        %classifier: Name of classifier to use. Currently supported: LDA,
        %        1NN
        %data:   NumPoints x NumFeatures numerical matrix representing the
        %        training data. (optional)
        %target: Grouping Array of length NumPoints representing the
        %        classification target. (optional)
        %rank:   Numerical Vector of length NumFeatures that sets an
        %        already known feature ranking to prevent retraining.
        %        (optional)
        %nFeat:  Number of features that are to be selected by this
        %        selector. (optional)
        %
        %Outputs:
        %this:   RFESVMSelector object that implements
        %        FeatureSelectorInterface
        
        getSensor(this, varargin);
        %Creates a SignalChainElement that represents a sensor and feeds
        %requested cycles into the SignalChain. Input to the step function
        %is typically a single number specifying the cyclenumber of the
        %cycle that is to be processed next.
        %
        %Inputs:
        %dataInterface: DataInterface to the sensor-data.
        %uid:           String that is inserted between idSuffix and id of
        %               the previous id to ensure signal ids to be unique
        %               in case of multiple senesors.
        %evalData:      DataInterface to evaluation data when no cross
        %               validation is used.
        %
        %Outputs:
        %obj:           Sensor object.
        
        getSerialController(this, varargin);
        %Creats a ControllerInterface that serially trains extractors and
        %extracts features.
        %
        %Inputs: none.
        %
        %Outputs:
        %obj: SerialController object.
        
        getSignalJoiner(this, varargin);
        %Creates a SignalJoiner that joins the signals with the given ids
        %to a sngle signal.
        %
        %Inputs:
        %signalsToJoin:   Cell array of objects whos output should be 
        %                 joined into a single signal.
        %
        %Outputs:
        %obj: SignalJoiner object.
        
        getSignalSplitter(this, varargin);
        %Creats a SignalChainElementInterface that distriputes incoming
        %signals to multiple targets. Outputs can be added using
        %addNextElement(nextElement).
        %
        %Inputs: none
        %
        %Outputs: SignalSplitter object.
        
        getSingleMatFileData(this, varargin);
        %Creats a DataInterface that interfaces data stored in a single
        %.mat file. The data is stored as numerical matrix (NumCycles x
        %NumFeatures) with name data.
        %
        %Inputs:
        %path: Full or relative path to the .mat file containing the data.
        %
        %Outputs:
        %obj:  SingleMatFileData object.
        
        getStatMom(this, varargin);
        %Creates a SignalChainElementInterface that passes on the first
        %four statistical moments extracted from that incoming data.
        %
        %Inputs: none.
        %
        %Outputs:
        %obj: StatMom object.
        
        getUniformDistributionData(this, varargin);
        %Creates a DataInterface that creates cycles which are rows of
        %uniformly distributed random number in the interval (0,1)
        %
        %Inputs:
        %length: Positive integer defining the number of variables per row
        %numCyc: Positive integer that defines the number of cycles created
        %
        %Outputs:
        %obj:    UniformDistributionData object.
        
        getWaveletTransform(this, varargin);
        %Creates SignalChainElementInterface that performs
        %Daubechies-4-Wavelet transform at maximum Wavelet level.
        %
        %Inputs: none.
        %
        %Outputs:
        %obj: WaveletTransform object.
        
        getALASplitSelection(this, id, targetMat);
        %Creates an ALASplit object with a Multitarget Pearson preselection
        %attached to it. Use to build more complex objects.
        %Inputs:
        %id:        String specifying the id of the signal that is to be
        %           processed by the SignalChain.
        %targetMat: NumPoints x NumTargets numerical matrix specifying the
        %           group for every training cycle concerning the
        %           respective target.
        %
        %Outputs:
        %obj:    ALASplit object (first in SignalChain).
        %allObj: Cell Array containing all further objects in the
        %        SignalChain 
        
        getALA(this, id);
        %Creates a SignalChain consisting of ALADownsampler,
        %ALAErrTransform and ALASplit.
        %
        %Inputs:
        %id:     String specifying the id of the signal that is to be
        %        processed by the SignalChain.
        %
        %Outputs:
        %obj:    ALADownsampler object (first in SignalChain).
        %allObj: Cell Array containing all further objects in the
        %        SignalChain
        
        getCVALA(this, id, cv);
        %Creates a cross-validated Adaptive Linear Approximation
        %SignalChain.
        %
        %Inputs:
        %id:     String specifying the id of the signal that is to be
        %        processed by the SignalChain.
        %cv:     cvpartition object specifying the cross-validation.
        %
        %Outputs:
        %obj:    ALADownsampler object (first in SignalChain).
        %allObj: Cell Array containing all further objects in the
        %        SignalChain
        
        getFullALA(this, id, sensors)
        %ToDo: document
        
        getMVPSelector(this, id, targetMat);
        %Creates  SignalSplitter that distributes the signal to multiple
        %StackedSelectors that use MeanvalueSelector and consecutive
        %PearsonPreselection trained on the different targets contained in
        %targetMat. There is one StackedSelector for each target in
        %targetMat. Each StackedSelector is trained on a different target.
        %Each StackedSelector useses PearsonPreselection proceeded by
        %MeanValueSelector to select features.
        %
        %Inputs:
        %id:        String specifying the id of the signal that is to be
        %           processed by the SignalChain.
        %targetMat: NumPoints x NumTargets numerical matrix specifying the
        %           group for every training cycle concerning the
        %           respective target.
        %
        %Outputs:
        %obj:       SignalSplitter object (first in SignalChain).
        %allObj:    Cell Array containing all further objects in the
        %           SignalChain
        
        getCVMVPSelector(this, id, cv, targetMat);
        %Creates a CrossValidation object that cross validates a
        %multitarget StackedSelector that uses PearsonPreselection
        %proceeded by MeanValueLearner to select features.
        %Inputs:
        %id:        String specifying the id of the signal that is to be
        %           processed by the SignalChain.
        %cv:        cvpartition object specifying the cross-validation.
        %targetMat: NumPoints x NumTargets numerical matrix specifying the
        %           group for every training cycle concerning the
        %           respective target.
        %
        %Outputs:
        %obj:       CrossValidator object (first in SignalChain).
        %allObj:    Cell Array containing all further objects in the
        %           SignalChain
        
        getMultitargetPearsonPreselection(this, id, targetMat);
        %Creates a SignalSplitter that distributs the incomming signal to
        %multiple PearsonPreselections that work on different targets,
        %specified by targetMat.
        %
        %Inputs:
        %id:        String specifying the id of the signal that is to be
        %           processed by the SignalChain.
        %targetMat: NumPoints x NumTargets numerical matrix specifying the
        %           group for every training cycle concerning the
        %           respective target.
        %
        %Outputs:
        %obj:       SignalSplitter object (first in SignalChain).
        %allObj:    Cell Array containing all further objects in the
        %           SignalChain (PearsonPreselections)
        
        
        getCVPearsonPreselection(this, id, cv, targetMat);
        %Creates a CrossValidator that corss-validates a
        %MultiTargetPearsonPreselcetion which is a SignalSplitter that
        %splits the signal to multiple PearsonPreselections that are
        %trained on the different targets that are specified by targetMat.
        %
        %Inputs:
        %id:        String specifying the id of the signal that is to be
        %           processed by the SignalChain.
        %cv:        cvpartition object specifying the cross-validation.
        %targetMat: NumPoints x NumTargets numerical matrix specifying the
        %           group for every training cycle concerning the
        %           respective target.
        %
        %Outputs:
        %obj:       CrossValidator object (first in SignalChain).
        %allObj:    Cell Array containing all further objects in the
        %           SignalChain
        
        getAmplitudeSpectrum(this, id, signalLength);
        %Creates a FourierTransform that is followed by a range that
        %selects only the fist half of the spectrum to exoloit the symmetry
        %property of the Fourier  transform and a Abs object that computes
        %the amplitude spectrum.
        %
        %Inputs:
        %id:           String specifying the id of the signal that is to be
        %              processed by the SignalChain.
        %signalLength: Length of the signal that is transformed. This is
        %              needed to select the first half of the spectrum.
        %
        %Outputs:
        %obj:          FourierTransform object (first in SignalChain).
        %allObj:       Cell Array containing all further objects in the
        %              SignalChain
        
        getCVFFT(this, id, cv, targetMat, signalLength);
        %Creates a FourierTransform that is used to compute the amplitude
        %spectrum which is passed on to a cross-validated, multi-target
        %StackedSelector that uses MeanValueLearner and PearsonPreselection
        %(in this order) to extract the most significant frequencies.
        %
        %Inputs:
        %id:           String specifying the id of the signal that is to be
        %              processed by the SignalChain.
        %cv:           cvpartition object specifying the cross-validation.
        %targetMat:    NumPoints x NumTargets numerical matrix specifying
        %              the group for every training cycle concerning the
        %              respective target.
        %signalLength: Length of the signal that is transformed. This is
        %              needed to select the first half of the spectrum.
        %
        %Outputs:
        %obj:          FourierTransform object (first in SignalChain).
        %allObj:       Cell Array containing all further objects in the
        %              SignalChain
        
        getFullCVFFT(this, id, cv, targetMat, signalLength, sensors)
        %ToDo:Document
        
        getCVBDW(this, id, cv, targetMat);
        %Creates a WaveletTransform that is used to compute the absolute
        %wavelet spectrum which is passed on to a cross-validated,
        %multi-target StackedSelector that uses MeanValueLearner and
        %PearsonPreselection (in this order) to extract the most
        %significant frequencies.
        %
        %Inputs:
        %id:           String specifying the id of the signal that is to be
        %              processed by the SignalChain.
        %cv:           cvpartition object specifying the cross-validation.
        %targetMat:    NumPoints x NumTargets numerical matrix specifying
        %              the group for every training cycle concerning the
        %              respective target.
        %
        %Outputs:
        %obj:          WaveletTransform object (first in SignalChain).
        %allObj:       Cell Array containing all further objects in the
        %              SignalChain
        
        getFullCVBDW(this, id, cv, targetMat, sensors)
        %ToDo:Document
        
        getStatMomExtractor(this, id, targetMat, signalLength, numRanges);
        %Creates a SignalSplitter that forwards the signal to several
        %Ranges that are followed by a StatMom that extracts statistical
        %Moments that are forwarded to a multi target PearsonPreselection.
        %
        %Inputs:
        %id:           String specifying the id of the signal that is to be
        %              processed by the SignalChain.
        %targetMat:    NumPoints x NumTargets numerical matrix specifying
        %              the group for every training cycle concerning the
        %              respective target.
        %signalLength: Length of the signal that is transformed. This is
        %              needed to compute the ranged from which statistical
        %              moments are extracted.
        %numRanges:    Number of Ranges on which statistical moments should
        %              be extracted.
        %
        %Outputs:
        %obj:          SignalSplitter object (first in SignalChain).
        %allObj:       Cell Array containing all further objects in the
        %              SignalChain
        
        getCVPCA(this, id, cv);
        %Creates a CrossValidator that distributes the incoming signal to a
        %cross-validated branch of PCA objects (including the object
        %trained on the full dataset).
        %
        %Inputs:
        %id:           String specifying the id of the signal that is to be
        %              processed by the SignalChain.
        %cv:           cvpartition object specifying the cross-validation.
        %
        %Outputs:
        %obj:          CrossValidator object (first in SignalChain).
        %allObj:       Cell Array containing all further objects in the
        %              SignalChain (PCAs)
        
        getFullTree(this, id, cv, targetMat, signalLength, numStatMomRanges);
        %Creates a SignalSplitter that forwards the signal to four feature
        %extraction algorithms that are ALA, BDF, BFC and statistical
        %moments. All extraction methods work on multiple targets and are
        %cross validated.
        %
        %Inputs:
        %id:           String specifying the id of the signal that is to be
        %              processed by the SignalChain.
        %cv:           cvpartition object specifying the cross-validation.
        %targetMat:    NumPoints x NumTargets numerical matrix specifying
        %              the group for every training cycle concerning the
        %              respective target.
        %signalLength: Length of the signal that is transformed. This is
        %              needed to compute the ranged from which statistical
        %              moments are extracted and the FourierTransform.
        %numStatMomRanges: Number of Ranges on which statistical moments
        %              should be extracted.
        %
        %Outputs:
        %obj:          SignalSplitter object (first in SignalChain).
        %allObj:       Cell Array containing all further objects in the
        %              SignalChain
        
        getMultisensorFullTree(this, id, cv, targetMat, signalLength, numStatMomRanges, sensors)
        %Creates a SignalSplitter that splits the signals to all sensors
        %from which features are extracted using ALA, BSW, BFC and statMom.
        %All features are extracted regarding multiple targets and using
        %crossvalidation. For all feature extraction methods the results
        %from different sensors are combined using JoinedSelectors.
        %Additionaly for the resutls of BDW and BFC coming from different
        %cross-validation folds are combined in CVSelFeatMats.
        %
        %Inputs:
        %id:           String specifying the id of the signal that is to be
        %              processed by the SignalChain.
        %cv:           cvpartition object specifying the cross-validation.
        %targetMat:    NumPoints x NumTargets numerical matrix specifying
        %              the group for every training cycle concerning the
        %              respective target.
        %signalLength: Vector of signal length of each sensor. This is
        %              needed to compute the ranged from which statistical
        %              moments are extracted and the FourierTransform.
        %numStatMomRanges: Number of Ranges on which statistical moments
        %              should be extracted.
        %sensors:      Cell array of sensors from which features are
        %              extracted.
        %
        %Outputs:
        %obj:          SignalSplitter object (first in SignalChain).
        %allObj:       Cell Array containing all further objects in the
        %              SignalChain
        
    end
    
end

