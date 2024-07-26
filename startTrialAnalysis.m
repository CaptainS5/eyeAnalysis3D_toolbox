% this script opens a GUI that plots the traces in each trial/file to help 
% with adjusting filtering and detection algorithm; 
% can also run auto-processing withou opening the GUI; 
% set autoProcess to indicate
%
% Some functions are currently commented out, feel free to use if if you'd like:
%      - can manually label invalid trials (e.g. too much blinking/noise etc.)
%      - can manually adjust saccade onsets/offset; consider only if you 
%        have a very simple design...
close all; clc; clear all; 
addpath(genpath('functions'))
analysisPath = pwd; % set the base path for the analysis

%% Set the starting parameters
autoProcess = 0; % 0-no GUI, run through all trials; 1-show GUI to click through trials 

dataPath = [analysisPath, '\data\pre_processed\data_GP']; % path + filename before the trial number
loadEyeTrial = 0; % if to re-process the eye trial data (0), or just to load (1) and plot
currentTrial = 1; % starting from which file to view the analysis plots

plotMode = 2; % for the GUI, which plots you want to see; can customize in updatePlots.m
% default is 0 = plot velocity traces with classification, 1 = plot head
% velocity, 2 = plot raw vs. filtered trace, change in updatePlots.m for
% orientaion/velocity
% could change in the GUI whenever you want

%% Set classification thresholds
% the noiseThres are mostly serving as a hard boundary for noise exclusion
% of the obviously wrong values; shouldn't matter much if you have a good
% signal; if your signal is really bad, then this cannot help too much
% either...
%     noiseThres.vel = 1000; % velocity
%     noiseThres.acc = 80000; % acceleration

% blink threshold
blinkThres.maxDur = 2; % s, to label suspecious durations when loss of signal is too long and may not be due to blinks
% blinkThres.vel = 50; % deg/s, velocity threshold, only applies to coil data - tracking signals available even with eye closure
% for video-based eye tracking, blink will be identify by loss of signal,
% which should be labeled as NaN in your data
% see details in findBlink.m

% depending on how your data look like, you may want to adjust the saccade
% thresholds below; see more details in findSaccade.m
sacThres = 50; % velocity threshold for finding the peaks
% initial threshold for the iterative algorithm to find a proper
% threshold based on current data, see details in findSaccade.m

% spatial dispersion threshold, with a minimum duration required
% see details in findGazeFix.m 
fixThres.vel = 30; % deg/s, fixation has to be under this 2D gaze velocity, a rough cutoff number as a sanity check
fixThres.minDur = 0.1; % s, min duration; 40 ms might be the minimum, but often required between 100-200ms
fixThres.rad = 1.3; % deg, dispersion algorithm, fixation has to be within this spatial range

% VOR is almost always there, I'd recommend just analyze the fixation
% frames together with head movements
% Currently mainly using a simple head velocity threshold; the gain is 
% tricky to play with for classification, unless you have very accurate
% tracking, I'd recommend to not use it
% vorThres.gain = 0.71; % range of direction gain, corresponding to 135-180 deg difference
vorThres.minHeadVel = 5; % deg/s, classified as VOR if during fixation head velocity is above this value

%% Start processing
% auto-capture how many files in the folder
fileT = dir([dataPath, '*.mat']);
trialAll = size(fileT, 1);

if autoProcess % loop through all trials and save processed file
    for trialI = currentTrial:trialAll
        processTrial(dataPath, currentTrial, loadEyeTrial, blinkThres, sacThres, fixThres, vorThres);
    end
