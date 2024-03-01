% script to load data and getting prepared for eye analysis
% customize to prepare your raw data here; see readMe.md for
% the final output needed for the eye movement analysis pipeline pre-processing
% head and target data are optional
clc; close all; clear
addpath(genpath('functions'))

datapath = 'data\raw\';
[status, msg, msgID] = mkdir([datapath, '..\pre_processed']);
fileName = {'head_move_sample_data_VFoV_study.mat'}; 

for trialI = 1:length(fileName) % assuming each file is recording of one "trial"; 
    % metadata not sorted here, just eye/head traces
    eyeTrial = [];

    %% load raw data
    dataRaw = load([datapath, fileName{trialI}]);


%     opts = delimitedTextImportOptions('Delimiter', ';');%, 'DataLines', [1, 2]);
%     varNames = readtable([datapath, fileName{trialI}], opts);
%     varNames = varNames{1, :};
%     dataRaw = readtable([datapath, fileName{trialI}], 'Delimiter', ';'); % if it's already sorted into csv or similar tables

%     % cleaning the data
%     dataRaw.Properties.VariableNames = varNames;
%     idx = find(cellfun(@isempty, dataRaw.headpose_position_x));
%     dataRaw(idx, :) = [];
%     dataRaw.headpose_rotation_w = cellfun(@str2num, dataRaw.headpose_rotation_w);
%     dataRaw.headpose_rotation_x = cellfun(@str2num, dataRaw.headpose_rotation_x);
%     dataRaw.headpose_rotation_y = cellfun(@str2num, dataRaw.headpose_rotation_y);
%     dataRaw.headpose_rotation_z = cellfun(@str2num, dataRaw.headpose_rotation_z);
%     dataRaw.headpose_position_x = cellfun(@str2num, dataRaw.headpose_position_x);
%     dataRaw.headpose_position_y = cellfun(@str2num, dataRaw.headpose_position_y);
%     dataRaw.headpose_position_z = cellfun(@str2num, dataRaw.headpose_position_z);
%     dataRaw.left_blink(strcmp(dataRaw.left_blink, 'FALSE')) = {0};
%     dataRaw.left_blink(strcmp(dataRaw.left_blink, 'TRUE')) = {1};
%     dataRaw.right_blink(strcmp(dataRaw.right_blink, 'FALSE')) = {0};
%     dataRaw.right_blink(strcmp(dataRaw.right_blink, 'TRUE')) = {1};
%     dataRaw.left_blink = cell2mat(dataRaw.left_blink);
%     dataRaw.right_blink = cell2mat(dataRaw.right_blink);

    % the sorted coordinate system is x+=forward, y+=left, z+=up, right-handed rotation,
    % following the matlab plot3 default

    %% sort head data
    % raw data coordinate system is Oculus (head):
    % x+=right, y+=up, z+=backward, left-handed rotation.
    % flip to Matlab plot3 convention, x+=forward, y+=left, z+=up, right-handed 
    headOriQ = [-dataRaw.data_for_xw.head_rot_wxyz(:, 1) -dataRaw.data_for_xw.head_rot_wxyz(:, 4) ...
        -dataRaw.data_for_xw.head_rot_wxyz(:, 2) dataRaw.data_for_xw.head_rot_wxyz(:, 3)];
    headPos = [-dataRaw.data_for_xw.head_trans_xyz(:, 3) -dataRaw.data_for_xw.head_trans_xyz(:, 1) dataRaw.data_for_xw.head_trans_xyz(:, 2)];
    timestamp = dataRaw.data_for_xw.timestamp; % in seconds
    % calculate head position in Euler angles
    eulZYX = quat2eul(headOriQ)/pi*180;

%     trial = ones(size(timestamp))*trialI;
    headFrameData = array2table([headOriQ headPos eulZYX timestamp], 'VariableNames', ...
        {'qW', 'qX', 'qY', 'qZ', 'posX', 'posY', 'posZ', 'ori_yaw', 'ori_pitch', 'ori_roll', 'timestamp'});
%     headFrameData = array2table([headOriQ headPos timestamp trial], 'VariableNames', ...
%         {'qW', 'qX', 'qY', 'qZ', 'posX', 'posY', 'posZ', 'timestamp', 'trial'});

    %% sort eye data
