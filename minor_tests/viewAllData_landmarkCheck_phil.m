% From a pre-processed data file, loads everything and plots a lot of
% stuff. .mat file is expected to be a table like:
% To do --> Update expected variable structure

% close all; clear all; clc;
close all;

% % Define the default histogram color
% hC = [0.6, 0.84, 0.91]; % Specify the RGB color values
% hL = [1, 0.63, 0.65]; % Specify the RGB color values 

% Load file and make sure everything's fine
addpath(genpath('functions'))
tic;

% if isfile(['data\pre_processed\fixTS_data_joint.mat']) 
%    load(['data\pre_processed\fixTS_data_joint.mat'])
% end


if isfile(['data\post_processed\study2\S2-small-post-data.mat']) 
  load(['data\post_processed\study2\S2-small-post-data.mat'])
  all_user_info = small_all_user_info;
end


survey_data = readtable('data/survey/PSHourglass_PrePostData_Study1.csv');
survey_data = sortrows(survey_data, {'ParticipantID', 'Condition'});
rows_to_keep = ismember(survey_data.CompletionTime, 'Session end');
survey_data = survey_data(rows_to_keep, :);
all_user_info = sortrows(all_user_info, {'UserID', 'ETDDC'});
fprintf('Data loaded correctly.\n');
toc;

tic;

%% DEBUG

% % Remove duplicate lines, if any
% % Find the indices of duplicate rows
% key = strcat(string(all_user_info.UserID), '|', string(all_user_info.Day));
% % Check for unique combinations
% is_unique = length(unique(key)) == height(all_user_info);
% % Remove duplicates based on the combination of values in Column1 and Column2
% if ~is_unique
%     [~, unique_indices, ~] = unique(key, 'stable');
%     duplicate_indices = setdiff(1:height(all_user_info), unique_indices);
%     all_user_info(duplicate_indices, :) = [];
%     disp('Duplicates removed:');
% else
%     disp('No duplicates found.');
% end


% Find values that appear only once in 'Column1'
unique_values = unique(all_user_info.UserID);
appear_once = unique_values(histcounts(double(all_user_info.UserID), double(unique_values)) == 1);
% all_user_info = all_user_info(~ismember(all_user_info.UserID, appear_once), :);
% all_user_info = all_user_info(all_user_info.UserID ~= '006', :);
% all_user_info = all_user_info(all_user_info.UserID ~= '035', :);
% all_user_info = all_user_info(all_user_info.UserID ~= '040', :);
% all_user_info = all_user_info(all_user_info.UserID ~= '041', :);
all_user_info = all_user_info(all_user_info.UserID ~= '001', :);
all_user_info = all_user_info(all_user_info.UserID ~= '999', :);

% Keep only info for those users
currUsers = str2double(all_user_info.UserID);
rows_to_keep = ismember(survey_data.ParticipantID, currUsers);
survey_data = survey_data(rows_to_keep, :);

%
% Prepare variables for statistical analysis
%
% Prepare VIMS and SSQ
SSQ_totalSubscale0 = survey_data.SSQ_totalSubscale(strcmp(survey_data.Condition, 'ETDDC OFF'))';
SSQ_totalSubscale1 = survey_data.SSQ_totalSubscale(strcmp(survey_data.Condition, 'ETDDC ON'))';
VIMSSQ_total0 = survey_data.VIMSSQ_total(strcmp(survey_data.Condition, 'ETDDC OFF'))';
VIMSSQ_total1 = survey_data.VIMSSQ_total(strcmp(survey_data.Condition, 'ETDDC ON'))';
% Merge for statistical analyses
SSQ_totalSubscale = [SSQ_totalSubscale0, SSQ_totalSubscale1]';
VIMSSQ_total = [VIMSSQ_total0, VIMSSQ_total1]';
% Create subject identifiers
subjects_OFF = all_user_info.UserID(1:2:end-1)';
subjects_ON = all_user_info.UserID(2:2:end)';
subjects = [subjects_OFF subjects_ON];
[~,~,subjects] = unique(subjects);
% Create ET-DDC condition identifier
group = [zeros(1, numel(SSQ_totalSubscale0)), ones(1, numel(SSQ_totalSubscale1))]';




% ========================================================== %
% ========================================================== %
% ======================= RAW GAZE DATA  =================== %
% ========================================================== %
% ========================================================== %







% If the directory does not exist, create it
dirPath1 = 'results/study2/rawGaze/';
if exist(dirPath1, 'dir') ~= 7
    mkdir(dirPath1);
    disp(['[MKDIR] Directory created: ' dirPath1]);
end
dirPath2 = 'results/study2/head/';
if exist(dirPath2, 'dir') ~= 7
    mkdir(dirPath2);
    disp(['[MKDIR] Directory created: ' dirPath2]);
end

% Gaze in head space
gazeHead0 = struct();           gazeHead1 = struct(); 
% Prepare a struct for each time chunk
gazeHead0.CH20 = struct();      gazeHead1.CH20 = struct(); 
gazeHead0.CH40 = struct();      gazeHead1.CH40 = struct(); 
gazeHead0.CH60 = struct();      gazeHead1.CH60 = struct(); 
gazeHead0.L10 = struct();       gazeHead1.L10 = struct(); 
% Gaze in world space
gazeWorld0 = struct();           gazeWorld1 = struct(); 
% Prepare a struct for each time chunk
gazeWorld0.CH20 = struct();      gazeWorld1.CH20 = struct(); 
gazeWorld0.CH40 = struct();      gazeWorld1.CH40 = struct(); 
gazeWorld0.CH60 = struct();      gazeWorld1.CH60 = struct(); 
gazeWorld0.L10 = struct();       gazeWorld1.L10 = struct(); 
% Head orientation
headWorld0 = struct();           headWorld1 = struct(); 
% Prepare a struct for each time chunk
headWorld0.CH20 = struct();      headWorld1.CH20 = struct(); 
headWorld0.CH40 = struct();      headWorld1.CH40 = struct(); 
headWorld0.CH60 = struct();      headWorld1.CH60 = struct(); 
headWorld0.L10 = struct();       headWorld1.L10 = struct(); 


structs = {'CH20', 'CH40', 'CH60', 'L10'};
for i = 1:length(structs)
    field = structs{i};
    % Gaze in head
    gazeHead0.(field).x = [];           gazeHead1.(field).x = [];
    gazeHead0.(field).y = [];           gazeHead1.(field).y = [];
    gazeHead0.(field).z = [];           gazeHead1.(field).z = [];
    gazeHead0.(field).headRawGazeAngleMagn = [];        gazeHead1.(field).headRawGazeAngleMagn = [];
    gazeHead0.(field).headThetaMagn = [];               gazeHead1.(field).headThetaMagn = [];       
    gazeHead0.(field).headPhiMagn = [];                 gazeHead1.(field).headPhiMagn = [];
    % Gaze in world
    gazeWorld0.(field).x = [];          gazeWorld1.(field).x = [];
    gazeWorld0.(field).y = [];          gazeWorld1.(field).y = [];
    gazeWorld0.(field).z = [];          gazeWorld1.(field).z = [];
    gazeWorld0.(field).worldRawGazeAngleMagn = [];       gazeWorld1.(field).worldRawGazeAngleMagn = [];
    gazeWorld0.(field).worldThetaMagn = [];              gazeWorld1.(field).worldThetaMagn = [];       
    gazeWorld0.(field).worldPhiMagn = [];                gazeWorld1.(field).worldPhiMagn = [];
    % Gaze in world
    headWorld0.(field).x = [];          headWorld1.(field).x = [];
    headWorld0.(field).y = [];          headWorld1.(field).y = [];
    headWorld0.(field).z = [];          headWorld1.(field).z = [];
    headWorld0.(field).worldRawGazeAngleMagn = [];       headWorld1.(field).worldRawGazeAngleMagn = [];
    headWorld0.(field).worldThetaMagn = [];              headWorld1.(field).worldThetaMagn = [];       
    headWorld0.(field).worldPhiMagn = [];                headWorld1.(field).worldPhiMagn = [];
