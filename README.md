# A New Home
This repository was moved here from https://gitlab.com/manuel.bastuck/dav3e-beta. The old repository will stay available but will no longer be updated. Future development will take place here.
# Quick Start
* Download DAV³E.
* Open [this example project](https://www.dropbox.com/s/p1ybuayfz6aw3mr/project_UST.zip?dl=0) in DAV³E to see how the [data described here](http://doi.org/10.5281/zenodo.1411209) have been evaluated.
* Import and evaluate your own cyclic data. 
* In case of problems, consult the [readme](#readme) or the [developers](mailto:dev@lmt.uni-saarland.de).
# Compatibility
MATLAB 2022b+ with Toolboxes:
* Image Processing Toolbox
* Statistics and Machine Learning Toolbox
* Deep Learning Toolbox (former Neural Network Toolbox)
* Signal Processing Toolbox
* Wavelet Toolbox (only if you want to use the feature extraction method: best daubechies wavelets)
* Curve Fitting Toolbox (only if you want to use the feature extraction method: gaussfit)
# Readme
DAV³E stands for "Data Analysis and Verification/Visualization/Validation Environment". It is a MATLAB-based toolbox for the evaluation of, mainly, cyclic sensor signals. It focuses on cycle-based raw data preprocessing, graphical feature extraction, and data annotation, but also provides commonly used machine learning methods (with cycle-specific extensions) to develop data-driven models. This allows for a sleek workflow from start to finish without having to change to third-party tools.

If you publish results obtained with DAV³E, please cite:
Manuel Bastuck, Tobias Baur, and Andreas Schütze: DAV3E – a MATLAB toolbox for multivariate sensor data evaluation, J. Sens. Sens. Syst. (2018), 7, 489-506 (open access), doi: 10.5194/jsss-7-489-2018.

This paper describes an earlier version of DAV³E. The current version is based on the older one, but has been rewritten completely from scratch. Please note that, despite thorough testing and care, we cannot guarantee the correct implementation of any function or algorithm and are not responsible for data loss or other issues that you might experience while using the software. We appreciate, however, any bug reports, feature requests, bug fixes, and new feature implementations.

The following is a short manual to get started with DAV³E:

After downloading, navigate to the respective folder in MATLAB and type "DAVE" (no quotation marks) to start the GUI. More advanced users might want to use the command-line based version which requires executing "init" once at the start of the session to make all functions and classes available. The following paragraphs will only look at the GUI version, however.

Click on "Import data", choose a file type, and import your data. Currently, the easiest way to feed files to DAV³E are *.mat or *.csv files, both in matrix form with one cycle per row. This is the usual format used in data science: one observation per row, one feature per column. The imported sensors and clusters (refer to the paper) appear in the table at the bottom of the window. Sensor-specific and cluster-specific options (names, offsets, sampling rates, abscissas, etc.) can be changed in the respective menu points in the "File" menu (top-left). Virtual sensors, derived from one or more sensors, can also be created. Note that in the bottom table, sensor properties can be changed as well. To select a sensor, click on its index (left-most column).

A click on "Preprocessing" on the left lets you proceed with the next step. This module shows quasistatic signals and cycles (their relation is described in the paper mentioned above). New points can be created by double-click, dragged, and deletes by right-click directly in the graphs. Additionally, preprocessing methods can be added ("preprocessing chain"). Point sets and preprocessing chains are global, i.e. they can be applied to all or only some sensors. New sets and chains can be added in case different sensors have different requirements. Note that the points in the quasistatic signals exist on a global timescale, i.e. some or all of them might not appear for sensors/clusters with different offsets. In this case, a new point set is required to visualize this sensor/cluster.

The "Cycle Ranges" module shows the previously defined quasistatic signals of the selected sensor. Ranges can be created by double-click, dragged, and deleted by right-click. The ranges created here define all cycles which will be part of the evaluation from here on - all other cycles are ignored. Each range can be annotated in the next module with different target values which are propagated to all its cycles.

The annotation happens in the "Grouping" module. An arbitrary number of groupings can be added, each with different annotations for each range, so that, e.g., one grouping can discriminate between three types of gases (for a classification task), and a second one can provide concentrations values of only the first gas (for a quantification task).

The "Feature Definition" module shows average cycles for all groups in the current grouping (can be switched in the Grouping menu in the menubar at the top). With either a double-click in the bottom graph or a click on "add" in the upper tablea new feature extraction with ranges can be defined. The ranges define the parts of the cycle where the selected extraction method is applied. The top graph gives a live preview of (centered) features generated from the averaged cycles.

In the final module, "Model", a data-driven model can be built based on the extracted features. Each model requires an "annotation" block (click on "add" below the table) to define which groupings and which groups to use, as well as the target and the features. All other blocks are optional and can be combined in many ways. Validation and Testing is highly recommended whenever supervised methods are used. Many parameters take a list of values and the model will be evaluated for all permutations, resulting in graphs of the errors (training, CV, testing) over those parameters. A click on "train" starts the complete model training and evaluation.
