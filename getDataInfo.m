         % getting some general stats of the eye data recording
close all; clear all; warning off; %clc
addpath(genpath('functions'))

set(0, 'units', 'pixels')
screenSize = get(groot,'ScreenSize'); % or specify which screen you are using
figPosition = [25 50 screenSize(3)-100, screenSize(4)-150];
colors = {[1 0 0], [0 0 1]};

%% set up which users' data to process
userAll = [1, 2, 8, 14, 15, 16, 20, 21, 22, 26, 27, 28, 30, 32, 33, 35, 36, 38, 40, 43, 44, 45, 48, 49, 50, 51, 52, 54, 56, 57, 58, 59, 60, 61];

%% for pre-processed data
% % sanity check gap between recordings, time of calibrations, duration of removed and NaNed data
% dataFolder = 'C:\Users\xiuyunwu\Downloads\ETDDC\preprocessed data\';
% dataInfo = table();
% count = 1;
% 
% for userI = 1:length(userAll)
%     userID = userAll(userI);
%     files = dir([dataFolder, 'prep_', num2str(userID, '%03i'), '*.mat']);
% 
%     for fileI = 1:size(files, 1)
%         % load data
%         fileName = files(fileI).name;
%         load([dataFolder, fileName])
% 
%         dataInfo.userID(count, 1) = str2num(sub_file_info.UserID{1});
%         dataInfo.session(count, 1) = sub_file_info.Session;
%         dataInfo.ETDDC(count, 1) = sub_file_info.ETDDC;
%         dataInfo.ten_min_chunk_in_session(count, 1) = sub_file_info.fileInfo.count;
%         dataInfo.day(count, 1) = sub_file_info.Day;
% 
%         dataInfo.totalRawDur_sec(count, 1) = (sub_file_info.EyeTrial.rawTimestampFull(end)-sub_file_info.EyeTrial.rawTimestampFull(1))/1000000;
%         dataInfo.totalValidDur_sec(count, 1) = (sub_file_info.EyeTrial.rawTimestampAfterCleaning(end)-sub_file_info.EyeTrial.rawTimestampAfterCleaning(1))/1000000;
% 
%         if dataInfo.ten_min_chunk_in_session(count, 1)==1
%             dataInfo.gapFromLastFile(count, 1) = NaN;
%             dataInfo.gapFromLastValidData(count, 1) = NaN;
%         else
%             dataInfo.gapFromLastFile(count, 1) = sub_file_info.EyeTrial.rawTimestampFull(1)-lastFileEndTimestamp;
%             dataInfo.gapFromLastValidData(count, 1) = sub_file_info.EyeTrial.rawTimestampAfterCleaning(1)-lastValidDataEndTimestamp;
%         end
% 
%         if isfield(sub_file_info.calibInfo, 'startTimestamp')
%             if ~isempty(sub_file_info.calibInfo.startTimestamp)
%                 dataInfo.calibStartTimeInFile_sec(count, 1) = {(sub_file_info.calibInfo.startTimestamp-sub_file_info.EyeTrial.rawTimestampFull(1))/1000000};
%             else
%                 dataInfo.calibStartTimeInFile_sec(count, 1) = {NaN};
%             end
% 
%             if ~isempty(sub_file_info.calibInfo.resultTimestamp)
%                 dataInfo.calibEndTimeInFile_sec(count, 1) = {(sub_file_info.calibInfo.resultTimestamp-sub_file_info.EyeTrial.rawTimestampFull(1))/1000000};
%             else
%                 dataInfo.calibEndTimeInFile_sec(count, 1) = {NaN};
%             end
%             dataInfo.removedCalibDur_sec(count, 1) = sub_file_info.removedStats.calibDur_sec;
%             dataInfo.calibInfoType(count, 1) = sub_file_info.removedStats.calibType;
%             dataInfo.removedCalib_propToTotalRaw(count, 1) = dataInfo.removedCalibDur_sec(count, 1)/dataInfo.totalRawDur_sec(count, 1);
%         else
%             dataInfo.calibStartTimeInFile_sec(count, 1) = {NaN};
%             dataInfo.calibEndTimeInFile_sec(count, 1) = {NaN};
%             dataInfo.removedCalibDur_sec(count, 1) = NaN;
%             dataInfo.calibInfoType(count, 1) = NaN;
%             dataInfo.removedCalib_propToTotalRaw(count, 1) = NaN;
%         end
% 
%         dataInfo.removedEmptyHead_propToTotalValidFrames(count, 1) = length(sub_file_info.removedStats.headEmptyTimestamp)/length(sub_file_info.EyeTrial.rawTimestampAfterCleaning);
%         dataInfo.nanNegDepth_propToTotalValidFrames(count, 1) = length(sub_file_info.removedStats.invalidDepthIdx)/length(sub_file_info.EyeTrial.rawTimestampAfterCleaning);
% 
%         lastFileEndTimestamp = sub_file_info.EyeTrial.rawTimestampFull(end);
%         lastValidDataEndTimestamp = sub_file_info.EyeTrial.rawTimestampAfterCleaning(end);
%         count = count+1;
%     end
% end
% save('dataInfo.mat', 'dataInfo')
% 
% %% plot
% for varI = [6:10, 12:size(dataInfo, 2)]
%     fig = figure('Position', figPosition);
%     axAll = [];
%     for subI = 1:length(userAll)
%         axAll{subI} = subplot(5, 7, subI);
%         idxT = find(dataInfo.userID==userAll(subI) & dataInfo.ETDDC==0);
%         plot(dataInfo.ten_min_chunk_in_session(idxT), dataInfo{idxT, varI}, 'o-', 'Color', colors{1})
% 
%         hold on
%         idxT = find(dataInfo.userID==userAll(subI) & dataInfo.ETDDC==1);
%         plot(dataInfo.ten_min_chunk_in_session(idxT), dataInfo{idxT, varI}, 'o-', 'Color', colors{2})
% 
%         if subI==1
%             legend({'ETDDC off', 'ETDDC on'})
%         end
%         title(num2str(userAll(subI)))
%     end
%     linkaxes([axAll{:}], 'y')
% 
%     saveas(gcf, ['C:\Users\xiuyunwu\OneDrive - Facebook\Documents\Consultation projects_meta\ETDDC motion sickness\plots\prepData_', ...
%         dataInfo.Properties.VariableNames{varI}, '.png'])
%     close
% end

