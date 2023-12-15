% master script to process all datasets and get stats about eye movement
% events. Specifically, timestamps with classification ID, eye-in-head and
% head rotational velocity, gaze velocity, and amplitude of gaze shifts
clear all; clc; close all
addpath(genpath('functions'))

%% process all datasets
sr = [1200, 100];

databaseNames = {'Rochester', 'SoaringEagle'};

% setting threshold
% blinkThres = 30; % velocity, for coil data
% % otherwise, NaN is used to identify blinks in video based data; did it in
% % pre-processing of raw data
%
% sacThres = 50; % currently not in use, using an adaptive threshold now

% duration and position threshold for fixation
fixThres.dur = 0.1; % s, min duration; 40ms might be the minimum, but often required between 100-200ms
fixThres.rad = 1.3; % deg, dispersion algorithm

% VOR is almost always there...
vorThres.gain = 0.71; % lowest gain required for direction; corresponding to 135-180 deg difference
% for Rochester database, 0.91, ~155~180; SE, 0.71
vorThres.head = 5;

sacThresAll = [20, 50];
blinkThresAll = [20, 50];

% for srN = 1:length(sr)
%     dataAll = {};
    % use paralell pooling to improve processing speed
    % parpool;
    % load('data\dataAll_0.91R_0.71plus5SE.mat')
    % dataAll{1} = [];
    for ii = 1:1%length(databaseNames)
        %     ii
        %     tic
        dataAll{ii} = autoProcess(databaseNames{ii}, fixThres, vorThres, sacThresAll, blinkThresAll, sr(ii));
        %     toc
        dataAll{ii}.database = databaseNames{ii};

        metaInfo = table();
        if strcmp(databaseNames{ii}, 'Rochester')
            metaData = readtable('data\raw\Rochester\metaData.csv');
            metaData = renamevars(metaData, ["task_string"],["TaskID"]);
            metaInfo = metaData(:, 2:4);
        elseif strcmp(databaseNames{ii}, 'SoaringEagle')
            load('C:\Users\xiuyunwu\OneDrive - Facebook\Documents\Existing projects\SoaringEagle\Project report and code\Data\SoaringEagleDataset_corrected.mat')
            metaInfo = SUMMARY.table;
        end
        dataAll{ii}.metaInfo = metaInfo;
    end
    save(['data\dataAll_0.91UR1200Hz_0.71plus5SE100Hz_adaptiveThres1_2.mat'], 'dataAll', '-v7.3')
% end

% % correct depth in SE...
% for ii = 1:length(dataAll{2}.traces)
%     dataAll{2}.traces{ii}.gazeDepth = dataAll{2}.traces{ii}.gazeDepth/10;
% end
% save('data\dataAll_0.91R_0.71plus5SE.mat', 'dataAll', '-v7.3')