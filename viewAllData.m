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

% Read the post-processed file from processAllData.m
if isfile(['data\post_processed\study2\S2-small-post-data.mat']) 
  load(['data\post_processed\study2\S2-small-post-data.mat'])
  all_user_info = small_all_user_info;
end

% Read survey info.
% Please note that for this survey, data is slightly hard-coded. Surveys
% can vary, although misery scales, SSQ, etc. should be similar (if not
% identical) if following same standards...
survey_data = readtable('data/survey/PSHourglass_PrePostData_Study1.csv');
% Order  both data sets similarly, to ensure a pair-wise relation
survey_data = sortrows(survey_data, {'ParticipantID', 'Condition'});
all_user_info = sortrows(all_user_info, {'UserID', 'ETDDC'});
% Keep only the questionnaires from the end of the session
rows_to_keep = ismember(survey_data.CompletionTime, 'Session end');
survey_data = survey_data(rows_to_keep, :);
fprintf('Data loaded correctly.\n');
toc;


tic;
% Check if, for some reason, some user/session has been included twice or
% more times (i.e., same entry multiple times)
key = strcat(string(all_user_info.UserID), '|', string(all_user_info.Day));
% Check for unique combinations
is_unique = length(unique(key)) == height(all_user_info);
% Remove duplicates based on the combination of values in Column1 and Column2
if ~is_unique
    [~, unique_indices, ~] = unique(key, 'stable');
    duplicate_indices = setdiff(1:height(all_user_info), unique_indices);
    all_user_info(duplicate_indices, :) = [];
    disp('Duplicates removed:');
else
    disp('No duplicates found.');
end

% We remove all users that have only done one session, because they have no
% pairwise info to be used in analyses. This can be changed if e.g., you
% only want visualizations, and not statistical things
% unique_values = unique(all_user_info.UserID);
% appear_once = unique_values(histcounts(double(all_user_info.UserID), double(unique_values)) == 1);
% all_user_info = all_user_info(~ismember(all_user_info.UserID, appear_once), :);

% Some examples of how to remove users manually
all_user_info = all_user_info(all_user_info.UserID ~= '040', :);
all_user_info = all_user_info(all_user_info.UserID ~= '041', :);

% Keep only info for those users that are in our analyses. Again this can
% be changed if only visualization is desired
currUsers = str2double(all_user_info.UserID);
rows_to_keep = ismember(survey_data.ParticipantID, currUsers);
survey_data = survey_data(rows_to_keep, :);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
% Prepare variables for statistical analysis %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %
%
% Please note that this is tied to the way survey is defined. Surveys
% should be defined similarly (i.e., with same headers). If they don't, it
% will be necessary to change the field names:
%
% survey_data.field_with_variable_to_analyze(strcmp(...))

% For all analysis onwards:
%
% variable0 means the condition is OFF (e.g., ET-DDC off)
% variable1 means the condition is ON  (e.g., ET-DDC on)

% Prepare VIMS and SSQ
% Note that I'm not doing these ones "agnostic" (e.g., naming them
% factor0, factor1, ... to favor readability. But it is important to
% understand that each of them is a factor for GLMM models
%
% SSQ_Subscale will be factor1
% VIMSSQ_total will be factor2
SSQ_totalSubscale0 = survey_data.SSQ_totalSubscale(strcmp(survey_data.Condition, 'ETDDC OFF'))';
SSQ_totalSubscale1 = survey_data.SSQ_totalSubscale(strcmp(survey_data.Condition, 'ETDDC ON'))';
VIMSSQ_total0 = survey_data.VIMSSQ_total(strcmp(survey_data.Condition, 'ETDDC OFF'))';
VIMSSQ_total1 = survey_data.VIMSSQ_total(strcmp(survey_data.Condition, 'ETDDC ON'))';
% Merge for statistical analyses
SSQ_totalSubscale = [SSQ_totalSubscale0, SSQ_totalSubscale1]';
VIMSSQ_total = [VIMSSQ_total0, VIMSSQ_total1]';
% Create subject identifiers
% Since we have our data ordered for users, then for sessions, we take user
% ID 1-in-1-out.
subjects_OFF = all_user_info.UserID(1:2:end-1)';
subjects_ON = all_user_info.UserID(2:2:end)';
subjects = [subjects_OFF subjects_ON];
[~,~,subjects] = unique(subjects);
% Create ET-DDC condition identifier
% Since we have first condition off, lets give it a 0 for consistency, and
% leave the other one as 1
group = [zeros(1, numel(SSQ_totalSubscale0)), ones(1, numel(SSQ_totalSubscale1))]';

% You can manually decide if some chunk should be skipped for analyses
data = {
    '009', '2', 'CH20';
    '009', '2', 'CH40';
    '009', '2', 'CH60';
    '009', '2', 'CH05';
    '009', '2', 'L10';
};
corrupted = table(data(:, 1), data(:, 2), data(:, 3), 'VariableNames', {'UserID', 'Session', 'Chunk'});

% ============================================================================= %
% ============================================================================= %
% ======================= RAW GAZE DATA and HEAD ORIENTATION ================== %
% ============================================================================= %
% ============================================================================= %

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
% These chunks respond to current way of performing analyses, namely
% CH20: Last 5 minutes of first chunk (15' to 20')
% CH40: Last 5 minutes of second chunk (35' to 40')
% CH60: Last 5 minutes of third chunk (55' to 60')
% L10: Last 10 minutes of session (70' to 80')
structs = {'CH20', 'CH40', 'CH60', 'L10'};

%% Important note: This chunk separation only works for Study 2 onwards
% If you want to re-run this for Study 1, you must only work with "L10",
% and comment all the parts of the code that go trhough/use CH20, 40 or 60.
% The other part of the code affected by this is the one related to
% "evolution over time"
for i = 1:length(structs)
    field = structs{i};
    % Gaze in head
    gazeHead0.(field).x = [];                       gazeHead1.(field).x = [];
    gazeHead0.(field).y = [];                       gazeHead1.(field).y = [];
    gazeHead0.(field).z = [];                       gazeHead1.(field).z = [];
    gazeHead0.(field).headRawGazeAngleMagn = [];    gazeHead1.(field).headRawGazeAngleMagn = [];
    gazeHead0.(field).headThetaMagn = [];           gazeHead1.(field).headThetaMagn = [];       
    gazeHead0.(field).headPhiMagn = [];             gazeHead1.(field).headPhiMagn = [];
    % Gaze in world
    gazeWorld0.(field).x = [];                      gazeWorld1.(field).x = [];
    gazeWorld0.(field).y = [];                      gazeWorld1.(field).y = [];
    gazeWorld0.(field).z = [];                      gazeWorld1.(field).z = [];
    gazeWorld0.(field).worldRawGazeAngleMagn = [];  gazeWorld1.(field).worldRawGazeAngleMagn = [];
    gazeWorld0.(field).worldThetaMagn = [];         gazeWorld1.(field).worldThetaMagn = [];       
    gazeWorld0.(field).worldPhiMagn = [];           gazeWorld1.(field).worldPhiMagn = [];
    % Gaze in world
    headWorld0.(field).x = [];                      headWorld1.(field).x = [];
    headWorld0.(field).y = [];                      headWorld1.(field).y = [];
    headWorld0.(field).z = [];                      headWorld1.(field).z = [];
    headWorld0.(field).worldRawGazeAngleMagn = [];  headWorld1.(field).worldRawGazeAngleMagn = [];
    headWorld0.(field).worldThetaMagn = [];         headWorld1.(field).worldThetaMagn = [];       
    headWorld0.(field).worldPhiMagn = [];           headWorld1.(field).worldPhiMagn = [];
end

for j = 1:length(structs)
    field = structs{j};
    for i = 1:height(all_user_info)
        % Recover head and eye traces 
        
        % Remove any chunk manually if desired (prev. defined)
        isTupleInTable = any(strcmp(corrupted.UserID, all_user_info.UserID(i)) & ...
                             strcmp(corrupted.Session, num2str(all_user_info.Session(i))) & ...
                             strcmp(corrupted.Chunk, field));
        if isTupleInTable
            continue;
        end

        switch field
            case 'CH20'
                eA = all_user_info.CH20_EyeInfo{i};
                hA = all_user_info.CH20_HeadInfo{i};
            case 'CH40'
                eA = all_user_info.CH40_EyeInfo{i};
                hA = all_user_info.CH40_HeadInfo{i};
            case 'CH60'
                eA = all_user_info.CH60_EyeInfo{i};
                hA = all_user_info.CH60_HeadInfo{i};
            otherwise
                eA = all_user_info.EyeInfo{i};
                hA = all_user_info.HeadInfo{i};
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


% Plot gaze data
fprintf('Analyzing and plotting raw gaze and head data.\n');
gH_L10  = plotGazeData(gazeHead0.L10,   gazeHead1.L10,   [dirPath1 'L10_GIHead_'], 'Ghead', 'ET-DDC Off', 'ET-DDC On');
gH_CH20 = plotGazeData(gazeHead0.CH20,  gazeHead1.CH20,  [dirPath1 'CH20_GIHead_'], 'Ghead', 'ET-DDC Off', 'ET-DDC On');
gH_CH40 = plotGazeData(gazeHead0.CH40,  gazeHead1.CH40,  [dirPath1 'CH40_GIHead_'], 'Ghead', 'ET-DDC Off', 'ET-DDC On');
gH_CH60 = plotGazeData(gazeHead0.CH60,  gazeHead1.CH60,  [dirPath1 'CH60_GIHead_'], 'Ghead', 'ET-DDC Off', 'ET-DDC On');
gW_L10  = plotGazeData(gazeWorld0.L10,  gazeWorld1.L10,  [dirPath1 'L10_GIWorld_'], 'Gworld', 'ET-DDC Off', 'ET-DDC On');
gW_CH20 = plotGazeData(gazeWorld0.CH20, gazeWorld1.CH20, [dirPath1 'CH20_GIWorld_'], 'Gworld', 'ET-DDC Off', 'ET-DDC On');
gW_CH40 = plotGazeData(gazeWorld0.CH40, gazeWorld1.CH40, [dirPath1 'CH40_GIWorld_'], 'Gworld', 'ET-DDC Off', 'ET-DDC On');
gW_CH60 = plotGazeData(gazeWorld0.CH60, gazeWorld1.CH60, [dirPath1 'CH60_GIWorld_'], 'Gworld', 'ET-DDC Off', 'ET-DDC On');
hW_L10  = plotGazeData(headWorld0.L10,  headWorld1.L10,  [dirPath2 'L10_HIWorld_'], 'Hworld', 'ET-DDC Off', 'ET-DDC On');
hW_CH20 = plotGazeData(headWorld0.CH20, headWorld1.CH20, [dirPath2 'CH20_HIWorld_'], 'Hworld', 'ET-DDC Off', 'ET-DDC On');
hW_CH40 = plotGazeData(headWorld0.CH40, headWorld1.CH40, [dirPath2 'CH40_HIWorld_'], 'Hworld', 'ET-DDC Off', 'ET-DDC On');
hW_CH60 = plotGazeData(headWorld0.CH60, headWorld1.CH60, [dirPath2 'CH60_HIWorld_'], 'Hworld', 'ET-DDC Off', 'ET-DDC On');
% Get some information about 2D distributions
calculateAndPlotHeatmapDifferences(gH_L10, gH_CH20, gH_CH40, gH_CH60, ...
                                   gW_L10, gW_CH20, gW_CH40, gW_CH60, ...
                                   hW_L10, hW_CH20, hW_CH40, hW_CH60); 