%% sanity check for those who had a calibration in the middle
userID = [44, 59, 61];
session = [1, 2, 2];
chunk = [2, 7, 8];

for subI = 1:length(userID)
    % find the timestamp of the middle calibration
    % first load the pre-processed file
    preFilename = ['C:\Users\xiuyunwu\Downloads\ETDDC\preprocessed data\prep_', ...
        num2str(userID(subI), '%03i'), '_s', num2str(session(subI)), '_f', num2str(chunk(subI)), '.mat'];
    load(preFilename)

    % load the post-processed file
    postFilename = ['C:\Users\xiuyunwu\Downloads\ETDDC\postprocessed data\post_', ...
        num2str(userID(subI)), '_s', num2str(session(subI)), '_f', num2str(chunk(subI)), '.mat'];
    load(postFilename)
end

%% summary stats sanity check 
load('ETDDC_summaryEyeHeadStats.mat')

for varI = 6:size(eyeHeadStats, 2)
    fig = figure('Position', figPosition);
    axAll = [];
    for subI = 1:length(userAll)
        axAll{subI} = subplot(5, 8, subI)
        idxT = find(eyeHeadStats.userID==userAll(subI) & eyeHeadStats.ETDDC==0);
        plot(eyeHeadStats.ten_min_chunk_in_session(idxT), eyeHeadStats{idxT, varI}, 'o-', 'Color', colors{1})

        hold on
        idxT = find(eyeHeadStats.userID==userAll(subI) & eyeHeadStats.ETDDC==1);
        plot(eyeHeadStats.ten_min_chunk_in_session(idxT), eyeHeadStats{idxT, varI}, 'o-', 'Color', colors{2})

%         ylim([0, 0.4])
        if subI==1
            legend({'ETDDC off', 'ETDDC on'})
        end
        title(num2str(userAll(subI)))
    end
    linkaxes(axAll{:}, 'y')

    saveas(gcf, ['C:\Users\xiuyunwu\OneDrive - Facebook\Documents\Consultation projects_meta\ETDDC motion sickness\plots\chunkSubData_', ...
        eyeHeadStats.Properties.VariableNames{varI}, '.png'])
end

%% sliding window data