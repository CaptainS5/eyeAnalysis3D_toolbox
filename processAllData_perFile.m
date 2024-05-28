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

%% set up which users' data to process
userAll = [1, 2, 4, 8, 9, 12, 14, 15, 16, 20, 21, 22, 26, 27, 28, 30, 31, 32, 33, 35, 36, 38, 40, 43, 44, 45, 48, 49, 50, 51, 52, 54, 56, 57, 58, 59, 60, 61];

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
    % find all relevant files

for chunk = 1:8
    for i = height(all_user_info):-1:1 % i = 1:height(all_user_info) %
        %try
        % If you are skipping already processed users, uncomment this
        % This user has been processed before

        % cont = false;
        % for j = 1:size(original_users)
        %     if str2double(original_users(j)) == str2double(all_user_info.UserID(i)) && ...
        %             (original_sessions(j) == all_user_info.Session(i))
        %         fprintf('This session for user %s already logged, trying next one\n', all_user_info.UserID(i));
        %         cont = true;
        %         break;
        %     end
        % end
        % if cont
        %     continue;
        % end

        % Identify current user...
        fprintf('Analyzing chunk %d for user %d\n',chunk, str2double(all_user_info.UserID{i}));

        % You can jump users based on ID, as always
        % if (str2double(all_user_info.UserID{i}) ~= 50)
        %   continue
        % end


        %% START ANALYZING TRIAL
        eyeTrial = all_user_info.EyeTrial{i};

        % Find indices of elements equal to 0
        % Each of them is the beginning of a new file, so the previous to
        % each of them is the end of the previous file
        zeroIndices = find(eyeTrial.headAligned.timestamp == 0);



        % Reset eyeTrial to get new data
        eyeTrial = all_user_info.EyeTrial{i};

        % We are now changing the way we load each game, so the timestamps
        % in the data restart four times

        % We now getting the last 5 minutes, same as commented before.
        % See comments from previous code for info.
        % minsToApply = 182;
        % We want to keep only the data for the first chunk

        startI = zeroIndices(chunk);
        if chunk==8
            endI = size(eyeTrial.headAligned, 1);
        else
            endI = zeroIndices(chunk+1)-1;
        end

        eyeTrial.headAligned = eyeTrial.headAligned(startI:endI, :);
        eyeTrial.eyeAligned = eyeTrial.eyeAligned(startI:endI, :);

        %Try to find the first indices of two consecutive not NaN rows in the
        %first 10 elements (e.g., data is technically "clean")
        first_non_nan_row = 1;
        found_first = false;
        for ii = 1:10
            if ~any(isnan(eyeTrial.headAligned{ii, :})) && ~any(isnan(eyeTrial.headAligned{ii+1, :}))
                first_non_nan_row = ii;
                found_first = true;
                break;
            end
        end

        % If the first search doesn't work, it means that there are lots of NaN
        % files. It can probably take up to hundreds of thousands (?), so I'm
        % doing a binary search, which should be faster than brute force
        % iterating
        % Binary search
        if ~found_first
            start = 1;
            stop = 30000;  % I assume that it cant be more than 2 minutes of NaN rows...

            while start <= stop
                mid = floor((start + stop) / 2);

                % Check if the mid and mid+1 rows are not NaN
                if ~any(isnan(eyeTrial.headAligned{mid, :})) && ~any(isnan(eyeTrial.headAligned{mid+1, :}))
                    first_non_nan_row = mid;
                    second_non_nan_row = mid + 1;
                    break;
                elseif any(isnan(eyeTrial.headAligned{mid, :}))
                    start = mid + 1;
                else
                    stop = mid - 1;
                end
            end
        end

        if ~isempty(first_non_nan_row) && first_non_nan_row > 1
            eyeTrial.headAligned(1:first_non_nan_row-1, :) = [];
        end


        if ~isempty(first_non_nan_row) && first_non_nan_row > 1
            eyeTrial.eyeAligned(1:first_non_nan_row-1, :) = [];
        end

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
            % 0 = blink, 1 = saccade, 2 = fixation, 3 = VOR, 4 = pursuit, NaN =
            % undefined

            %% IDENTIFY BLINKS
            % for coil data, look for 2-peak-in-opposite-direction peak pairs
            dataType = 2; % video-based eye tracker
            [eyeTrial.blink, eyeTrial.classID] = findBlink(eyeTrial.eyeTrace, eyeTrial.sampleRate, dataType, blinkThres);
            % 0/0.5 = blink (0 means it is within a normal blink duration, 0.5 means the duration is a bit long)
            % 1 = saccade

            % Use blinkFlag to double check and update eyeTrial.classID
            idx = find(eyeTrial.classID~=0 & eyeTrial.classID~=0.5 & eyeTrial.eyeAligned.blinkFlag>0);
            if ~isempty(idx)
                eyeTrial.classID(idx) = 0.5;
            end

            %% IDENTIFY SACCADES
            [eyeTrial.saccade, eyeTrial.classID] = findSaccade(eyeTrial.eyeTrace, eyeTrial.sampleRate, eyeTrial.classID, sacThres);

            %% IDENTIFY FIXATIONS
            % First, find gaze fixation, which includes VOR
            % Check dispersion of this gaze position, to be within a radius
            % threshold to count as a fixation (with a min duration required)
            if ismember({'frameXYZ'}, eyeTrial.eyeAligned.Properties.VariableNames)
                [eyeTrial.gazeFix eyeTrial.classID] = findGazeFix(eyeTrial.eyeTrace, eyeTrial.eyeAligned.frameXYZ, ...
                    fixThres, eyeTrial.classID, eyeTrial.sampleRate, eyeTrial.eyeTrace.timestamp);
            else
                [eyeTrial.gazeFix eyeTrial.classID] = findGazeFix(eyeTrial.eyeTrace, [], ...
                    fixThres, eyeTrial.classID, eyeTrial.sampleRate, eyeTrial.eyeTrace.timestamp);
            end


            %% IDENTIFY VORs
            % within the fixation period, identify VOR
            eyeVelXY = [eyeTrial.eyeTrace.velOriHeadFiltX eyeTrial.eyeTrace.velOriHeadFiltY]; % eye-in-head velocity
            % for the head, we need to know both translation and rotation, and to
            % do this we also need to know where the 3D gaze position is
            % just calculate the "combined" head movement that needs to be canceled
            % by VOR

            headRot = [eyeTrial.headTrace.rotFiltQw eyeTrial.headTrace.rotFiltQx ...
                eyeTrial.headTrace.rotFiltQy eyeTrial.headTrace.rotFiltQz];
            % headRot takes care of the head rotational part, in world/body
            % coordinates, already velocity
            % let's use the simplified thing for SE... just turn head rotation
            % into angles; use the quaternion representing rotation between
            % frames--velocity

            % Initialize the reference vector
            refVec = [1; 1; 1] / norm([1; 1; 1]);
            % Initialize the output array for improved performance
            rotVec = NaN(size(headRot, 1), 3);
            % Set the first row of rotVec to the reference vector
            rotVec(1, :) = refVec;

            % Rotate
            for ii = 2:size(headRot, 1)
                if any(isnan(rotVec(ii-1, :))) || any(isnan(headRot(ii, :)))
                    % If any NaN values are present, reset to the reference vector
                    rotVec(ii, :) = refVec;
                else
                    % Perform the rotation
                    rotMat = quat2rotm(headRot(ii, :));
                    rotVec(ii, :) = (rotMat * rotVec(ii-1, :).').';
                end
            end

            % Transform into head frame
            angRot = [-atan2d(rotVec(:, 2), rotVec(:, 1)) ...
                atan2d(rotVec(:, 3), sqrt( rotVec(:, 1).^2 + rotVec(:, 2).^2) )];
            % ref: https://www.mathworks.com/matlabcentral/answers/101590-how-can-i-determine-the-angle-between-two-vectors-in-matlab
            % atan is recommended instead of acos to recover small angles

            diffAng = diff(angRot);
            % deal with the extreme values when crossing the non-continuous
            % border...
            idxT = find(angRot(1:end-1, 1).*angRot(2:end, 1)<0 & abs(angRot(1:end-1, 1)) > 90 & abs(angRot(2:end, 1)) > 90);
            diffAng(idxT, 1) = 360-abs(angRot(idxT, 1))-abs(angRot(idxT+1, 1));

            rotVel = diffAng.*eyeTrial.sampleRate; % in deg
            rotVel = [rotVel; NaN(1, 2)];
            headVelXY = rotVel;

            % calculate the translation part using an assumed head radius and
            % gaze depth
            d = eyeTrial.eyeAligned.gazeDepth; % in m
            headR = 0.1; % in m
            transVel = atan2d(headR*sin(rotVel/180*pi), ...
                headR + repmat(d, 1, 2) - headR*cos(rotVel/180*pi));
            transVel(isnan(transVel)) = 0;
            headVelXY = rotVel + transVel;

            % Prepare data for storing
            eyeTrial.headTrace.displaceX = headVelXY(:, 1);
            eyeTrial.headTrace.displaceY = headVelXY(:, 2);
            eyeTrial.headTrace.displace2D = sqrt(sum(headVelXY.^2, 2));

            % Finally find VOR
            [eyeTrial.VOR eyeTrial.classID] = findVOR(eyeVelXY, headVelXY, eyeTrial.headTrace.rotVel3DFilt, ...
                vorThres, eyeTrial.gazeFix, eyeTrial.classID, eyeTrial.eyeTrace.timestamp, eyeTrial.sampleRate);


            %% PROCESS BLINKS AND SACCADES
            blinkStats = processBlink(eyeTrial.blink);
            if ismember({'frameXYZ'}, eyeTrial.eyeAligned.Properties.VariableNames)
                sacStats = processSaccade(eyeTrial.saccade, eyeTrial.eyeTrace, eyeTrial.eyeAligned.frameXYZ);
            else
                sacStats = processSaccade(eyeTrial.saccade, eyeTrial.eyeTrace, []);
            end


            % We want to keep only certain statistics


            % Note that here is when the variable names must change (e.g., FM_
            % or whatever other thing you want to try...)
            %                 short_headTrace = struct();
            %                 short_headTrace.timestamp = eyeTrial.headTrace.timestamp;
            %                 short_headTrace.displace2D = eyeTrial.headTrace.displace2D;
            %                 short_headTrace.rotVel3D = eyeTrial.headTrace.rotVel3DFilt;
            %                 all_user_info.HeadInfo{i} = short_headTrace;
            all_user_info.EyeInfo{i} = eyeTrial.eyeTrace;
            all_user_info.HeadInfo{i} = eyeTrial.headTrace;
            all_user_info.gazeFix{i} = eyeTrial.gazeFix;
            all_user_info.saccade{i} = eyeTrial.saccade;
            all_user_info.blink{i} = eyeTrial.blink;
            all_user_info.VOR{i} = eyeTrial.VOR;
            all_user_info.classID{i} = eyeTrial.classID;
            %
            % =========================================== %
            % ++++++++++++ SACCADE ANALYSIS +++++++++++++ %
            % =========================================== %

%             % Get indices of saccades that are correct
%             dur_sac = eyeTrial.saccade.offsetTime - eyeTrial.saccade.onsetTime;
%             indices = (dur_sac <= 0.25 & dur_sac > 0);
%             eyeTrial.saccade.onsetTime = eyeTrial.saccade.onsetTime(indices, :);
%             eyeTrial.saccade.offsetTime = eyeTrial.saccade.offsetTime(indices, :);
% 
%             % Get statistics
%             tot_sac = size(eyeTrial.saccade.onsetTime, 1);
%             dur_sac = eyeTrial.saccade.offsetTime - eyeTrial.saccade.onsetTime;
%             avg_sac_dur = nanmean(dur_sac(1:end));
%             sac_per_sec = tot_sac / (eyeTrial.saccade.offsetTime(end) - eyeTrial.saccade.offsetTime(1));

            all_user_info.SaccadeInfo{i} = struct();
%             all_user_info.SaccadeInfo{i}.tot_sac = tot_sac;
%             all_user_info.SaccadeInfo{i}.dur_sac = dur_sac;
%             all_user_info.SaccadeInfo{i}.avg_sac_dur = avg_sac_dur;
%             all_user_info.SaccadeInfo{i}.sac_per_sec = sac_per_sec;
            all_user_info.SaccadeInfo{i}.amp = sacStats.amp;
            all_user_info.SaccadeInfo{i}.ampInHead = sacStats.ampInHead;
            all_user_info.SaccadeInfo{i}.meanVel = sacStats.meanVel;
            all_user_info.SaccadeInfo{i}.meanVelHead = sacStats.meanVelHead;
            all_user_info.SaccadeInfo{i}.peakVel = sacStats.peakVel;
            all_user_info.SaccadeInfo{i}.peakVelHead = sacStats.peakVelHead;
            all_user_info.SaccadeInfo{i}.duration = sacStats.duration;
            %
            %                 % =========================================== %
            %                 % ++++++++++++ FIXATION ANALYSIS +++++++++++++ %
            %                 % =========================================== %
            %
            %                 % Get indices of fixations that are correct
            %                 dur_fix = eyeTrial.gazeFix.offsetTime - eyeTrial.gazeFix.onsetTime;
            %                 indices = (dur_fix <= 2 & dur_fix > 0.1);
            %                 eyeTrial.gazeFix.onsetTime = eyeTrial.gazeFix.onsetTime(indices, :);
            %                 eyeTrial.gazeFix.offsetTime = eyeTrial.gazeFix.offsetTime(indices, :);
            %
            %                 % Get statistics
            %                 tot_fix = size(eyeTrial.gazeFix.onsetTime, 1);
            %                 dur_fix = eyeTrial.gazeFix.offsetTime - eyeTrial.gazeFix.onsetTime;
            %                 avg_fix_dur = nanmean(dur_fix(1:end));
            %                 fix_per_sec = tot_fix / (eyeTrial.gazeFix.offsetTime(end) - eyeTrial.gazeFix.offsetTime(1));
            %
            %                 all_user_info.FixationInfo{i} = struct();
            %                 all_user_info.FixationInfo{i}.tot_fix = tot_fix;
            %                 all_user_info.FixationInfo{i}.dur_fix = dur_fix;
            %                 all_user_info.FixationInfo{i}.fix_per_sec = fix_per_sec;
            %                 all_user_info.FixationInfo{i}.avg_fix_dur = avg_fix_dur;
            %
            %
            %                 % =========================================== %
            %                 % ++++++++++++ BLINK ANALYSIS +++++++++++++ %
            %                 % =========================================== %
            %
            %                 % Get indices of fixations that are correct
            %                 dur_bli = eyeTrial.blink.offsetTime - eyeTrial.blink.onsetTime;
            %                 indices = (dur_bli <= 1 & dur_bli > 0);
            %                 eyeTrial.blink.onsetTime = eyeTrial.blink.onsetTime(indices, :);
            %                 eyeTrial.blink.offsetTime = eyeTrial.blink.offsetTime(indices, :);
            %
            %                 % Get statistic
            %                 tot_bli = size(eyeTrial.blink.onsetTime, 1);
            %                 dur_bli = eyeTrial.blink.offsetTime - eyeTrial.blink.onsetTime;
            %                 avg_bli_dur = nanmean(dur_bli(1:end));
            %                 bli_per_sec = tot_bli / (eyeTrial.blink.offsetTime(end) - eyeTrial.blink.offsetTime(1));
            %
            %                 all_user_info.BlinkInfo{i} = struct();
            %                 all_user_info.BlinkInfo{i}.tot_bli = tot_bli;
            %                 all_user_info.BlinkInfo{i}.dur_bli = dur_bli;
            %                 all_user_info.BlinkInfo{i}.avg_bli_dur = avg_bli_dur;
            %                 all_user_info.BlinkInfo{i}.bli_per_sec = bli_per_sec;
            %
            %
            %                 % =========================================== %
            %                 % +++++++++++++++ VOR ANALYSIS ++++++++++++++ %
            %                 % =========================================== %
            %
            %                 % Get indices of fixations that are not correct
            %                 dur_vor = eyeTrial.VOR.offsetTime - eyeTrial.VOR.onsetTime;
            %                 indices = (dur_vor <= 1 & dur_vor > 0);
            %                 eyeTrial.VOR.onsetTime = eyeTrial.VOR.onsetTime(indices, :);
            %                 eyeTrial.VOR.offsetTime = eyeTrial.VOR.offsetTime(indices, :);
            %
            %                 tot_vor = size(eyeTrial.VOR.onsetTime, 1);
            %                 dur_vor = eyeTrial.VOR.offsetTime - eyeTrial.VOR.onsetTime;
            %                 avg_vor_dur = nanmean(dur_vor(1:end));
            %                 vor_per_sec = tot_vor / (eyeTrial.VOR.offsetTime(end) - eyeTrial.VOR.offsetTime(1));
            %
            %                 all_user_info.VORInfo{i} = struct();
            %                 all_user_info.VORInfo{i}.tot_vor = tot_vor;
            %                 all_user_info.VORInfo{i}.dur_vor = dur_vor;
            %                 all_user_info.VORInfo{i}.avg_vor_dur = avg_vor_dur;
            %                 all_user_info.VORInfo{i}.vor_per_sec = vor_per_sec;
        catch
            disp('Skipped due to errors...');
        end

    end

    small_all_user_info = all_user_info;
    for i = 1:height(all_user_info)
        small_all_user_info.EyeTrial{i} = [];
    end
    save(['C:\Users\xiuyunwu\Downloads\ETDDC\postprocessed data\post_', userID, '_s', num2str(current_session), '_f', num2str(fileInfo.count), '.mat'], 'small_all_user_info', '-v7.3');
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