% Last 10 minutes for statistical analyses
%
% Overall angular distance in head space
headRawGazeAngleMagn = [gazeHead0.L10.headRawGazeAngleMagn; gazeHead1.L10.headRawGazeAngleMagn];
% Overall angular distance in world space
worldRawGazeAngleMagn = [gazeWorld0.L10.worldRawGazeAngleMagn; gazeWorld1.L10.worldRawGazeAngleMagn];
% Theta angular distance in head space
headThetaMagn = [gazeHead0.L10.headThetaMagn; gazeHead1.L10.headThetaMagn];
% Theta angular distance in world space
worldThetaMagn = [gazeWorld0.L10.worldThetaMagn; gazeWorld1.L10.worldThetaMagn];
% Phi angular distance in head space
headPhiMagn = [gazeHead0.L10.headPhiMagn; gazeHead1.L10.headPhiMagn];
% Phi angular distance in world space
worldPhiMagn = [gazeWorld0.L10.worldPhiMagn; gazeWorld1.L10.worldPhiMagn];

% Everything works like:
% 1 - Create a table for analysis
% 2 - Fit the generalized linear mixed-effects model
% 3 - Then save the GLME results and plot interaction effects

% % Check overall eye movement magnitude
% data_table = table(headRawGazeAngleMagn, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'headRawGazeAngleMagn ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_GIHead_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, headRawGazeAngleMagn, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*headRawGazeAngleMagn + headRawGazeAngleMagn*VIMSSQ_total + group:headRawGazeAngleMagn:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'headRawGazeAngleMagn', 'VIMSSQ_total', [dirPath 'SA_SSQ_GIHead_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(worldRawGazeAngleMagn, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'worldRawGazeAngleMagn ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_GIWorld_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, worldRawGazeAngleMagn, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*worldRawGazeAngleMagn + worldRawGazeAngleMagn*VIMSSQ_total + group:worldRawGazeAngleMagn:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'worldRawGazeAngleMagn', 'VIMSSQ_total', [dirPath 'SA_SSQ_GIWorld_'], 'ET-DDC Off', 'ET-DDC On');

% % The same but only for the first 5 minutes block
% % Note that you can do this for as many blocks as needed
% data_table = table(FM_headRawGazeAngleMagn, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'FM_headRawGazeAngleMagn ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'FM_SA_GIHead_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, FM_headRawGazeAngleMagn, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*FM_headRawGazeAngleMagn + FM_headRawGazeAngleMagn*VIMSSQ_total + group:FM_headRawGazeAngleMagn:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'FM_headRawGazeAngleMagn', 'VIMSSQ_total', [dirPath 'FM_SA_SSQ_GIHead_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(FM_worldRawGazeAngleMagn, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'FM_worldRawGazeAngleMagn ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'FM_SA_GIWorld_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, FM_worldRawGazeAngleMagn, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*FM_worldRawGazeAngleMagn + FM_worldRawGazeAngleMagn*VIMSSQ_total + group:FM_worldRawGazeAngleMagn:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'FM_worldRawGazeAngleMagn', 'VIMSSQ_total', [dirPath 'FM_SA_SSQ_GIWorld_'], 'ET-DDC Off', 'ET-DDC On');

% % Check granularly (i.e., each angle on isolation)
% data_table = table(headThetaMagn, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'headThetaMagn ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_GIHead_Theta_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, headThetaMagn, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*headThetaMagn + headThetaMagn*VIMSSQ_total + group:headThetaMagn:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'headThetaMagn', 'VIMSSQ_total', [dirPath 'SA_SSQ_Head_Theta_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(headPhiMagn, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'headPhiMagn ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_GIHead_Phi_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, headPhiMagn, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*headPhiMagn + headPhiMagn*VIMSSQ_total + group:headPhiMagn:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'headPhiMagn', 'VIMSSQ_total', [dirPath 'SA_SSQ_Head_Phi_'], 'ET-DDC Off', 'ET-DDC On');

% Perform Levene's test (I'm not saving this one so far)
[pValue, stat] = vartestn([headWorld0.L10.worldRawGazeAngleMagn; headWorld1.L10.worldRawGazeAngleMagn], 'TestType', 'LeveneAbsolute');
% Display the results
disp(['Levene''s Test p-value: ' num2str(pValue)]);


% =============================================================== %
% =============================================================== %
% ======================= FIX GAZE DATA ========================= %
% =============================================================== %
% =============================================================== %

% If the directory does not exist, create it
dirPath = 'results/study2/fixations/';
if exist(dirPath, 'dir') ~= 7
    mkdir(dirPath);
    disp(['[MKDIR] Directory created: ' dirPath]);
end


% Gaze in head space 
fixHead0 = struct();        fixHead1 = struct(); 
fixHead0.x = [];            fixHead1.x = [];
fixHead0.y = [];            fixHead1.y = [];
fixHead0.z = [];            fixHead1.z = [];
headFixAngleMagn0 = [];
headFixThetaMagn0 = [];     headFixPhiMagn0 = [];
headFixAngleMagn1 = [];
headFixThetaMagn1 = [];     headFixPhiMagn1 = [];

% Gaze in world space
fixWorld0 = struct();       fixWorld1 = struct(); 
fixWorld0.x = [];           fixWorld1.x = [];
fixWorld0.y = [];           fixWorld1.y = [];
fixWorld0.z = [];           fixWorld1.z = [];
worldFixAngleMagn0 = [];
worldFixThetaMagn0 = [];    worldFixPhiMagn0 = [];
worldFixAngleMagn1 = [];
worldFixThetaMagn1 = [];    worldFixPhiMagn1 = [];

for i = 1:height(all_user_info)
    % Recover eye, head, and fixation traces
    eA = all_user_info.EyeInfo{i};
    gF = all_user_info.gazeFix{i};
    hA = all_user_info.HeadInfo{i};
    % Iterate fixations and look for first gaze point w/ such a timestamp
    idx = find(ismember(eA.timestamp, gF.onsetTime));
    gH = [eA.gazePosHeadFiltX(idx) eA.gazePosHeadFiltY(idx) eA.gazePosHeadFiltZ(idx)] / 1000;
    gH = gH(~any(isnan(gH), 2), :);
    gW = [eA.gazePosWorldFiltX(idx) eA.gazePosWorldFiltY(idx) eA.gazePosWorldFiltZ(idx)] / 1000;
    gW = gW(~any(isnan(gW), 2), :);
    if all_user_info.ETDDC(i) == 0
        % Store gaze in head
        fixHead0.x = [fixHead0.x ; gH(:, 1)];
        fixHead0.y = [fixHead0.y ; gH(:, 2)];
        fixHead0.z = [fixHead0.z ; gH(:, 3)];
        % Store gaze in world
        fixWorld0.x = [fixWorld0.x ; gW(:, 1)];
        fixWorld0.y = [fixWorld0.y ; gW(:, 2)];
        fixWorld0.z = [fixWorld0.z ; gW(:, 3)];
        % Pre-compute eye movements for statistical analyses (head)
        theta = -atan2d(gH(:, 2), gH(:, 1));
        phi = atan2d(gH(:, 3), sqrt(gH(:, 1).^2 + gH(:, 2).^2));
        headFixAngleMagn0 = [headFixAngleMagn0 ; median(sqrt(theta.^2 + phi.^2))];
        headFixPhiMagn0 = [headFixPhiMagn0 ; median(phi)];
        headFixThetaMagn0 = [headFixThetaMagn0 ; median(theta)];
        % Pre-compute eye movements for statistical analyses (world)
        theta = -atan2d(gW(:, 2), gW(:, 1));
        phi = atan2d(gW(:, 3), sqrt(gW(:, 1).^2 + gW(:, 2).^2));
        worldFixAngleMagn0 = [worldFixAngleMagn0 ; median(sqrt(theta.^2 + phi.^2))];
        worldFixPhiMagn0 = [worldFixPhiMagn0 ; median(phi)];
        worldFixThetaMagn0 = [worldFixThetaMagn0 ; median(theta)];
    else
        % Store gaze in head
        fixHead1.x = [fixHead1.x ; gH(:, 1)];
        fixHead1.y = [fixHead1.y ; gH(:, 2)];
        fixHead1.z = [fixHead1.z ; gH(:, 3)];
        % Store gaze in world
        fixWorld1.x = [fixWorld1.x ; gW(:, 1)];
        fixWorld1.y = [fixWorld1.y ; gW(:, 2)];
        fixWorld1.z = [fixWorld1.z ; gW(:, 3)];
        % Pre-compute eye movements for statistical analyses (head)
        theta = -atan2d(gH(:, 2), gH(:, 1));
        phi = atan2d(gH(:, 3), sqrt(gH(:, 1).^2 + gH(:, 2).^2));
        headFixAngleMagn1 = [headFixAngleMagn1 ; median(sqrt(theta.^2 + phi.^2))];
        headFixPhiMagn1 = [headFixPhiMagn1 ; median(phi)];
        headFixThetaMagn1 = [headFixThetaMagn1 ; median(theta)];
        % Pre-compute eye movements for statistical analyses (world)
        theta = -atan2d(gW(:, 2), gW(:, 1));
        phi = atan2d(gW(:, 3), sqrt(gW(:, 1).^2 + gW(:, 2).^2));
        worldFixAngleMagn1 = [worldFixAngleMagn1 ; median(sqrt(theta.^2 + phi.^2))];
        worldFixPhiMagn1 = [worldFixPhiMagn1 ; median(phi)];
        worldFixThetaMagn1 = [worldFixThetaMagn1 ; median(theta)];
    end
    
end

% Similar to above
headFixAngleMagn = [headFixAngleMagn0; headFixAngleMagn1];
worldFixAngleMagn = [worldFixAngleMagn0; worldFixAngleMagn1];
headFixThetaMagn = [headFixThetaMagn0; headFixThetaMagn1];
worldFixThetaMagn = [worldFixThetaMagn0; worldFixThetaMagn1];
headFixPhiMagn = [headFixPhiMagn0; headFixPhiMagn1];
worldFixPhiMagn = [worldFixPhiMagn0; worldFixPhiMagn1];

% Plot gaze data
fprintf('Analyzing and plotting fixation data.\n');
% plotGazeData(fixHead0, fixHead1, [dirPath 'FixHead_'], 'head', 'ET-DDC Off', 'ET-DDC On');
% plotGazeData(fixWorld0, fixWorld1, [dirPath 'FixWorld_'], 'world', 'ET-DDC Off', 'ET-DDC On');

% Everything works like:
% 1 - Create a table for analysis
% 2 - Fit the generalized linear mixed-effects model
% 3 - Then save the GLME results and plot interaction effects

% % Check overall eye movement magnitude
% data_table = table(headFixAngleMagn, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'headFixAngleMagn ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_FixHead_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, headFixAngleMagn, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*headFixAngleMagn + headFixAngleMagn*VIMSSQ_total + group:headFixAngleMagn:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'headFixAngleMagn', 'VIMSSQ_total', [dirPath 'SA_SSQ_FixHead_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(worldFixAngleMagn, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'worldFixAngleMagn ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_FixWorld_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, worldFixAngleMagn, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*worldFixAngleMagn + worldFixAngleMagn*VIMSSQ_total + group:worldFixAngleMagn:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'worldFixAngleMagn', 'VIMSSQ_total', [dirPath 'SA_SSQ_FixWorld_'], 'ET-DDC Off', 'ET-DDC On');

% % Check granularly (i.e., each angle on isolation)
% data_table = table(headFixThetaMagn, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'headFixThetaMagn ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_FixHead_Theta_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, headFixThetaMagn, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*headFixThetaMagn + headFixThetaMagn*VIMSSQ_total + group:headFixThetaMagn:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'headFixThetaMagn', 'VIMSSQ_total', [dirPath 'SA_SSQ_FixHead_Theta_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(headFixPhiMagn, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'headFixPhiMagn ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_FixHead_Phi_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, headFixPhiMagn, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*headFixPhiMagn + headFixPhiMagn*VIMSSQ_total + group:headFixPhiMagn:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'headFixPhiMagn', 'VIMSSQ_total', [dirPath 'SA_SSQ_FixHead_Phi_'], 'ET-DDC Off', 'ET-DDC On');

% % Perform Levene's test
% [pValue, stat] = vartestn([headFixAngleMagn0 headFixAngleMagn1], 'TestType', 'LeveneAbsolute');
% % Display the results
% disp(['Levene''s Test p-value: ' num2str(pValue)]);
% 
% % Perform Levene's test
% [pValue, stat] = vartestn([headFixThetaMagn0 headFixThetaMagn1], 'TestType', 'LeveneAbsolute');
% % Display the results
% disp(['Levene''s Test p-value: ' num2str(pValue)]);



% =============================================================== %
% =============================================================== %
% ======================= SAC GAZE DATA ========================= %
% =============================================================== %
% =============================================================== %

% If the directory does not exist, create it
dirPath = 'results/study2/saccades/';
if exist(dirPath, 'dir') ~= 7
    mkdir(dirPath);
    disp(['[MKDIR] Directory created: ' dirPath]);
end


% Saccade in head space 
gazeSac0 = struct();      gazeSac1 = struct();  
gazeSac0.dirX = [];       gazeSac1.dirX = [];
gazeSac0.dirY = [];       gazeSac1.dirY = []; 
gazeSac0.dirZ = [];       gazeSac1.dirZ = [];
gazeSac0.mag = [];        gazeSac1.mag = [];  
gazeSac0.endX = [];       gazeSac1.endX = [];
gazeSac0.endY = [];       gazeSac1.endY = [];
gazeSac0.endZ = [];       gazeSac1.endZ = [];

for i = 1:height(all_user_info)
    % Get eye and head traces
    eA = all_user_info.EyeInfo{i};
    gF = all_user_info.saccade{i};
    hA = all_user_info.HeadInfo{i};
    % Iterate fixations and look for first gaze point w/ such a timestamp
    idx_inset = find(ismember(eA.timestamp, gF.onsetTime));
    idx_offset = find(ismember(eA.timestamp, gF.offsetTime));
    % Get the direction vector of the saccade
    saccadeDir = [eA.gazePosHeadFiltX(idx_offset) - eA.gazePosHeadFiltX(idx_inset), ...
                   eA.gazePosHeadFiltY(idx_offset) - eA.gazePosHeadFiltY(idx_inset), ...
                   eA.gazePosHeadFiltZ(idx_offset) - eA.gazePosHeadFiltZ(idx_inset)];
    if all_user_info.ETDDC(i) == 0
        % Store direction
        gazeSac0.dirX = [gazeSac0.dirX ; saccadeDir(:, 1)];
        gazeSac0.dirY = [gazeSac0.dirY ; saccadeDir(:, 2)];
        gazeSac0.dirZ = [gazeSac0.dirZ ; saccadeDir(:, 3)];
        % Calculate magnitude
        gazeSac0.mag =  [gazeSac0.mag; sqrt(sum(saccadeDir.^2, 2)) / 1000];
        % Get landing position
        gazeSac0.endX = [gazeSac0.endX ; eA.gazePosHeadFiltX(idx_offset)];
        gazeSac0.endY = [gazeSac0.endY ; eA.gazePosHeadFiltY(idx_offset)];
        gazeSac0.endZ = [gazeSac0.endZ ; eA.gazePosHeadFiltZ(idx_offset)];
        % Precompute angles
        theta = -atan2(gazeSac0.endY, gazeSac0.endX);
        phi = atan2(gazeSac0.endZ, sqrt(gazeSac0.endX.^2 + gazeSac0.endY.^2));
        theta_deg = rad2deg(theta);
        phi_deg = rad2deg(phi);
    else
        % Store direction
        gazeSac1.dirX = [gazeSac1.dirX ; saccadeDir(:, 1)];
        gazeSac1.dirY = [gazeSac1.dirY ; saccadeDir(:, 2)];
        gazeSac1.dirZ = [gazeSac1.dirZ ; saccadeDir(:, 3)];
        % Calculate magnitude
        gazeSac1.mag = [gazeSac1.mag; sqrt(sum(saccadeDir.^2, 2)) / 1000];
        % Get landing position
        gazeSac1.endX = [gazeSac1.endX ; eA.gazePosHeadFiltX(idx_offset)];
        gazeSac1.endY = [gazeSac1.endY ; eA.gazePosHeadFiltY(idx_offset)];
        gazeSac1.endZ = [gazeSac1.endZ ; eA.gazePosHeadFiltZ(idx_offset)];
        % Precompute angles 
        theta = -atan2(gazeSac0.endY, gazeSac0.endX);
        phi = atan2(gazeSac0.endZ, sqrt(gazeSac0.endX.^2 + gazeSac0.endY.^2));
        theta_deg = rad2deg(theta);
        phi_deg = rad2deg(phi);
    end
end

% This one has no functionalities developed yet, but it will soon


% =============================================================== %
% =============================================================== %
% ========================= HEAD DATA =========================== %
% =============================================================== %
% =============================================================== %

% If the directory does not exist, create it
dirPath = 'results/study2/head/';
if exist(dirPath, 'dir') ~= 7
    mkdir(dirPath);
    disp(['[MKDIR] Directory created: ' dirPath]);
end


% For last 10 minutes
rotVel0 = [];
rotVel1 = [];
rotVel3D0 = [];
rotVel3D1 = [];

for i = 1:height(all_user_info)
    zero_indices = all_user_info.HeadInfo{i}.displace2D == 0;
    all_user_info.HeadInfo{i} = all_user_info.HeadInfo{i}(~zero_indices, :);
    % zero_indices = all_user_info.FM_HeadInfo{i}.displace2D == 0;
    % all_user_info.FM_HeadInfo{i} = all_user_info.FM_HeadInfo{i}(~zero_indices, :);
    if all_user_info.ETDDC(i) == 0
        rotVel0 = [rotVel0 ...
           nanmedian(all_user_info.HeadInfo{i}.displace2D)];
        rotVel3D0 = [rotVel3D0 ...
           nanmedian(all_user_info.HeadInfo{i}.rotVel3D)];
    else
        rotVel1 = [rotVel1 ...
           nanmedian(all_user_info.HeadInfo{i}.displace2D)];
        rotVel3D1 = [rotVel3D1 ...
           nanmedian(all_user_info.HeadInfo{i}.rotVel3D)];
    end
end
% For last 10 minutes
velocity = [rotVel0, rotVel1]';
velocity3D = [rotVel3D0, rotVel3D1]';

% Everything works like:
% 1 - Create a table for analysis
% 2 - Fit the generalized linear mixed-effects model
% 3 - Then save the GLME results and plot interaction effects

fprintf('Analyzing head data.\n');

% Last 10 minutes

% % Check overall 2D head movement magnitude
% data_table = table(velocity, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'velocity ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_2DHead_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, velocity, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*velocity + velocity*VIMSSQ_total + group:velocity:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'velocity', 'VIMSSQ_total', [dirPath 'SA_SSQ_2DHead_'], 'ET-DDC Off', 'ET-DDC On');
% 
% % Check overall 3D head movement magnitude
% data_table = table(velocity3D, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'velocity3D ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_3DHead_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, velocity3D, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*velocity3D + velocity3D*VIMSSQ_total + group:velocity3D:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'velocity3D', 'VIMSSQ_total', [dirPath 'SA_SSQ_3DHead_'], 'ET-DDC Off', 'ET-DDC On');

% % Plotting
% plotPairwiseHeadInfo(rotVel0, rotVel1, [dirPath 'Head2D_'], '2D head movement', 'ET-DDC Off', 'ET-DDC On');
% plotPairwiseHeadInfo(rotVel3D0, rotVel3D1, [dirPath 'Head3D_'], '3D head movement', 'ET-DDC Off', 'ET-DDC On');

% First 5 minutes

% % Check overall 2D head movement magnitude
% data_table = table(FM_velocity, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'FM_velocity ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'FM_SA_2DHead_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, FM_velocity, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*FM_velocity + FM_velocity*VIMSSQ_total + group:FM_velocity:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'FM_velocity', 'VIMSSQ_total', [dirPath 'FM_SA_SSQ_2DHead_'], 'ET-DDC Off', 'ET-DDC On');
% 
% % Check overall 3D head movement magnitude
% data_table = table(FM_velocity3D, group, SSQ_totalSubscale, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'FM_velocity3D ~ 1 + group*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + group:SSQ_totalSubscale:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'FM_SA_3DHead_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, group, FM_velocity3D, VIMSSQ_total, subjects);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + group*FM_velocity3D + FM_velocity3D*VIMSSQ_total + group:FM_velocity3D:VIMSSQ_total + (1 | subjects)');
% analyzeGlmeEffects(glme, data_table, 'group', 'FM_velocity3D', 'VIMSSQ_total', [dirPath 'FM_SA_SSQ_3DHead_'], 'ET-DDC Off', 'ET-DDC On');

% % Plotting
% plotPairwiseHeadInfo(FM_rotVel0, FM_rotVel1, [dirPath 'FM_Head2D_'], '2D head movement', 'ET-DDC Off', 'ET-DDC On');
% plotPairwiseHeadInfo(FM_rotVel3D0, FM_rotVel3D1, [dirPath 'FM_Head3D_'], '3D head movement', 'ET-DDC Off', 'ET-DDC On');




% =============================================================== %
% =============================================================== %
% ========================= EVOLUTION =========================== %
% =============================================================== %
% =============================================================== %

%% Important note: Again, this only works for Study 2 onwards.
% if you want to run this for Study 1, then probably comment this big chunk
% of code and forget about it.

% Let's check evolution of different variables
evol0 = struct();                       evol1 = struct();
% Head movements per chunk of time
evol0.rotVel3D = struct();              evol1.rotVel3D = struct();
evol0.rotVel3D.CH05 = [];               evol1.rotVel3D.CH05 = [];
evol0.rotVel3D.CH20 = [];               evol1.rotVel3D.CH20 = [];
evol0.rotVel3D.CH40 = [];               evol1.rotVel3D.CH40 = [];
evol0.rotVel3D.CH60 = [];               evol1.rotVel3D.CH60 = [];
evol0.rotVel3D.L10 = [];                evol1.rotVel3D.L10 = [];
% Gaze in head movements per chunk of time
evol0.gazeHeadAngle = struct();         evol1.gazeHeadAngle = struct();
evol0.gazeHeadAngle.CH05 = [];          evol1.gazeHeadAngle.CH05 = [];
evol0.gazeHeadAngle.CH20 = [];          evol1.gazeHeadAngle.CH20 = [];
evol0.gazeHeadAngle.CH40 = [];          evol1.gazeHeadAngle.CH40 = [];
evol0.gazeHeadAngle.CH60 = [];          evol1.gazeHeadAngle.CH60 = [];
evol0.gazeHeadAngle.L10 = [];           evol1.gazeHeadAngle.L10 = [];
% Gaze in world movements per chunk of time
evol0.gazeWorldAngle = struct();        evol1.gazeWorldAngle = struct();
evol0.gazeWorldAngle.CH05 = [];         evol1.gazeWorldAngle.CH05 = [];
evol0.gazeWorldAngle.CH20 = [];         evol1.gazeWorldAngle.CH20 = [];
evol0.gazeWorldAngle.CH40 = [];         evol1.gazeWorldAngle.CH40 = [];
evol0.gazeWorldAngle.CH60 = [];         evol1.gazeWorldAngle.CH60 = [];
evol0.gazeWorldAngle.L10 = [];          evol1.gazeWorldAngle.L10 = [];


% Iterate data and get it from different chunks
for i = 1:height(all_user_info)
    
    % If the user is missing chunks, we should not use the session here
    isTupleInTable = any(strcmp(corrupted.UserID, all_user_info.UserID(i)) & ...
                         strcmp(corrupted.Session, num2str(all_user_info.Session(i))));
    if isTupleInTable
        continue;
    end
    
    % Head info from chunks
    hI_CH05 = all_user_info.CH05_HeadInfo{i};
    hI_CH20 = all_user_info.CH20_HeadInfo{i};
    hI_CH40 = all_user_info.CH40_HeadInfo{i};
    hI_CH60 = all_user_info.CH60_HeadInfo{i};
    hI_L10 = all_user_info.HeadInfo{i};
    % Eye info from chunks
    eI_CH05 = all_user_info.CH05_EyeInfo{i};
    eI_CH20 = all_user_info.CH20_EyeInfo{i};
    eI_CH40 = all_user_info.CH40_EyeInfo{i};
    eI_CH60 = all_user_info.CH60_EyeInfo{i};
    eI_L10 = all_user_info.EyeInfo{i};
    % This is gaze position in head space 
    gH_CH05 = [eI_CH05.gazePosHeadFiltX eI_CH05.gazePosHeadFiltY eI_CH05.gazePosHeadFiltZ] / 1000;
    gH_CH20 = [eI_CH20.gazePosHeadFiltX eI_CH20.gazePosHeadFiltY eI_CH20.gazePosHeadFiltZ] / 1000;
    gH_CH40 = [eI_CH40.gazePosHeadFiltX eI_CH40.gazePosHeadFiltY eI_CH40.gazePosHeadFiltZ] / 1000;
    gH_CH60 = [eI_CH60.gazePosHeadFiltX eI_CH60.gazePosHeadFiltY eI_CH60.gazePosHeadFiltZ] / 1000;
    gH_L10 = [eI_L10.gazePosHeadFiltX eI_L10.gazePosHeadFiltY eI_L10.gazePosHeadFiltZ] / 1000;
    gH_CH05 = gH_CH05(~any(isnan(gH_CH05), 2), :);
    gH_CH20 = gH_CH20(~any(isnan(gH_CH20), 2), :);
    gH_CH40 = gH_CH40(~any(isnan(gH_CH40), 2), :);
    gH_CH60 = gH_CH60(~any(isnan(gH_CH60), 2), :);
    gH_L10 = gH_L10(~any(isnan(gH_L10), 2), :);
    % This is gaze position in world space
    gW_CH05 = [eI_CH05.gazePosWorldFiltX eI_CH05.gazePosWorldFiltY eI_CH05.gazePosWorldFiltZ] / 1000;
    gW_CH20 = [eI_CH20.gazePosWorldFiltX eI_CH20.gazePosWorldFiltY eI_CH20.gazePosWorldFiltZ] / 1000;
    gW_CH40 = [eI_CH40.gazePosWorldFiltX eI_CH40.gazePosWorldFiltY eI_CH40.gazePosWorldFiltZ] / 1000;
    gW_CH60 = [eI_CH60.gazePosWorldFiltX eI_CH60.gazePosWorldFiltY eI_CH60.gazePosWorldFiltZ] / 1000;
    gW_L10 = [eI_L10.gazePosWorldFiltX eI_L10.gazePosWorldFiltY eI_L10.gazePosWorldFiltZ] / 1000;
    gW_CH05 = gW_CH05(~any(isnan(gW_CH05), 2), :);
    gW_CH20 = gW_CH20(~any(isnan(gW_CH20), 2), :);
    gW_CH40 = gW_CH40(~any(isnan(gW_CH40), 2), :);
    gW_CH60 = gW_CH60(~any(isnan(gW_CH60), 2), :);
    gW_L10 = gW_L10(~any(isnan(gW_L10), 2), :);
   
    % Store
    if all_user_info.ETDDC(i) == 0
        % Save 3D head rotation
        evol0.rotVel3D.CH05 = [evol0.rotVel3D.CH05; nanmedian(hI_CH05.rotVel3DFilt)];
        evol0.rotVel3D.CH20 = [evol0.rotVel3D.CH20; nanmedian(hI_CH20.rotVel3DFilt)];
        evol0.rotVel3D.CH40 = [evol0.rotVel3D.CH40; nanmedian(hI_CH40.rotVel3DFilt)];
        evol0.rotVel3D.CH60 = [evol0.rotVel3D.CH60; nanmedian(hI_CH60.rotVel3DFilt)];
        evol0.rotVel3D.L10  = [evol0.rotVel3D.L10;  nanmedian(hI_L10.rotVel3DFilt)];
        % Save gaze in head
        evol0.gazeHeadAngle.CH05 = [evol0.gazeHeadAngle.CH05; nanmedian(angleMagnitude(gH_CH05))];
        evol0.gazeHeadAngle.CH20 = [evol0.gazeHeadAngle.CH20; nanmedian(angleMagnitude(gH_CH20))];
        evol0.gazeHeadAngle.CH40 = [evol0.gazeHeadAngle.CH40; nanmedian(angleMagnitude(gH_CH40))];
        evol0.gazeHeadAngle.CH60 = [evol0.gazeHeadAngle.CH60; nanmedian(angleMagnitude(gH_CH60))];
        evol0.gazeHeadAngle.L10  = [evol0.gazeHeadAngle.L10;  nanmedian(angleMagnitude(gH_L10))];
        % Save gaze in world
        evol0.gazeWorldAngle.CH05 = [evol0.gazeWorldAngle.CH05; nanmedian(angleMagnitude(gW_CH05))];
        evol0.gazeWorldAngle.CH20 = [evol0.gazeWorldAngle.CH20; nanmedian(angleMagnitude(gW_CH20))];
        evol0.gazeWorldAngle.CH40 = [evol0.gazeWorldAngle.CH40; nanmedian(angleMagnitude(gW_CH40))];
        evol0.gazeWorldAngle.CH60 = [evol0.gazeWorldAngle.CH60; nanmedian(angleMagnitude(gW_CH60))];
        evol0.gazeWorldAngle.L10  = [evol0.gazeWorldAngle.L10;  nanmedian(angleMagnitude(gW_L10))];
    else
        % Save 3D head rotation
        evol1.rotVel3D.CH05 = [evol1.rotVel3D.CH05; nanmedian(hI_CH05.rotVel3DFilt)];
        evol1.rotVel3D.CH20 = [evol1.rotVel3D.CH20; nanmedian(hI_CH20.rotVel3DFilt)];
        evol1.rotVel3D.CH40 = [evol1.rotVel3D.CH40; nanmedian(hI_CH40.rotVel3DFilt)];
        evol1.rotVel3D.CH60 = [evol1.rotVel3D.CH60; nanmedian(hI_CH60.rotVel3DFilt)];
        evol1.rotVel3D.L10  = [evol1.rotVel3D.L10;  nanmedian(hI_L10.rotVel3DFilt)];
        % Save gaze in head
        evol1.gazeHeadAngle.CH05 = [evol1.gazeHeadAngle.CH05; nanmedian(angleMagnitude(gH_CH05))];
        evol1.gazeHeadAngle.CH20 = [evol1.gazeHeadAngle.CH20; nanmedian(angleMagnitude(gH_CH20))];
        evol1.gazeHeadAngle.CH40 = [evol1.gazeHeadAngle.CH40; nanmedian(angleMagnitude(gH_CH40))];
        evol1.gazeHeadAngle.CH60 = [evol1.gazeHeadAngle.CH60; nanmedian(angleMagnitude(gH_CH60))];
        evol1.gazeHeadAngle.L10  = [evol1.gazeHeadAngle.L10;  nanmedian(angleMagnitude(gH_L10))];
        % Save gaze in world
        evol1.gazeWorldAngle.CH05 = [evol1.gazeWorldAngle.CH05; nanmedian(angleMagnitude(gW_CH05))];
        evol1.gazeWorldAngle.CH20 = [evol1.gazeWorldAngle.CH20; nanmedian(angleMagnitude(gW_CH20))];
        evol1.gazeWorldAngle.CH40 = [evol1.gazeWorldAngle.CH40; nanmedian(angleMagnitude(gW_CH40))];
        evol1.gazeWorldAngle.CH60 = [evol1.gazeWorldAngle.CH60; nanmedian(angleMagnitude(gW_CH60))];
        evol1.gazeWorldAngle.L10  = [evol1.gazeWorldAngle.L10;  nanmedian(angleMagnitude(gW_L10))];
    end
end

% All the things whose evolutions are being analyzed...
supraLabels = {'results/study2/head/3DHead_', 'results/study2/rawGaze/GIHead_', 'results/study2/rawGaze/GIWorld_'};
fields = {'rotVel3D', 'gazeHeadAngle', 'gazeWorldAngle'};
metrics = {'3D head movement', 'Gaze in head', 'Gaze in world'};

% This function does both plotting and GLME because it is slightly funky
plotEvolutionInformation(evol0, evol1, supraLabels, fields, metrics, 'ET-DDC Off', 'ET-DDC On', SSQ_totalSubscale, VIMSSQ_total);


fprintf('Now analyzing specific eye movements\n');

% =============================================================== %
% =============================================================== %
% ========================= FIXATIONS =========================== %
% =============================================================== %
% =============================================================== %

% If the directory does not exist, create it
dirPath = 'results/study2/fixations/';
if exist(dirPath, 'dir') ~= 7
    mkdir(dirPath);
    disp(['[MKDIR] Directory created: ' dirPath]);
end

% Initialize an empty array to store fixation durations
allFixDur0 = [];            allFixDur1 = [];
fixNumber0 = [];            fixNumber1 = [];
fixPerSec0 = [];            fixPerSec1 = [];
% These ones are for statistical analysis
allFixDur = [];             
fixPerSec = [];
userFix = [];
condFix = [];

% Iterate through each row of the table and concat fixation data for ETDDC = 0
for i = 1:height(all_user_info)
    if all_user_info.ETDDC(i) == 0
        allFixDur0 = [allFixDur0; all_user_info.FixationInfo{i}.dur_fix];
        fixNumber0 = [fixNumber0; all_user_info.FixationInfo{i}.tot_fix];
        fixPerSec0 = [fixPerSec0; all_user_info.FixationInfo{i}.fix_per_sec];
    elseif all_user_info.ETDDC(i) == 1
        allFixDur1 = [allFixDur1; all_user_info.FixationInfo{i}.dur_fix];      
        fixNumber1 = [fixNumber1; all_user_info.FixationInfo{i}.tot_fix];
        fixPerSec1 = [fixPerSec1; all_user_info.FixationInfo{i}.fix_per_sec];
    end
    allFixDur = [allFixDur; median(all_user_info.FixationInfo{i}.dur_fix)];
    fixPerSec = [fixPerSec; median(all_user_info.FixationInfo{i}.fix_per_sec)];
    userFix = [userFix; str2num(all_user_info.UserID(i))];
    condFix = [condFix; all_user_info.ETDDC(i)];
end

% Remove invalid
allFixDur0 = allFixDur0(allFixDur0 < 1.5 & allFixDur0 > 0);
allFixDur1 = allFixDur1(allFixDur1 < 1.5 & allFixDur1 > 0);

% Plot visual information
plotEyeMetricInfo(allFixDur0, allFixDur1, ...
                    'Duration', ...
                    fixNumber0, fixNumber1, ...
                    fixPerSec0, fixPerSec1, ...
                    [dirPath 'FIX_'], 'Fixation', ...
                    'ET-DDC Off', 'ET-DDC On');

% % Run GLME for both variables
% data_table = table(allFixDur, condFix, SSQ_totalSubscale, VIMSSQ_total, userFix);
% glme = fitglme(data_table, 'allFixDur ~ 1 + condFix*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + condFix:SSQ_totalSubscale:VIMSSQ_total + (1 | userFix)');
% analyzeGlmeEffects(glme, data_table, 'condFix', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_Fix_Dur_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, condFix, allFixDur, VIMSSQ_total, userFix);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + condFix*allFixDur + allFixDur*VIMSSQ_total + condFix:allFixDur:VIMSSQ_total +  (1 | userFix)');
% analyzeGlmeEffects(glme, data_table, 'condFix', 'allFixDur', 'VIMSSQ_total', [dirPath 'SA_SSQ_Fix_Dur_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(fixPerSec, condFix, SSQ_totalSubscale, VIMSSQ_total, userFix);
% glme = fitglme(data_table, 'fixPerSec ~ 1 + condFix*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + condFix:SSQ_totalSubscale:VIMSSQ_total + (1 | userFix)');
% analyzeGlmeEffects(glme, data_table, 'condFix', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_Fix_PerSec_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, condFix, fixPerSec, VIMSSQ_total, userFix);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + condFix*fixPerSec + fixPerSec*VIMSSQ_total + condFix:fixPerSec:VIMSSQ_total +  (1 | userFix)');
% analyzeGlmeEffects(glme, data_table, 'condFix', 'fixPerSec', 'VIMSSQ_total', [dirPath 'SA_SSQ_Fix_PerSec_'], 'ET-DDC Off', 'ET-DDC On');
% 



% =============================================================== %
% =============================================================== %
% ========================= SACCADES ============================ %
% =============================================================== %
% =============================================================== %

% If the directory does not exist, create it
dirPath = 'results/study2/saccades/';
if exist(dirPath, 'dir') ~= 7
    mkdir(dirPath);
    disp(['[MKDIR] Directory created: ' dirPath]);
end

% Initialize an empty array to store saccade durations
allSacDur0 = [];            allSacDur1 = [];
% allSacAmp0 = [];            allSacAmp1 = [];
% allSacVel0 = [];            allSacVel1 = [];
sacNumber0 = [];            sacNumber1 = [];
sacPerSec0 = [];            sacPerSec1 = [];
% These ones are for statistical analysis
allSacDur = [];
sacPerSec = [];
userSac = [];
condSac = [];

% Iterate through each row of the table and concat saccade data for ETDDC = 0
for i = 1:height(all_user_info)
    if all_user_info.ETDDC(i) == 0
        allSacDur0 = [allSacDur0; all_user_info.SaccadeInfo{i}.dur_sac];
        % allSacAmp0 = [allSacAmp0; all_user_info.SaccadeInfo{i}.amp];
        % allSacVel0 = [allSacVel0; all_user_info.SaccadeInfo{i}.meanVel];
        sacNumber0 = [sacNumber0; all_user_info.SaccadeInfo{i}.tot_sac];
        sacPerSec0 = [sacPerSec0; all_user_info.SaccadeInfo{i}.sac_per_sec];
    elseif all_user_info.ETDDC(i) == 1
        allSacDur1 = [allSacDur1; all_user_info.SaccadeInfo{i}.dur_sac];
        % allSacAmp1 = [allSacAmp1; all_user_info.SaccadeInfo{i}.amp];
        % allSacVel1 = [allSacVel1; all_user_info.SaccadeInfo{i}.meanVel];
        sacNumber1 = [sacNumber1; all_user_info.SaccadeInfo{i}.tot_sac];
        sacPerSec1 = [sacPerSec1; all_user_info.SaccadeInfo{i}.sac_per_sec];
    end
    allSacDur = [allSacDur; nanmedian(all_user_info.SaccadeInfo{i}.dur_sac)];
    sacPerSec = [sacPerSec; nanmedian(all_user_info.SaccadeInfo{i}.sac_per_sec)];
    userSac = [userSac; str2num(all_user_info.UserID(i))];
    condSac = [condSac; all_user_info.ETDDC(i)];
end

% Remove invalid
allSacDur0 = allSacDur0(allSacDur0 < 0.2 & allSacDur0 > 0);
allSacDur1 = allSacDur1(allSacDur1 < 0.2 & allSacDur1 > 0);
% allSacAmp0 = allSacAmp0(allSacAmp0 < 50 & allSacAmp0 > 0);
% allSacAmp1 = allSacAmp1(allSacAmp1 < 50 & allSacAmp1 > 0);
% allSacVel0 = allSacVel0(allSacVel0 < 800 & allSacVel0 > 0);
% allSacVel1 = allSacVel1(allSacVel1 < 800 & allSacVel1 > 0);


% Plot visual information
plotEyeMetricInfo(allSacDur0, allSacDur1, ...
                    'Duration', ...
                    sacNumber0, sacNumber1, ...
                    sacPerSec0, sacPerSec1, ...
                    [dirPath 'SAC_'], 'Saccade', ...
                    'ET-DDC Off', 'ET-DDC On');

% % Run GLME for both variables
% data_table = table(allSacDur, condSac, SSQ_totalSubscale, VIMSSQ_total, userSac);
% glme = fitglme(data_table, 'allSacDur ~ 1 + condSac*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + condSac:SSQ_totalSubscale:VIMSSQ_total + (1 | userSac)');
% analyzeGlmeEffects(glme, data_table, 'condSac', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_Sac_Dur_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, condSac, allSacDur, VIMSSQ_total, userSac);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + condSac*allSacDur + allSacDur*VIMSSQ_total + condSac:allSacDur:VIMSSQ_total +  (1 | userSac)');
% analyzeGlmeEffects(glme, data_table, 'condSac', 'allSacDur', 'VIMSSQ_total', [dirPath 'SA_SSQ_Sac_Dur_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(sacPerSec, condSac, SSQ_totalSubscale, VIMSSQ_total, userSac);
% glme = fitglme(data_table, 'sacPerSec ~ 1 + condSac*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + condSac:SSQ_totalSubscale:VIMSSQ_total + (1 | userSac)');
% analyzeGlmeEffects(glme, data_table, 'condSac', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_Sac_PerSec_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, condSac, sacPerSec, VIMSSQ_total, userSac);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + condSac*sacPerSec + sacPerSec*VIMSSQ_total + condSac:sacPerSec:VIMSSQ_total +  (1 | userSac)');
% analyzeGlmeEffects(glme, data_table, 'condSac', 'sacPerSec', 'VIMSSQ_total', [dirPath 'SA_SSQ_Sac_PerSec_'], 'ET-DDC Off', 'ET-DDC On');
% 



% =============================================================== %
% =============================================================== %
% ========================== BLINKS ============================= %
% =============================================================== %
% =============================================================== %

% If the directory does not exist, create it
dirPath = 'results/study2/blinks/';
if exist(dirPath, 'dir') ~= 7
    mkdir(dirPath);
    disp(['[MKDIR] Directory created: ' dirPath]);
end

% Initialize an empty array to store fixation durations
allBliDur0 = [];        allBliDur1 = [];
bliNumber0 = [];        bliNumber1 = [];
bliPerSec0 = [];        bliPerSec1 = [];
% These ones are for statistical analysis
allBliDur = [];
bliPerSec = [];
userBli  = [];
condBli = [];

% Iterate through each row of the table and concat fixation data for ETDDC = 0
for i = 1:height(all_user_info)
    if all_user_info.ETDDC(i) == 0
        allBliDur0 = [allBliDur0; all_user_info.BlinkInfo{i}.dur_bli];
        bliNumber0 = [bliNumber0; all_user_info.BlinkInfo{i}.tot_bli];
        bliPerSec0 = [bliPerSec0; all_user_info.BlinkInfo{i}.bli_per_sec];
    elseif all_user_info.ETDDC(i) == 1
        allBliDur1 = [allBliDur1; all_user_info.BlinkInfo{i}.dur_bli];
        bliNumber1 = [bliNumber1; all_user_info.BlinkInfo{i}.tot_bli];
        bliPerSec1 = [bliPerSec1; all_user_info.BlinkInfo{i}.bli_per_sec];
    end
    allBliDur = [allBliDur; nanmedian(all_user_info.BlinkInfo{i}.dur_bli)];
    bliPerSec = [bliPerSec; nanmedian(all_user_info.BlinkInfo{i}.bli_per_sec)];
    userBli = [userBli; str2num(all_user_info.UserID(i))];
    condBli = [condBli; all_user_info.ETDDC(i)];
end

% Remove invalid
allBliDur0 = allBliDur0(allBliDur0 < 1 & allBliDur0 > 0);
allBliDur1 = allBliDur1(allBliDur1 < 1 & allBliDur1 > 0);

% Plot visual information
plotEyeMetricInfo(allBliDur0, allBliDur1, ...
                    'Duration', ...
                    bliNumber0, bliNumber1, ...
                    bliPerSec0, bliPerSec1, ...
                    [dirPath 'BLI_'], 'Blink', ...
                    'ET-DDC Off', 'ET-DDC On');

% % Run GLME for both variables
% data_table = table(allBliDur, condBli, SSQ_totalSubscale, VIMSSQ_total, userBli);
% glme = fitglme(data_table, 'allBliDur ~ 1 + condBli*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + condBli:SSQ_totalSubscale:VIMSSQ_total + (1 | userBli)');
% analyzeGlmeEffects(glme, data_table, 'condBli', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_Bli_Dur_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, condBli, allBliDur, VIMSSQ_total, userBli);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + condBli*allBliDur + allBliDur*VIMSSQ_total + condBli:allBliDur:VIMSSQ_total +  (1 | userBli)');
% analyzeGlmeEffects(glme, data_table, 'condBli', 'allBliDur', 'VIMSSQ_total', [dirPath 'SA_SSQ_Bli_Dur_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(bliPerSec, condBli, SSQ_totalSubscale, VIMSSQ_total, userBli);
% glme = fitglme(data_table, 'bliPerSec ~ 1 + condBli*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + condBli:SSQ_totalSubscale:VIMSSQ_total + (1 | userBli)');
% analyzeGlmeEffects(glme, data_table, 'condBli', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_Bli_PerSec_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, condBli, bliPerSec, VIMSSQ_total, userBli);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + condBli*bliPerSec + bliPerSec*VIMSSQ_total + condBli:bliPerSec:VIMSSQ_total +  (1 | userBli)');
% analyzeGlmeEffects(glme, data_table, 'condBli', 'bliPerSec', 'VIMSSQ_total', [dirPath 'SA_SSQ_Bli_PerSec_'], 'ET-DDC Off', 'ET-DDC On');
% 


% =============================================================== %
% =============================================================== %
% =========================== VORs -============================= %
% =============================================================== %
% =============================================================== %

% If the directory does not exist, create it
dirPath = 'results/study2/vors/';
if exist(dirPath, 'dir') ~= 7
    mkdir(dirPath);
    disp(['[MKDIR] Directory created: ' dirPath]);
end

% Initialize an empty array to store fixation durations
allVorDur0 = [];        allVorDur1 = [];
vorNumber0 = [];        vorNumber1 = [];
vorPerSec0 = [];        vorPerSec1 = [];
% These ones are for statistical analysis
allVorDur = [];
vorPerSec = [];
userVor  = [];
condVor = [];

% Iterate through each row of the table and concat fixation data for ETDDC = 0
for i = 1:height(all_user_info)
    if all_user_info.ETDDC(i) == 0
        allVorDur0 = [allVorDur0; all_user_info.VORInfo{i}.dur_vor];
        vorNumber0 = [vorNumber0; all_user_info.VORInfo{i}.tot_vor];
        vorPerSec0 = [vorPerSec0; all_user_info.VORInfo{i}.vor_per_sec];
    elseif all_user_info.ETDDC(i) == 1
        allVorDur1 = [allVorDur1; all_user_info.VORInfo{i}.dur_vor];
        vorNumber1 = [vorNumber1; all_user_info.VORInfo{i}.tot_vor];
        vorPerSec1 = [vorPerSec1; all_user_info.VORInfo{i}.vor_per_sec];
    end
    allVorDur = [allVorDur; nanmedian(all_user_info.VORInfo{i}.dur_vor)];
    vorPerSec = [vorPerSec; nanmedian(all_user_info.VORInfo{i}.vor_per_sec)];
    userVor = [userVor; str2num(all_user_info.UserID(i))];
    condVor = [condVor; all_user_info.ETDDC(i)];
end

% Remove invalid
allVorDur0 = allVorDur0(allVorDur0 < 0.3 & allVorDur0 > 0);
allVorDur1 = allVorDur1(allVorDur1 < 0.3 & allVorDur1 > 0);

% Plot visual information
plotEyeMetricInfo(allVorDur0, allVorDur1, ...
                    'Duration', ...
                    vorNumber0, vorNumber1, ...
                    vorPerSec0, vorPerSec1, ...
                    [dirPath 'VOR_'], 'VOR', ...
                    'ET-DDC Off', 'ET-DDC On');

% % Run GLME for both variables
% data_table = table(allVorDur, condVor, SSQ_totalSubscale, VIMSSQ_total, userVor);
% glme = fitglme(data_table, 'allVorDur ~ 1 + condVor*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + condVor:SSQ_totalSubscale:VIMSSQ_total + (1 | userVor)');
% analyzeGlmeEffects(glme, data_table, 'condVor', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_Vor_Dur_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, condVor, allVorDur, VIMSSQ_total, userVor);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + condVor*allVorDur + allVorDur*VIMSSQ_total + condVor:allVorDur:VIMSSQ_total +  (1 | userVor)');
% analyzeGlmeEffects(glme, data_table, 'condVor', 'allVorDur', 'VIMSSQ_total', [dirPath 'SA_SSQ_Vor_Dur_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(vorPerSec, condVor, SSQ_totalSubscale, VIMSSQ_total, userVor);
% glme = fitglme(data_table, 'vorPerSec ~ 1 + condVor*SSQ_totalSubscale + SSQ_totalSubscale*VIMSSQ_total + condVor:SSQ_totalSubscale:VIMSSQ_total + (1 | userVor)');
% analyzeGlmeEffects(glme, data_table, 'condVor', 'SSQ_totalSubscale', 'VIMSSQ_total', [dirPath 'SA_Vor_PerSec_'], 'ET-DDC Off', 'ET-DDC On');
% 
% data_table = table(SSQ_totalSubscale, condVor, vorPerSec, VIMSSQ_total, userVor);
% glme = fitglme(data_table, 'SSQ_totalSubscale ~ 1 + condVor*vorPerSec + vorPerSec*VIMSSQ_total + condVor:vorPerSec:VIMSSQ_total +  (1 | userVor)');
% analyzeGlmeEffects(glme, data_table, 'condVor', 'vorPerSec', 'VIMSSQ_total', [dirPath 'SA_SSQ_Vor_PerSec_'], 'ET-DDC Off', 'ET-DDC On');



% Additional statistical tests
outputString = '';
% Create a string to capture the display output
% Start with gaze in head and world
outputString = [outputString evalc("performNormalityAndTtest(gazeHead0.L10.headRawGazeAngleMagn', gazeHead1.L10.headRawGazeAngleMagn', '[Gaze in head raw angle magnitude]')")];
outputString = [outputString evalc("performNormalityAndTtest(gazeWorld0.L10.worldRawGazeAngleMagn, gazeWorld1.L10.worldRawGazeAngleMagn', '[Gaze in world raw angle magnitude]')")];
% Continue with fix in head and world
% outputString = [outputString evalc('performNormalityAndTtest(headFixAngleMagn0, headFixAngleMagn1, "[Fix in head angle magnitude]")')];
% outputString = [outputString evalc('performNormalityAndTtest(worldFixAngleMagn0, worldFixAngleMagn1, "[Fix in world angle magnitude]")')];
% outputString = [outputString evalc('performNormalityAndTtest(headFixThetaMagn0, headFixThetaMagn1, "[Fix in head theta magnitude]")')];
% outputString = [outputString evalc('performNormalityAndTtest(worldFixThetaMagn0, worldFixThetaMagn0, "[Fix in world theta magnitude]")')];
% outputString = [outputString evalc('performNormalityAndTtest(headFixPhiMagn0, headFixPhiMagn1, "[Fix in head phi magnitude]")')];
% outputString = [outputString evalc('performNormalityAndTtest(worldFixPhiMagn0, worldFixPhiMagn0, "[Fix in world phi magnitude]")')];
% Check head velocities
outputString = [outputString evalc('performNormalityAndTtest(rotVel0, rotVel1, "[2D head velocity]")')];
outputString = [outputString evalc('performNormalityAndTtest(rotVel3D0, rotVel3D1, "[3D head velocity]")')];
% Check eye movements per second
outputString = [outputString evalc('performNormalityAndTtest(fixPerSec0, fixPerSec1, "[Fixations per second]")')];
outputString = [outputString evalc('performNormalityAndTtest(sacPerSec0, sacPerSec1, "[Saccades per second]")')];
outputString = [outputString evalc('performNormalityAndTtest(bliPerSec0, bliPerSec1, "[Blink per second]")')];
outputString = [outputString evalc('performNormalityAndTtest(vorPerSec0, vorPerSec1, "[VOR per second]")')];

% Open the file for writing
fileID = fopen('results/ALL_Normality_TTests.txt', 'w');
% Write the output string to the file
fprintf(fileID, '%s', outputString);
% Close the file
fclose(fileID);

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

function heatmaps = plotGazeData(data0, data1, supraLabel, coordSys, label0, label1)
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
    
    % Check if labels are passed as identifiers of each condition.
    % Otherwise, establish a default value.
    if nargin < 5
        label0 = 'Condition 0';
        label1 = 'Condition 1';
    end

    % We are first plotting dipoter distributions (by means of KDE) for
    % both conditions

    figure('Position', [100, 100, 1400, 600], 'Visible', 'off');
    subplot(1,2,1);
    
    % Creating a kernel density estimation plot
    % We first remove spurious data
    diopt0x = data0.x;
    diopt0x(diopt0x > 20 | diopt0x < 0.25) = [];
    % Transform meters to diopters
    diopt0x = 1 ./ diopt0x;
    % Calculate and plot 25, 50, and 75 percentiles
    percentiles = prctile(diopt0x, [25, 50, 75]);
    for i = 1:length(percentiles)
        line([percentiles(i) percentiles(i)], ylim, 'Color', 'r', 'LineStyle', '--');
        hold on;
    end
    % Calculate KDE
    [f, xi] = ksdensity(diopt0x);
    % Plot KDE
    plot(xi, f, 'b', 'LineWidth', 2);  
    xlabel('Depth (Diopters)');
    ylabel('Probability Density');
    title(['Raw gaze in head depth KDE for ' label0]);
    xlim([0, 4]);
    ylim([0, 1]);
    set(gca, 'XDir','reverse'); 
    
    subplot(1,2,2);

    % Creating a kernel density estimation plot
    % We first remove spurious data
    diopt1x = data1.x;
    diopt1x(diopt1x > 20 | diopt1x < 0.25) = [];
    % Transform meters to diopters
    diopt1x = 1 ./ diopt1x;
    % Calculate and plot 25, 50, and 75 percentiles
    percentiles = prctile(diopt1x, [25, 50, 75]);
    for i = 1:length(percentiles)
        line([percentiles(i) percentiles(i)], ylim, 'Color', 'r', 'LineStyle', '--');
        hold on;
    end
    % Calculate KDE
    [f, xi] = ksdensity(diopt1x);
    % Plot KDE
    plot(xi, f, 'b', 'LineWidth', 2);
    xlabel('Depth (Diopters)');
    ylabel('Probability Density');
    title(['Raw gaze in head depth KDE for ' label1]);
    xlim([0, 4]);
    ylim([0, 1]);
    set(gca, 'XDir','reverse'); 
    
    % Inform that data has been saved
    saveas(gcf, [supraLabel 'DioptersKDE.png']);
    fprintf(['[SAVED] Diopters KDE --> ' supraLabel 'DioptersKDE.png\n']);

    % We are now plotting gaze points in 3D space and a slice of gaze
    % points as if seen agreggated from the front view
    
    % Since this could be a very dense scatter plot, im setting a threshold
    % of which points to show (i.e.g, one every X points), so it is faster
    % and less heavy.
    pTh = 10;

    
    figure('Position', [100, 100, 1400, 1400], 'Visible', 'off');
    subplot(2, 2, 1);
    % Each scatter point is a gaze point
    scatter3(data0.x(1:pTh:end), data0.y(1:pTh:end), data0.z(1:pTh:end), 'filled', 'MarkerFaceColor', 'b'); 
    hold on;
    % Adding vectors for the positive direction of each axis
    quiver3(0, 0, 0, 1, 0, 0, 'r', 'LineWidth', 2); % Red arrow for the x-axis
    quiver3(0, 0, 0, 0, 1, 0, 'g', 'LineWidth', 2); % Green arrow for the y-axis
    quiver3(0, 0, 0, 0, 0, 1, 'm', 'LineWidth', 2); % Magenta arrow for the z-axis
    grid on; 
    xlabel('X-axis'); 
    ylabel('Y-axis');
    zlabel('Z-axis'); 
    % I'm setting the axis because I know the range of values, but this can
    % be removed or modified according to any data distribution.
    axis([-1, 20, -8, 8, -4, 10]);
    title([label0 ' - Gaze Position in ' coordSys]); 
    hold on;
    
    subplot(2, 2, 3);
    % Each scatter point is a gaze point
    scatter3(data1.x(1:pTh:end), data1.y(1:pTh:end), data1.z(1:pTh:end), 'filled', 'MarkerFaceColor', 'b'); 
    hold on;
    % Adding vectors for the positive direction of each axis
    quiver3(0, 0, 0, 1, 0, 0, 'r', 'LineWidth', 2); % Red arrow for the x-axis
    quiver3(0, 0, 0, 0, 1, 0, 'g', 'LineWidth', 2); % Green arrow for the y-axis
    quiver3(0, 0, 0, 0, 0, 1, 'm', 'LineWidth', 2); % Magenta arrow for the z-axis
    grid on; 
    xlabel('X-axis'); 
    ylabel('Y-axis');
    zlabel('Z-axis'); 
    % I'm setting the axis because I know the range of values, but this can
    % be removed or modified according to any data distribution.
    axis([-1, 20, -8, 8, -4, 10]);
    title([label1 ' - Gaze Position in ' coordSys]); % Title for the plot
    hold on;
    
    subplot(2, 2, 2);
    % Same scatter but from a frontal slice
    scatter(data0.y(1:pTh:end), data0.z(1:pTh:end), 50, data0.x(1:pTh:end), 'filled');
    colorbar; 
    colormap jet; 
    xlabel('Y-axis');
    ylabel('Z-axis');
    title('Heatmap based on Y and Z coordinates');
    
    subplot(2, 2, 4); 
    % Same scatter but from a frontal slice
    scatter(data1.y(1:pTh:end), data1.z(1:pTh:end), 50, data1.x(1:pTh:end), 'filled');
    colorbar; 
    colormap jet; 
    xlabel('Y-axis');
    ylabel('Z-axis');
    title('Heatmap based on Y and Z coordinates');

    % Inform that data has been saved
    saveas(gcf, [supraLabel 'ScatterPoints.png']);
    fprintf(['[SAVED] Scatter points --> ' supraLabel 'ScatterPoints.png\n']);

    % We are finally plotting the angular distribution of gaze. We do this
    % in two different figures because they are so complex already to be
    % combined together (we would otherwise have subfigures of subfigures).

    figure('Position', [100, 100, 1400, 1400], 'Visible', 'off');

    % Set positions for some subplots
    phiHistPos = [0.76 0.10 0.20 0.65];
    thetaHistPos = [0.10 0.76 0.65 0.20];

    % Convert Cartesian coordinates to spherical coordinates
    theta = -atan2(data0.y, data0.x);
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
    smoothed_data0 = imgaussfilt(hist_data, sigma);

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
    smoothed_data0 = smoothed_data0';
    imagesc(smoothed_data0);
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

    if strcmp(coordSys, 'Hworld') || strcmp(coordSys, 'Gworld')
        xticklabels({'-180', '-90', '0', '90', '180'});
        yticklabels({'90', '45', '0', '-45', '-90'});
    elseif strcmp(coordSys, 'Ghead')
        xticklabels({'-40', '-20', '0', '20', '40'});
        yticklabels({'-40', '-20', '0', '20', '40'});
    end

    xlabel('Theta (degrees)');
    ylabel('Phi (degrees)');
    % Visibility off so it can be ploted all together
    ax = axes('Position', [0 0 1 1], 'Visible', 'off');
    text(0.90, 0.90, [coordSys ' for ' label0], 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');

    % Inform that data has been saved
    saveas(gcf, [supraLabel 'GazeAngleDist_OFF.png']);
    fprintf(['[SAVED] Gaze angle distrbution for ET-DDC off --> ' supraLabel 'GazeAngleDist_OFF.png\n']);

    figure('Position', [100, 100, 1400, 1400], 'Visible', 'off');

    % Convert Cartesian coordinates to spherical coordinates
    theta = -atan2(data1.y, data1.x);
    phi = atan2(data1.z, sqrt(data1.x.^2 + data1.y.^2));
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
    smoothed_data1 = imgaussfilt(hist_data, sigma);

    % Show the distribution of theta OVER the heatmap
    subplot('Position', thetaHistPos);
    % % Fit histogram to distribution
    % pd = fitdist(theta_deg, 'Normal');
    % x = min(theta_deg):0.1:max(theta_deg);
    % y = pdf(pd, x);
    % plot(x, y, 'LineWidth', 2);
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
    smoothed_data1 = smoothed_data1';
    imagesc(smoothed_data1);
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

    if strcmp(coordSys, 'Hworld') || strcmp(coordSys, 'Gworld')
        xticklabels({'-180', '-90', '0', '90', '180'});
        yticklabels({'90', '45', '0', '-45', '-90'});
    elseif strcmp(coordSys, 'Ghead')
        xticklabels({'-40', '-20', '0', '20', '40'});
        yticklabels({'-40', '-20', '0', '20', '40'});
    end

    xlabel('Theta (degrees)');
    ylabel('Phi (degrees)');
    % Visibility off so it can be ploted all together
    ax = axes('Position', [0 0 1 1], 'Visible', 'off');
    text(0.90, 0.90, [coordSys ' for ' label1], 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');

    % Inform that data has been saved
    saveas(gcf, [supraLabel 'GazeAngleDist_ON.png']);
    fprintf(['[SAVED] Gaze angle distrbution for ET-DDC on --> ' supraLabel 'GazeAngleDist_ON.png\n']);

    heatmaps = struct();
    heatmaps.h0 = smoothed_data0;
    heatmaps.h1 = smoothed_data1;

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
        set(gca, 'ColorOrder', color_map);
        
        % Top-left subplot is raw evolution for condition 0
        subplot(2, 2, 1);
        hold on;
        plot([1, 2, 3, 4, 5], [data0.CH05, data0.CH20, data0.CH40, data0.CH60, data0.L10], 'o-', 'LineWidth', 3);
        hold off;
        % ylim([])
        xticks(1:5);
        xticklabels({'CH05', 'CH20', 'CH40', 'CH60', 'L10'}); 
        title([metric ' evolution - ' label0]);
        
        % Top-right subplot is raw evolution for condition 1
        subplot(2, 2, 2);
        hold on;
        plot([1, 2, 3, 4, 5], [data1.CH05, data1.CH20, data1.CH40, data1.CH60, data1.L10], 'o-', 'LineWidth', 3);
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
             'o-', 'LineWidth', 3);        
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
             'o-', 'LineWidth', 3);        
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

% Todo --> Maybe arguments can be passed in a more fancy way, but for now
% this works
function calculateAndPlotHeatmapDifferences(gH_L10, gH_CH20, gH_CH40, gH_CH60, ...
                                            gW_L10, gW_CH20, gW_CH40, gW_CH60, ...
                                            hW_L10, hW_CH20, hW_CH40, hW_CH60)

    % One figure per env. (gaze in head, gaze in world, head in world)
   
    % Group colors
    groupColors = [0.7 0.7 1; 0.7 1 0.7; 1 0.7 0.7];

    % Create a figure for the subplots
    figure('Position', [200, 200, 1600, 800], 'Visible', 'off'); 

    subplot('Position', [0.1, 0.1, 0.28, 0.8]);

    bar((1:4), [klDivergence(gH_CH20.h0, gH_CH20.h1), ...
                            klDivergence(gH_CH40.h0, gH_CH40.h1), ...
                            klDivergence(gH_CH60.h0, gH_CH60.h1), ...
                            klDivergence(gH_L10.h0, gH_L10.h1)], ...
                            'FaceColor', groupColors(1, :), 'BarWidth', 0.85);
    
    % Customize x-axis ticks and labels
    xticks((1:4));
    xticklabels({'G1', 'G2', 'G3', 'G4'});
    ylim([0, 1]);
    % Add a legend
    legend('KLDiv ↓↓');

    subplot('Position', [0.44, 0.1, 0.50, 0.8]);

    c1 = corrcoef(gH_CH20.h0(:), gH_CH20.h1(:));
    c2 = corrcoef(gH_CH40.h0(:), gH_CH40.h1(:));
    c3 = corrcoef(gH_CH60.h0(:), gH_CH60.h1(:));
    c4 = corrcoef(gH_L10.h0(:),  gH_L10.h1(:));
    bar((1:4), [c1(1,2), ...
                c2(1,2), ...
                c3(1,2), ...
                c4(1,2)], ...
                'FaceColor', groupColors(2, :), 'BarWidth', 0.85);
    hold on;
    bar((6:9), [sum(min(gH_CH20.h0(:), gH_CH20.h1(:))) / sum(gH_CH20.h0(:)), ...
                            sum(min(gH_CH40.h0(:), gH_CH40.h1(:))) / sum(gH_CH40.h0(:)), ...
                            sum(min(gH_CH60.h0(:), gH_CH60.h1(:))) / sum(gH_CH60.h0(:)), ...
                            sum(min(gH_L10.h0(:), gH_L10.h1(:))) / sum(gH_L10.h0(:))], ...
                            'FaceColor', groupColors(3, :), 'BarWidth', 0.85);

    % Customize x-axis ticks and labels
    xticks([1, 2, 3, 4, 6, 7, 8, 9]);
    xticklabels({'G1', 'G2', 'G3', 'G4', 'G1', 'G2', 'G3', 'G4'});
    ylim([0, 1]);
    % Add a legend
    legend('CC ↑↑', 'SIM ↑↑');
    
    hold off;
    saveas(gcf, 'results/study2/rawGaze/GIHead_Metrics.png');
    fprintf(['[SAVED] Gaze in head metrics plot --> results/study2/rawGaze/GIHead_Metrics.png\n']);


    % Create a figure for the subplots
    figure('Position', [200, 200, 1600, 800], 'Visible', 'off'); 
    
    subplot('Position', [0.1, 0.1, 0.28, 0.8]);

    bar((1:4), [klDivergence(gW_CH20.h0, gW_CH20.h1), ...
                            klDivergence(gW_CH40.h0, gW_CH40.h1), ...
                            klDivergence(gW_CH60.h0, gW_CH60.h1), ...
                            klDivergence(gW_L10.h0, gW_L10.h1)], ...
                            'FaceColor', groupColors(1, :), 'BarWidth', 0.85);
    
    % Customize x-axis ticks and labels
    xticks((1:4));
    xticklabels({'G1', 'G2', 'G3', 'G4'});
    ylim([0, 6]);
    % Add a legend
    legend('KLDiv ↓↓');

    subplot('Position', [0.44, 0.1, 0.50, 0.8]);

    c1 = corrcoef(gW_CH20.h0(:), gW_CH20.h1(:));
    c2 = corrcoef(gW_CH40.h0(:), gW_CH40.h1(:));
    c3 = corrcoef(gW_CH60.h0(:), gW_CH60.h1(:));
    c4 = corrcoef(gW_L10.h0(:),  gW_L10.h1(:));
    bar((1:4), [c1(1,2), ...
                            c2(1,2), ...
                            c3(1,2), ...
                            c4(1,2)], ...
                            'FaceColor', groupColors(2, :), 'BarWidth', 0.85);
    hold on;
    bar((6:9), [sum(min(gW_CH20.h0(:), gW_CH20.h1(:))) / sum(gW_CH20.h0(:)), ...
                            sum(min(gW_CH40.h0(:), gW_CH40.h1(:))) / sum(gW_CH40.h0(:)), ...
                            sum(min(gW_CH60.h0(:), gW_CH60.h1(:))) / sum(gW_CH60.h0(:)), ...
                            sum(min(gW_L10.h0(:), gW_L10.h1(:))) / sum(gW_L10.h0(:))], ...
                            'FaceColor', groupColors(3, :), 'BarWidth', 0.85);
    
    % Customize x-axis ticks and labels
    xticks([1, 2, 3, 4, 6, 7, 8, 9]);
    xticklabels({'G1', 'G2', 'G3', 'G4', 'G1', 'G2', 'G3', 'G4'});
    ylim([0, 1]);
    % Add a legend
    legend('CC ↑↑', 'SIM ↑↑');
    
    hold off;
    saveas(gcf, 'results/study2/rawGaze/GIWorld_Metrics.png');
    fprintf(['[SAVED] Gaze in world metrics plot --> results/study2/rawGaze/GIWorld_Metrics.png\n']);


    % Create a figure for the subplots
    figure('Position', [200, 200, 1600, 800], 'Visible', 'off'); 

    subplot('Position', [0.1, 0.1, 0.28, 0.8]);
    
    bar((1:4), [klDivergence(hW_CH20.h0, hW_CH20.h1), ...
                            klDivergence(hW_CH40.h0, hW_CH40.h1), ...
                            klDivergence(hW_CH60.h0, hW_CH60.h1), ...
                            klDivergence(hW_L10.h0, hW_L10.h1)], ...
                            'FaceColor', groupColors(1, :), 'BarWidth', 0.85);
    
    % Customize x-axis ticks and labels
    xticks((1:4));
    xticklabels({'G1', 'G2', 'G3', 'G4'});
    ylim([0, 6]);
    % Add a legend
    legend('KLDiv ↓↓');

    subplot('Position', [0.44, 0.1, 0.50, 0.8]);

    c1 = corrcoef(hW_CH20.h0(:), hW_CH20.h1(:));
    c2 = corrcoef(hW_CH40.h0(:), hW_CH40.h1(:));
    c3 = corrcoef(hW_CH60.h0(:), hW_CH60.h1(:));
    c4 = corrcoef(hW_L10.h0(:),  hW_L10.h1(:));
    bar((1:4), [c1(1,2), ...
                            c2(1,2), ...
                            c3(1,2), ...
                            c4(1,2)], ...
                            'FaceColor', groupColors(2, :), 'BarWidth', 0.85);
    hold on;
    bar((6:9), [sum(min(hW_CH20.h0(:), hW_CH20.h1(:))) / sum(hW_CH20.h0(:)), ...
                            sum(min(hW_CH40.h0(:), hW_CH40.h1(:))) / sum(hW_CH40.h0(:)), ...
                            sum(min(hW_CH60.h0(:), hW_CH60.h1(:))) / sum(hW_CH60.h0(:)), ...
                            sum(min(hW_L10.h0(:), hW_L10.h1(:))) / sum(hW_L10.h0(:))], ...
                            'FaceColor', groupColors(3, :), 'BarWidth', 0.85);

    % Customize x-axis ticks and labels
    xticks([1, 2, 3, 4, 6, 7, 8, 9]);
    xticklabels({'G1', 'G2', 'G3', 'G4', 'G1', 'G2', 'G3', 'G4'});
    ylim([0, 1]);
    % Add a legend
    legend('CC ↑↑', 'SIM ↑↑');
    
    hold off;
    saveas(gcf, 'results/study2/head/HIWorld_Metrics.png');
    fprintf(['[SAVED] Head movement metrics plot --> results/study2/head/HIWorld_Metrics.png\n']);



    outputString = '';

    outputString = [outputString evalc('fprintf(strjoin("KL-Div (0 to Inf)\n"))')];
    outputString = [outputString evalc('fprintf(strjoin(["[KL-DIV] " "CH20_GIHead " " --> " klDivergence(gH_CH20.h0, gH_CH20.h1) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[KL-DIV] " "CH40_GIHead " " --> " klDivergence(gH_CH40.h0, gH_CH40.h1) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[KL-DIV] " "CH60_GIHead " " --> " klDivergence(gH_CH60.h0, gH_CH60.h1) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[KL-DIV] " "L10_GIHead  " " --> " klDivergence(gH_L10.h0,  gH_L10.h1) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[KL-DIV] " "CH20_GIWorld" " --> " klDivergence(gW_CH20.h0, gW_CH20.h1) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[KL-DIV] " "CH40_GIWorld" " --> " klDivergence(gW_CH40.h0, gW_CH40.h1) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[KL-DIV] " "CH60_GIWorld" " --> " klDivergence(gW_CH60.h0, gW_CH60.h1) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[KL-DIV] " "L10_GIWorld " " --> " klDivergence(gW_L10.h0,  gW_L10.h1) "\n"]))')];   
    outputString = [outputString evalc('fprintf(strjoin(["[KL-DIV] " "CH20_HIWorld" " --> " klDivergence(hW_CH20.h0, hW_CH20.h1) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[KL-DIV] " "CH40_HIWorld" " --> " klDivergence(hW_CH40.h0, hW_CH40.h1) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[KL-DIV] " "CH60_HIWorld" " --> " klDivergence(hW_CH60.h0, hW_CH60.h1) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[KL-DIV] " "L10_HIWorld " " --> " klDivergence(hW_L10.h0,  hW_L10.h1) "\n"]))')];
    
    outputString = [outputString evalc('fprintf(strjoin("\nCC (-1 to 1)\n"))')];
    outputString = [outputString evalc('correlation_coefficient = corrcoef(gH_CH20.h0(:), gH_CH20.h1(:)); fprintf(strjoin(["[CC] " "CH20_GIHead "  " --> " correlation_coefficient(1, 2) "\n"]))')];
    outputString = [outputString evalc('correlation_coefficient = corrcoef(gH_CH40.h0(:), gH_CH40.h1(:)); fprintf(strjoin(["[CC] " "CH40_GIHead "  " --> " correlation_coefficient(1, 2) "\n"]))')];
    outputString = [outputString evalc('correlation_coefficient = corrcoef(gH_CH60.h0(:), gH_CH60.h1(:)); fprintf(strjoin(["[CC] " "CH60_GIHead "  " --> " correlation_coefficient(1, 2) "\n"]))')];
    outputString = [outputString evalc('correlation_coefficient = corrcoef(gH_L10.h0(:),  gH_L10.h1(:));  fprintf(strjoin(["[CC] " "L10_GIHead  "  " --> " correlation_coefficient(1, 2) "\n"]))')];    
    outputString = [outputString evalc('correlation_coefficient = corrcoef(gW_CH20.h0(:), gW_CH20.h1(:)); fprintf(strjoin(["[CC] " "CH20_GIWorld"  " --> " correlation_coefficient(1, 2) "\n"]))')];
    outputString = [outputString evalc('correlation_coefficient = corrcoef(gW_CH40.h0(:), gW_CH40.h1(:)); fprintf(strjoin(["[CC] " "CH40_GIWorld"  " --> " correlation_coefficient(1, 2) "\n"]))')];
    outputString = [outputString evalc('correlation_coefficient = corrcoef(gW_CH60.h0(:), gW_CH60.h1(:)); fprintf(strjoin(["[CC] " "CH60_GIWorld"  " --> " correlation_coefficient(1, 2) "\n"]))')];
    outputString = [outputString evalc('correlation_coefficient = corrcoef(gW_L10.h0(:),  gW_L10.h1(:));  fprintf(strjoin(["[CC] " "L10_GIWorld "  " --> " correlation_coefficient(1, 2) "\n"]))')];    
    outputString = [outputString evalc('correlation_coefficient = corrcoef(hW_CH20.h0(:), hW_CH20.h1(:)); fprintf(strjoin(["[CC] " "CH20_HIWorld"  " --> " correlation_coefficient(1, 2) "\n"]))')];
    outputString = [outputString evalc('correlation_coefficient = corrcoef(hW_CH40.h0(:), hW_CH40.h1(:)); fprintf(strjoin(["[CC] " "CH40_HIWorld"  " --> " correlation_coefficient(1, 2) "\n"]))')];
    outputString = [outputString evalc('correlation_coefficient = corrcoef(hW_CH60.h0(:), hW_CH60.h1(:)); fprintf(strjoin(["[CC] " "CH60_HIWorld"  " --> " correlation_coefficient(1, 2) "\n"]))')];
    outputString = [outputString evalc('correlation_coefficient = corrcoef(hW_L10.h0(:),  hW_L10.h1(:));  fprintf(strjoin(["[CC] " "L10_HIWorld "  " --> " correlation_coefficient(1, 2) "\n"]))')];    

    outputString = [outputString evalc('fprintf(strjoin("\nSIM (0 to 1)\n"))')];
    outputString = [outputString evalc('fprintf(strjoin(["[SIM] " "CH20_GIHead "  " --> " sum(min(gH_CH20.h0(:), gH_CH20.h1(:))) / sum(gH_CH20.h0(:)) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[SIM] " "CH40_GIHead "  " --> " sum(min(gH_CH40.h0(:), gH_CH40.h1(:))) / sum(gH_CH40.h0(:)) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[SIM] " "CH60_GIHead "  " --> " sum(min(gH_CH60.h0(:), gH_CH60.h1(:))) / sum(gH_CH60.h0(:)) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[SIM] " "L10_GIHead  "  " --> " sum(min(gH_L10.h0(:),  gH_L10.h1(:)))  / sum(gH_L10.h0(:)) "\n"]))')];    
    outputString = [outputString evalc('fprintf(strjoin(["[SIM] " "CH20_GIWorld"  " --> " sum(min(gW_CH20.h0(:), gW_CH20.h1(:))) / sum(gW_CH20.h0(:)) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[SIM] " "CH40_GIWorld"  " --> " sum(min(gW_CH40.h0(:), gW_CH40.h1(:))) / sum(gW_CH40.h0(:)) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[SIM] " "CH60_GIWorld"  " --> " sum(min(gW_CH60.h0(:), gW_CH60.h1(:))) / sum(gW_CH60.h0(:)) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[SIM] " "L10_GIWorld "  " --> " sum(min(gW_L10.h0(:),  gW_L10.h1(:)))  / sum(gW_L10.h0(:)) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[SIM] " "CH20_HIWorld"  " --> " sum(min(hW_CH20.h0(:), hW_CH20.h1(:))) / sum(hW_CH20.h0(:)) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[SIM] " "CH40_HIWorld"  " --> " sum(min(hW_CH40.h0(:), hW_CH40.h1(:))) / sum(hW_CH40.h0(:)) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[SIM] " "CH60_HIWorld"  " --> " sum(min(hW_CH60.h0(:), hW_CH60.h1(:))) / sum(hW_CH60.h0(:)) "\n"]))')];
    outputString = [outputString evalc('fprintf(strjoin(["[SIM] " "L10_HIWorld "  " --> " sum(min(hW_L10.h0(:),  hW_L10.h1(:)))  / sum(hW_L10.h0(:)) "\n"]))')];

    % Open the file for writing
    fileID = fopen('results/ALL_Distribution_Tests.txt', 'w');
    % Write the output string to the file
    fprintf(fileID, '%s', outputString);
    % Close the file
    fclose(fileID);

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
    theta = -atan2d(v(:, 2), v(:, 1));
    phi = atan2d(v(:, 3), sqrt(v(:, 1).^2 + v(:, 2).^2));
    angle = sqrt(theta.^2 + phi.^2);
end

% 2D heatmap evaluation

function kl_divergence = klDivergence(P, Q)
    % Normalize the matrices to make them probability distributions
    P = P / sum(P(:));
    Q = Q / sum(Q(:));
    
    % Avoid zero values to prevent issues with log(0)
    P(P == 0) = eps;
    Q(Q == 0) = eps;
    
    % Calculate Kullback-Leibler Divergence
    kl_divergence = sum(P(:) .* log(P(:) ./ Q(:)));
end