% script to load data and getting prepared for eye analysis
% customize to prepare your raw data here; see readMe.md for
% the final output needed for the eye movement analysis pipeline pre-processing
% head and target data are optional

% output follows the coordinate system of x+=forward, y+=left, z+=up, right-handed rotation,
% following the matlab plot3 default

clc; close all; clear
addpath(genpath('functions'))

datapath = 'data\raw\';
[status, msg, msgID] = mkdir([datapath, '..\pre_processed']);
% fileName = {'EyeTrackerLog_20230717-141507.txt'};
fileName = {'Button1_tobii.mat'}; % assuming each file is data from one continuous recording

for trialI = 1:length(fileName)
    eyeTrial = [];

    %% load raw data
    dataRaw = load([datapath, fileName{trialI}]);

    % cleaning/reorganizing the data - not needed right now

    % no actual timestamps from data--calculating from frame and sampling rate
    timestamp = [0:(dataRaw.Button1_tobii_1.Frames-1)]'.*(1/dataRaw.Button1_tobii_1.FrameRate); % in seconds, start from 0

    %% sort head data
    % raw data coordinate system is x+=right, y+=forward, z+=up, right-handed
    headIdx = find(strcmp(dataRaw.Button1_tobii_1.RigidBodies.Name, 'Tobii3-Set-L1-R1'));

    headRotMatRaw = reshape(squeeze(dataRaw.Button1_tobii_1.RigidBodies.Rotations(headIdx, :, :)), 3, 3, length(timestamp));
    headQuatRaw = rotm2quat(headRotMatRaw); % in the original coordinates

    %     % sanity check to see if Euler angles give the same results
    %     headRPYRaw = [squeeze(dataRaw.Button1_tobii_1.RigidBodies.RPYs(headIdx, 1, :)) ...
    %         squeeze(dataRaw.Button1_tobii_1.RigidBodies.RPYs(headIdx, 2, :)) ...
    %         squeeze(dataRaw.Button1_tobii_1.RigidBodies.RPYs(headIdx, 3, :))];
    %     eulRPY = rad2deg(quat2eul(headQuatRaw, 'XYZ'));
    %     rotM = eul2rotm(headRPYRaw/180*pi, 'XYZ');
    %     % yes they matched!

    headOriQ = [headQuatRaw(:, 1) headQuatRaw(:, 3) -headQuatRaw(:, 2) headQuatRaw(:, 4)];
    % coordinates transformed

    % 3D position in world coordinates
    headPos = [squeeze(dataRaw.Button1_tobii_1.RigidBodies.Positions(headIdx, 2, :)) ...
        squeeze(-dataRaw.Button1_tobii_1.RigidBodies.Positions(headIdx, 1, :)) ...
        squeeze(dataRaw.Button1_tobii_1.RigidBodies.Positions(headIdx, 3, :))]./1000;
    % coordinates transformed, change from mm to m

    % calculate the head frames per frame
    headRefXYZ = dataRaw.Button1_tobii_1.RigidBodies.CoordinateSystem(headIdx).DataRotation; % in original coordinates
    for jj = 1:size(headRotMatRaw, 3)
        headFrameXYZraw = headRotMatRaw(:, :, jj)*headRefXYZ;
        % still in original coordinates, the head basis axes are right, forward, and up

        %         % sanity check
        % %                 headFrameXYZraw = headRefXYZ;
        %         figure
        %         plot3([0; headFrameXYZraw(1, 1)], [0; headFrameXYZraw(2, 1)], [0; headFrameXYZraw(3, 1)], 'r-' )
        %         hold on
        %         plot3([0; headFrameXYZraw(1, 2)], [0; headFrameXYZraw(2, 2)], [0; headFrameXYZraw(3, 2)], 'g-' )
        %         plot3([0; headFrameXYZraw(1, 3)], [0; headFrameXYZraw(2, 3)], [0; headFrameXYZraw(3, 3)], 'b-' )
        %         xlabel('x')
        %         ylabel('y')
        %         zlabel('z')
        %         hold off

        headFrameXYZ{jj, 1} = [headFrameXYZraw(2, :); -headFrameXYZraw(1, :); headFrameXYZraw(3, :)];
        headFrameXYZ{jj, 1} = [headFrameXYZ{jj, 1}(:, 2) -headFrameXYZ{jj, 1}(:, 1) headFrameXYZ{jj, 1}(:, 3)];
        % coordinates transformed; each column is one basis axis of the
        % head frame, basis axes of forward, left, and up
        headFrameXYZ{jj, 1} = normc(headFrameXYZ{jj, 1});    % normalize the columns into unit vectors

        %         % sanity check
        %         figure
        %         plot3([0; headFrameXYZ{jj, 1}(1, 1)], [0; headFrameXYZ{jj, 1}(2, 1)], [0; headFrameXYZ{jj, 1}(3, 1)], 'r-' )
        %         hold on
        %         plot3([0; headFrameXYZ{jj, 1}(1, 2)], [0; headFrameXYZ{jj, 1}(2, 2)], [0; headFrameXYZ{jj, 1}(3, 2)], 'g-' )
        %         plot3([0; headFrameXYZ{jj, 1}(1, 3)], [0; headFrameXYZ{jj, 1}(2, 3)], [0; headFrameXYZ{jj, 1}(3, 3)], 'b-' )
        %         xlabel('x')
        %         ylabel('y')
        %         zlabel('z')
        %         hold off
    end

    headFrameData = array2table([headOriQ headPos timestamp], 'VariableNames', ...
        {'qW', 'qX', 'qY', 'qZ', 'posX', 'posY', 'posZ', 'timestamp'});
    headFrameData.frameXYZ = headFrameXYZ;

    %% sort eye data
    % for Tobii, raw data coordinates are x+=left, y+=up, z+=forward%
    % calculate cyclopean eye data based on binocular data - below are in
    % head coordinates
    leftEyePos = [dataRaw.Button1_tobii_1.Analog.Data(3, :); dataRaw.Button1_tobii_1.Analog.Data(1, :); dataRaw.Button1_tobii_1.Analog.Data(2, :)];
    rightEyePos = [dataRaw.Button1_tobii_1.Analog.Data(10, :); dataRaw.Button1_tobii_1.Analog.Data(8, :); dataRaw.Button1_tobii_1.Analog.Data(9, :)];
    leftEyeDir = [dataRaw.Button1_tobii_1.Analog.Data(6, :); dataRaw.Button1_tobii_1.Analog.Data(4, :); dataRaw.Button1_tobii_1.Analog.Data(5, :)];
    rightEyeDir = [dataRaw.Button1_tobii_1.Analog.Data(13, :); dataRaw.Button1_tobii_1.Analog.Data(11, :); dataRaw.Button1_tobii_1.Analog.Data(12, :)];

    [verDist verAngle gazePoints] = getVergence(leftEyePos, leftEyeDir, rightEyePos, rightEyeDir);
    % since the original coordinates are in mm, verDist is in mm
    % verAngle is in degs
    % gaze points are the calculated intersection point of gaze in head
    % coordinates
    % note that the gaze points here are in the transformed coordinate system, x+ forward, y+ left, z+ up
    % if the gaze directions are parallel, verDist = inf, verAngle = NaN;
    % if verDist = NaN, it's mostly likely that the gaze direction is [0, 0, 0], which is missing signal for Tobii Crystal
    depth = verDist'/1000; % in meters

    gazeOrigin = (leftEyePos+rightEyePos)/2; % cyclopean eye
    gazeVec = (gazePoints-gazeOrigin)'; % in transformed head coordinate system
    azimuthH = -atan2d(gazeVec(:, 2), gazeVec(:, 1));
    elevationH = atan2d(gazeVec(:, 3), sqrt( gazeVec(:, 1).^2 + gazeVec(:, 2).^2) );

    eyeFrameData = array2table([gazeOrigin' gazePoints' azimuthH elevationH depth timestamp], 'VariableNames', ...
        {'eyePosHeadX', 'eyePosHeadY', 'eyePosHeadZ', 'gazePosHeadX', 'gazePosHeadY', 'gazePosHeadZ', ...
        'gazeOriHeadX', 'gazeOriHeadY', 'gazeDepth', 'timestamp'});
    % "eyePosHead" is the cyclopean eye position in head coordinates;
    % "gazePosHead" is the gaze point in head coordinates;
    % gazeOri is azimuth and elevation; azimuth forward is 0, left is negative;
    % elevation forward is 0, down is negative;
    % depth is in meters
    % "gazeOriHead" is eye in head gaze angle; gazeOriWorld and gazePosWorld will be
    % calculated later after time alignment of eye and head

    %         % Re. whether do alignTime or not:
    %         % If you don't have long-duration of missing frames and the head and eye data are
    %         % already aligned, you can skip this step;
    %         % If you might have long-duration of missing frames (during which data
    %         % should not be interpolated), or need to align head/eye data, or wants
    %         % to resampling to a different sampling rate, use the function below.
    %         % "missing frames" meaning that the timestamps are missing, not just no
    %         % signals but with timestamps
    %         [eyeTrial.sampleRate, eyeTrial.eyeAligned, eyeTrial.headAligned] = alignTime(eyeFrameData, 'headFrameTrial', headFrameData, 'sampleRateDesired', 240);

    % calculate gaze position and orientation in world
    leftEyePosW = [dataRaw.Button1_tobii_1.GazeVector(1).GazeVector(3, :); dataRaw.Button1_tobii_1.GazeVector(1).GazeVector(1, :); dataRaw.Button1_tobii_1.GazeVector(1).GazeVector(2, :)];
    rightEyePosW = [dataRaw.Button1_tobii_1.GazeVector(2).GazeVector(3, :); dataRaw.Button1_tobii_1.GazeVector(2).GazeVector(1, :); dataRaw.Button1_tobii_1.GazeVector(2).GazeVector(2, :)];
    leftEyeDirW = [dataRaw.Button1_tobii_1.GazeVector(1).GazeVector(6, :); dataRaw.Button1_tobii_1.GazeVector(1).GazeVector(4, :); dataRaw.Button1_tobii_1.GazeVector(1).GazeVector(5, :)];
    rightEyeDirW = [dataRaw.Button1_tobii_1.GazeVector(2).GazeVector(6, :); dataRaw.Button1_tobii_1.GazeVector(2).GazeVector(4, :); dataRaw.Button1_tobii_1.GazeVector(2).GazeVector(5, :)];

    [verDistW verAngleW gazePointsW] = getVergence(leftEyePosW, leftEyeDirW, rightEyePosW, rightEyeDirW);
    depthW = verDistW'/1000; % in meters
    % this has a weird shift when comparing to depth calculated from head
    % coordinates...

    gazeOriginW = (leftEyePosW+rightEyePosW)/2; % cyclopean eye
    gazeVecW = (gazePointsW-gazeOriginW)'; % in transformed world coordinate system
    azimuthW = -atan2d(gazeVecW(:, 2), gazeVecW(:, 1));
    elevationW = atan2d(gazeVecW(:, 3), sqrt( gazeVecW(:, 1).^2 + gazeVecW(:, 2).^2) );

    % Now let's get the eye frames in world coordinates
    % For binocular data, let's find the eye frame for each eye
    % gaze_vector is the line of sight, one axis (x-forward) for the eye frame. use head_up to find the
    % up axis for the eye (z-up), then cross product to find the final axis
    % (y-left)
    % Then do the same for the cyclopean eye
    eyeFrameXYZ_L = [];
    eyeFrameXYZ_R = [];
    eyeFrameXYZ = [];
    for jj = 1:length(headFrameXYZ)
        % forward direction is line of sight, i.e. gaze vector
        eyeForward_L = leftEyeDirW(:, jj);
        eyeForward_L = eyeForward_L./norm(eyeForward_L);

        eyeForward_R = rightEyeDirW(:, jj);
        eyeForward_R = eyeForward_R./norm(eyeForward_R);

        eyeForward = gazeVecW(jj, :)';
        eyeForward = eyeForward./norm(eyeForward); % cyclopean eye

        % calcualte up direction use the head up direction
        headUp = headFrameXYZ{jj}(:, 3); % already a unit vector

        eyeUp_L = headUp-(headUp'*eyeForward_L)*eyeForward_L;
        eyeUp_L = eyeUp_L/norm(eyeUp_L);

        eyeUp_R = headUp-(headUp'*eyeForward_R)*eyeForward_R;
        eyeUp_R = eyeUp_R/norm(eyeUp_R);

        eyeUp = headUp-(headUp'*eyeForward)*eyeForward;
        eyeUp = eyeUp/norm(eyeUp);

        % calculate the left direction using cross product
        eyeLeft_L = cross(eyeUp_L, eyeForward_L);
        eyeLeft_L = eyeLeft_L/norm(eyeLeft_L);

        eyeLeft_R = cross(eyeUp_R, eyeForward_R);
        eyeLeft_R = eyeLeft_R/norm(eyeLeft_R);

        eyeLeft = cross(eyeUp, eyeForward);
        eyeLeft = eyeLeft/norm(eyeLeft);

        eyeFrameXYZ_L{jj, 1} = [eyeForward_L, eyeLeft_L, eyeUp_L]; % in world cooridnates
        eyeFrameXYZ_R{jj, 1} = [eyeForward_R, eyeLeft_R, eyeUp_R]; % in world cooridnates
        eyeFrameXYZ{jj, 1} = [eyeForward, eyeLeft, eyeUp]; % in world cooridnates

        %         close all
        %         figure
        %         plot3([0; headFrameXYZ{jj, 1}(1, 1)], [0; headFrameXYZ{jj, 1}(2, 1)], [0; headFrameXYZ{jj, 1}(3, 1)], 'r-' )
        %         hold on
        %         plot3([0; headFrameXYZ{jj, 1}(1, 2)], [0; headFrameXYZ{jj, 1}(2, 2)], [0; headFrameXYZ{jj, 1}(3, 2)], 'g-' )
        %         plot3([0; headFrameXYZ{jj, 1}(1, 3)], [0; headFrameXYZ{jj, 1}(2, 3)], [0; headFrameXYZ{jj, 1}(3, 3)], 'b-' )
        %
        %         plot3([0; eyeForward(1)], [0; eyeForward(2)], [0; eyeForward(3)], 'k-')
        %
        %         plot3([0; eyeFrameXYZ{jj, 1}(1, 1)], [0; eyeFrameXYZ{jj, 1}(2, 1)], [0; eyeFrameXYZ{jj, 1}(3, 1)], 'r--' )
        %         plot3([0; eyeFrameXYZ{jj, 1}(1, 2)], [0; eyeFrameXYZ{jj, 1}(2, 2)], [0; eyeFrameXYZ{jj, 1}(3, 2)], 'g--' )
        %         plot3([0; eyeFrameXYZ{jj, 1}(1, 3)], [0; eyeFrameXYZ{jj, 1}(2, 3)], [0; eyeFrameXYZ{jj, 1}(3, 3)], 'b--' )
        %         xlabel('x')
        %         ylabel('y')
        %         zlabel('z')
        %         hold off

        %         % or, let's see if our calculation is correct...
        %         hz = headFrameXYZ{jj}(:, 3);
        %         hz(1:2, :) = -hz(1:2, :);
        % %         hz2 = quat2rotm(dataT.head_rotation_quat(:,jj)')*dataT.headRefXYZ;
        %         frameT = vec2frame(dataT.gaze_vector(:, jj), hz, {'X','Z'});
    end

    eyeTrial.eyeAligned = [eyeFrameData array2table([gazeOriginW' gazePointsW' azimuthW elevationW], 'VariableNames', ...
        {'eyePosWorldX', 'eyePosWorldY', 'eyePosWorldZ', 'gazePosWorldX', 'gazePosWorldY', 'gazePosWorldZ', ...
        'gazeOriWorldX', 'gazeOriWorldY'})];
    eyeTrial.eyeAligned.frameXYZ = eyeFrameXYZ;
    % currently only including the cyclopean eye data; can include
    % binocular data if needed

    eyeTrial.headAligned = headFrameData;
    eyeTrial.sampleRate = dataRaw.Button1_tobii_1.FrameRate; % manually put in the sampleRate, mostly a reference for filtering choices

    save([datapath, '..\pre_processed\data_GP', num2str(trialI), '.mat'], 'eyeTrial')
end


%% parking lot... for previous examples
%     opts = delimitedTextImportOptions('Delimiter', ';');%, 'DataLines', [1, 2]);
%     varNames = readtable([datapath, fileName{trialI}], opts);
%     varNames = varNames{1, :};
%     dataRaw = readtable([datapath, fileName{trialI}], 'Delimiter', ';'); % if it's already sorted into csv or similar tables

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