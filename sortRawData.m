% script to load data and getting prepared for eye analysis
% customize to prepare your raw data here; see readMe.md for
% the final output needed for the eye movement analysis pipeline pre-processing
% head and target data are optional
clc; close all; clear all; warning off
addpath(genpath('functions'))

datapath = 'data\raw\';
[status, msg, msgID] = mkdir([datapath, '..\pre_processed']);
fileName = {'tobiipublisher.json'};

% some format prep...
rawVarNames_eye = {'left_gaze_origin_x', 'left_gaze_origin_y', 'left_gaze_origin_z', 'left_gaze_direction_x', 'left_gaze_direction_y', 'left_gaze_direction_z', ...
    'left_pupil_center_x', 'left_pupil_center_y', 'left_pupil_center_z', 'left_pupil_entrance_x', 'left_pupil_entrance_y', 'left_pupil_entrance_z', ...
    'left_pupil_diameter', ... %'left_blink', 
    'right_gaze_origin_x', 'right_gaze_origin_y', 'right_gaze_origin_z', 'right_gaze_direction_x', 'right_gaze_direction_y', 'right_gaze_direction_z', ...
    'right_pupil_center_x', 'right_pupil_center_y', 'right_pupil_center_z', 'right_pupil_entrance_x', 'right_pupil_entrance_y', 'right_pupil_entrance_z', ...
    'right_pupil_diameter', ... %'right_blink', 
    'combined_gaze_origin_x', 'combined_gaze_origin_y', 'combined_gaze_origin_z', 'combined_gaze_direction_x', 'combined_gaze_direction_y', 'combined_gaze_direction_z', ...
    'combined_gaze_point_x', 'combined_gaze_point_y', 'combined_gaze_point_z', 'timestamp'}; % variable names for the dataRaw table

fileVarNames_eye = {'left_eye.gaze.gaze_origin.z', 'left_eye.gaze.gaze_origin.x', 'left_eye.gaze.gaze_origin.y', 'left_eye.gaze.gaze_direction.z', 'left_eye.gaze.gaze_direction.x', 'left_eye.gaze.gaze_direction.y', ...
    'left_eye.pupil_center.z', 'left_eye.pupil_center.x', 'left_eye.pupil_center.y', 'left_eye.pupil_entrance.z', 'left_eye.pupil_entrance.x', 'left_eye.pupil_entrance.y', ...
    'left_eye.pupil_diameter', ... %'left_blink', 
    'right_eye.gaze.gaze_origin.z', 'right_eye.gaze.gaze_origin.x', 'right_eye.gaze.gaze_origin.y', 'right_eye.gaze.gaze_direction.z', 'right_eye.gaze.gaze_direction.x', 'right_eye.gaze.gaze_direction.y', ...
    'right_eye.pupil_center.x', 'right_eye.pupil_center.y', 'right_eye.pupil_center.z', 'right_eye.pupil_entrance.x', 'right_eye.pupil_entrance.y', 'right_eye.pupil_entrance.z', ...
    'right_eye.pupil_diameter', ... %'left_blink', 
    'combined.gaze.gaze_origin.z', 'combined.gaze.gaze_origin.x', 'combined.gaze.gaze_origin.y', 'combined.gaze.gaze_direction.z', 'combined.gaze.gaze_direction.x', 'combined.gaze.gaze_direction.y', ...
    'combined.gaze_point.z', 'combined.gaze_point.x', 'combined.gaze_point.y', 'timestamp.nanoseconds'}; % variable names from the json file
% note that here we switched the axis already

rawVarNames_head = {'trans_x', 'trans_y', 'trans_z', ...
    'ori_Qw', 'ori_Qx', 'ori_Qy', 'ori_Qz'}; % variable names for the dataRaw table

fileVarNames_head = {'translation.z', 'translation.x', 'translation.y', ...
    'rotation.w', 'rotation.z', 'rotation.x', 'rotation.y'}; % variable names from the json file
% note that here we switched the axis already

