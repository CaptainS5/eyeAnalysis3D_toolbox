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
datapath = 'G:\.shortcut-targets-by-id\1-tQ5Ewvk-g5Dp2KbJCxnyPx0Wwud3kOZ\ETDDC UXR study folder\De-identified data\Eye tracking data\Study 2 (80 min Gameplay)'; %data\raw\study2\';
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

%% WE SAVE USER INFO IN THIS DATA STRUCTURE
% Define column names and types as a cell array
columnNames = {'UserID', 'Session', 'ETDDC', 'Day', 'fileInfo', 'calibInfo', 'removedStats', 'EyeTrial'};
variableTypes = {'string', 'int8', 'logical', 'string', 'struct', 'struct', 'struct', 'cell'};

tic; % Just for performance measurements.

% For debug purposes
debug_total_rows = 0;
debug_removed_rows = 0;

%% ITERATE OVER ALL USER FILES
fileCount = 0;
for userFileI = 1:length(fileName)
    % Use regular expressions to extract UserID and day
    userMatch = regexp(fileName{userFileI}, userIDPattern, 'tokens');
    if isempty(userMatch)
        continue
    end
    dayMatch = regexp(fileName{userFileI}, dayPattern, 'tokens');

    % Extracted UserID and day
    userID = userMatch{1}{1};
    day = dayMatch{1}{1};
    if fileCount == 0 % the very first file processed
        prevUserID = userID;
        prevDay = day;
        current_session = 1;
    end

    % You can jump users based on ID
    % if str2double(userID) ~= 27
    % continue
    % end

    % You can also jump users that have been already included. 
    % If only one session has been included, you should force the remainder
    % to be the second session.
    cont = false;
    forceSession = false;
 
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

    % Reset variables 
    sub_file_info = table('Size', [0, length(columnNames)], 'VariableNames', columnNames,  'VariableTypes', variableTypes);
   
    fileInfo = [];
    % Store the path
    idxT = strfind(fileName{userFileI}, '\');
    fileInfo.name = fileName{userFileI}(idxT(end)+1:end);
    
    calibInfo = [];
    removedStats = [];

    eyeTrial = [];
    fileCount = fileCount + 1;
    
    if (isequal(userID, prevUserID) && ~isequal(day, prevDay))
        % Same user but second session
        current_session = 2;
        fileCount = 1;
    elseif ~isequal(userID, prevUserID)
        % different user, first session
        current_session = 1;
        fileCount = 1;
    end
    fileInfo.count = fileCount;
    
    % Display the current user, for visualization purposes
    fprintf(['UserID ', userID, ', session ', num2str(current_session), ', file ', num2str(fileCount), '\n']);

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
            calibInfo.result = string(data(calibration_result_indices));
            disp('One calibration result acquired.');
        else
            calibInfo.result = {};
            for jj = 1:num_results
                % Store calibration results.
                calibInfo.result = [calibInfo.result; string(data(calibration_result_indices(jj)))];
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
        varNames = readtable('EyeTrackerLog_00001122_334455.txt', opts);
        varNames = varNames{1, :};
        dataRaw = readtable([fileName{userFileI}], 'Delimiter', ';'); 
        dataRaw.Properties.VariableNames = varNames;
        dataRaw.UseEyeTrackedDistortion = strcmp(dataRaw.UseEyeTrackedDistortion, 'TRUE');

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
    eyeTrial.rawTimestampFull = dataRaw.TimeMicroSec;

    % So far, data has been ready and casted. We still have the raw data
    % structure.

    %% REMOVE ALL ROWS THAT DEPEND ON CALIBRATION
    % There is another (lots of fun, huh?) funky thing going on here: We
    % cannot remove rows dynamically from a table (obviously); otherwise
    % indices get messed up, therefore we need to accumulate all indices
    % that are to be removed, and remove them all at once.
    % These are all the possible cases, nothing fancy but just iteration
    % and removals and some logging messages.
    if ~isempty(calibration_result_indices)
        calibInfo.resultTimestamp = dataRaw.TimeMicroSec(calibration_result_indices);
        if isempty(calibration_started_indices)
            calibInfo.startTimestamp = [];
            removedStats.calibType = 0;
        else
            calibInfo.startTimestamp = dataRaw.TimeMicroSec(calibration_started_indices);
            removedStats.calibType = 1;
        end        
        removedStats.calibRowN = calibration_result_indices(end);
        removedStats.calibDur_sec = (dataRaw.TimeMicroSec(calibration_result_indices(end))-dataRaw.TimeMicroSec(1))/1000000;

        % Some calibration was ended but start is not correctly indicated (?)
        dataRaw(1:calibration_result_indices(end), :) = [];
        %         fprintf('Some calibration was started before. Removed %d rows.\n', calibration_result_indices);
    elseif isempty(calibration_result_indices) && ~isempty(calibration_started_indices)
        calibInfo.resultTimestamp = [];
        calibInfo.startTimestamp = dataRaw.TimeMicroSec(calibration_started_indices);

        removedStats.calibRowN = size(dataRaw, 2) - calibration_started_indices(end);
        removedStats.calibDur_sec = (dataRaw.TimeMicroSec(end)-dataRaw.TimeMicroSec(calibration_started_indices(end)))/1000000;
        removedStats.calibType = -1;
        % Some calibration was started but end is not correctly indicated (?)
        dataRaw(calibration_started_indices(end):end, :) = [];
        fprintf(userID, '_', num2str(current_session), '_some calibration was ended later. Removed %d rows.\n', size(dataRaw, 2) - calibration_started_indices);
        
%     elseif ~isempty(calibration_result_indices) && ~isempty(calibration_started_indices)
%         removedStats.calibRowN = [];
%         removedStats.calibDur_sec = [];
% 
%         calibInfo.startTimestamp = dataRaw.TimeMicroSec(calibration_start_indices);
%         calibInfo.resultTimestamp = dataRaw.TimeMicroSec(calibration_result_indices);
% %         if num_starts==num_results
% 
%         % If a log has calibration results, we can assume that is the
%         % beginning of the game. Similarly, if there are more than one, we
%         % just trust the last one, i.e., remove everything until that
%         last_calibration_results = calibration_result_indices(end);
%         dataRaw(1:last_calibration_results, :) = [];
%         fprintf(userID, '_', num2str(current_session), '_multiple calibration: Removed %d rows.\n',last_calibration_results);
%         removedStats.calibRowN = [removedStats.calibRowN; last_calibration_results];
%         removedStats.calibDur_sec = [removedStats.calibDur_sec; ...
%             (dataRaw.TimeMicroSec(last_calibration_results)-dataRaw.TimeMicroSec(1))/1000];
%         removedStats.calibType = 3;
% 
%         % % Both were somehow correctly logged
%         % if num_starts == num_results
%         %     if num_results == 1
%         %        dataRaw(calibration_started_indices:calibration_result_indices, :) = [];
%         %        fprintf('Other weird cases: Removed %d rows.\n',calibration_result_indices-calibration_started_indices);
%         %     else
%         %         rowsToRemove = [];
%         %         for j = 1:num_starts
%         %              rowsToRemove = [rowsToRemove, calibration_started_indices(j):calibration_result_indices(j)];
%         %         end
%         %         dataRaw(rowsToRemove, :) = [];
%         %         fprintf('Other weird cases: Removed %d rows.\n',size(rowsToRemove, 2));
%         %     end
%         % % Sometimes there are results without starting / ending flag
%         % else
%         %     rowsToRemove = [];
%         %     if num_starts > num_results
%         %         % Remove the last lines corresponding to the unfinished
%         %         % calibration
%         %         rowsToRemove = calibration_started_indices(end):height(dataRaw);
%         %         calibration_started_indices = calibration_started_indices(1:end-1);
%         %     elseif num_results > num_starts
%         %         % Remove the first lines corresponding to the unfinished
%         %         % calibration
%         %         rowsToRemove = 1:calibration_result_indices(1);
%         %         calibration_result_indices = calibration_result_indices(2:end);
%         %     end
%         %     % Once we removed the uneven ones, remove the paired ones.
%         %     for j = 1:numel(calibration_result_indices)
%         %        rowsToRemove = [rowsToRemove, calibration_started_indices(j):calibration_result_indices(j)];
%         %     end
%         %     % And finally remove all.
%         %     dataRaw(rowsToRemove, :) = [];
%         %     fprintf('Other weird cases: Removed %d rows.\n',size(rowsToRemove, 2));
%         % end       
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
        removeStats.headEmptyTimestamp = dataRaw.TimeMicroSec(idx);
%         removedStats.headEmptyRowN = length(idx);
%         removedStats.headEmptyDur_sec = (dataRaw.TimeMicroSec(idx(end))-dataRaw.TimeMicroSec(idx(1)))/1000000;
        dataRaw(idx, :) = [];
    catch exception
        % Remove other lines with no info
        idx = find(cellfun('isempty', num2cell(dataRaw.headpose_position_x)));
        removeStats.headEmptyTimestamp = dataRaw.TimeMicroSec(idx);
%         removedStats.headEmptyRowN = length(idx);
%         removedStats.headEmptyDur_sec = (dataRaw.TimeMicroSec(idx(end))-dataRaw.TimeMicroSec(idx(1)))/1000000;
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
    eyeTrial.rawTimestampAfterCleaning = dataRaw.TimeMicroSec;
    % First get the relative timestamp in the current file
    % Then account for the accumulated from previous timestamps
    timestamp = (dataRaw.TimeMicroSec - dataRaw.TimeMicroSec(1)) ./ 1000000; % + timestamp_accum;
    
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
    removedStats.eyeZerosIdx = rowsWithZeros;
    removedStats.eyeZerosRawTime = dataRaw.TimeMicroSec(rowsWithZeros);
    
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
    removedStats.invalidDepthIdx = rowsWithNegDepth;
    removedStats.invalidDepthRawTime = dataRaw.TimeMicroSec(rowsWithNegDepth);
    % Debug how many wrong Tobii rows were removed
    fprintf('Fixed %d rows with funky gaze depths\n\n', size(rowsWithNegDepth, 1));
    debug_removed_rows = debug_removed_rows + size(rowsWithNegDepth, 1);
    debug_total_rows = debug_total_rows + size(dataRaw, 1);


    %% CHECKPOINT!
    % If you got here, then it means that dataRaw now contains all valid
    % data, and no more invalid Tobii rows, zero-like rows, gaps, etc. are
    % there, and all the session is properly organized.


    %% UNIFY COORDINATE SYSTEMS AND DO REQUIRED TRANSFORMATIONS FOR HEAD INFO
    % Head data is currently in a right-handed system with x+=right, y+=up, z+=backward
    % This is head orientation (Quaternion)
    headOriQ = [dataRaw.headpose_rotation_w -dataRaw.headpose_rotation_z -dataRaw.headpose_rotation_x dataRaw.headpose_rotation_y]; 
    % This is head position (3D vector). Same as before applies.
    headPos = [-dataRaw.headpose_position_z -dataRaw.headpose_position_x dataRaw.headpose_position_y];
    % This is trial the user is conducting, for now we assume only Trial 1
    trial = ones(size(timestamp))*1;
    % Now we change the head coordinate system into Matlab plot3 default, 
    % x+ forward, y+left, z+up 
    
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
    gazePoints = (gazeOrigin + gazeVec .* depth); % .* 1000;
    % Whether convergence was valid w.r.t. to Tobii's calculations
    convergence_distance_validity = dataRaw.convergence_distance_validity;
    % With gaze direction, we can calculate the polar coordinates
    azimuthH = -atan2d(gazeVec(:, 2), gazeVec(:, 1));
    elevationH = atan2d(gazeVec(:, 3), sqrt( gazeVec(:, 1).^2 + gazeVec(:, 2).^2) );
    % Finally, check whether the user was blinking
    blinkFlag = (dataRaw.left_blink + dataRaw.right_blink)/2;
    blinkFlag(rowsWithNegDepth) = -1; % these are not blinks, just wrong depth

    % Store eyeFrame data
    eyeFrameData = array2table([gazeOrigin gazePoints gazeVec azimuthH elevationH depth blinkFlag timestamp trial], 'VariableNames', ...
        {'eyePosHeadX', 'eyePosHeadY', 'eyePosHeadZ', 'gazePosHeadX', 'gazePosHeadY', 'gazePosHeadZ', ...
         'gazeDirHeadX', 'gazeDirHeadY', 'gazeDirHeadZ', ...
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
    eT_eA = [eyeFrameData array2table([gazePointsWorld gazeVecWorld gazeOriWorld], 'VariableNames', ...
            {'gazePosWorldX', 'gazePosWorldY', 'gazePosWorldZ', ...
            'gazeDirWorldX', 'gazeDirWorldY', 'gazeDirWorldZ', ...
            'gazeOriWorldX', 'gazeOriWorldY'})];

    
    %% SAVE ALL TRACES FOR POSTERIOR PROCESSING
    eyeTrial.headAligned = headFrameData;
    eyeTrial.sampleRate = 240;
    eyeTrial.eyeAligned = eT_eA;

    if sum(dataRaw.UseEyeTrackedDistortion == 1) > sum(dataRaw.UseEyeTrackedDistortion == 0)
        ETDDC = 1;
    else
        ETDDC = 0;
    end

    % Store current file
    sub_file_info = {userID, current_session, ETDDC, day, ...
        fileInfo, calibInfo, removedStats, eyeTrial};
    save(['C:\Users\xiuyunwu\Downloads\ETDDC\preprocessed data\prep_', userID, '_s', num2str(current_session), '_f', num2str(fileInfo.count), '.mat'], 'sub_file_info', '-v7.3')

    prevUserID = userID;
    prevDay = day;
end
toc;                    % Just for performance measurements.
disp('Data pre-processing done');

processAllData_perFile;

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