% This script builds upon Xiuyun Wu's previous version
% Process head & eye data for the current trial
% This is the main script where we outline all the processing steps
% Pre-req: You should have run sortRawData before, so that you have a
%     preprocessed file with data with correct coordinate systems, removed
%     gaps and invalid information, etc.
% After processing, you should have a file with the followig fields (update
%     this header if changes are made:
% Columns 1 through 9
%       {'UserID'}    {'Session'}    {'Day'}    {'Duration'}    {'ETDDC'}    {'Files'}    {'EyeTrial'}    {'Calibration'}    {'HeadInfo'}
% Columns 10 through 17
%       {'EyeInfo'}    {'gazeFix'}    {'saccade'}    {'classID'}    {'FixationInfo'}    {'SaccadeInfo'}    {'BlinkInfo'}    {'VORInfo'}
% Columns 18 through XXX
%       The same information but for different time chunks, if required
%       (e.g., each 10 minutes or the last 5 minutes)

close all; clear all; clc
addpath(genpath('functions'))
dataFolder = 'C:\Users\xiuyunwu\Downloads\ETDDC\preprocessed data\';

%% set up which users' data to process
userAll = [1, 2, 8, 14, 15, 16, 20, 21, 22, 26, 27, 28, 30, 32, 33, 35, 36, 38, 40, 43, 44, 45, 48, 49, 50, 51, 52, 54, 56, 57, 58, 59, 60, 61];

%% SETTING THRESHOLDS FOR CLASSIFICATION - XIUYUN'S CODE!
% depending on how your data look like, you may want to adjust the
% thresholds below; see more details in findSaccade.m
sacThres = 50; % velocity threshold for finding the peaks
% initial threshold for the iterative algorithm to find a proper
% threshold based on current data

% the noiseThres are mostly serving as a hard boundary for noise exclusion
% of the obviously wrong values; shouldn't matter much if you have a good
% signal; if your signal is really bad, then this cannot help too much
% either...
%     noiseThres.vel = 1000; % velocity
%     noiseThres.acc = 80000; % acceleration
blinkThres = 50; % velocity

% velocity threshold for fixation, or you can use position threshold, not
% implemented yet though...
fixThres.dur = 0.1; % s, min duration; 40 ms might be the minimum, but often required between 100-200ms
fixThres.rad = 1.3; % deg, dispersion algorithm

% VOR is almost always there, and to focus on the smooth part, we
% define it by gain
vorThres.head = 5;

% For debugging and performance measurement purposes
tic;

% Iterate through user sessions (i.e., table rows).
for userI = 1:length(userAll)
    userID = userAll(userI);

    % find all relevant files
    files = dir([dataFolder, 'prep_', num2str(userID, '%03i'), '*.mat']);

    for fileI = 1:size(files, 1)
        % load data
        fileName = files(fileI).name;
        load([dataFolder, fileName])

        % get file info
        idxT = strfind(fileName, 's');
        session = str2num(fileName(idxT+1));
        idxT = strfind(fileName, 'f');
        chunk = str2num(fileName(idxT+1));

        % You can jump users based on ID, as always
        if userID==1 && session==1
            continue
        end

        % Identify current user...
        fprintf('Analyzing session %d chunk %d for user %d\n',session, chunk, userID);

        %% START ANALYZING TRIAL
        eyeTrial = sub_file_info.EyeTrial;

        flag = 0;
        first_non_nan_row = 1;
        while isnan(eyeTrial.headAligned.posZ(first_non_nan_row))
            first_non_nan_row = first_non_nan_row + 1;
            flag = 1;
        end

        if flag==1
            eyeTrial.headAligned(1:first_non_nan_row-1, :) = [];
            eyeTrial.eyeAligned(1:first_non_nan_row-1, :) = [];
        end

%         % Try to find the first indices of two consecutive not NaN rows in the
%         % first 10 elements (e.g., data is technically "clean")
%         first_non_nan_row = 1;
%         found_first = false;
%         for ii = 1:10
%             if ~any(isnan(eyeTrial.headAligned{ii, :})) && ~any(isnan(eyeTrial.headAligned{ii+1, :}))
%                 first_non_nan_row = ii;
%                 found_first = true;
%                 break;
%             end
%         end
% 
%         % If the first search doesn't work, it means that there are lots of NaN
%         % files. It can probably take up to hundreds of thousands (?), so I'm
%         % doing a binary search, which should be faster than brute force
%         % iterating
%         % Binary search
%         if ~found_first
%             start = 1;
%             stop = 30000;  % I assume that it cant be more than 2 minutes of NaN rows...
% 
%             while start <= stop
%                 mid = floor((start + stop) / 2);
% 
%                 % Check if the mid and mid+1 rows are not NaN
%                 if ~any(isnan(eyeTrial.headAligned{mid, :})) && ~any(isnan(eyeTrial.headAligned{mid+1, :}))
%                     first_non_nan_row = mid;
%                     second_non_nan_row = mid + 1;
%                     break;
%                 elseif any(isnan(eyeTrial.headAligned{mid, :}))
%                     start = mid + 1;
%                 else
%                     stop = mid - 1;
%                 end
%             end
%         end
% 
%         if ~isempty(first_non_nan_row) && first_non_nan_row > 1
%             eyeTrial.headAligned(1:first_non_nan_row-1, :) = [];
%         end
% 
%         if ~isempty(first_non_nan_row) && first_non_nan_row > 1
%             eyeTrial.eyeAligned(1:first_non_nan_row-1, :) = [];
%         end

        try

            %% FILTER DATA. THIS IS ONE OF THE MOST CRITICAL POINTS!
            eyeTrial.headTrace = filterHeadTrace(eyeTrial.headAligned, eyeTrial.sampleRate);
            eyeTrial.eyeTrace = filterEyeTrace(eyeTrial.eyeAligned, eyeTrial.sampleRate);

            %% DATA CLASSIFICATION
            % first, identify saccades, check for blinks (different process for
            % coil and video-based eye tracker)
            % then, identify fixation, and VOR
            % lastly, potential smooth pursuit
            % classID:
            % 0 = blink, 1 = saccade, 2 = fixation, 3 = VOR, NaN = undefined

            %% IDENTIFY BLINKS
            % for coil data, look for 2-peak-in-opposite-direction peak pairs
            dataType = 2; % video-based eye tracker
            [eyeTrial.blink, eyeTrial.classID] = findBlink(eyeTrial.eyeTrace, eyeTrial.sampleRate, dataType, blinkThres);
            % 0 = blink
            % 1 = saccade

            % Use blinkFlag to double check and update eyeTrial.classID
            idx = find(eyeTrial.classID~=0 & eyeTrial.eyeAligned.blinkFlag>0);
            if ~isempty(idx)
                eyeTrial.classID(idx) = 0.5;
            end

            %% IDENTIFY SACCADES
            [eyeTrial.saccade, eyeTrial.classID] = findSaccade(eyeTrial.eyeTrace, eyeTrial.sampleRate, eyeTrial.classID, sacThres);

            %% IDENTIFY FIXATIONS
            % First, find gaze fixation, which includes VOR
            % Check dispersion of this gaze position, to be within a radius
            % threshold to count as a fixation (with a min duration required)
            [eyeTrial.gazeFix eyeTrial.classID] = findGazeFix(eyeTrial.eyeTrace, [], ...
                fixThres, eyeTrial.classID, eyeTrial.sampleRate, eyeTrial.eyeTrace.timestamp);

            %% IDENTIFY VORs
            [eyeTrial.VOR eyeTrial.classID] = findVOR(eyeTrial.headTrace.rotVel3DFilt, ...
                vorThres, eyeTrial.gazeFix, eyeTrial.classID, eyeTrial.eyeTrace.timestamp, eyeTrial.sampleRate);

            %% PROCESS BLINKS AND SACCADES
            blinkStats = processBlink(eyeTrial.blink);
            sacStats = processSaccade(eyeTrial.saccade, eyeTrial.eyeTrace, []);

            sub_file_info.EyeInfo{1, 1} = eyeTrial.eyeTrace;
            sub_file_info.HeadInfo{1, 1} = eyeTrial.headTrace;
            sub_file_info.gazeFix{1, 1} = eyeTrial.gazeFix;
            sub_file_info.saccade{1, 1} = eyeTrial.saccade;
            sub_file_info.blink{1, 1} = eyeTrial.blink;
            sub_file_info.VOR{1, 1} = eyeTrial.VOR;
            sub_file_info.classID{1, 1} = eyeTrial.classID;
            %
            % =========================================== %
            % ++++++++++++ SACCADE ANALYSIS +++++++++++++ %
            % =========================================== %

            sub_file_info.SaccadeInfo = struct();
            sub_file_info.SaccadeInfo.amp = sacStats.amp;
            sub_file_info.SaccadeInfo.ampInHead = sacStats.ampInHead;
            sub_file_info.SaccadeInfo.meanVel = sacStats.meanVel;
            sub_file_info.SaccadeInfo.meanVelHead = sacStats.meanVelHead;
            sub_file_info.SaccadeInfo.peakVel = sacStats.peakVel;
            sub_file_info.SaccadeInfo.peakVelHead = sacStats.peakVelHead;
            sub_file_info.SaccadeInfo.duration = sacStats.duration;
        catch
            disp('Skipped due to errors...');
        end

        small_file_info = sub_file_info;
        small_file_info.EyeTrial = [];

        save(['C:\Users\xiuyunwu\Downloads\ETDDC\postprocessed data\post_', num2str(userID), '_s', num2str(sub_file_info.Session), '_f', num2str(sub_file_info.fileInfo.count), '.mat'], 'small_file_info', '-v7.3');
    end
end
% Just for performance check
toc;

sortSummaryStats;

% % sanity check plots
% figure
% plot(eyeTrial.eyeTrace.velOriWorldFilt2D)
% hold on
% xlim([0, 500])
% % scatter(eyeTrial.saccade.onsetI, eyeTrial.eyeTrace.velOriWorldFilt2D(eyeTrial.saccade.onsetI))
% % scatter(eyeTrial.saccade.offsetI, eyeTrial.eyeTrace.velOriWorldFilt2D(eyeTrial.saccade.offsetI))
% scatter(eyeTrial.gazeFix.onsetI, eyeTrial.eyeTrace.velOriWorldFilt2D(eyeTrial.gazeFix.onsetI))
% scatter(eyeTrial.gazeFix.offsetI, eyeTrial.eyeTrace.velOriWorldFilt2D(eyeTrial.gazeFix.offsetI))