for fileI = 1:length(fileName)
    eyeTrial = [];

    %% sort head data
    % raw data is in meters and seconds, seems to be the same as the Tobii
    % system, x+=left, y+=up, z+=forward, seems to be right-handed rotation already
    jsonStr = fileread([datapath, 'example.json']);
    % delete the dashes...
    jsonStr = regexprep(jsonStr, '---', ',');
    jsonStr = ['[' jsonStr(1:end-2) ']'];

    % Convert JSON string to MATLAB variables
    jsonData = jsondecode(jsonStr);

    % organize the raw data
    headRaw = table();
    for ii = 1:size(jsonData, 1)
        for jj = 1:length(rawVarNames_head)
            if ~isempty(eval(['jsonData(ii).transform.', fileVarNames_head{jj}]))
                headRaw.(rawVarNames_head{jj})(ii, 1) = eval(['jsonData(ii).transform.', fileVarNames_head{jj}]);
            else
                headRaw.(rawVarNames_head{jj})(ii, 1) = NaN;
            end
        end
    end
    % the axis switch is done; the sorted coordinate system is 
    % x+=forward, y+=left, z+=up, right-handed rotation, following the matlab plot3 default

    % sanity check, plot to see the coordinate systems
    figure
    % orientation
    headOriQ = [headRaw.ori_Qw headRaw.ori_Qx headRaw.ori_Qy headRaw.ori_Qz];
    eulYPR = quat2eul(headOriQ)/pi*180;

    subplot(3, 2, 1)
    plot(-eulYPR(:, 1))
    ylabel('azimuth')
    
    subplot(3, 2, 3)
    plot(-eulYPR(:, 2))
    ylabel('elevation')

    subplot(3, 2, 5)
    plot(eulYPR(:, 3))
    ylabel('roll (left negative)')

    % translation
    subplot(3, 2, 2)
    plot(headRaw.trans_x)
    ylabel('x')
    
    subplot(3, 2, 4)
    plot(headRaw.trans_y)
    ylabel('y')

    subplot(3, 2, 6)
    plot(headRaw.trans_z)
    ylabel('z')

    headPos = [headRaw.tran_x headRaw.trans_y headRaw.trans_z];
%     timestamp = eyeRaw.TimeMicroSec./1000000; % in seconds
%     file = ones(size(timestamp))*fileI;
%     headFrameData = array2table([headOriQ headPos timestamp file], 'VariableNames', ...
%         {'qW', 'qX', 'qY', 'qZ', 'posX', 'posY', 'posZ', 'timestamp', 'trial'});

    %% sort eye data
    % for Tobii, raw data coordinates are x+=left, y+=up, z+=forward
    % Read JSON data from a file
    jsonStr = fileread([datapath, fileName{fileI}]);
    % Convert JSON string to MATLAB variables
    jsonData = jsondecode(jsonStr);

    % organize the raw data
    eyeRaw = table();
    for ii = 1:size(jsonData.data, 1)
        for jj = 1:length(rawVarNames_eye)
            if ~isempty(eval(['jsonData.data(ii).estimates.', fileVarNames_eye{jj}]))
                eyeRaw.(rawVarNames_eye{jj})(ii, 1) = eval(['jsonData.data(ii).estimates.', fileVarNames_eye{jj}]);
            else
                eyeRaw.(rawVarNames_eye{jj})(ii, 1) = NaN;
            end
        end
        %         eyeRaw.left_blink(strcmp(eyeRaw.left_blink, 'FALSE')) = {0};
        %         eyeRaw.left_blink(strcmp(eyeRaw.left_blink, 'TRUE')) = {1};
        %         eyeRaw.right_blink(strcmp(eyeRaw.right_blink, 'FALSE')) = {0};
        %         eyeRaw.right_blink(strcmp(eyeRaw.right_blink, 'TRUE')) = {1};
        %         eyeRaw.left_blink = cell2mat(eyeRaw.left_blink);
        %         eyeRaw.right_blink = cell2mat(eyeRaw.right_blink);
    end
    % the axis switch is done; the sorted coordinate system is 
    % x+=forward, y+=left, z+=up, following the matlab plot3 default

    % calculate cyclopean eye data based on binocular data
    leftEyePos = [eyeRaw.left_gaze_origin_x eyeRaw.left_gaze_origin_y eyeRaw.left_gaze_origin_z]';
    rightEyePos = [eyeRaw.right_gaze_origin_x eyeRaw.right_gaze_origin_y eyeRaw.right_gaze_origin_z]';
    leftEyeDir = [eyeRaw.left_gaze_direction_x eyeRaw.left_gaze_direction_y eyeRaw.left_gaze_direction_z]';
    rightEyeDir = [eyeRaw.right_gaze_direction_x eyeRaw.right_gaze_direction_y eyeRaw.right_gaze_direction_z]';

    [verDist verAngle gazePoints] = getVergence(leftEyePos, leftEyeDir, rightEyePos, rightEyeDir);
    % since the original coordinates are in mm, verDist is in mm
    % verAngle is in degs
    % gaze points are the calculated intersection point of gaze
    % note that the gaze points here are in the transformed coordinate system, x+ forward, y+ left, z+ up
    % if the gaze directions are parallel, verDist = inf, verAngle = NaN;
    % if verDist = NaN, it's mostly likely that the gaze direction is [0, 0, 0], which is missing signal for Tobii Crystal
    depth = verDist'/1000; % in meters

    gazeOrigin = (leftEyePos+rightEyePos)/2; % cyclopean eye
    gazeVec = (gazePoints-gazeOrigin)'; % in transformed coordinate system
    azimuthH = -atan2d(gazeVec(:, 2), gazeVec(:, 1));
    elevationH = atan2d(gazeVec(:, 3), sqrt( gazeVec(:, 1).^2 + gazeVec(:, 2).^2) );

    % combined data
    gazeDir_c = [eyeRaw.combined_gaze_direction_x eyeRaw.combined_gaze_direction_y eyeRaw.combined_gaze_direction_z];
    azimuthH_c = -atan2d(gazeDir_c(:, 2), gazeDir_c(:, 1));
    elevationH_c = atan2d(gazeDir_c(:, 3), sqrt( gazeDir_c(:, 1).^2 + gazeDir_c(:, 2).^2) );