else % use GUI to click through
    %% open a figure as the visualization GUI
    % set size depending on your current screen size
    set(0, 'units', 'pixels')
    screenSize = get(groot,'ScreenSize'); % or specify which screen you are using
    figPosition = [25 50 screenSize(3)-100, screenSize(4)-150];  % define how large your figure is on the screen
    % positions are in pixels, left bottom is (0,0)
    fig = figure('Position', figPosition);
    subplotTotalN = 3;
    for ii = 1:subplotTotalN % generate the axes to plot the subplots
        axSub(ii) = subplot(subplotTotalN,1,ii);
    end

    %% prepare error file
    % % this is if you want to manually label some trials to discard
    % errorFilePath = fullfile(analysisPath,'\ErrorFiles\');
    % if exist(errorFilePath, 'dir') == 0
    %     % Make folder if it does not exist.
    %     mkdir(errorFilePath);
    % end
    % errorFileName = [errorFilePath, databaseName, '_errorFile.mat'];
    % try
    %     load(errorFileName);
    %     disp('Error file loaded');
    % catch
    %     errorStatus = NaN(length(trialAll), 1);
    %     disp('No error file found. Created a new one.');
    % end

    %% go through the analysis and plot
    eyeTrial = processTrial(dataPath, currentTrial, loadEyeTrial, blinkThres, sacThres, fixThres, vorThres); % set the detection thresholds in this function
    % sacEditing = 0; % whether it is currently manually selecting saccades, default is 0
    updateGUI;

    %% buttons for the GUI
    % which plot to check
    buttons.seeSaccades = uicontrol(fig,'string','gaze','Position',[0,410,100,30],...
        'callback', 'plotMode = 0; eyeTrial = processTrial(dataPath, currentTrial, loadEyeTrial, blinkThres, sacThres, fixThres, vorThres); updateGUI;');
    buttons.seeVOR = uicontrol(fig,'string','head','Position',[0,380,100,30],...
        'callback', 'plotMode = 1; eyeTrial = processTrial(dataPath, currentTrial, loadEyeTrial, blinkThres, sacThres, fixThres, vorThres); updateGUI;');
    buttons.seeFiltering = uicontrol(fig,'string','filtering','Position',[0,350,100,30],...
        'callback', 'plotMode = 2; eyeTrial = processTrial(dataPath, currentTrial, loadEyeTrial, blinkThres, sacThres, fixThres, vorThres); updateGUI;');
    % buttons.see2D = uicontrol(fig,'string','see position 2d','Position',[0,320,100,30],...
    %     'callback', 'plotMode = 3; processTrial; updateGUI;');

    buttons.next = uicontrol(fig,'string','Next (0) >>','Position',[0,130,100,30],...
        'callback','currentTrial = min(currentTrial+1, trialAll); eyeTrial = processTrial(dataPath, currentTrial, loadEyeTrial, blinkThres, sacThres, fixThres, vorThres); updateGUI;');
    buttons.previous = uicontrol(fig,'string','<< Previous','Position',[0,100,100,30],...
        'callback','currentTrial = max(currentTrial-1,1); eyeTrial = processTrial(dataPath, currentTrial, loadEyeTrial, blinkThres, sacThres, fixThres, vorThres); updateGUI;');
    buttons.jumpToTrialN = uicontrol(fig,'string','Jump to trial..','Position',[0,70,100,30],...
        'callback','inputTrial = inputdlg(''Go to trial:''); currentTrial = str2num(inputTrial{:}); eyeTrial = processTrial(dataPath, currentTrial, loadEyeTrial, blinkThres, sacThres, fixThres, vorThres); updateGUI;');

    % % click to manually correct saccade onsets and offsets on the plot, if
    % % needed--would not suggest for the actual/final/formal processing, but
    % % feel free to use to explore data
    % buttons.editSac = uicontrol(fig,'string','edit saccade','Position',[0,250,100,30],...
    %     'Tag', 'editSac', 'callback', 'manualSelection;');
    %
    % % manually labeling invalid trials
    % buttons.discardTrial = uicontrol(fig,'string','!Discard trial!(1) >>','Position',[0,220,100,30],...
    %     'callback', 'errorStatus(currentTrial, 1)=1; currentTrial = currentTrial+1; load([dataPath, ''\data'', databaseName, num2str(currentTrial), ''.mat'']); processTrial; updateGUI;');
    % % navigating through trials
    % buttons.next = uicontrol(fig,'string','Next (0) >>','Position',[0,130,100,30],...
    %     'callback','errorStatus(currentTrial, 1)=0; currentTrial = min(currentTrial+1, size(errorStatus, 1)); load([dataPath, ''\data'', databaseName, num2str(currentTrial), ''.mat'']); processTrial; updateGUI;');
    % buttons.previous = uicontrol(fig,'string','<< Previous','Position',[0,100,100,30],...
    %     'callback','currentTrial = max(currentTrial-1,1); load([dataPath, ''\data'', databaseName, num2str(currentTrial), ''.mat'']); processTrial;updateGUI;');
    % buttons.jumpToTrialN = uicontrol(fig,'string','Jump to trial..','Position',[0,70,100,30],...
    %     'callback','inputTrial = inputdlg(''Go to trial:''); currentTrial = str2num(inputTrial{:}); load([dataPath, ''\data'', databaseName, num2str(currentTrial), ''.mat'']); processTrial; updateGUI;');
    %
    % % save & quit
    % buttons.exitAndSave = uicontrol(fig,'string','Exit & Save','Position',[0,35,100,30],...
    %     'callback', ['close(fig); save(errorFileName,''errorStatus''); ...' ...
    %     'eyeHeadTrial{currentTrial} = eyeTrial; save([''eyeHeadTrial_'', currentSub, ''.mat''], ''eyeHeadTrial'')']);
end