%     % for Tobii, raw data coordinates are x+=left, y+=up, z+=forward
% 
%     % calculate cyclopean eye data based on binocular data
%     leftEyePos = [dataRaw.left_gaze_origin_mm_xyz_z dataRaw.left_gaze_origin_mm_xyz_x dataRaw.left_gaze_origin_mm_xyz_y]';
%     rightEyePos = [dataRaw.right_gaze_origin_mm_xyz_z dataRaw.right_gaze_origin_mm_xyz_x dataRaw.right_gaze_origin_mm_xyz_y]';
%     leftEyeDir = [dataRaw.left_gaze_direction_normalized_xyz_z dataRaw.left_gaze_direction_normalized_xyz_x dataRaw.left_gaze_direction_normalized_xyz_y]';
%     rightEyeDir = [dataRaw.right_gaze_direction_normalized_xyz_z dataRaw.right_gaze_direction_normalized_xyz_x dataRaw.right_gaze_direction_normalized_xyz_y]';
% 
%     [verDist verAngle gazePoints] = getVergence(leftEyePos, leftEyeDir, rightEyePos, rightEyeDir);
%     % since the original coordinates are in mm, verDist is in mm
%     % verAngle is in degs
%     % gaze points are the calculated intersection point of gaze
%     % note that the gaze points here are in the transformed coordinate system, x+ forward, y+ left, z+ up
%     % if the gaze directions are parallel, verDist = inf, verAngle = NaN;
%     % if verDist = NaN, it's mostly likely that the gaze direction is [0, 0, 0], which is missing signal for Tobii Crystal
%     depth = verDist'/1000; % in meters
% 
%     gazeOrigin = (leftEyePos+rightEyePos)/2; % cyclopean eye
%     gazeVec = (gazePoints-gazeOrigin)'; % in transformed coordinate system
%     azimuthH = -atan2d(gazeVec(:, 2), gazeVec(:, 1));
%     elevationH = atan2d(gazeVec(:, 3), sqrt( gazeVec(:, 1).^2 + gazeVec(:, 2).^2) );
% 
%     blinkFlag = (dataRaw.left_blink + dataRaw.right_blink)/2;
% 
%     timestamp = dataRaw.TimeMicroSec/1000000;
%     trial = ones(size(timestamp))*trialI;
%     eyeFrameData = array2table([gazeOrigin' gazePoints' azimuthH elevationH depth blinkFlag timestamp trial], 'VariableNames', ...
%         {'eyePosHeadX', 'eyePosHeadY', 'eyePosHeadZ', 'gazePosHeadX', 'gazePosHeadY', 'gazePosHeadZ', ...
%         'gazeOriHeadX', 'gazeOriHeadY', 'gazeDepth', 'blinkFlag', 'timestamp', 'trial'});
%     % "eyePosHead" is the cyclopean eye position in eye tracker coordinates;
%     % "gazePosHead" is the gaze point in eye tracker coordinates;
%     % gazeOri is azimuth and elevation; azimuth forward is 0, left is negative; 
%     % elevation forward is 0, down is negative; 
%     % depth is in meters
%     % "gazeOriHead" is eye in head gaze angle; gazeOriWorld and gazePosWorld will be
%     % calculated later after time alignment of eye and head
%     % blink possible: 1 if both left&right_blink, 0.5 if only one, 0 if neither
% 
%     %     % Re. whether do alignTime or not:
%     %     % If you don't have long-duration of missing frames and the head and eye data are
%     %     % already aligned, you can skip this step;
%     %     % If you might have long-duration of missing frames (during which data
%     %     % should not be interpolated), or need to align head/eye data, or wants
%     %     % to resampling to a different sampling rate, use the function below.
%     %     % "missing frames" meaning that the timestamps are missing, not just no
%     %     % signals but with timestamps
%     %     [eyeTrial.sampleRate, eyeTrial.eyeAligned, eyeTrial.headAligned] = alignTime(eyeFrameData, 'headFrameTrial', headFrameData, 'sampleRateDesired', 240);
%     
%     % if not doing the alignTime.m, just put the original data in, and manually put in the sampleRate
%     % the sampleRate is mostly a reference for filtering choices
    eyeTrial.headAligned = headFrameData;
    eyeTrial.sampleRate = round(1./mode(diff(headFrameData.timestamp)));
% 
%     % calculate gaze position and orientation in world
%     % note that here gazeOriWorld is mostly re. body, eye + head rotation
%     % gazePosWorld is the gaze points in the world coordinates, taken into
%     % account both head translation and rotation
% 
%     % here we just assume the eye tracker coordinate system is the same as
%     % the device/head coordinate system; so rotate eye by head is world
%     eyeHeadRot = rotatepoint(quaternion(headFrameData{:, 1:4}), gazeVec); % apply head rotation
%     gazePosWorld = eyeHeadRot + headFrameData{:, 5:7}; % add head translation... what's the unit for head position?
%     %     eyePosWorld = gazeOrigin + headFrameData{:, 5:7};
% 
%     % ideally gazeOriWorld should be calculated on the gaze vec in world,
%     % gazePosWorld-eyePosWorld... let's figure out the head translation unit
%     % first
% 
%     gazeOriWorld = [-atan2d(eyeHeadRot(:, 2), eyeHeadRot(:, 1)) ...
%         atan2d(eyeHeadRot(:, 3), sqrt( eyeHeadRot(:, 1).^2 + eyeHeadRot(:, 2).^2) )]; % just applied head rotation for now
% 
%     eyeTrial.eyeAligned = [eyeFrameData array2table([gazePosWorld gazeOriWorld], 'VariableNames', ...
%         {'gazePosWorldX', 'gazePosWorldY', 'gazePosWorldZ', ...
%         'gazeOriWorldX', 'gazeOriWorldY'})];    

    save([datapath, '..\pre_processed\data', num2str(trialI), '.mat'], 'eyeTrial')
end