end

for j = 1:length(structs)
    field = structs{j};
    for i = 1:height(all_user_info)
        % Recover head and eye traces from last 10 minutes
        switch field
            case 'CH20'
                a = 40;
                b = 200;
                eA = all_user_info.EyeInfo{i}(all_user_info.EyeInfo{i}.timestamp >= a & all_user_info.EyeInfo{i}.timestamp <= b, :);
                hA = all_user_info.HeadInfo{i}(all_user_info.HeadInfo{i}.timestamp >= a & all_user_info.HeadInfo{i}.timestamp <= b, :);
            case 'CH40'
                a = 420;
                b = 540;
                eA = all_user_info.EyeInfo{i}(all_user_info.EyeInfo{i}.timestamp >= a & all_user_info.EyeInfo{i}.timestamp <= b, :);
                hA = all_user_info.HeadInfo{i}(all_user_info.HeadInfo{i}.timestamp >= a & all_user_info.HeadInfo{i}.timestamp <= b, :);
            case 'CH60'
                a = 205;
                b = 320;
                eA = all_user_info.EyeInfo{i}(all_user_info.EyeInfo{i}.timestamp >= a & all_user_info.EyeInfo{i}.timestamp <= b, :);
                hA = all_user_info.HeadInfo{i}(all_user_info.HeadInfo{i}.timestamp >= a & all_user_info.HeadInfo{i}.timestamp <= b, :);
            otherwise
                a = 880;    % Fifth
                b = 1030;   % Fifth
                %a = 550;   % Fourth
                %b = 700;   % Fourth
                eA = all_user_info.EyeInfo{i}(all_user_info.EyeInfo{i}.timestamp >= a & all_user_info.EyeInfo{i}.timestamp <= b, :);
                hA = all_user_info.HeadInfo{i}(all_user_info.HeadInfo{i}.timestamp >= a & all_user_info.HeadInfo{i}.timestamp <= b, :);
        end
        gH = [eA.gazePosHeadFiltX eA.gazePosHeadFiltY eA.gazePosHeadFiltZ] / 1000;
        gH = gH(~any(isnan(gH), 2), :);
        % This is gaze position in world space from last 10 minutes
        gW = [eA.gazePosWorldFiltX eA.gazePosWorldFiltY eA.gazePosWorldFiltZ] / 1000;
        gW = gW(~any(isnan(gW), 2), :);
        % Get head rotation
        hR = [hA.oriFiltQw, hA.oriFiltQx, hA.oriFiltQy, hA.oriFiltQz];
        hR =  rotatepoint(quaternion(hR), [1, 0, 0]);
        
        % % Get fixations
        % gF = all_user_info.gazeFix{i};
        % idx = find(ismember(eA.timestamp, gF.onsetTime));
        % gH = [eA.gazePosHeadFiltX(idx) eA.gazePosHeadFiltY(idx) eA.gazePosHeadFiltZ(idx)] / 1000;
        % gH = gH(~any(isnan(gH), 2), :);
        % gW = [eA.gazePosWorldFiltX(idx) eA.gazePosWorldFiltY(idx) eA.gazePosWorldFiltZ(idx)] / 1000;
        % gW = gW(~any(isnan(gW), 2), :);

        if all_user_info.ETDDC(i) == 0
            % Store gaze in head
            gazeHead0.(field).x = [gazeHead0.(field).x ; gH(:, 1)];
            gazeHead0.(field).y = [gazeHead0.(field).y ; gH(:, 2)];
            gazeHead0.(field).z = [gazeHead0.(field).z ; gH(:, 3)];
            % Store gaze in world
            gazeWorld0.(field).x = [gazeWorld0.(field).x ; gW(:, 1)];
            gazeWorld0.(field).y = [gazeWorld0.(field).y ; gW(:, 2)];
            gazeWorld0.(field).z = [gazeWorld0.(field).z ; gW(:, 3)];
            % Store head orientation
            headWorld0.(field).x = [headWorld0.(field).x ; hR(:, 1)];
            headWorld0.(field).y = [headWorld0.(field).y ; hR(:, 2)];
            headWorld0.(field).z = [headWorld0.(field).z ; hR(:, 3)];
            % Pre-compute eye movements for statistical analyses (head)
            theta = -atan2d(gH(:, 2), gH(:, 1));
            phi = atan2d(gH(:, 3), sqrt(gH(:, 1).^2 + gH(:, 2).^2));
            gazeHead0.(field).headRawGazeAngleMagn = [gazeHead0.(field).headRawGazeAngleMagn ; median(sqrt(theta.^2 + phi.^2))];
            gazeHead0.(field).headPhiMagn = [gazeHead0.(field).headPhiMagn ; median(phi)];
            gazeHead0.(field).headThetaMagn = [gazeHead0.(field).headThetaMagn ; median(theta)];
            % Pre-compute eye movements for statistical analyses (world)
            theta = -atan2d(gW(:, 2), gW(:, 1));
            phi = atan2d(gW(:, 3), sqrt(gW(:, 1).^2 + gW(:, 2).^2));
            gazeWorld0.(field).worldRawGazeAngleMagn = [gazeWorld0.(field).worldRawGazeAngleMagn ; median(sqrt(theta.^2 + phi.^2))];
            gazeWorld0.(field).worldPhiMagn = [gazeWorld0.(field).worldPhiMagn ; median(phi)];
            gazeWorld0.(field).worldThetaMagn = [gazeWorld0.(field).worldThetaMagn ; median(theta)];
            % Pre-compute head movements for statistical analyses (world)
            theta = -atan2d(hR(:, 2), hR(:, 1));
            phi = atan2d(hR(:, 3), sqrt(hR(:, 1).^2 + hR(:, 2).^2));
            headWorld0.(field).worldRawGazeAngleMagn = [headWorld0.(field).worldRawGazeAngleMagn ; median(sqrt(theta.^2 + phi.^2))];
            headWorld0.(field).worldPhiMagn = [headWorld0.(field).worldPhiMagn ; median(phi)];
            headWorld0.(field).worldThetaMagn = [headWorld0.(field).worldThetaMagn ; median(theta)];
        else
            % Store gaze in head
            gazeHead1.(field).x = [gazeHead1.(field).x ; gH(:, 1)];
            gazeHead1.(field).y = [gazeHead1.(field).y ; gH(:, 2)];
            gazeHead1.(field).z = [gazeHead1.(field).z ; gH(:, 3)];
            % Store gaze in world
            gazeWorld1.(field).x = [gazeWorld1.(field).x ; gW(:, 1)];
            gazeWorld1.(field).y = [gazeWorld1.(field).y ; gW(:, 2)];
            gazeWorld1.(field).z = [gazeWorld1.(field).z ; gW(:, 3)];
            % Store head orientation
            headWorld1.(field).x = [headWorld1.(field).x ; hR(:, 1)];
            headWorld1.(field).y = [headWorld1.(field).y ; hR(:, 2)];
            headWorld1.(field).z = [headWorld1.(field).z ; hR(:, 3)];
            % Pre-compute eye movements for statistical analyses (head)
            theta = -atan2d(gH(:, 2), gH(:, 1));
            phi = atan2d(gH(:, 3), sqrt(gH(:, 1).^2 + gH(:, 2).^2));
            gazeHead1.(field).headRawGazeAngleMagn = [gazeHead1.(field).headRawGazeAngleMagn ; median(sqrt(theta.^2 + phi.^2))];
            gazeHead1.(field).headPhiMagn = [gazeHead1.(field).headPhiMagn ; median(phi)];
            gazeHead1.(field).headThetaMagn = [gazeHead1.(field).headThetaMagn ; median(theta)];
            % Pre-compute eye movements for statistical analyses (world)
            theta = -atan2d(gW(:, 2), gW(:, 1));
            phi = atan2d(gW(:, 3), sqrt(gW(:, 1).^2 + gW(:, 2).^2));
            gazeWorld1.(field).worldRawGazeAngleMagn = [gazeWorld1.(field).worldRawGazeAngleMagn ; median(sqrt(theta.^2 + phi.^2))];
            gazeWorld1.(field).worldPhiMagn = [gazeWorld1.(field).worldPhiMagn ; median(phi)];
            gazeWorld1.(field).worldThetaMagn = [gazeWorld1.(field).worldThetaMagn ; median(theta)];
            % Pre-compute head movements for statistical analyses (world)
            theta = -atan2d(hR(:, 2), hR(:, 1));
            phi = atan2d(hR(:, 3), sqrt(hR(:, 1).^2 + hR(:, 2).^2));
            headWorld1.(field).worldRawGazeAngleMagn = [headWorld1.(field).worldRawGazeAngleMagn ; median(sqrt(theta.^2 + phi.^2))];
            headWorld1.(field).worldPhiMagn = [headWorld1.(field).worldPhiMagn ; median(phi)];
            headWorld1.(field).worldThetaMagn = [headWorld1.(field).worldThetaMagn ; median(theta)];
        end
    end
