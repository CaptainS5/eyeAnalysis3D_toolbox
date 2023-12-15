% this script plots the traces in each trial to help with adjusting
% filtering and saccade detection algorithm; can also manually label
% invalid trials (e.g. too much blinking/noise etc.)
close all; clc; %clear all; 
addpath(genpath('functions'))
analysisPath = pwd; % set the base path for the analysis
dataPath = [analysisPath, '\data\pre_processed\'];

%% Set the starting parameters
loadEyeTrial = 0; % if to re-process the eye trial data (0), or just to load (1) and plot
currentTrial = 1; % starting from which trial to view the analysis plots
% currentSub = '111'; % string of the client ID for the current subject to view; related to how you organize and load data in the next section

% auto-capture how many files (one per trial) in the folder
fileT = dir([dataPath, 'data*.mat']);
trialAll = size(fileT, 1);

%% Load data
% depending on your specific way of organizing data, you may need to
% customize the way of reading data here

% here we assume that the raw data has already be sorted into tables in matlab
% see more details in sortRawData.m for the outcome of the data tables
load([dataPath, 'data', num2str(currentTrial), '.mat']) 

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
processTrial; % set the detection thresholds in this function
plotMode = 0; % default is to plot the results with saccade detection & stats on velocity & acceleration traces
% could change in the GUI to plot saccades on position trace, or middle steps of filtering (getEyeTrace.m) 
% sacEditing = 0; % whether it is currently manually selecting saccades, default is 0
updateGUI;

%% buttons for the GUI
% which plot to check
buttons.seeSaccades = uicontrol(fig,'string','gaze','Position',[0,410,100,30],...
    'callback', 'plotMode = 0; processTrial; updateGUI;');
buttons.seeVOR = uicontrol(fig,'string','head','Position',[0,380,100,30],...
    'callback', 'plotMode = 1; processTrial; updateGUI;');
buttons.seeFiltering = uicontrol(fig,'string','filtering','Position',[0,350,100,30],...
    'callback', 'plotMode = 2; processTrial; updateGUI;');
% buttons.see2D = uicontrol(fig,'string','see position 2d','Position',[0,320,100,30],...
%     'callback', 'plotMode = 3; processTrial; updateGUI;');

buttons.next = uicontrol(fig,'string','Next (0) >>','Position',[0,130,100,30],...
    'callback','currentTrial = min(currentTrial+1, trialAll); load([dataPath, ''\data'', databaseName, num2str(currentTrial), ''.mat'']); processTrial; updateGUI;');
buttons.previous = uicontrol(fig,'string','<< Previous','Position',[0,100,100,30],...
    'callback','currentTrial = max(currentTrial-1,1); load([dataPath, ''\data'', databaseName, num2str(currentTrial), ''.mat'']); processTrial;updateGUI;');
buttons.jumpToTrialN = uicontrol(fig,'string','Jump to trial..','Position',[0,70,100,30],...
    'callback','inputTrial = inputdlg(''Go to trial:''); currentTrial = str2num(inputTrial{:}); load([dataPath, ''\data'', databaseName, num2str(currentTrial), ''.mat'']); processTrial; updateGUI;');

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