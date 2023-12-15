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

close all;
addpath(genpath('functions'))

% Load previous users
% You can load previous users if postprocessing has been done before, and
% you just want to add some additional new users.

% If you read previous suers, please make sure that you keep them in
% another variable, otherwise chances are that you overwrite some info...
% if isfile(['data\post_processed\fixTS_post_data_joint.mat']) % && loadEyeTrial
%    load(['data\post_processed\fixTS_post_data_joint.mat'])
%    original_users = all_user_info.UserID;
%    original_sessions = all_user_info.Session;
%    tempU = all_user_info;
% end

% Load the preprocessed file as returned by sortRawData.m
if isfile(['data\pre_processed\study2\S2-prep-data.mat']) 
   load(['data\pre_processed\study2\S2-prep-data.mat'])
end



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
fixThres.rad = 1.3; % 1.3; % deg, dispersion algorithm

% VOR is almost always there, and to focus on the smooth part, we
% define it by gain
vorThres.gain = 0.71; % range of direction gain, corresponding to 135-180 deg difference
vorThres.head = 5;

% For debugging and performance measurement purposes
tic;

% Iterate through user sessions (i.e., table rows).
for i = height(all_user_info):-1:1
    try
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
        fprintf('Analyzing session %d for user %s\n', all_user_info.Session(i), all_user_info.UserID(i));
    
        % You can jump users based on ID, as always
        % if ~(str2double(all_user_info.UserID{i}) == 998)
        %   continue
        % end
    
    
        %% START ANALYZING TRIAL
        eyeTrial = all_user_info.EyeTrial{i};
    

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% -------------> DO IT WITH LAST 10 MINUTES <------------- %%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Okay, the following code can be repeated as many times as
        % needed, one per each time chunk from which you want to run
        % further analyses later, provided that:
        %
        % 1/ You properly select the timestamps (minsToApply) of your chunk
        % (the following code)
        %
        % 2/ You make sure that each chunk that you save later in your
        % all_user_info variable has a different name (i.e., not to
        % overwrite information).
        %
        % 3/ You have enough memory (I mean your PC, not you)
        %
        % 4/ You properly reset variables if needed (e.g., not to
        % accumulate information).

        % Take the last OK timestamp and substract X mins
        % In this case, we take the last 10 minutes
        minsToApply = 600;      
        % Start with the last not-NaN row, otherwise we can be losing information
        last_non_nan_row = find(~any(isnan(all_user_info.EyeTrial{i}.headAligned.qW), 2), 1, 'last');
        timestamp_to_end = all_user_info.EyeTrial{i}.headAligned.timestamp(last_non_nan_row);
        % Calculate where to start from to get all those X minutes
        init_ten_sec_timestamps = timestamp_to_end - minsToApply;  
        % Get only the corresponding information from your trial (head)
        if ~isempty(eyeTrial.headAligned(eyeTrial.headAligned.timestamp >= init_ten_sec_timestamps & eyeTrial.headAligned.timestamp <= timestamp_to_end, :))
            eyeTrial.headAligned = eyeTrial.headAligned(eyeTrial.headAligned.timestamp >= init_ten_sec_timestamps & eyeTrial.headAligned.timestamp <= timestamp_to_end, :);
        end
        % Get only the corresponding information from your trial (eye)
        if ~isempty(eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp >= init_ten_sec_timestamps & eyeTrial.eyeAligned.timestamp <= timestamp_to_end, :))
            eyeTrial.eyeAligned = eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp >= init_ten_sec_timestamps & eyeTrial.eyeAligned.timestamp <= timestamp_to_end, :);
        end
    
        % Note: In some cases, it can happen that since you are taking a
        % small chunk, you are starting with a NaN row (because that
        % specific second was an issue or something). Therefore, you have
        % to remove those first rows (shouldn't be much tho). 
        % To do so, we first try to find the first indices of two consecutive 
        % not NaN rows in the first 10 elements (e.g., data is technically "clean")
        first_non_nan_row = 1;
        found_first = false;
        for ii = 1:10
            if ~any(isnan(eyeTrial.headAligned{ii, :})) && ~any(isnan(eyeTrial.headAligned{ii+1, :}))
                first_non_nan_row = ii;
                found_first = true;
                break;
            end
        end
        % If the first search doesn't work, it means that there are more NaN
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
    
        % Okay, if this went well (it should have, otherwise something very
        % bad is going on), update our trace.
        if ~isempty(first_non_nan_row) && first_non_nan_row > 1
            eyeTrial.headAligned(1:first_non_nan_row-1, :) = [];
            eyeTrial.eyeAligned(1:first_non_nan_row-1, :) = [];
        end
    
      
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

        %% SAVE MAIN INFORMATION IN OUR MAIN VARIABLE!
        all_user_info.HeadInfo{i} = eyeTrial.headTrace;
        all_user_info.EyeInfo{i} = eyeTrial.eyeTrace;
        all_user_info.gazeFix{i} = eyeTrial.gazeFix;
        all_user_info.saccade{i} = eyeTrial.saccade;
        all_user_info.classID{i} = eyeTrial.classID;
    
        %% STARRT FURTHER ANALYSES
        % This is only being done for last 10 mins, but can be extended if
        % needed by simply copypasting and ensuring that storage is done
        % with different variable names, etc.

        % Print few information to make sure we are OK...
        fprintf(['\nStarting analyses for %s, session %d. ' ...
            'Trial lasted %0.2f seconds (%0.2f minutes).\n'], ...
            all_user_info.UserID{i}, ...
            all_user_info.Session(i), ...
            eyeTrial.saccade.offsetTime(end), ...
            eyeTrial.saccade.offsetTime(end) / 60);
           
        
        % =========================================== %
        % ++++++++++++ FIXATION ANALYSIS ++++++++++++ %
        % =========================================== %
        
        tot_fix = size(eyeTrial.gazeFix.onsetTime, 1) - 1;         % Remove first one
        dur_fix = eyeTrial.gazeFix.offsetTime - eyeTrial.gazeFix.onsetTime;
    
        % Sanity checks!
        % Remove extremely long fixations (>10 sec)
        dur_fix = dur_fix( ...
                dur_fix >= 0 & ...
                dur_fix <= 10 ...
        );
    
        avg_fix_dur = nanmean(dur_fix(2:end));                     % Remove first one
        fix_per_sec = tot_fix / (eyeTrial.gazeFix.offsetTime(end) - eyeTrial.gazeFix.offsetTime(1));
    
        fprintf(['\n============ FIXATIONS ============\n' ...
            'A total of %d fixations were found.\n' ...
            'On average, %.2f fixations per second.\n' ...
            'Average fixation duration of %0.2f seconds.\n'], ...
            tot_fix, ...
            fix_per_sec, ...
            avg_fix_dur);
    
        all_user_info.FixationInfo{i} = struct();
        all_user_info.FixationInfo{i}.tot_fix = tot_fix;
        all_user_info.FixationInfo{i}.dur_fix = dur_fix;
        all_user_info.FixationInfo{i}.avg_fix_dur = avg_fix_dur;
        all_user_info.FixationInfo{i}.fix_per_sec = fix_per_sec;
    
        
    
        % =========================================== %
        % ++++++++++++ SACCADE ANALYSIS +++++++++++++ %
        % =========================================== %
        
        tot_sac = size(eyeTrial.saccade.onsetTime, 1) - 1;          % Remove first one
        dur_sac = eyeTrial.saccade.offsetTime - eyeTrial.saccade.onsetTime;
    
        % Sanity checks!
        % Remove extremely long saccades (>0.5 sec)
        dur_sac = dur_sac( ...
                dur_sac >= 0 & ...
                dur_sac <= 0.5 ...
            );
    
        avg_sac_dur = nanmean(dur_sac(2:end));                         % Remove first one
        sac_per_sec = tot_sac / (eyeTrial.saccade.offsetTime(end) - eyeTrial.saccade.offsetTime(1));
        fprintf(['\n============ SACCADES ============\n' ...
            'A total of %d saccades were found.\n' ...
            'On average, %.2f saccades per second.\n' ...
            'Average saccade duration of %0.2f seconds.\n'], ...
            tot_sac, ...
            sac_per_sec, ...
            avg_sac_dur);
        fprintf(['\n======== SACCADES (proc.) ========\n' ...
            'Mean amplitude:\t\t\t%0.2f\n' ...
            'Mean amplitude (Head):\t%0.2f\n' ...
            'Mean velocity:\t\t\t%0.2f\n' ...
            'Mean velocity (Head):\t%0.2f\n' ...
            'Peak velocity:\t\t\t%0.2f\n' ...
            'Peak velocity (Head):\t%0.2f\n' ...
            'Duration:\t\t\t\t%0.2f\n'], ...
            nanmean(sacStats.amp, 1), ...
            nanmean(sacStats.ampInHead, 1), ...
            nanmean(sacStats.meanVel, 1), ...
            nanmean(sacStats.meanVelHead, 1), ...
            nanmean(sacStats.peakVel, 1), ...
            nanmean(sacStats.peakVelHead, 1), ...
            nanmean(sacStats.duration));
        
        all_user_info.SaccadeInfo{i} = struct();
        all_user_info.SaccadeInfo{i}.tot_sac = tot_sac;
        all_user_info.SaccadeInfo{i}.dur_sac = dur_sac;
        all_user_info.SaccadeInfo{i}.avg_sac_dur = avg_sac_dur;
        all_user_info.SaccadeInfo{i}.sac_per_sec = sac_per_sec;
        all_user_info.SaccadeInfo{i}.amp = sacStats.amp;
        all_user_info.SaccadeInfo{i}.ampInHead = sacStats.ampInHead;
        all_user_info.SaccadeInfo{i}.meanVel = sacStats.meanVel;
        all_user_info.SaccadeInfo{i}.meanVelHead = sacStats.meanVelHead;
        all_user_info.SaccadeInfo{i}.peakVel = sacStats.peakVel;
        all_user_info.SaccadeInfo{i}.peakVelHead = sacStats.peakVelHead;
        all_user_info.SaccadeInfo{i}.duration = sacStats.duration;
    
        % Sanity checks!
        % Remove extremely wide saccades
        all_user_info.SaccadeInfo{i}.amp = ...
            all_user_info.SaccadeInfo{i}.amp( ...
                all_user_info.SaccadeInfo{i}.amp >= 0 & ...
                all_user_info.SaccadeInfo{i}.amp <= 100 ...
            );
    
        % Remove extremely wide saccades
        all_user_info.SaccadeInfo{i}.ampInHead = ...
            all_user_info.SaccadeInfo{i}.ampInHead( ...
                all_user_info.SaccadeInfo{i}.ampInHead >= 0 & ...
                all_user_info.SaccadeInfo{i}.ampInHead <= 100 ...
            );
    
        % Remove extremely fast saccades
        all_user_info.SaccadeInfo{i}.meanVel = ...
            all_user_info.SaccadeInfo{i}.meanVel( ...
                all_user_info.SaccadeInfo{i}.meanVel >= 0 & ...
                all_user_info.SaccadeInfo{i}.meanVel <= 1000 ...
            );
    
        % Remove extremely fast saccades
        all_user_info.SaccadeInfo{i}.meanVelHead = ...
            all_user_info.SaccadeInfo{i}.meanVelHead( ...
                all_user_info.SaccadeInfo{i}.meanVelHead >= 0 & ...
                all_user_info.SaccadeInfo{i}.meanVelHead <= 1000 ...
            );
    
        % Remove extremely fast saccades
        all_user_info.SaccadeInfo{i}.peakVel = ...
            all_user_info.SaccadeInfo{i}.peakVel( ...
                all_user_info.SaccadeInfo{i}.peakVel >= 0 & ...
                all_user_info.SaccadeInfo{i}.peakVel <= 1000 ...
            );
    
        % Remove extremely fast saccades
        all_user_info.SaccadeInfo{i}.peakVelHead = ...
            all_user_info.SaccadeInfo{i}.peakVelHead( ...
                all_user_info.SaccadeInfo{i}.peakVelHead >= 0 & ...
                all_user_info.SaccadeInfo{i}.peakVelHead <= 1000 ...
            );
     
        
        % =========================================== %
        % ++++++++++++++ BLINK ANALYSIS +++++++++++++ %
        % =========================================== %
    
        tot_bli = size(eyeTrial.blink.onsetTime, 1) - 1;         % Remove first one
        dur_bli = eyeTrial.blink.offsetTime - eyeTrial.blink.onsetTime;
    
        % Sanity checks!
        % Remove extremely long fixations (>1 sec)
        dur_bli = dur_bli( ...
                dur_bli >= 0 & ...
                dur_bli <= 1 ...
            );
    
        avg_bli_dur = nanmean(dur_bli(2:end));                   % Remove first one
        bli_per_sec = tot_bli / (eyeTrial.blink.offsetTime(end) - eyeTrial.blink.offsetTime(1));
        fprintf(['\n============ BLINKS ============\n' ...
            'A total of %d blinks were found.\n' ...
            'On average, %.2f blinks per second.\n' ...
            'Average blink duration of %0.2f seconds.\n'], ...
            tot_bli, ...
            bli_per_sec, ...
            avg_bli_dur);
    
        all_user_info.BlinkInfo{i} = struct();
        all_user_info.BlinkInfo{i}.tot_bli = tot_bli;
        all_user_info.BlinkInfo{i}.dur_bli = dur_bli;
        all_user_info.BlinkInfo{i}.avg_bli_dur = avg_bli_dur;
        all_user_info.BlinkInfo{i}.bli_per_sec = bli_per_sec;
    

        % =========================================== %
        % +++++++++++++++ VOR ANALYSIS ++++++++++++++ %
        % =========================================== %
        
        
        tot_vor = size(eyeTrial.VOR.onsetTime, 1) - 1;          % Remove first one
        dur_vor = eyeTrial.VOR.offsetTime - eyeTrial.VOR.onsetTime;
    
        % Sanity checks!
        % Remove extremely long fixations (>0.2 sec)
        dur_vor = dur_vor( ...
               dur_vor >= 0 & ...
               dur_vor <= 0.2 ...
            );
    
        avg_vor_dur = nanmean(dur_vor(2:end));                         % Remove first one
        vor_per_sec = tot_vor / (eyeTrial.VOR.offsetTime(end) - eyeTrial.VOR.offsetTime(1));
        fprintf(['\n============= VOR =============\n' ...
            'A total of %d VORs were found.\n' ...
            'On average, %.2f VORs per second.\n' ...
            'Average VORs duration of %0.2f seconds.\n'], ...
            tot_vor, ...
            vor_per_sec, ...
            avg_vor_dur);
    
        all_user_info.VORInfo{i} = struct();
        all_user_info.VORInfo{i}.tot_vor = tot_vor;
        all_user_info.VORInfo{i}.dur_vor = dur_vor;
        all_user_info.VORInfo{i}.avg_vor_dur = avg_vor_dur;
        all_user_info.VORInfo{i}.vor_per_sec = vor_per_sec;
    


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% ---------> STORE 5 MINS FROM 20, 40, 60 CHECKPOINTS <--------- %%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% -------------> 5 LAST MINUTES OF 20 CHUNK <------------- %%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
        disp('Analyzing 20M chunk.');

        % Reset eyeTrial to get new data
        eyeTrial = all_user_info.EyeTrial{i};
        
        % We now getting the first 5 minutes, same as commented before.
        % See comments from previous code for info.
        minsToApply = 300;
        % We want to go to the minute 15 and take the next 5 minutes
        startingPoint = 15 * 60;
        eyeTrial.headAligned = eyeTrial.headAligned(eyeTrial.headAligned.timestamp >= startingPoint, :);
        eyeTrial.eyeAligned = eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp >= startingPoint, :);
        % Start with the last not-NaN row, otherwise can be losing information
        first_non_nan_row = find(~any(isnan(eyeTrial.headAligned.qW), 2), 1);
        timestamp_to_start = eyeTrial.headAligned.timestamp(first_non_nan_row);
        final_timestamp = timestamp_to_start + minsToApply;  
        if ~isempty(eyeTrial.headAligned(eyeTrial.headAligned.timestamp <= final_timestamp & eyeTrial.headAligned.timestamp >= timestamp_to_start, :))
            eyeTrial.headAligned = eyeTrial.headAligned(eyeTrial.headAligned.timestamp <= final_timestamp & eyeTrial.headAligned.timestamp >= timestamp_to_start, :);
        end
        if ~isempty(eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp <= final_timestamp & eyeTrial.eyeAligned.timestamp >= timestamp_to_start, :))
            eyeTrial.eyeAligned = eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp <= final_timestamp & eyeTrial.eyeAligned.timestamp >= timestamp_to_start, :);
        end
    
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

        % Note that here is when the variable names must change (e.g., FM_
        % or whatever other thing you want to try...)
        all_user_info.CH20_HeadInfo{i} = eyeTrial.headTrace;
        all_user_info.CH20_EyeInfo{i} = eyeTrial.eyeTrace;
        all_user_info.CH20_gazeFix{i} = eyeTrial.gazeFix;
        all_user_info.CH20_saccade{i} = eyeTrial.saccade;
        all_user_info.CH20_classID{i} = eyeTrial.classID;


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% -------------> 5 LAST MINUTES OF 40 CHUNK <------------- %%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
        disp('Analyzing 40M chunk.');

        % Reset eyeTrial to get new data
        eyeTrial = all_user_info.EyeTrial{i};
        
        % See comments from previous code for info.
        minsToApply = 300;
        % We want to go to the minute 35 and take the next 5 minutes
        startingPoint = 35 * 60;
        eyeTrial.headAligned = eyeTrial.headAligned(eyeTrial.headAligned.timestamp >= startingPoint, :);
        eyeTrial.eyeAligned = eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp >= startingPoint, :);
        % Start with the last not-NaN row, otherwise can be losing information
        first_non_nan_row = find(~any(isnan(eyeTrial.headAligned.qW), 2), 1);
        timestamp_to_start = eyeTrial.headAligned.timestamp(first_non_nan_row);
        final_timestamp = timestamp_to_start + minsToApply;  
        if ~isempty(eyeTrial.headAligned(eyeTrial.headAligned.timestamp <= final_timestamp & eyeTrial.headAligned.timestamp >= timestamp_to_start, :))
            eyeTrial.headAligned = eyeTrial.headAligned(eyeTrial.headAligned.timestamp <= final_timestamp & eyeTrial.headAligned.timestamp >= timestamp_to_start, :);
        end
        if ~isempty(eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp <= final_timestamp & eyeTrial.eyeAligned.timestamp >= timestamp_to_start, :))
            eyeTrial.eyeAligned = eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp <= final_timestamp & eyeTrial.eyeAligned.timestamp >= timestamp_to_start, :);
        end
    
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

        % Note that here is when the variable names must change (e.g., FM_
        % or whatever other thing you want to try...)
        all_user_info.CH40_HeadInfo{i} = eyeTrial.headTrace;
        all_user_info.CH40_EyeInfo{i} = eyeTrial.eyeTrace;
        all_user_info.CH40_gazeFix{i} = eyeTrial.gazeFix;
        all_user_info.CH40_saccade{i} = eyeTrial.saccade;
        all_user_info.CH40_classID{i} = eyeTrial.classID;
    

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% -------------> 5 LAST MINUTES OF 60 CHUNK <------------- %%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
        disp('Analyzing 60M chunk.');

        % Reset eyeTrial to get new data
        eyeTrial = all_user_info.EyeTrial{i};

        % See comments from previous code for info.
        minsToApply = 300;
        % We want to go to the minute 55 and take the next 5 minutes
        startingPoint = 55 * 60;
        eyeTrial.headAligned = eyeTrial.headAligned(eyeTrial.headAligned.timestamp >= startingPoint, :);
        eyeTrial.eyeAligned = eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp >= startingPoint, :);
        % Start with the last not-NaN row, otherwise can be losing information
        first_non_nan_row = find(~any(isnan(eyeTrial.headAligned.qW), 2), 1);
        timestamp_to_start = eyeTrial.headAligned.timestamp(first_non_nan_row);
        final_timestamp = timestamp_to_start + minsToApply;  
        if ~isempty(eyeTrial.headAligned(eyeTrial.headAligned.timestamp <= final_timestamp & eyeTrial.headAligned.timestamp >= timestamp_to_start, :))
            eyeTrial.headAligned = eyeTrial.headAligned(eyeTrial.headAligned.timestamp <= final_timestamp & eyeTrial.headAligned.timestamp >= timestamp_to_start, :);
        end
        if ~isempty(eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp <= final_timestamp & eyeTrial.eyeAligned.timestamp >= timestamp_to_start, :))
            eyeTrial.eyeAligned = eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp <= final_timestamp & eyeTrial.eyeAligned.timestamp >= timestamp_to_start, :);
        end
    
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

        % Note that here is when the variable names must change (e.g., FM_
        % or whatever other thing you want to try...)
        all_user_info.CH60_HeadInfo{i} = eyeTrial.headTrace;
        all_user_info.CH60_EyeInfo{i} = eyeTrial.eyeTrace;
        all_user_info.CH60_gazeFix{i} = eyeTrial.gazeFix;
        all_user_info.CH60_saccade{i} = eyeTrial.saccade;
        all_user_info.CH60_classID{i} = eyeTrial.classID;      


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% -------------> FIRST 5 MINUTES OF 60 CHUNK <------------- %%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
        disp('Analyzing 05M chunk.');

        % Reset eyeTrial to get new data
        eyeTrial = all_user_info.EyeTrial{i};
        
        % We now getting the first 5 minutes, same as commented before.
        % See comments from previous code for info.
        minsToApply = 300;
        % Start with the last not-NaN row, otherwise can be losing information
        first_non_nan_row = find(~any(isnan(eyeTrial.headAligned.qW), 2), 1);
        timestamp_to_start = eyeTrial.headAligned.timestamp(first_non_nan_row);
        final_timestamp = timestamp_to_start + minsToApply;  
        if ~isempty(eyeTrial.headAligned(eyeTrial.headAligned.timestamp <= final_timestamp & eyeTrial.headAligned.timestamp >= timestamp_to_start, :))
            eyeTrial.headAligned = eyeTrial.headAligned(eyeTrial.headAligned.timestamp <= final_timestamp & eyeTrial.headAligned.timestamp >= timestamp_to_start, :);
        end
        if ~isempty(eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp <= final_timestamp & eyeTrial.eyeAligned.timestamp >= timestamp_to_start, :))
            eyeTrial.eyeAligned = eyeTrial.eyeAligned(eyeTrial.eyeAligned.timestamp <= final_timestamp & eyeTrial.eyeAligned.timestamp >= timestamp_to_start, :);
        end
    
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

        % Note that here is when the variable names must change (e.g., FM_
        % or whatever other thing you want to try...)
        all_user_info.CH05_HeadInfo{i} = eyeTrial.headTrace;
        all_user_info.CH05_EyeInfo{i} = eyeTrial.eyeTrace;
        all_user_info.CH05_gazeFix{i} = eyeTrial.gazeFix;
        all_user_info.CH05_saccade{i} = eyeTrial.saccade;
        all_user_info.CH05_classID{i} = eyeTrial.classID;

    catch exception
       % Some errors can happen (although they shouldn't)...
       % If any error happens, then you can run this gain with the
       % "skipping previously load users" thing and just focus on the
       % remaining ones...
       fprintf(['\n ERROR for %s, session %d. '], ...
           all_user_info.UserID{i}, ...
           all_user_info.Session(i));
    end
end

% Just for performance check
toc;

% Save a super complete version
% This is technically not necessary, but I leave it here in case
% save(['data\post_processed\study2\S2-post-data.mat'], 'all_user_info', '-v7.3');

% Save a less heavy version (we remove EyeTrial, which is almost 75% of the
% size of the file) with another variable (in orther not to mess MATLAB
% workspace, i.e., so you can still use all_user_info if you don't remove
% workplace variables)
small_all_user_info = all_user_info;
for i = 1:height(all_user_info)
    small_all_user_info.EyeTrial{i} = [];
end
save(['data\post_processed\study2\S2-small-post-data.mat'], 'small_all_user_info', '-v7.3');