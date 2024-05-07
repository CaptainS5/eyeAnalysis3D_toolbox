% Script to load data and getting prepared for eye analysis
% This script builds upon Xiuyun Wu's previous version
% Customize to prepare your raw data here
clc; close all; clear all;
addpath(genpath('functions'))
format long;

% Path where your raw data is saved
% This script assumes that you have your data structured in such a way that
% each user has its own subfolder, and all sessions for that user and in
% that folder. Each session should have a different timestamp
% Right now, the file names are supposed to be 
% EyeTrackerLog_YYYYMMdd-hhmmss.txt
datapath = 'data\raw\study2\';
% Create a directory to save results
%[status, msg, msgID] = mkdir([datapath, '..\pre_processed']);


% Get list of files. For now, it works writting all of them manually,
% and assumes one user.
fileName = getAllTxtFiles(datapath);

%% IMPORTANT NOTE
% There is one wacky thing going on with log files sometimes for the ET-DDC project.
% First file (which I coin initial) has a difference w.r.t. to the rest of
% the files: it has some first rows where the last 7 fields have no data
% (WARNING! it is not that they are empty; they do not exist, i.e., there
% are only 45 fields). This can also happen when e.g., the tracker fails
% Therefore,, they work slightly different to the rest of files.
% That's why we need to take it into account and be ready for two different
% arrangement of data.