end

% Last 10 minutes
headRawGazeAngleMagn = [gazeHead0.L10.headRawGazeAngleMagn; gazeHead1.L10.headRawGazeAngleMagn];
worldRawGazeAngleMagn = [gazeWorld0.L10.worldRawGazeAngleMagn; gazeWorld1.L10.worldRawGazeAngleMagn];
headThetaMagn = [gazeHead0.L10.headThetaMagn; gazeHead1.L10.headThetaMagn];
worldThetaMagn = [gazeWorld0.L10.worldThetaMagn; gazeWorld1.L10.worldThetaMagn];
headPhiMagn = [gazeHead0.L10.headPhiMagn; gazeHead1.L10.headPhiMagn];
worldPhiMagn = [gazeWorld0.L10.worldPhiMagn; gazeWorld1.L10.worldPhiMagn];

% % Plot gaze data
% fprintf('Analyzing and plotting raw gaze data.\n');
% plotGazeData(gazeHead1.L10,  gazeHead1.L10,  [dirPath1 '4TH_GIHead_'], 'world', 'ET-DDC Off', 'ET-DDC On');
% plotGazeData(gazeHead1.CH20, gazeHead1.CH20, [dirPath1 '1ST_GIHead_'], 'world', 'ET-DDC Off', 'ET-DDC On');
% plotGazeData(gazeHead1.CH40, gazeHead1.CH40, [dirPath1 '2ND_GIHead_'], 'world', 'ET-DDC Off', 'ET-DDC On');
% plotGazeData(gazeHead1.CH60, gazeHead1.CH60, [dirPath1 '3RD_GIHead_'], 'world', 'ET-DDC Off', 'ET-DDC On');
m4 = plotGazeData(gazeWorld1.L10,  gazeWorld1.L10,  [dirPath1 '4TH_GIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
m1 = plotGazeData(gazeWorld1.CH20, gazeWorld1.CH20, [dirPath1 '1ST_GIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
m2 = plotGazeData(gazeWorld1.CH40, gazeWorld1.CH40, [dirPath1 '2ND_GIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
m3 = plotGazeData(gazeWorld1.CH60, gazeWorld1.CH60, [dirPath1 '3RD_GIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
% plotGazeData(headWorld1.L10,  headWorld1.L10,  [dirPath2 '4TH_HIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
% plotGazeData(headWorld1.CH20, headWorld1.CH20, [dirPath2 '1ST_HIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
% plotGazeData(headWorld1.CH40, headWorld1.CH40, [dirPath2 '2ND_HIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
% plotGazeData(headWorld1.CH60, headWorld1.CH60, [dirPath2 '3RD_HIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');

% Normalize matrices
m1 = m1 / sum(m1(:));
m2 = m2 / sum(m2(:));
m3 = m3 / sum(m3(:));
m4 = m4 / sum(m4(:));

figure;
m2 = abs(m2 - m1);
imagesc(m2);
colorbar;
hold off;

figure;
m3 = abs(m3 - m1);
imagesc(m3);
colorbar;
hold off;

figure;
m4 = abs(m4 - m1);
imagesc(m4);
colorbar;
hold off;







%{

% If the directory does not exist, create it
dirPath1 = 'results/study2/rawGaze/';
if exist(dirPath1, 'dir') ~= 7
    mkdir(dirPath1);
    disp(['[MKDIR] Directory created: ' dirPath1]);
end
dirPath2 = 'results/study2/head/';
if exist(dirPath2, 'dir') ~= 7
    mkdir(dirPath2);
    disp(['[MKDIR] Directory created: ' dirPath2]);
end

% Gaze in head space
gazeHead0 = struct();           gazeHead1 = struct(); 
% Prepare a struct for each time chunk
gazeHead0.CH20 = struct();      gazeHead1.CH20 = struct(); 
gazeHead0.CH40 = struct();      gazeHead1.CH40 = struct(); 
gazeHead0.CH60 = struct();      gazeHead1.CH60 = struct(); 
gazeHead0.L10 = struct();       gazeHead1.L10 = struct(); 
% Gaze in world space
gazeWorld0 = struct();           gazeWorld1 = struct(); 
% Prepare a struct for each time chunk
gazeWorld0.CH20 = struct();      gazeWorld1.CH20 = struct(); 
gazeWorld0.CH40 = struct();      gazeWorld1.CH40 = struct(); 
gazeWorld0.CH60 = struct();      gazeWorld1.CH60 = struct(); 
gazeWorld0.L10 = struct();       gazeWorld1.L10 = struct(); 
% Head orientation
headWorld0 = struct();           headWorld1 = struct(); 
% Prepare a struct for each time chunk
headWorld0.CH20 = struct();      headWorld1.CH20 = struct(); 
headWorld0.CH40 = struct();      headWorld1.CH40 = struct(); 
headWorld0.CH60 = struct();      headWorld1.CH60 = struct(); 
headWorld0.L10 = struct();       headWorld1.L10 = struct(); 
structs = {'CH20', 'CH40', 'CH60', 'L10'};
for i = 1:length(structs)
    field = structs{i};
    % Gaze in head
    gazeHead0.(field).x = [];           gazeHead1.(field).x = [];
    gazeHead0.(field).y = [];           gazeHead1.(field).y = [];
    gazeHead0.(field).z = [];           gazeHead1.(field).z = [];
    gazeHead0.(field).headRawGazeAngleMagn = [];        gazeHead1.(field).headRawGazeAngleMagn = [];
    gazeHead0.(field).headThetaMagn = [];               gazeHead1.(field).headThetaMagn = [];       
    gazeHead0.(field).headPhiMagn = [];                 gazeHead1.(field).headPhiMagn = [];
    % Gaze in world
    gazeWorld0.(field).x = [];          gazeWorld1.(field).x = [];
    gazeWorld0.(field).y = [];          gazeWorld1.(field).y = [];
    gazeWorld0.(field).z = [];          gazeWorld1.(field).z = [];
    gazeWorld0.(field).worldRawGazeAngleMagn = [];       gazeWorld1.(field).worldRawGazeAngleMagn = [];
    gazeWorld0.(field).worldThetaMagn = [];              gazeWorld1.(field).worldThetaMagn = [];       
    gazeWorld0.(field).worldPhiMagn = [];                gazeWorld1.(field).worldPhiMagn = [];
    % Gaze in world
    headWorld0.(field).x = [];          headWorld1.(field).x = [];
    headWorld0.(field).y = [];          headWorld1.(field).y = [];
    headWorld0.(field).z = [];          headWorld1.(field).z = [];
    headWorld0.(field).worldRawGazeAngleMagn = [];       headWorld1.(field).worldRawGazeAngleMagn = [];
    headWorld0.(field).worldThetaMagn = [];              headWorld1.(field).worldThetaMagn = [];       
    headWorld0.(field).worldPhiMagn = [];                headWorld1.(field).worldPhiMagn = [];
end

for j = 1:length(structs)
    field = structs{j};
    for i = 1:height(all_user_info)
        % Recover head and eye traces from last 10 minutes
        switch field
            case 'CH20'
                a = 75;
                b = 125;
                eA = all_user_info.EyeInfo{i}(all_user_info.EyeInfo{i}.timestamp >= a & all_user_info.EyeInfo{i}.timestamp <= b, :);
                hA = all_user_info.HeadInfo{i}(all_user_info.HeadInfo{i}.timestamp >= a & all_user_info.HeadInfo{i}.timestamp <= b, :);;
            case 'CH40'
                a = 370;
                b = 440;
                eA = all_user_info.EyeInfo{i}(all_user_info.EyeInfo{i}.timestamp >= a & all_user_info.EyeInfo{i}.timestamp <= b, :);;
                hA = all_user_info.HeadInfo{i}(all_user_info.HeadInfo{i}.timestamp >= a & all_user_info.HeadInfo{i}.timestamp <= b, :);;
            case 'CH60'
                a = 590;
                b = 680;
                eA = all_user_info.EyeInfo{i}(all_user_info.EyeInfo{i}.timestamp >= a & all_user_info.EyeInfo{i}.timestamp <= b, :);;
                hA = all_user_info.HeadInfo{i}(all_user_info.HeadInfo{i}.timestamp >= a & all_user_info.HeadInfo{i}.timestamp <= b, :);;
            otherwise
                a = 840;
                b = 929;
                eA = all_user_info.EyeInfo{i}(all_user_info.EyeInfo{i}.timestamp >= a & all_user_info.EyeInfo{i}.timestamp <= b, :);;
                hA = all_user_info.HeadInfo{i}(all_user_info.HeadInfo{i}.timestamp >= a & all_user_info.HeadInfo{i}.timestamp <= b, :);;
        end
        gH = [eA.gazePosHeadFiltX eA.gazePosHeadFiltY eA.gazePosHeadFiltZ] / 1000;
        gH = gH(~any(isnan(gH), 2), :);
        % This is gaze position in world space from last 10 minutes
        gW = [eA.gazePosWorldFiltX eA.gazePosWorldFiltY eA.gazePosWorldFiltZ] / 1000;
        gW = gW(~any(isnan(gW), 2), :);
        % Get head rotation
        hR = [hA.oriFiltQw, hA.oriFiltQx, hA.oriFiltQy, hA.oriFiltQz];
        hR =  rotatepoint(quaternion(hR), [1, 0, 0]);
        if all_user_info.ETDDC(i) == 0
            % Store gaze in head
            gazeHead0.(field).x = [gazeHead0.(field).x ; gH(:, 1)];
            gazeHead0.(field).y = [gazeHead0.(field).y ; gH(:, 2)];
            gazeHead0.(field).z = [gazeHead0.(field).z ; gH(:, 3)];
            % Store gaze in world
            gazeWorld0.(field).x = [gazeWorld0.(field).x ; gW(:, 1)];
            gazeWorld0.(field).y = [gazeWorld0.(field).y ; gW(:, 2)];
            gazeWorld0.(field).z = [gazeWorld0.(field).z ; gW(:, 3)];
            % Store head orientation
            headWorld0.(field).x = [headWorld0.(field).x ; hR(:, 1)];
            headWorld0.(field).y = [headWorld0.(field).y ; hR(:, 2)];
            headWorld0.(field).z = [headWorld0.(field).z ; hR(:, 3)];
            % Pre-compute eye movements for statistical analyses (head)
            theta = -atan2d(gH(:, 2), gH(:, 1));
            phi = atan2d(gH(:, 3), sqrt(gH(:, 1).^2 + gH(:, 2).^2));
            gazeHead0.(field).headRawGazeAngleMagn = [gazeHead0.(field).headRawGazeAngleMagn ; median(sqrt(theta.^2 + phi.^2))];
            gazeHead0.(field).headPhiMagn = [gazeHead0.(field).headPhiMagn ; median(phi)];
            gazeHead0.(field).headThetaMagn = [gazeHead0.(field).headThetaMagn ; median(theta)];
            % Pre-compute eye movements for statistical analyses (world)
            theta = -atan2d(gW(:, 2), gW(:, 1));
            phi = atan2d(gW(:, 3), sqrt(gW(:, 1).^2 + gW(:, 2).^2));
            gazeWorld0.(field).worldRawGazeAngleMagn = [gazeWorld0.(field).worldRawGazeAngleMagn ; median(sqrt(theta.^2 + phi.^2))];
            gazeWorld0.(field).worldPhiMagn = [gazeWorld0.(field).worldPhiMagn ; median(phi)];
            gazeWorld0.(field).worldThetaMagn = [gazeWorld0.(field).worldThetaMagn ; median(theta)];
            % Pre-compute head movements for statistical analyses (world)
            theta = -atan2d(hR(:, 2), hR(:, 1));
            phi = atan2d(hR(:, 3), sqrt(hR(:, 1).^2 + hR(:, 2).^2));
            headWorld0.(field).worldRawGazeAngleMagn = [headWorld0.(field).worldRawGazeAngleMagn ; median(sqrt(theta.^2 + phi.^2))];
            headWorld0.(field).worldPhiMagn = [headWorld0.(field).worldPhiMagn ; median(phi)];
            headWorld0.(field).worldThetaMagn = [headWorld0.(field).worldThetaMagn ; median(theta)];
        else
            % Store gaze in head
            gazeHead1.(field).x = [gazeHead1.(field).x ; gH(:, 1)];
            gazeHead1.(field).y = [gazeHead1.(field).y ; gH(:, 2)];
            gazeHead1.(field).z = [gazeHead1.(field).z ; gH(:, 3)];
            % Store gaze in world
            gazeWorld1.(field).x = [gazeWorld1.(field).x ; gW(:, 1)];
            gazeWorld1.(field).y = [gazeWorld1.(field).y ; gW(:, 2)];
            gazeWorld1.(field).z = [gazeWorld1.(field).z ; gW(:, 3)];
            % Store head orientation
            headWorld1.(field).x = [headWorld1.(field).x ; hR(:, 1)];
            headWorld1.(field).y = [headWorld1.(field).y ; hR(:, 2)];
            headWorld1.(field).z = [headWorld1.(field).z ; hR(:, 3)];
            % Pre-compute eye movements for statistical analyses (head)
            theta = -atan2d(gH(:, 2), gH(:, 1));
            phi = atan2d(gH(:, 3), sqrt(gH(:, 1).^2 + gH(:, 2).^2));
            gazeHead1.(field).headRawGazeAngleMagn = [gazeHead1.(field).headRawGazeAngleMagn ; median(sqrt(theta.^2 + phi.^2))];
            gazeHead1.(field).headPhiMagn = [gazeHead1.(field).headPhiMagn ; median(phi)];
            gazeHead1.(field).headThetaMagn = [gazeHead1.(field).headThetaMagn ; median(theta)];
            % Pre-compute eye movements for statistical analyses (world)
            theta = -atan2d(gW(:, 2), gW(:, 1));
            phi = atan2d(gW(:, 3), sqrt(gW(:, 1).^2 + gW(:, 2).^2));
            gazeWorld1.(field).worldRawGazeAngleMagn = [gazeWorld1.(field).worldRawGazeAngleMagn ; median(sqrt(theta.^2 + phi.^2))];
            gazeWorld1.(field).worldPhiMagn = [gazeWorld1.(field).worldPhiMagn ; median(phi)];
            gazeWorld1.(field).worldThetaMagn = [gazeWorld1.(field).worldThetaMagn ; median(theta)];
            % Pre-compute head movements for statistical analyses (world)
            theta = -atan2d(hR(:, 2), hR(:, 1));
            phi = atan2d(hR(:, 3), sqrt(hR(:, 1).^2 + hR(:, 2).^2));
            headWorld1.(field).worldRawGazeAngleMagn = [headWorld1.(field).worldRawGazeAngleMagn ; median(sqrt(theta.^2 + phi.^2))];
            headWorld1.(field).worldPhiMagn = [headWorld1.(field).worldPhiMagn ; median(phi)];
            headWorld1.(field).worldThetaMagn = [headWorld1.(field).worldThetaMagn ; median(theta)];
        end
    end
end

% Last 10 minutes
headRawGazeAngleMagn = [gazeHead0.L10.headRawGazeAngleMagn; gazeHead1.L10.headRawGazeAngleMagn];
worldRawGazeAngleMagn = [gazeWorld0.L10.worldRawGazeAngleMagn; gazeWorld1.L10.worldRawGazeAngleMagn];
headThetaMagn = [gazeHead0.L10.headThetaMagn; gazeHead1.L10.headThetaMagn];
worldThetaMagn = [gazeWorld0.L10.worldThetaMagn; gazeWorld1.L10.worldThetaMagn];
headPhiMagn = [gazeHead0.L10.headPhiMagn; gazeHead1.L10.headPhiMagn];
worldPhiMagn = [gazeWorld0.L10.worldPhiMagn; gazeWorld1.L10.worldPhiMagn];

% % Plot gaze data
% fprintf('Analyzing and plotting raw gaze data.\n');
plotGazeData(gazeHead0.L10,   gazeHead1.L10,   [dirPath1 'L10_GIHead_'], 'head', 'ET-DDC Off', 'ET-DDC On');
plotGazeData(gazeWorld0.L10,  gazeWorld1.L10,  [dirPath1 'L10_GIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
plotGazeData(gazeWorld0.CH20, gazeWorld1.CH20, [dirPath1 'CH20_GIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
plotGazeData(gazeWorld0.CH40, gazeWorld1.CH40, [dirPath1 'CH40_GIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
plotGazeData(gazeWorld0.CH60, gazeWorld1.CH60, [dirPath1 'CH60_GIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
plotGazeData(headWorld0.L10,  headWorld1.L10,  [dirPath2 'L10_HIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
plotGazeData(headWorld0.CH20, headWorld1.CH20, [dirPath2 'CH20_HIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
plotGazeData(headWorld0.CH40, headWorld1.CH40, [dirPath2 'CH40_HIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');
plotGazeData(headWorld0.CH60, headWorld1.CH60, [dirPath2 'CH60_HIWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');

%}

toc;



%% FUNCTIONS %%

function plotEyeMetricInfo(val0, val1, metric, num0, num1, perSec0, perSec1, supraLabel, tyeOfMovement, label0, label1)
    % val0 and val1 contain the 'metric' (e.g., duration) of all eye 
    % movements of the type to be analyzed per condition 
    % (0 is one condition, 1 is the other).
    % 
    % metric contains a string label with the metric that value refers to
    %
    % num0 and num1 contain the number of such movements per user (again
    % per condition)
    %
    % perSec0 and perSec1 contain the number of such movements per second
    % (again per condition)
    %
    % supraLabel is the tag for the stored plots
    %
    % typeOfMovement is a string indicating which eye movement is being
    % analyzed, e.g., Fixations, Saccades. Is for visualization purposes
    % only
    %
    % label0 and label1 are the text labels for each condition (for the
    % plots)

    % Define the default histogram color
    hC = [0.6, 0.84, 0.91]; % Specify the RGB color values
    hL = [1, 0.63, 0.65]; % Specify the RGB color values

    % Create a figure for the subplots
    figure('Position', [200, 200, 1600, 800], 'Visible', 'off');  
    
    % Plot for ETDDC = 0
    subplot(1, 2, 1); % Create the first subplot
      
    % Calculate the average fixation duration for ETDDC = 0
    medianVal0 = median(val0);
    
    % Create a histogram for first condition
    numBins = 60; 
    h = histogram(val0, numBins, 'FaceColor', hC);
    title([tyeOfMovement metric ' Histogram ' label0]);
    xlabel([tyeOfMovement metric]);
    ylabel('Frequency');
    
    % Add a vertical red dotted line at the average duration for ETDDC = 0
    hold on;
    plot([medianVal0, medianVal0], ylim, 'b--', 'LineWidth', 1.5);
    
    % Obtain histogram data
    binCounts = h.Values;
    binEdges = h.BinEdges;
    
    % Calculate the bin centers
    binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;
    
    % Calculate piecewise linear interpolation
    x = binCenters;
    y = binCounts;
    
    % Generate points for the curve
    xInterp = linspace(min(binCenters), max(binCenters), 100); % Adjust as needed
    yInterp = interp1(x, y, xInterp, 'linear');
    
    % Plot the piecewise linear curve over the histogram
    plot(xInterp, yInterp, 'b-', 'LineWidth', 1.5, 'Color', hL);
    
    % Add a text box with the mean and standard deviation for other metrics
    text(4*medianVal0, max(ylim) / 2, ...
        sprintf(['Median (STD)\n' ...
                    metric ': %.2f (%.2f)\n' ...
                    'Kurtosis: %.2f\n' ...
                    'Skewness: %.2f\n' ...
                                  '\n' ...
                    'Number: %.2f (%.2f)\n' ...
                    'Per sec.: %.2f (%.2f)\n'], ... 
        median(val0), std(val0), ...
            kurtosis(val0), ...
            skewness(val0), ...
            median(num0), std(num0),...
            median(perSec0), std(perSec0)), ...
        'VerticalAlignment', 'bottom', ...
        'HorizontalAlignment', 'right', ...
        'Color', 'b');
    hold off; 
    

    % Plot for ETDDC = 1
    subplot(1, 2, 2); % Create the second subplot
    
    % Calculate the average fixation duration for ETDDC = 1
    medianVal1 = median(val1);
    
    % Create a histogram for ETDDC = 1
    h = histogram(val1, numBins, 'FaceColor', hC);
    title([tyeOfMovement metric ' Histogram ' label1]);
    xlabel([tyeOfMovement metric]);
    ylabel('Frequency');
    
    % Add a vertical red dotted line at the average duration for ETDDC = 1
    hold on;
    plot([medianVal1, medianVal1], ylim, 'b--', 'LineWidth', 1.5);
    
    % Obtain histogram data
    binCounts = h.Values;
    binEdges = h.BinEdges;
    
    % Calculate the bin centers
    binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;
    
    % Calculate piecewise linear interpolation
    x = binCenters;
    y = binCounts;
    
    % Generate points for the curve
    xInterp = linspace(min(binCenters), max(binCenters), 100); % Adjust as needed
    yInterp = interp1(x, y, xInterp, 'linear');
    
    % Plot the piecewise linear curve over the histogram
    plot(xInterp, yInterp, 'b-', 'LineWidth', 1.5, 'Color', hL);
    
    % Add a text box with the mean and standard deviation for ETDDC = 0
    text(4*medianVal1, max(ylim) / 2, ...
        sprintf(['Median (STD)\n' ...
                    metric ': %.2f (%.2f)\n' ...
                    'Kurtosis: %.2f\n' ...
                    'Skewness: %.2f\n' ...
                                  '\n' ...
                    'Number: %.2f (%.2f)\n' ...
                    'Per sec.: %.2f (%.2f)\n'], ... 
        median(val1), std(val1), ...
            kurtosis(val1), ...
            skewness(val1), ...
            median(num1), std(num1),...
            median(perSec1), std(perSec1)), ...
        'VerticalAlignment', 'bottom', ...
        'HorizontalAlignment', 'right', ...
        'Color', 'b');
   
    hold off; 

    % Inform that data has been saved
    saveas(gcf, [supraLabel 'Dynamics.png']);
    fprintf(['[SAVED] Eye movement dynamics --> ' supraLabel 'Dynamics.png\n']);
end

function plotPairwiseHeadInfo(data0, data1, supraLabel, headMovement, label0, label1)
    % data0 and data1 are expected to be two arrays with head movement per
    % participant (pairwise correlation) as a 1D vector (i.e., magnitude of
    % movement or displacement)

    % Define the default histogram color
    hC = [0.6, 0.84, 0.91]; % Specify the RGB color values
    hL = [1, 0.63, 0.65]; % Specify the RGB color values
    fixpairs = [];
    for i = 1:size(data0, 2)
        fixpairs = [fixpairs ; [data0(i), data1(i)]];
    end

    % Create a figure for the subplots
    figure('Position', [200, 200, 1400, 600], 'Visible', 'off');
    
    % We plot each user as a pair of bars
    h = bar(fixpairs, 'grouped');
    % Changing the colors of the bars
    for i = 1:2:length(h)
        h(i).CData = repmat([0.2, 0.5, 0.8], size(h(i).CData, 1), 1);
        h(i+1).CData = repmat([0.8, 0.2, 0.5], size(h(i+1).CData, 1), 1);
    end
    ylabel(headMovement);
    xlabel('Participant');
    title([headMovement ' w.r.t. ET-DDC per participant']);
    hold on;

    plot(xlim, [median(fixpairs(:, 1)), median(fixpairs(:, 1))], 'b--', 'LineWidth', 1.5);
    plot(xlim, [median(fixpairs(:, 2)), median(fixpairs(:, 2))], 'r--', 'LineWidth', 1.5);
    legend(label0, label1, ['Median ' label0], ['Median ' label1], 'Location', 'northeast', 'Orientation', 'vertical');
    hold off; 
    
    % Inform that data has been saved
    saveas(gcf, [supraLabel 'PerParticipant.png']);
    fprintf(['[SAVED] Head movement per participant --> ' supraLabel 'PerParticipant.png\n']);

    % Create a boxplot for the two conditions
    figure('Position', [200, 200, 800, 800], 'Visible', 'off');  
    boxplot(fixpairs, 'Labels', {label0, label1});
    ylabel(headMovement);
    xlabel('Condition');
    title([headMovement ' w.r.t. ET-DDC']);

    % Overlay medians
    hold on;
    plot([1, 2], [median(fixpairs(:, 1)), median(fixpairs(:, 2))], 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);
    hold off;

    % Inform that data has been saved
    saveas(gcf, [supraLabel 'Boxplot.png']);
    fprintf(['[SAVED] Head movement boxplot --> ' supraLabel 'Boxplot.png\n']);
    
    % Scatter plot between conditions
    % Create a scatter plot
    figure('Position', [200, 200, 600, 600], 'Visible', 'off');
    scatter(data0, data1, [], hC, 'filled', 'MarkerEdgeColor', hC - 0.1);
    hold on;
    
    % Draw a diagonal line
    minValue = min([data0; data1]);
    maxValue = max([data0; data1]);
    line([minValue, maxValue], [minValue, maxValue], 'Color', hL, 'LineStyle', '--', 'LineWidth', 2);
    
    % Add labels and title
    xlabel(label0);
    ylabel(label1);
    title(['Scatter of ' headMovement]);
    legend('Data Points', 'Line of Equality');
    hold off;
    
    % Inform that data has been saved
    saveas(gcf, [supraLabel 'ScatterBetweenConditions.png']);
    fprintf(['[SAVED] Head movement per participant --> ' supraLabel 'ScatterBetweenConditions.png\n']);

end

function smoothed_data = plotGazeData(data0, data1, supraLabel, coordSys, label0, label1)
    % dataX is expected to be a struct such as:
    %       dataX.x, dataX.y, dataX.z
    % following MATLAB Plot3 coordinate space
    %
    % labelX contains an identifier of each condition for visualization
    % purposes
    %
    % supraLabel contain a label that will be included before each plot, to
    % identify all the plots, data used.
    %
    % coordSys can be either 'head' and 'world', depending on the
    % coordinate system used. It can affect some plots and magnitudes
    

    % We are finally plotting the angular distribution of gaze. We do this
    % in two different figures because they are so complex already to be
    % combined together (we would otherwise have subfigures of subfigures).

    figure('Position', [100, 100, 1400, 1400], 'Visible', 'off');

    % Set positions for some subplots
    phiHistPos = [0.76 0.10 0.20 0.65];
    thetaHistPos = [0.10 0.76 0.65 0.20];

    % Convert Cartesian coordinates to spherical coordinates
    theta = atan2(data0.y, data0.x);
    phi = atan2(data0.z, sqrt(data0.x.^2 + data0.y.^2));
    % Convert to degrees
    theta_deg = rad2deg(theta);
    phi_deg = rad2deg(phi);
    % Keep aboslute value for later analysis, this does not affect plots!
    d0 = abs([theta_deg phi_deg]);

    % Define custom bins for the histogram. The more bins, the more smooth
    % the heatmap will look like
    theta_bins = linspace(-180, 180, 500); 
    phi_bins = linspace(-90, 90, 500); 

    % Create a 2D heatmap of theta and phi
    h = histogram2(theta_deg, phi_deg, theta_bins, phi_bins, 'DisplayStyle', 'tile', 'ShowEmptyBins', 'on');
    
    % Smooth histograms for visualization
    hist_data = h.Values;
    sigma = 2;
    smoothed_data = imgaussfilt(hist_data, sigma);

    % Show the distribution of theta OVER the heatmap
    subplot('Position', thetaHistPos);
    % % Fit histogram to distribution
    % pd = fitdist(theta_deg, 'Normal');
    % x = min(theta_deg):0.1:max(theta_deg);
    % y = pdf(pd, x);
    % plot(x, y, 'LineWidth', 2);
    numBins = 60; 
    h = histogram(theta_deg, numBins);
    % Obtain histogram data
    binCounts = h.Values;
    binEdges = h.BinEdges;
    % Calculate the bin centers
    binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;    
    % Calculate piecewise linear interpolation
    x = binCenters;
    y = binCounts;
    % Generate points for the curve
    xInterp = linspace(min(binCenters), max(binCenters), 100); % Adjust as needed
    yInterp = interp1(x, y, xInterp, 'linear');   
    % Plot the piecewise linear curve over the histogram
    plot(xInterp, yInterp, 'b-', 'LineWidth', 1.5);
    hold on;
    % Remove ticks to make it cleaner
    set(gca, 'XTickLabel', [], 'YTickLabel', [], 'XTick', [], 'YTick', []);
    % Show the region that encompasses 25 to 75 percentiles
    percentile_25 = prctile(theta_deg, 25);
    percentile_75 = prctile(theta_deg, 75);
    rectangle('Position', [percentile_25, 0, percentile_75 - percentile_25, max(y) * 1.1], 'FaceColor', [1 0 0 0.3], 'EdgeColor', 'none');
    ylim([0, 1.1 * max(y)]);
    xlim([-180, 180]);
    hold off;

    % Show the distribution of phi TO THE RIGHT of the heatmap
    subplot('Position', phiHistPos);
    % % Fit histogram to distribution
    % pd = fitdist(phi_deg, 'Normal');
    % x = min(phi_deg):0.1:max(phi_deg);
    % y = pdf(pd, x);
    % plot(x, y, 'LineWidth', 2);
    h = histogram(phi_deg, numBins);
    % Obtain histogram data
    binCounts = h.Values;
    binEdges = h.BinEdges;
    % Calculate the bin centers
    binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;    
    % Calculate piecewise linear interpolation
    x = binCenters;
    y = binCounts;
    % Generate points for the curve
    xInterp = linspace(min(binCenters), max(binCenters), 100); % Adjust as needed
    yInterp = interp1(x, y, xInterp, 'linear');   
    % Plot the piecewise linear curve over the histogram
    plot(xInterp, yInterp, 'b-', 'LineWidth', 1.5);
    hold on;
    % Remove ticks to make it cleaner
    set(gca, 'XTickLabel', [], 'YTickLabel', [], 'XTick', [], 'YTick', []);
    % Show the region that encompasses 25 to 75 percentiles
    set(gca, 'View', [90 -90]);
    percentile_25 = prctile(phi_deg, 25);
    percentile_75 = prctile(phi_deg, 75);
    rectangle('Position', [percentile_25, 0, percentile_75 - percentile_25, max(y) * 1.1], 'FaceColor', [1 0 0 0.3], 'EdgeColor', 'none');
    ylim([0, 1.1 * max(y)]);
    xlim([-90, 90]);
    set(gca, 'XDir', 'reverse');
    hold off;

    % Show the heatmap itself
    subplot('Position', [0.10 0.10 0.65 0.65]);
    smoothed_data = smoothed_data';
    imagesc(smoothed_data);
    % hold on;
    % You can show the percentiles if you want
    % threshold_50 = median(smoothed_data(:));
    % threshold_75 = prctile(smoothed_data(:), 75);
    % threshold_90 = prctile(smoothed_data(:), 90);
    % [x, y] = meshgrid(1:size(smoothed_data, 2), 1:size(smoothed_data, 1));
    % contour(x, y, smoothed_data, [threshold_50, threshold_50], 'LineColor', 'r', 'LineWidth', 0.5);
    % contour(x, y, smoothed_data, [threshold_75, threshold_75], 'LineColor', 'white', 'LineWidth', 0.5);
    % contour(x, y, smoothed_data, [threshold_90, threshold_90], 'LineColor', 'yellow', 'LineWidth', 0.5);
    % hold off;

    % Define custom tick positions and labels
    xticks([0 125 250 375 499]);
    yticks([0 125 250 375 499]);

    if strcmp(coordSys, 'world')
        xticklabels({'-180', '-90', '0', '90', '180'});
        yticklabels({'90', '45', '0', '-45', '-90'});
    elseif strcmp(coordSys, 'head')
        xticklabels({'-40', '-20', '0', '20', '40'});
        yticklabels({'-40', '-20', '0', '20', '40'});
    end

    xlabel('Theta (degrees)');
    ylabel('Phi (degrees)');
    % Visibility off so it can be ploted all together
    ax = axes('Position', [0 0 1 1], 'Visible', 'off');
    text(0.90, 0.90, ['Gaze in ' coordSys ' for ' label0], 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');

    % Inform that data has been saved
    saveas(gcf, [supraLabel 'GazeAngleDist_OFF.png']);
    fprintf(['[SAVED] Gaze angle distrbution for ET-DDC off --> ' supraLabel 'GazeAngleDist_OFF.png\n']);

    

    % You can show some data from the distributions if desired
    % fprintf('D0 TH: Mean %0.2f - Median %0.2f - STD %0.2f\n', mean(d0(:, 1)), median(d0(:, 1)), std(d0(:, 1)));
    % fprintf('D1 TH: Mean %0.2f - Median %0.2f - STD %0.2f\n', mean(d1(:, 1)), median(d1(:, 1)), std(d1(:, 1)));
    % fprintf('D0 PHI: Mean %0.2f - Median %0.2f - STD %0.2f\n', mean(d0(:, 2)), median(d0(:, 2)), std(d0(:, 2)));
    % fprintf('D1 PHI: Mean %0.2f - Median %0.2f - STD %0.2f\n\n', mean(d1(:, 2)), median(d1(:, 2)), std(d1(:, 2)));
end

function analyzeGlmeEffects(glme, data_table, group, factor1, factor2, supraLabel, label0, label1)
    % glme is the fit glme model
    %
    % data_table is the original data table that was used to run the
    % fitglme function
    %
    % group, factor1, factor2, ... are tha string labels for each factor,
    % exactly as input in the glme formula.
    
    % We first dump the GLME results in a file.
    % Create a string to capture the display output
    outputString = evalc('disp(glme)');
    % Open the file for writing
    fileID = fopen([supraLabel 'GLME.txt'], 'w');
    % Write the output string to the file
    fprintf(fileID, '%s', outputString);
    % Close the file
    fclose(fileID);
   
    % Inform that data has been saved
    fprintf(['[SAVED] GLME results --> ' supraLabel 'GLME.txt\n']);
    

    % We then plot some additional higher-order interactions
    
    % Extract GLME coefficients
    coefficients = glme.Coefficients.Estimate;
    % Extract data from the table
    groupData = data_table.(group);
    factor1Data = data_table.(factor1);
    factor2Data = data_table.(factor2);

    % Generate interaction terms
    interaction_group_factor1 = groupData .* factor1Data;
    interaction_factor1_factor2 = factor1Data .* factor2Data;
    interaction_thirdLevel = groupData .* factor1Data .* factor2Data;

    % Predict response
    predictedResponse = coefficients(1) + ...
                         coefficients(2) * groupData + ...
                         coefficients(3) * factor1Data + ...
                         coefficients(4) * factor2Data + ...
                         coefficients(5) * interaction_group_factor1 + ...
                         coefficients(6) * interaction_factor1_factor2 + ...
                         coefficients(7) * interaction_thirdLevel;

    % Get unique group labels and assign colors
    uniqueGroups = unique(groupData);
    colors = lines(length(uniqueGroups));
    labels = {label0, label1};

    % Visualize second-order interaction with separate regression lines for each group
    figure('Position', [100, 100, 1400, 800], 'Visible', 'off');
    hold on;
    % Scatter points and fit regression lines for each group
    for i = 1:length(uniqueGroups)
        idx = ismember(groupData, uniqueGroups(i));
        scatter(factor1Data(idx), predictedResponse(idx), 50, colors(i, :), 'filled', 'DisplayName', labels{i});    
        % Fit a linear model for each group
        mdl = fitlm(factor1Data(idx), predictedResponse(idx));   
        % Plot the regression line
        xValues = linspace(min(factor1Data(idx)), max(factor1Data(idx)), 100);
        yValues = predict(mdl, xValues');
        plot(xValues, yValues, 'LineWidth', 2, 'Color', colors(i, :), 'DisplayName', labels{i});
    end
    hold off;
    xlabel(factor1);
    ylabel('Predicted Response');
    title(['Second-Order Interaction: ' factor1]);
    legend('show', 'Location', 'Best');
    
    % Inform that data has been saved
    saveas(gcf, [supraLabel 'SecondOrder_1.png']);
    fprintf(['[SAVED] Second order interaction plot --> ' supraLabel 'SecondOrder_1.png\n']);


    figure('Position', [100, 100, 1400, 800], 'Visible', 'off');
    hold on;
    % Scatter points and fit regression lines for each group
    for i = 1:length(uniqueGroups)
        idx = ismember(groupData, uniqueGroups(i));
        scatter(factor2Data(idx), predictedResponse(idx), 50, colors(i, :), 'filled', 'DisplayName', labels{i});   
        % Fit a linear model for each group
        mdl = fitlm(factor2Data(idx), predictedResponse(idx)); 
        % Plot the regression line
        xValues = linspace(min(factor2Data(idx)), max(factor2Data(idx)), 100);
        yValues = predict(mdl, xValues');
        plot(xValues, yValues, 'LineWidth', 2, 'Color', colors(i, :), 'DisplayName', labels{i});
    end
    hold off;    
    xlabel(factor2);
    ylabel('Predicted Response');
    title(['Second-Order Interaction: ' factor2]);
    legend('show', 'Location', 'Best');

    % Inform that data has been saved
    saveas(gcf, [supraLabel 'SecondOrder_2.png']);
    fprintf(['[SAVED] Second order interaction plot --> ' supraLabel 'SecondOrder_2.png\n']);


    % Visualize third-order interaction with surface
    figure('Position', [100, 100, 800, 800], 'Visible', 'off');
    hold on;    
    % Scatter points
    for i = 1:length(uniqueGroups)
        idx = ismember(groupData, uniqueGroups(i));
        scatter3(factor1Data(idx), factor2Data(idx), predictedResponse(idx), 50, colors(i, :), 'filled');
    end 
    % Create surface
    [X, Y] = meshgrid(unique(factor1Data), unique(factor2Data));
    warning('off', 'MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId');
    Z = griddata(factor1Data, factor2Data, predictedResponse, X, Y);
    warning('on', 'MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId');
    mesh(X, Y, Z, 'FaceAlpha', 0.5, 'EdgeAlpha', 0.5);    
    hold off;  
    xlabel(factor1);
    ylabel(factor2);
    zlabel('Predicted Response');
    title(['Third-Order Interaction: ' factor1 ' and ' factor2]);
    legend(arrayfun(@num2str, uniqueGroups, 'UniformOutput', false), 'Location', 'Best');

    % Inform that data has been saved
    saveas(gcf, [supraLabel 'ThirdOrder.png']);
    fprintf(['[SAVED] Thirs order interaction plot --> ' supraLabel 'ThirdOrder.png\n']);
end

% Todo --> Add statistical things when data is ready
function plotEvolutionInformation(evol0, evol1, supraLabels, fields, metrics, label0, label1, SSQ_totalSubscale, VIMSSQ_total);
    % Complete argument information


    % Iterate all stuff to be ploted and analyzed
    for i = 1:length(fieldnames(evol0))
        field = fields{i};
        data0 = evol0.(field);
        data1 = evol1.(field);
        supraLabel = supraLabels{i};
        metric = metrics{i};

        % We know that each of those have 4 chunks of time (because how we
        % defined our postprocessing thing).
        % We also know that those are .CH20, .CH40, .CH60, .L10

        % First plot the value evolution (base and normalized)
        figure('Position', [100, 100, 1400, 1000], 'Visible', 'off');

        % Define a color map
        color_map = lines(size(data0.L10));
        
        % Top-left subplot is raw evolution for condition 0
        subplot(2, 2, 1);
        hold on;
        plot([1, 2, 3, 4, 5], [data0.CH05, data0.CH20, data0.CH40, data0.CH60, data0.L10], 'o-', 'Color', color_map, 'LineWidth', 3);
        hold off;
        % ylim([])
        xticks(1:5);
        xticklabels({'CH05', 'CH20', 'CH40', 'CH60', 'L10'}); 
        title([metric ' evolution - ' label0]);
        
        % Top-right subplot is raw evolution for condition 1
        subplot(2, 2, 2);
        hold on;
        plot([1, 2, 3, 4, 5], [data1.CH05, data1.CH20, data1.CH40, data1.CH60, data1.L10], 'o-', 'Color', color_map, 'LineWidth', 3);
        hold off;
        % ylim([])
        xticks(1:5);
        xticklabels({'CH05', 'CH20', 'CH40', 'CH60', 'L10'}); 
        title([metric ' evolution - ' label1]);
        
        % Left subplot is normalized evolution for condition 0
        subplot(2, 2, 3);
        hold on;
        plot([1, 2, 3, 4, 5], [ data0.CH05 - data0.CH05, ...
                            data0.CH20 - data0.CH05,  ...
                            data0.CH40 - data0.CH05,  ...
                            data0.CH60 - data0.CH05,  ...
                            data0.L10  - data0.CH05], ...
             'o-', 'Color', color_map, 'LineWidth', 3);        
        hold off;
        % ylim([])
        xticks(1:5);
        xticklabels({'CH05', 'CH20', 'CH40', 'CH60', 'L10'}); 
        title([metric ' normalized evolution - ' label0]);
                
        % Right subplot
        subplot(2, 2, 4);
        hold on;
        plot([1, 2, 3, 4, 5], [ data1.CH05 - data1.CH05,  ...
                            data1.CH20 - data1.CH05, ...
                            data1.CH40 - data1.CH05, ...
                            data1.CH60 - data1.CH05, ...
                            data1.L10  - data1.CH05], ...
             'o-', 'Color', color_map, 'LineWidth', 3);        
        hold off;
        % ylim([])
        xticks(1:5);
        xticklabels({'CH05', 'CH20', 'CH40', 'CH60', 'L10'}); 
        title([metric ' normalized evolution - ' label1]);

        % Inform that data has been saved
        saveas(gcf, [supraLabel 'Evolution.png']);
        fprintf(['[SAVED] Evolution plot --> ' supraLabel 'Evolution.png\n']);

        % % Join all evolutions together for statistical analyses
        % evolOverTime = [data0.CH20; data0.CH40; data0.CH60; data0.L1; ...
        %                 data1.CH20; data1.CH40; data1.CH60; data1.L10];
        % % Condition (i.e., label0, label1)
        % % We know there are 4 sets of the same length for both conditions
        % group = [repmat(categorical(1), 1, 4 * numel(data0.CH20)), ...
        %          repmat(categorical(2), 1, 4 * numel(data0.CH20))]';
        % % Time chunk (1,2,3,4) is now also a factor
        % timechunk = [repmat(1, 1, numel(data0.CH20)), ...
        %              repmat(2, 1, numel(data0.CH20)), ...
        %              repmat(3, 1, numel(data0.CH20)), ...
        %              repmat(4, 1, numel(data0.CH20)), ...
        %              repmat(1, 1, numel(data0.CH20)), ...
        %              repmat(2, 1, numel(data0.CH20)), ...
        %              repmat(3, 1, numel(data0.CH20)), ...
        %              repmat(4, 1, numel(data0.CH20))]';
        % 
        % % Subjects follow a diff. structure than other analysis, cause each one
        % % is included four times (one per chunk) per condition
        % subjects = [subjects_OFF; subjects_OFF; subjects_OFF; subjects_OFF; ...
        %             subjects_ON; subjects_ON; subjects_ON; subjects_ON];
        % 
        % % Create a table
        % data_table = table(evolOverTime, group, timechunk, SSQ_totalSubscale, subjects);
        % 
        % % Fit the generalized linear mixed-effects model
        % glme = fitglme(data_table, 'headOverTime ~ 1 + group*timechunk*SSQ_totalSubscale + (1 | subjects)');
        % analyzeGlmeEffects(glme, data_table, 'group', 'timechunk', 'SSQ_totalSubscale', supraLabel, 'ET-DDC Off', 'ET-DDC On');
    end
end

function performTtest(var1, var2, text)
    % Perform a paired t-test
    [h, p, ci, stats] = ttest2(var1, var2, 'Alpha', 0.05);
     
    if h
        fprintf('%s (NO NORM) There is a significant difference, p-value = %.4f\n',text,p);
    else
        fprintf('%s (NO NORM) There is no significant difference, p-value = %.4f\n',text,p);
    end
end

function performNormalityAndTtest(var1, var2, text)
   % Perform the Kolmogorov-Smirnov test
    alpha = 0.05; % Set significance level
    
    [h1, p1] = kstest(var1);
    [h2, p2] = kstest(var2);
    
    if h1 == 0 && h2 == 0
        % Both conditions are normally distributed
        [~, p] = ttest2(var1, var2);
        
        if p < alpha
            fprintf('%s (NORM) There is a significant difference, p-value = %.4f\n',text,p);
        else
            fprintf('%s (NORM) There is no significant difference, p-value = %.4f\n',text,p);
        end
    else
        % At least one condition is not normally distributed, use a non-parametric test
        [p, ~] = ranksum(var1, var2);
        
        if p < alpha
            fprintf('%s (NO NORM) There is a significant difference, p-value = %.2f\n',text,p);
        else
            fprintf('%s (NO NORM) There is no significant difference, p-value = %.2f\n',text,p);
        end
    end


end

function angle = angleMagnitude(v)
    theta = atan2d(v(:, 2), v(:, 1));
    phi = atan2d(v(:, 3), sqrt(v(:, 1).^2 + v(:, 2).^2));
    angle = sqrt(theta.^2 + phi.^2);
end