%     blinkFlag = (eyeRaw.left_blink + eyeRaw.right_blink)/2;

    file = ones(size(eyeRaw.timestamp))*fileI;

    eyeFrameData = array2table([gazeOrigin' gazePoints' azimuthH elevationH depth ...
        eyeRaw.combined_gaze_origin_x eyeRaw.combined_gaze_origin_y eyeRaw.combined_gaze_origin_z ...
        eyeRaw.combined_gaze_point_x eyeRaw.combined_gaze_point_y eyeRaw.combined_gaze_point_z azimuthH_c elevationH_c ... % depth_t blinkFlag
        eyeRaw.timestamp file], 'VariableNames', ...
        {'eyePosHeadX_bino', 'eyePosHeadY_bino', 'eyePosHeadZ_bino', 'gazePosHeadX_bino', 'gazePosHeadY_bino', 'gazePosHeadZ_bino', ...
        'gazeOriHeadX_bino', 'gazeOriHeadY_bino', 'gazeDepth_bino', ...
        'eyePosHeadX_combined', 'eyePosHeadY_combined', 'eyePosHeadZ_combined', 'gazePosHeadX_combined', 'gazePosHeadY_combined', 'gazePosHeadZ_combined', ...
        'gazeOriHeadX_combined', 'gazeOriHeadY_combined', ... %'gazeDepth_tobii', 'blinkFlag', 
        'timestamp', 'fileN'});

%     eyeFrameData = array2table([gazeOrigin' gazePoints' azimuthH elevationH depth blinkFlag timestamp trial], 'VariableNames', ...
%         {'eyePosHeadX', 'eyePosHeadY', 'eyePosHeadZ', 'gazePosHeadX', 'gazePosHeadY', 'gazePosHeadZ', ...
%         'gazeOriHeadX', 'gazeOriHeadY', 'gazeDepth', 'blinkFlag', 'timestamp', 'fileN'});
    % "eyePosHead" is the cyclopean eye position in eye tracker coordinates;
    % "gazePosHead" is the gaze point in eye tracker coordinates;
    % gazeOri is azimuth and elevation; azimuth forward is 0, left is negative;
    % elevation forward is 0, down is negative;
    % depth is in meters
    % "gazeOriHead" is eye in head gaze angle; gazeOriWorld and gazePosWorld will be
    % calculated later after time alignment of eye and head
    % blink possible: 1 if both left&right_blink, 0.5 if only one, 0 if neither

    %     % Re. whether do alignTime or not:
    %     % If you don't have long-duration of missing frames and the head and eye data are
    %     % already aligned, you can skip this step;
    %     % If you might have long-duration of missing frames (during which data
    %     % should not be interpolated), or need to align head/eye data, or wants
    %     % to resampling to a different sampling rate, use the function below.
    %     % "missing frames" meaning that the timestamps are missing, not just no
    %     % signals but with timestamps
    %     [eyeTrial.sampleRate, eyeTrial.eyeAligned, eyeTrial.headAligned] = alignTime(eyeFrameData, 'headFrameTrial', headFrameData, 'sampleRateDesired', 240);

    % if not doing the alignTime.m, just put the original data in, and manually put in the sampleRate
    % the sampleRate is mostly a reference for filtering choices
    eyeTrial.headAligned = headFrameData;
    eyeTrial.sampleRate = 240;

    % calculate gaze position and orientation in world
    % note that here gazeOriWorld is mostly re. body, eye + head rotation
    % gazePosWorld is the gaze points in the world coordinates, taken into
    % account both head translation and rotation

    % here we just assume the eye tracker coordinate system is the same as
    % the device/head coordinate system; so rotate eye by head is world
    eyeHeadRot = rotatepoint(quaternion(headFrameData{:, 1:4}), gazeVec); % apply head rotation
    gazePosWorld = eyeHeadRot + headFrameData{:, 5:7}; % add head translation... what's the unit for head position?
    %     eyePosWorld = gazeOrigin + headFrameData{:, 5:7};

    % ideally gazeOriWorld should be calculated on the gaze vec in world,
    % gazePosWorld-eyePosWorld... let's figure out the head translation unit
    % first

    gazeOriWorld = [-atan2d(eyeHeadRot(:, 2), eyeHeadRot(:, 1)) ...
        atan2d(eyeHeadRot(:, 3), sqrt( eyeHeadRot(:, 1).^2 + eyeHeadRot(:, 2).^2) )]; % just applied head rotation for now

    eyeTrial.eyeAligned = [eyeFrameData array2table([gazePosWorld gazeOriWorld], 'VariableNames', ...
        {'gazePosWorldX', 'gazePosWorldY', 'gazePosWorldZ', ...
        'gazeOriWorldX', 'gazeOriWorldY'})];

    save([datapath, '..\pre_processed\data', num2str(fileI), '.mat'], 'eyeTrial')
end