%% SET VARIABLE TYPES FOR THE READ TXTs
% Force varaible types to avoid errors
% Variables for the non-initial files (the ones that have proper 52
% columns)
variable_types = {
    'double', 'logical', 'logical', 'logical', 'double', 'double', 'double', ...
    'logical', 'double', 'double', 'double', 'logical', 'double', 'logical', ...
    'double', 'double', 'double', 'logical', 'double', 'double', 'double', ...
    'logical', 'double', 'double', 'double', 'logical', 'double', 'logical', ...
    'logical', 'logical', 'double', 'double', 'double', 'logical', 'double', ...
    'double', 'double', 'logical', 'double', 'double', 'double', 'logical', ...
    'double', 'logical', 'logical', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double'};
% Variables for the initial files (the ones that have proper some shorter
% rows because head information is not available yet)
variable_types_initial = {
    'double', 'logical', 'logical', 'logical', 'double', 'double', 'double', ...
    'logical', 'double', 'double', 'double', 'logical', 'double', 'logical', ...
    'double', 'double', 'double', 'logical', 'double', 'double', 'double', ...
    'logical', 'double', 'double', 'double', 'logical', 'double', 'logical', ...
    'logical', 'logical', 'double', 'double', 'double', 'logical', 'double', ...
    'double', 'double', 'logical', 'double', 'double', 'double', 'logical', ...
    'double', 'logical', 'logical'};
% Define regular expressions to match UserID and day
userIDPattern = 'P(\d+)';    % Matches "P" followed by digits (User ID)
dayPattern = '(\d{8})';      % Matches 8 digits (Date in YYYYMMDD format)

%% REQUIRED AUXILIAR VARIABLES
% We want to iterate through the files and store all data in one table per
% participant. To do so, we require some auxiliar variables
timestamp_accum = 0;    % Some users have multiple files per session. Therefore,
                        % we need to accumulate their timestamps. We need to 
                        % apply an offset given the last timestamp of previous file.
eyeTrial = [];          % To store all the eye-related information.
userID = 'NaN';         % Current user ID
prevUserID = 'NaN';     % Previous log user ID (req. to know when a new user comes)
day = 'NaN';            % Current day
prevDay = 'NaN';        % Previous log dat (req. to know when a new session comes)
prevETDDC = 'NaN';      % Whether last session had ET-DDC on.
                        % Note that ET-DDC can be replaced by any condition
                        % that is being tested (e.g., foveation vs. no foveation...)
current_session = 1;    % Whether it is the first or second session of the user.
thisUserCalibration = ['None;'];    % This is to store calibration data.
files = "";             % This is to store all file names for a session of a user.


%% WE SAVE USER INFO IN THIS DATA STRUCTURE
% Define column names and types as a cell array
columnNames = {'UserID', 'Session', 'Day', 'GameDurations', 'ETDDC', 'Files', 'EyeTrial', 'Calibration'};
variableTypes = {'string', 'int8', 'string', 'cell', 'logical', 'string', 'cell', 'cell'};
% Create an empty table with specified column names
all_user_info = table('Size', [0, length(columnNames)], 'VariableNames', columnNames,  'VariableTypes', variableTypes);

% It is possible to preload previously saved preprocessed files.
% This makes sense if we just want to add a few new users, instead of
% processing all users once again

% if isfile(['data\pre_processed\fixTS_data_joint.mat']) 
%   load(['data\pre_processed\fixTS_data_joint.mat'])
% end
original_users = all_user_info.UserID;      % Keep track of the users that were already
                                            % saved (if a file has been loaded).

tic; % Just for performance measurements.

% For debug purposes
debug_total_rows = 0;
debug_removed_rows = 0;
game_durations = struct();
game_durations.dur = [];
n_files = 0;

%% ITERATE OVER ALL USER FILES
for userFileI = 1:length(fileName)
% for userFileI = length(fileName):-1:1 
    % Get user and session data
    % Use regular expressions to extract UserID and day
    userMatch = regexp(fileName{userFileI}, userIDPattern, 'tokens');
    dayMatch = regexp(fileName{userFileI}, dayPattern, 'tokens');

    % Extracted UserID and day
    userID = userMatch{1}{1};
    day = dayMatch{1}{1};

    % You can jump users based on ID
    % if str2double(userID) ~= 27
    % continue
    % end

    % You can also jump users that have been already included. 
    % If only one session has been included, you should force the remainder
    % to be the second session.
    cont = false;
    forceSession = false;
    % for j = 1:size(original_users) 
    %     % If the user appears and has appeared twice
    %     if str2double(original_users{j}) == str2double(userID) ...
    %             && sum(str2double(original_users) == str2double(userID)) == 2
    %         fprintf('User %s already logged, trying next one\n', userID);
    %         cont = true;
    %         break;
    %     elseif str2double(original_users{j}) == str2double(userID) ...
    %             && sum(str2double(original_users) == str2double(userID)) == 1
    %         fprintf('User %s has one session, trying next one\n', userID);
    %         forceSession = true;  
    %     end
    % end
    % if cont
    %     continue;
    % end
 
    % If the user has not been skipped/forced previously, you need to check
    % whether the current user is different, or the same, and whether the
    % session is the same. Basically, there are three possibilities:
    % 
    % 1 - Same user and same day: This means that the session continues and
    % that this log file is the follow-up of the previous one. Therefore,
    % no action is required, rather than continuing merging information.
    %
    % 2 - If the same user but different day (first if): Then this means
    % that the previous session has been preprocessed, and a new one is
    % starting. You have to save all the data so far (that's why you keep
    % info of the previous day, previous condition, etc.), and reset all
    % variables to start logging the second session.
    %
    % 3 - Different user and different day (second if): This means that the
    % last session of the last user already ended. You have to store
    % everything again, and reset for this new user.

    % Same user but second session
    if (isequal(userID, prevUserID) && ~isequal(day, prevDay))
        % Store first session
        all_user_info = [all_user_info ; ...
            {prevUserID, current_session, prevDay, ...
            game_durations, ...
            prevETDDC, files, eyeTrial, thisUserCalibration}];
        % Reset variables and prepare for session 2
        files = "";
        current_session = 2;
        game_durations.dur = [];
        n_files = 0;
        timestamp_accum = 0;
        thisUserCalibration = ['None;'];
    end

    % Different user, first session
    if (~isequal(userID, prevUserID) && ~isequal(prevUserID,'NaN'))
        % Store last session
        all_user_info = [all_user_info ; ...
            {prevUserID, current_session, prevDay, ...
            game_durations, ...
            prevETDDC, files, eyeTrial, thisUserCalibration}];
        % Reset variables and prepare for session 1
        files = "";
        current_session = 1;
        timestamp_accum = 0;
        game_durations.dur = [];
        n_files = 0;
        thisUserCalibration = ['None;'];
    end

    % Store the path
    files = files + ';' + fileName{userFileI};

    % If session was forced before (i.e., because a rpeviously loaded
    % datafile already contained info for the 1st session), then disregard
    % previous ifs and set this session.
    % This should be uncommented if the above related code is uncommented to
    % if forceSession
    %     current_session = 2;
    % end
    
    % Display the current user, for visualization purposes
    fprintf('UserID: %s\n', userID);
    fprintf('Day: %s\n', day);
    fprintf('Current session: %d\n', current_session);

    %% REMOVE ALL EYE-TRACKING RELATED ROWS, WHILE KEEPING CALIBRATION INFO
    
    % First check calibration status. Open the file for reading
    fileID = fopen(fileName{userFileI}, 'r');
    
    % Read the lines of the file
    data = textscan(fileID, '%s', 'Delimiter', '\n');
    data = data{1};
    
    % Close the file (to avoid corruptions)
    fclose(fileID);
    
    % Find the row that contains the specific strings for the beginning and
    % the end of the calibration procedures.
    search_string = 'EYETRACKER_CALIBRATION_RESULTS';
    search_string_2 = 'EYETRACKER_CALIBRATION_STARTED';
    matching_rows = contains(data, search_string);
    matching_rows_2 = contains(data, search_string_2);
    calibration_result_indices = find(matching_rows);
    calibration_started_indices = find(matching_rows_2);
    
    % Check the number of matching indices.
    % This is VERY tricky. It could happen (shoudn't, but could) that some
    % files share calibration, i.e., one file starts the calibration
    % procedure and the next one finishes it. This would lead to uneven
    % number of rows of calibration start and end in a particular file.
    % Therefore, there are four cases:
    %
    % 1 - No calibration in the files --> Yay!
    %
    % 2 - Even number of calibration starts and ends --> Easy, just remove
    % rows in between.
    %
    % 3 - One more start at the end of the file --> Remove all rows from
    % such a start to the end of the file.
    %
    % 4 - One more end at the beginning of the file --> Remove all rows
    % from beginning to that line.
    num_starts = numel(calibration_started_indices);
    num_results = numel(calibration_result_indices);
    
    % Check if find returns nothing, one value, or multiple values
    % We want to first store calibration information
    if isempty(calibration_result_indices)
        disp('No calibration found.');
    else
        if num_results == 1
            % Store calibration results.
            thisUserCalibration = [thisUserCalibration ; string(data(calibration_result_indices))];
            disp('One calibration result acquired.');
        else
            for j = 1:num_results
                % Store calibration results.
                thisUserCalibration = [thisUserCalibration ; string(data(calibration_result_indices(j)))];
            end
            disp('Multiple calibration result acquired.');
        end
    end
    % Note --> We have to store this first because otherwise the
    % information could be lost.
    

    %% LOAD RAW DATA FROM THE FILES
    % We first load the variable names.
    opts = delimitedTextImportOptions('Delimiter', ';');
    varNames = readtable([fileName{userFileI}], opts);
    varNames = varNames{1, :};
    % Then the funky thing of initial vs. no initial file (52 vs. 45
    % columns) can happen. Although not the cleanest way of handling this,
    % this try-catch technique works surprisingly well and fast. Basically
    % innocent until otherwise provedn: Assume that we have 52 columns, and
    % if it fails, it means that we don't :)
    try 
        % Adjust options of readtable for this type of files.
        opts = detectImportOptions([fileName{userFileI}]);
        % Assign variable types, see above.
        opts.VariableTypes = variable_types; 
        dataRaw = readtable([fileName{userFileI}], opts);        
        dataRaw.Properties.VariableNames = varNames;
    % If it is the initial file, then the previous try has failed hehe. 
    % Now we must work around uncomplete rows
    catch exception
        % It is interesting to uncomment this if something goes wacky. It
        % should never be here, unless a file is corrupted or has a
        % structure that we are not accounting for!
        % if (isequal(userID, prevUserID) && isequal(day, prevDay))
        %    fprintf('Shouldn`t be here! There is some error with the files!');
        %    exit();
        % end

        % Adjust options of readtable for this type of files.
        opts = delimitedTextImportOptions('Delimiter', ';');
        varNames = readtable([fileName{userFileI}], opts);
        varNames = varNames{1, :};
        dataRaw = readtable([fileName{userFileI}], 'Delimiter', ';'); 
        dataRaw.Properties.VariableNames = varNames;

        % List of columns to convert to numeric - These last 7 fields were
        % empty at the beginning, so they are not properly casted to the
        % type we would like.
        columns_to_convert = {'headpose_rotation_w', 'headpose_rotation_x', 'headpose_rotation_y', ...
            'headpose_rotation_z', 'headpose_position_x', 'headpose_position_y', 'headpose_position_z'};
        % Loop through each column and convert it to numeric
        % Again in a try-catch because in some cases they are already
        % correctly casted. Why? I have no clue. But this works perfectly.
        try
            for col = columns_to_convert
               dataRaw.(col{1}) = str2double(dataRaw.(col{1}));
            end
        catch exception
            % Nothing
        end
        
        % Convert 'TRUE' to 1 and 'FALSE' to 0 directly
        dataRaw.left_blink = strcmp(dataRaw.left_blink, 'TRUE');
        dataRaw.right_blink = strcmp(dataRaw.right_blink, 'TRUE');
        dataRaw.gaze_origin_combined_validity = strcmp(dataRaw.gaze_origin_combined_validity, 'TRUE');
        dataRaw.gaze_direction_combined_validity = strcmp(dataRaw.gaze_direction_combined_validity, 'TRUE');
        dataRaw.convergence_distance_validity = strcmp(dataRaw.convergence_distance_validity, 'TRUE');
        dataRaw.entrance_pupil_position_left_validity = strcmp(dataRaw.entrance_pupil_position_left_validity, 'TRUE');
        dataRaw.left_gaze_origin_validity = strcmp(dataRaw.left_gaze_origin_validity, 'TRUE');
        dataRaw.left_gaze_direction_validity = strcmp(dataRaw.left_gaze_direction_validity, 'TRUE');
        dataRaw.left_pupil_diameter_validity = strcmp(dataRaw.left_pupil_diameter_validity, 'TRUE');
        dataRaw.left_blink_validity = strcmp(dataRaw.left_blink_validity, 'TRUE');
        dataRaw.entrance_pupil_position_right_validity = strcmp(dataRaw.entrance_pupil_position_right_validity, 'TRUE');
        dataRaw.right_gaze_origin_validity = strcmp(dataRaw.right_gaze_origin_validity, 'TRUE');
        dataRaw.right_gaze_direction_validity = strcmp(dataRaw.right_gaze_direction_validity, 'TRUE');
        dataRaw.right_pupil_diameter_validity = strcmp(dataRaw.right_pupil_diameter_validity, 'TRUE');
        dataRaw.right_blink_validity = strcmp(dataRaw.right_blink_validity, 'TRUE'); 
    end

    % So far, data has been ready and casted. We still have the raw data
    % structure.

    %% REMOVE ALL ROWS THAT DEPEND ON CALIBRATION
    % There is another (lots of fun, huh?) funky thing going on here: We
    % cannot remove rows dynamically from a table (obviously); otherwise
    % indices get messed up, therefore we need to accumulate all indices
    % that are to be removed, and remove them all at once.
    % These are all the possible cases, nothing fancy but just iteration
    % and removals and some logging messages.
    if ~isempty(calibration_result_indices) && isempty(calibration_started_indices)
        % Some calibration was ended but start is not correctly indicated (?)
        dataRaw(1:calibration_result_indices, :) = [];
        fprintf('Some calibration was started before. Removed %d rows.\n', calibration_result_indices);
    elseif isempty(calibration_result_indices) && ~isempty(calibration_started_indices)
        % Some calibration was started but end is not correctly indicated (?)
        dataRaw(calibration_started_indices:end, :) = [];
        fprintf('Some calibration was ended later. Removed %d rows.\n', size(dataRaw, 2) - calibration_started_indices);
    elseif ~isempty(calibration_result_indices) && ~isempty(calibration_started_indices)
        % If a log has calibration results, we can assume that is the
        % beginning of the game. Similarly, if there are more than one, we
        % just trust the last one, i.e., remove everything until that
        last_calibration_results = calibration_result_indices(end);
        dataRaw(1:last_calibration_results, :) = [];
        fprintf('Calibration: Removed %d rows.\n',last_calibration_results);
        % % Both were somehow correctly logged
        % if num_starts == num_results
        %     if num_results == 1
        %        dataRaw(calibration_started_indices:calibration_result_indices, :) = [];
        %        fprintf('Other weird cases: Removed %d rows.\n',calibration_result_indices-calibration_started_indices);
        %     else
        %         rowsToRemove = [];
        %         for j = 1:num_starts
        %              rowsToRemove = [rowsToRemove, calibration_started_indices(j):calibration_result_indices(j)];
        %         end
        %         dataRaw(rowsToRemove, :) = [];
        %         fprintf('Other weird cases: Removed %d rows.\n',size(rowsToRemove, 2));
        %     end
        % % Sometimes there are results without starting / ending flag
        % else
        %     rowsToRemove = [];
        %     if num_starts > num_results
        %         % Remove the last lines corresponding to the unfinished
        %         % calibration
        %         rowsToRemove = calibration_started_indices(end):height(dataRaw);
        %         calibration_started_indices = calibration_started_indices(1:end-1);
        %     elseif num_results > num_starts
        %         % Remove the first lines corresponding to the unfinished
        %         % calibration
        %         rowsToRemove = 1:calibration_result_indices(1);
        %         calibration_result_indices = calibration_result_indices(2:end);
        %     end
        %     % Once we removed the uneven ones, remove the paired ones.
        %     for j = 1:numel(calibration_result_indices)
        %        rowsToRemove = [rowsToRemove, calibration_started_indices(j):calibration_result_indices(j)];
        %     end
        %     % And finally remove all.
        %     dataRaw(rowsToRemove, :) = [];
        %     fprintf('Other weird cases: Removed %d rows.\n',size(rowsToRemove, 2));
        % end       
    end


    %% REMOVING REMAINING WEIRD ROWS
    % There are some rows that have not head values yet, or that has some 
    % errors or bugs that might have not been handled before, so we need to
    % delete them, otherwise things go wacky
    % Dani's note --> Yeah, another try-catch because in some cases the
    % type of rows include cells, and in other cases, it includes normal
    % data (e.g., doubles...). This handles both cases perfectly.
    try      
        % Remove other lines with no info
        idx = find(cellfun(@isempty, dataRaw.headpose_position_x));
        dataRaw(idx, :) = [];
    catch exception
        % Remove other lines with no info
        idx = find(cellfun('isempty', num2cell(dataRaw.headpose_position_x)));
        dataRaw(idx, :) = [];
    end

    %% IMPORTANT! START OF ACTUAL DATA CLEANING AND UNIFYING %%

    % First of all, it is very important to understand that we are playing
    % with three different coordinate systems:
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% % 
    % %%%%%%%% COORDINATE SYSTEMS %%%%%%%%% %
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% % 
    % SORTED COORDINATE SYSTEM [MATLAB Plot3 DEFAULT]               -->      x+=forward      y+=left     z+=up           right-handed rotation.
    % UNITY COORDINATE SYSTEM (Affects head position and rotation)  -->      x+=right        y+=up       z+=backward     left-handed rotation.     
    % TOBII EYE DATA COORDINATE SYSTEM (Affects gaze-related data)  -->      x+=left         y+=up       z+=forward      right-handed rotation.


    %% ACCUMULATE TIMESTAMPS
    % First get the relative timestamp in the current file
    dataRaw.TimeMicroSec = dataRaw.TimeMicroSec - dataRaw.TimeMicroSec(1);
    % Then account for the accumulated from previous timestamps
    timestamp = dataRaw.TimeMicroSec ./ 1000000 + timestamp_accum;
    
   
    %% REMOVE GAPS (ADDING NANs)
    % Note that this is likely to create small jumps. Post processing will
    % ignore NaN and gaps and never create interpolations or weird gaps.
    % If gaps in time, replace prior and posterior line with NaNs to
    % facilitate this behavior later.
    % We set a threshold that is clearly larger than our sample rate
    % (0.004)
    threshold = 0.01;
    exceed_indices = find(diff(timestamp) > threshold) + 1;
    for k = 1:size(exceed_indices, 1)
        idx = exceed_indices(k);
        % Make idx and idx-1 NaN
        for tt = 5:52
            % We need to iterate all numeric fields because funky MATLAB
            % Also: DO NOT CHANGE logical values, otherwise everything will
            % break in post processing...
            if isnumeric(dataRaw{idx-1, tt})
                dataRaw{idx-1, tt} = NaN;
                dataRaw{idx, tt} = NaN;
            end
        end
    end
    % Debug how many gaps were "removed"
    fprintf('Fixed %d gaps\n', size(exceed_indices, 1));

    
    %% REMOVE INVALID TOBII DATA
    % Check also (0,0,0) in gaze_direction_combined_normalized_xyz from the 
    % Tobii raw data, mark all Tobii eye in head data as NaN if that's the
    % case. This is because they are "invalid" (although not broken) rows
    % and should not be included in the analyses.
    
    % Find all rows where 'ColumnX' is 0 and remove values
    rowsWithZeros = find(dataRaw.gaze_origin_combined_mm_xyz_x == 0 ...
        & dataRaw.gaze_origin_combined_mm_xyz_y == 0 ...
        & dataRaw.gaze_origin_combined_mm_xyz_z == 0); 
    
    % We are remvoing numerical values BUT NOT CHANGING logicals (as
    % before)
    partial_dataRaw = [dataRaw(rowsWithZeros, 1:4), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithZeros, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(5:7)), ...
        dataRaw(rowsWithZeros, 8), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithZeros, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(9:11)) ...
        dataRaw(rowsWithZeros, 12), ...
        array2table(repmat([NaN], size(rowsWithZeros, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(13)) ...
        dataRaw(rowsWithZeros, 14), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithZeros, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(15:17)) ...
        dataRaw(rowsWithZeros, 18), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithZeros, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(19:21)) ...
        dataRaw(rowsWithZeros, 22), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithZeros, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(23:25)) ...
        dataRaw(rowsWithZeros, 26), ...
        array2table(repmat([NaN], size(rowsWithZeros, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(27)) ...
        dataRaw(rowsWithZeros, 28:30), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithZeros, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(31:33)) ...
        dataRaw(rowsWithZeros, 34), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithZeros, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(35:37)) ...
        dataRaw(rowsWithZeros, 38), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithZeros, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(39:41)) ...
        dataRaw(rowsWithZeros, 42), ...
        array2table(repmat([NaN], size(rowsWithZeros, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(43)) ...
        dataRaw(rowsWithZeros, 44:45), ...
        array2table(repmat([NaN, NaN, NaN, NaN, NaN, NaN, NaN], size(rowsWithZeros, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(46:end))];  
    % Change all at once
    dataRaw(rowsWithZeros, :) = partial_dataRaw;
    % Debug how many wrong Tobii rows were removed
    fprintf('Fixed %d rows with (0,0,0)\n', size(rowsWithZeros, 1));
    debug_removed_rows = debug_removed_rows + size(rowsWithZeros, 1);
    
    % We have also discovered that some lines have negative depths coming
    % from Tobii, which is surely weird. We should not take those lines
    % into account, we don't know if the rest of the info is correct...
    %
    % ==NOTE== This could be merged with the previous snippet of code, you
    % see they are similar. I'm kippng them separated for the sake of
    % readability
    %
    % You could merge it with the other with something like
    % rowsWithZeros = rowsWithZeros | rowsWithNegDepth
    % i.e., using logical operators

    % Find all rows where 'gazeDepth' is negative or 0
    rowsWithNegDepth = find(dataRaw.convergence_distance_mm <= 0 );
    % We are remvoing numerical values BUT NOT CHANGING logicals (as
    % before)
    partial_dataRaw = [dataRaw(rowsWithNegDepth, 1:4), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithNegDepth, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(5:7)), ...
        dataRaw(rowsWithNegDepth, 8), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithNegDepth, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(9:11)) ...
        dataRaw(rowsWithNegDepth, 12), ...
        array2table(repmat([NaN], size(rowsWithNegDepth, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(13)) ...
        dataRaw(rowsWithNegDepth, 14), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithNegDepth, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(15:17)) ...
        dataRaw(rowsWithNegDepth, 18), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithNegDepth, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(19:21)) ...
        dataRaw(rowsWithNegDepth, 22), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithNegDepth, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(23:25)) ...
        dataRaw(rowsWithNegDepth, 26), ...
        array2table(repmat([NaN], size(rowsWithNegDepth, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(27)) ...
        dataRaw(rowsWithNegDepth, 28:30), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithNegDepth, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(31:33)) ...
        dataRaw(rowsWithNegDepth, 34), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithNegDepth, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(35:37)) ...
        dataRaw(rowsWithNegDepth, 38), ...
        array2table(repmat([NaN, NaN, NaN], size(rowsWithNegDepth, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(39:41)) ...
        dataRaw(rowsWithNegDepth, 42), ...
        array2table(repmat([NaN], size(rowsWithNegDepth, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(43)) ...
        dataRaw(rowsWithNegDepth, 44:45), ...
        array2table(repmat([NaN, NaN, NaN, NaN, NaN, NaN, NaN], size(rowsWithNegDepth, 1), 1), 'VariableNames', dataRaw.Properties.VariableNames(46:end))];  
    % Change all at once
    dataRaw(rowsWithNegDepth, :) = partial_dataRaw;
    % Debug how many wrong Tobii rows were removed
    fprintf('Fixed %d rows with funky gaze depths\n\n', size(rowsWithNegDepth, 1));
    debug_removed_rows = debug_removed_rows + size(rowsWithNegDepth, 1);
    debug_total_rows = debug_total_rows + size(dataRaw, 1);


    %% CHECKPOINT!
    % If you got here, then it means that dataRaw now contains all valid
    % data, and no more invalid Tobii rows, zero-like rows, gaps, etc. are
    % there, and all the session is properly organized.


    %% UNIFY COORDINATE SYSTEMS AND DO REQUIRED TRANSFORMATIONS FOR HEAD INFO
    % Head data is currently in Unity space, we need to change it to MATLAB
    % space, following transformations as stated above.
    % This is head orientation (Quaternion)
    % Note that we had the opposite handness (-w) and forward (-x) and
    % right (-z) vectors go the other way.
    headOriQ = [dataRaw.headpose_rotation_w -dataRaw.headpose_rotation_z -dataRaw.headpose_rotation_x dataRaw.headpose_rotation_y]; 
    % This is head position (3D vector). Same as before applies.
    headPos = [-dataRaw.headpose_position_z -dataRaw.headpose_position_x dataRaw.headpose_position_y];
    % This is trial the user is conducting, for now we assume only Trial 1
    trial = ones(size(timestamp))*1;
    
    % Store headFrame data.
    headFrameData = array2table([headOriQ headPos timestamp], 'VariableNames', ...
        {'qW', 'qX', 'qY', 'qZ', 'posX', 'posY', 'posZ', 'timestamp'});
    % For posterior calculations, we want to have this in mm.
    headFrameData{:, 5:7} = headFrameData{:, 5:7} * 1000;

    %% UNIFY COORDINATE SYSTEMS AND DO REQUIRED TRANSFORMATIONS FOR GAZE INFO
    % Gaze data is currently in Tobii space, we need to change it to MATLAB
    % Gaze origin from Tobii's calculations is in mm, we change it to m. 
    gazeOrigin = [dataRaw.gaze_origin_combined_mm_xyz_z / 1000, dataRaw.gaze_origin_combined_mm_xyz_x / 1000, dataRaw.gaze_origin_combined_mm_xyz_y / 1000];
    % Gaze direction from Tobii's calculations, it is already normalized!
    gazeVec = [dataRaw.gaze_direction_combined_normalized_xyz_z, dataRaw.gaze_direction_combined_normalized_xyz_x, dataRaw.gaze_direction_combined_normalized_xyz_y];
    % Vergence distance (i.e., depth), in mm.
    depth = dataRaw.convergence_distance_mm/1000;
    % With gaze origin and direction, we can calculate gaze points (in m)
    gazePoints = (gazeOrigin + gazeVec .* depth) .* 1000;
    % Whether convergence was valid w.r.t. to Tobii's calculations
    convergence_distance_validity = dataRaw.convergence_distance_validity;
    % With gaze direction, we can calculate the polar coordinates
    azimuthH = -atan2d(gazeVec(:, 2), gazeVec(:, 1));
    elevationH = atan2d(gazeVec(:, 3), sqrt( gazeVec(:, 1).^2 + gazeVec(:, 2).^2) );
    % Finally, check whether the user was blinking
    blinkFlag = (dataRaw.left_blink + dataRaw.right_blink)/2;

    % Store eyeFrame data
    eyeFrameData = array2table([gazeOrigin gazePoints gazeVec * 1000 azimuthH elevationH depth blinkFlag timestamp trial], 'VariableNames', ...
        {'eyePosHeadX', 'eyePosHeadY', 'eyePosHeadZ', 'gazePosHeadX', 'gazePosHeadY', 'gazePosHeadZ', ...
         'gazeVecHeadX', 'gazeVecHeadY', 'gazeVecHeadZ', ...
         'gazeOriHeadX', 'gazeOriHeadY', 'gazeDepth', 'blinkFlag', 'timestamp', 'trial'});

    % This is inherited from Xiuyun, not sure how it works but I'm not
    % removing it :)
    %     % Re. Whether do alignTime or not:
    %     % If you don't have long-duration of missing frames and the head and eye data are
    %     % already aligned, you can skip this step;
    %     % If you might have long-duration of missing frames (during which data
    %     % should not be interpolated), or need to align head/eye data, or wants
    %     % to resampling to a different sampling rate, use the function below.
    %     % "missing frames" meaning that the timestamps are missing, not just no
    %     % signals but with timestamps
    %     [eyeTrial.sampleRate, eyeTrial.eyeAligned, eyeTrial.headAligned] = alignTime(eyeFrameData, 'headFrameTrial', headFrameData, 'sampleRateDesired', 240);
    
    
    %% PREPARE DATA IN WORLD SPACE
    % We first rotate the gaze vector in head space by the head space
    % quarternion. Note that both gazeVec and headFrameData already follow
    % MATLAB coordinate system, therefore axes are properly ordered and
    % have correct sign. We just want to apply the rotation as a coordinate
    % system transformation.
    % This is only a direction vector, and thus we do NOT need to add any
    % head position offset. 
    gazeVecWorld = rotatepoint(quaternion(headFrameData{:, 1:4}), gazeVec); 
    % We do something similar with gaze points, however in this case we DO
    % need to take into account head position offset.
    gazePointsWorld = rotatepoint(quaternion(headFrameData{:, 1:4}), gazePoints) + headFrameData{:, 5:7};
    % Finally, we calculate polar coordinates as above following the same
    % trend.
    gazeOriWorld = [-atan2d(gazeVecWorld(:, 2), gazeVecWorld(:, 1)) ...
        atan2d(gazeVecWorld(:, 3), sqrt( gazeVecWorld(:, 1).^2 + gazeVecWorld(:, 2).^2) )];

    % Store eyeFrame data in world space
    eT_eA = [eyeFrameData array2table([gazePointsWorld gazeVecWorld*1000 gazeOriWorld], 'VariableNames', ...
            {'gazePosWorldX', 'gazePosWorldY', 'gazePosWorldZ', ...
            'gazeVecWorldX', 'gazeVecWorldY', 'gazeVecWorldZ', ...
            'gazeOriWorldX', 'gazeOriWorldY'})];

    
    %% SAVE ALL TRACES FOR POSTERIOR PROCESSING
    % Check if same user but new session or new user. If that's the case,
    % we overwrite previous variable.
    if ((isequal(userID, prevUserID) && ~isequal(day, prevDay)) || ~isequal(userID, prevUserID))
        eyeTrial.headAligned = headFrameData;
        eyeTrial.sampleRate = 240; 
        eyeTrial.eyeAligned = eT_eA;
    end
    % If same user and same session, then just accumulate!
    if (isequal(userID, prevUserID) && isequal(day, prevDay))
        eyeTrial.headAligned = vertcat(eyeTrial.headAligned, headFrameData); 
        eyeTrial.eyeAligned = vertcat(eyeTrial.eyeAligned, eT_eA);
    end
    % Update timestamp accumulation for next file, just in case.
    timestamp_accum = timestamp_accum + dataRaw.TimeMicroSec(end) ./ 1000000;

    % Finally update "previous" user info for next iteration
    try
        if sum(dataRaw.UseEyeTrackedDistortion == 1) > sum(dataRaw.UseEyeTrackedDistortion == 0)
            prevETDDC = 1;
        else
            prevETDDC = 0;
        end
    catch
        % Initialize variables to count occurrences of 0s and 1s
        count_zeros = 0;
        count_ones = 0;
        
        % Iterate over each cell in the cell array
        for i = 1:numel(dataRaw.UseEyeTrackedDistortion)
            % Check if the cell contains a scalar or a vector
            cell_content = dataRaw.UseEyeTrackedDistortion{i};
            
            % If the content is a scalar, increment the corresponding count
            if isscalar(cell_content)
                if cell_content == 0
                    count_zeros = count_zeros + 1;
                elseif cell_content == 1
                    count_ones = count_ones + 1;
                else
                    error('Invalid value in the cell array.'); % Handle invalid values
                end
            % If the content is a vector, increment counts based on its elements
            elseif isvector(cell_content)
                count_zeros = count_zeros + sum(cell_content == 0);
                count_ones = count_ones + sum(cell_content == 1);
            else
                error('Invalid content in the cell array.'); % Handle invalid content
            end
        end
    end
    prevUserID = userID;
    prevDay = day;
    n_files = n_files + 1;
    if (mod(n_files, 2) == 0)
        game_durations.dur = [game_durations.dur ; timestamp_accum];
        timestamp_accum = 0;
    end
    
end

% Store last session
game_durations.dur = [game_durations.dur ; timestamp_accum];
all_user_info = [all_user_info ; ...
    {prevUserID, current_session, prevDay, ...
    game_durations, ...
    prevETDDC, files, eyeTrial, thisUserCalibration}];

% Once we are here, all files have been processed
for i = 1:height(all_user_info)
    % Check for ascending order and find discrepancies. If this message
    % pops-up, it means that something has broken. Timestamps should always
    % be ascending, albeit having some gaps. Check everything if this
    % appears.
    discrepancies = find(diff(all_user_info.EyeTrial{i}.headAligned.timestamp) < 0);
    if ~isempty(discrepancies) && size(discrepancies, 1) == 3
        fprintf('All four games split properly.\n');
    else
        fprintf('User %s Session %d - Discrepancies found at indices: \n', all_user_info.UserID(i), all_user_info.Session(i));
        disp(discrepancies);
    end
end

% Save this user file
save(['data\pre_processed\study2\P027-fixed-S2-prep-data.mat'], 'all_user_info', '-v7.3')

toc;                    % Just for performance measurements.
% disp('Data pre-processed properly');
% processAllData;         % Run data processing after this (if required)

%%

function txtFiles = getAllTxtFiles(directory)
    % Initialize the cell array to store the file names
    txtFiles = {};

    % Get a list of all files and folders in the directory
    listing = dir(directory);

    % Iterate through the entries in the directory
    for i = 1:length(listing)
        entry = listing(i);

        % Check if the entry is a directory and not '.' or '..'
        if entry.isdir && ~strcmp(entry.name, '.') && ~strcmp(entry.name, '..')
            % Recursively call the function for subdirectories
            subDir = fullfile(directory, entry.name);
            txtFiles = [txtFiles; getAllTxtFiles(subDir)];
        elseif ~entry.isdir
            % Check if the entry is a .txt file
            [~,~,ext] = fileparts(entry.name);
            if strcmp(ext, '.txt')
                % Add the file name to the list
                txtFiles = [txtFiles; fullfile(directory, entry.name)];
            end
        end
    end
end