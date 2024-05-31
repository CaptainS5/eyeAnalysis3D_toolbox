% getting some general stats of the eye data recording
close all; clear all; warning off; %clc
addpath(genpath('functions'))

set(0, 'units', 'pixels')
screenSize = get(groot,'ScreenSize'); % or specify which screen you are using
figPosition = [25 50 screenSize(3)-100, screenSize(4)-150];

%% set up which users' data to process
userAll = [1, 2, 8, 14, 15, 16, 20, 21, 22, 26, 27, 28, 30, 32, 33, 35, 36, 38, 40, 43, 44, 45, 48, 49, 50, 51, 52, 54, 56, 57, 58, 59, 60, 61];

%% for pre-processed data
% colors = {[1 0 0], [0 0 1]};
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
%         % get the time when file was created
%         rawFName = sub_file_info.fileInfo.name;
%         idx1 = strfind(rawFName, '_');
%         idx2 = strfind(rawFName, '.');
%         datetimeS = rawFName(idx1+1:idx2-1);
%
%         infmt = "yyyymmdd-HHmmss";
%         dt = datetime(datetimeS, "InputFormat", infmt);
%
%         dataInfo.userID(count, 1) = str2num(sub_file_info.UserID{1});
%         dataInfo.session(count, 1) = sub_file_info.Session;
%         dataInfo.ETDDC(count, 1) = sub_file_info.ETDDC;
%         dataInfo.ten_min_chunk_in_session(count, 1) = sub_file_info.fileInfo.count;
%         dataInfo.day(count, 1) = sub_file_info.Day;
%
%         dataInfo.totalRawDur_min(count, 1) = (sub_file_info.EyeTrial.rawTimestampFull(end)-sub_file_info.EyeTrial.rawTimestampFull(1))/1000000/60;
%         dataInfo.totalValidDur_min(count, 1) = (sub_file_info.EyeTrial.rawTimestampAfterCleaning(end)-sub_file_info.EyeTrial.rawTimestampAfterCleaning(1))/1000000/60;
%
%         if dataInfo.ten_min_chunk_in_session(count, 1)==1
%             dataInfo.gapFromLastFileStart_min(count, 1) = NaN;
%             dataInfo.gapFromLastFileEnd_min(count, 1) = NaN;
% %             dataInfo.gapFromLastValidData(count, 1) = NaN;
%         else
%             tDiff = dt-lastDT;
%             dataInfo.gapFromLastFileStart_min(count, 1) = minutes(tDiff);
%             dataInfo.gapFromLastFileEnd_min(count, 1) = minutes(tDiff)-dataInfo.totalRawDur_min(count-1, 1);
%             %             dataInfo.gapFromLastValidData(count, 1) = sub_file_info.EyeTrial.rawTimestampAfterCleaning(1)-lastValidDataEndTimestamp;
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
%             dataInfo.removedCalib_propToTotalRaw(count, 1) = dataInfo.removedCalibDur_sec(count, 1)/dataInfo.totalRawDur_min(count, 1)/60;
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
%         lastDT = dt;
% %         lastFileEndTimestamp = sub_file_info.EyeTrial.rawTimestampFull(end);
% %         lastValidDataEndTimestamp = sub_file_info.EyeTrial.rawTimestampAfterCleaning(end);
%         count = count+1;
%     end
% end
% save('dataInfo.mat', 'dataInfo')
%
% %% plot
% for varI = [6:9, 12:size(dataInfo, 2)]
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
% userID = [44, 59, 61];
% session = [1, 2, 2];
% chunk = [2, 7, 8];
% durAll = [60, 120];
% 
% stats = table;
% count = 1;
% for durI = 1:length(durAll)
%     for subI = 1:length(userID)
%         % find the timestamp of the middle calibration
%         % first load the pre-processed file
% %                 preFilename = ['C:\Users\xiuyunwu\OneDrive - Facebook\Documents\Consultation projects_meta\ETDDC motion sickness\prep_', ...
% %                     num2str(userID(subI), '%03i'), '_s', num2str(session(subI)), '_f', num2str(chunk(subI)), '.mat'];
%         preFilename = ['C:\Users\xiuyunwu\Downloads\ETDDC\preprocessed data\prep_', ...
%             num2str(userID(subI), '%03i'), '_s', num2str(session(subI)), '_f', num2str(chunk(subI)), '.mat'];
%         load(preFilename)
% 
%         % find when the calibration was done
%         calibStartTimestamp = sub_file_info.calibInfo.startTimestamp(end);
%         calibEndTimestamp = sub_file_info.calibInfo.resultTimestamp(end);
%         timeInDataS = (calibStartTimestamp-sub_file_info.EyeTrial.rawTimestampAfterCleaning(1))./ 1000000;
%         timeInDataE = (calibEndTimestamp-sub_file_info.EyeTrial.rawTimestampAfterCleaning(1))./ 1000000;
% 
%         % load the post-processed file
% %                 postFilename = ['C:\Users\xiuyunwu\OneDrive - Facebook\Documents\Consultation projects_meta\ETDDC motion sickness\post_', ...
% %                     num2str(userID(subI)), '_s', num2str(session(subI)), '_f', num2str(chunk(subI)), '.mat'];
%         postFilename = ['C:\Users\xiuyunwu\Downloads\ETDDC\postprocessed data\post_', ...
%             num2str(userID(subI)), '_s', num2str(session(subI)), '_f', num2str(chunk(subI)), '.mat'];
%         load(postFilename)
% 
%         % find duration of one minute before and one minute after
% %         idxT = find(small_file_info.EyeInfo{1}.timestamp<timeInDataS);
% %         durBefore = small_file_info.EyeInfo{1}.timestamp(idxT(end))-small_file_info.EyeInfo{1}.timestamp(1)
%         idxBefore = find( (small_file_info.EyeInfo{1}.timestamp>=timeInDataS-durAll(durI)) & ...
%             (small_file_info.EyeInfo{1}.timestamp<timeInDataS));
%         idxAfter = find( (small_file_info.EyeInfo{1}.timestamp>timeInDataE) & ...
%             (small_file_info.EyeInfo{1}.timestamp<=timeInDataE+durAll(durI)));
% 
%         % get stats
%         for ii = 1:2
%             if ii==1
%                 startTime = small_file_info.EyeInfo{1}.timestamp(idxBefore(1));
%                 endTime = small_file_info.EyeInfo{1}.timestamp(idxBefore(end));
%             else
%                 startTime = small_file_info.EyeInfo{1}.timestamp(idxAfter(1));
%                 endTime = small_file_info.EyeInfo{1}.timestamp(idxAfter(end));
%             end
% 
%             stats(count, :) = getWindowStats(small_file_info, startTime, endTime, ii-1, durAll(durI));
% 
%             count = count+1;
%         end
%     end
% end
% 
% %% plot the comparisons before and after
% userID = [44, 59, 61];
% session = [1, 2, 2];
% chunk = [2, 7, 8];
% durAll = [60, 120];
% 
% colors = [1 0 0; 0 1 0; 0 0 1];
% 
% fig = figure('Position', figPosition);
% for varI = 7:size(stats, 2)
%     subplot(6, 8, varI-6);
%     hold on
%     for subI = 1:length(userID)
%         for durI = 1:length(durAll)
%             idxB = find(stats.userID==userID(subI) & stats.isAfter==0 & stats.dur_s==durAll(durI));
%             idxA = find(stats.userID==userID(subI) & stats.isAfter==1 & stats.dur_s==durAll(durI));
%             if durI==1
%                 p1 = plot([0 1], [stats{idxB, varI} stats{idxA, varI}], 'o--', 'Color', colors(subI, :));
%             else
%                 p1 = plot([0 1], [stats{idxB, varI} stats{idxA, varI}], 'o-', 'Color', colors(subI, :));
%             end
%         end
%     end
%     xticks([0, 1])
%     xticklabels({'before', 'after'})
%     if varI==1
%         legend([p1, p2], {'60s', '120s'})
%     end
%     title(stats.Properties.VariableNames{varI})
% end
% saveas(gcf, ['C:\Users\xiuyunwu\OneDrive - Facebook\Documents\Consultation projects_meta\ETDDC motion sickness\plots\statsBeforeAfterMiddelCalib.png'])
% close
% 
%% summary stats sanity check
% colors = {[1 0 0], [0 0 1]};
% load('ETDDC_summaryEyeHeadStats.mat')
% 
% for varI = 6:size(eyeHeadStats, 2)
%     fig = figure('Position', figPosition);
%     axAll = [];
%     for subI = 1:length(userAll)
%         axAll{subI} = subplot(5, 7, subI);
%         idxT = find(eyeHeadStats.userID==userAll(subI) & eyeHeadStats.ETDDC==0);
%         plot(eyeHeadStats.ten_min_chunk_in_session(idxT), eyeHeadStats{idxT, varI}, 'o-', 'Color', colors{1})
% 
%         hold on
%         idxT = find(eyeHeadStats.userID==userAll(subI) & eyeHeadStats.ETDDC==1);
%         plot(eyeHeadStats.ten_min_chunk_in_session(idxT), eyeHeadStats{idxT, varI}, 'o-', 'Color', colors{2})
% 
%         %         ylim([0, 0.4])
%         if subI==1
%             legend({'ETDDC off', 'ETDDC on'})
%         end
%         title(num2str(userAll(subI)))
%     end
%     linkaxes([axAll{:}], 'y')
% 
%     saveas(gcf, ['C:\Users\xiuyunwu\OneDrive - Facebook\Documents\Consultation projects_meta\ETDDC motion sickness\plots\summaryStats\', ...
%         eyeHeadStats.Properties.VariableNames{varI}, '.png'])
%     close
% end

%% sliding window data
dMeta = load('ETDDC_summaryEyeHeadStats.mat');

windowLength = [30, 60, 120];% [30, 120]; % in secs
windowGap = [10, 20, 30];% [10, 30]; % secs

for wI = 1:length(windowLength)
    load(['ETDDC_summaryEyeHeadStats_slidingWindow_', num2str(windowLength(wI)), 'length_', num2str(windowGap(wI)), 'gap.mat'])
    varAll = eyeHeadStats.Properties.VariableNames;

    for dI = 1:size(dMeta.eyeHeadStats, 1)
        userID = dMeta.eyeHeadStats.userID(dI);
        session = dMeta.eyeHeadStats.session(dI);
        ETDDC = dMeta.eyeHeadStats.ETDDC(dI);

        idxT = find(eyeHeadStats.userID==userID & eyeHeadStats.session==session & eyeHeadStats.ETDDC==ETDDC);

        fig = figure('Position', figPosition);
        for varI = 8:size(eyeHeadStats, 2)
            subplot(6, 8, varI-7)
            plot(eyeHeadStats.windowN(idxT), eyeHeadStats{idxT, varI})
            xlabel('window')
            title(varAll{varI})
        end
        saveas(gcf, ['C:\Users\xiuyunwu\OneDrive - Facebook\Documents\Consultation projects_meta\ETDDC motion sickness\plots\slidingWindow\', ...
            num2str(userID), '_', eyeHeadStats.Properties.VariableNames{varI}, '.png'])
        close
    end
end

%%
function stats = getWindowStats(dataAll, startTimestamp, endTimestamp, isAfter, dur)
stats = table;

stats.userID = str2num(dataAll.UserID{1});
stats.session = dataAll.Session;
stats.ETDDC = dataAll.ETDDC;
stats.chunk = dataAll.fileInfo.count;
stats.isAfter = isAfter;
stats.dur_s = dur;

durTotal = stats.dur_s;

%% blink
skip = 0;
% find the idx of the blinks that are within the window
startInI = find(dataAll.blink{1}.onsetTime>=startTimestamp & dataAll.blink{1}.onsetTime<endTimestamp);
if isempty(startInI)
    skip = 1;
else
    onsetTimeW = dataAll.blink{1}.onsetTime(startInI);
end

endInI = find(dataAll.blink{1}.offsetTime>=startTimestamp & dataAll.blink{1}.offsetTime<endTimestamp);
if isempty(endInI)
    skip = 1;
else
    offsetTimeW = dataAll.blink{1}.offsetTime(endInI);
end

if ~skip
    % check the ones across window and modify duration to be within the
    % window
    if startInI(1)>endInI(1) % the first one started in the last window
        onsetTimeW = [startTimestamp; onsetTimeW];
    end

    if startInI(end)>endInI(end) % the last one finished in the next window
        offsetTimeW = [offsetTimeW; endTimestamp];
    end

    %     blinkDur = dataAll.blink{1}.offsetTime(startI:endI)-dataAll.blink{1}.onsetTime(startI:endI);
    blinkDur = offsetTimeW-onsetTimeW;

    idxE = find(blinkDur>2);
    blinkDur(idxE) = [];

    stats.blink_total_num = length(blinkDur);
    stats.blink_rate_per_sec = length(blinkDur)/durTotal;
    stats.blink_dur_mean = nanmean(blinkDur);
    stats.blink_dur_median = nanmedian(blinkDur);
    stats.blink_dur_total_proportion = sum(blinkDur)/durTotal;

    
%     stats.blink_within2S_total_num = length(blinkDur);
%     stats.blink_within2S_rate_per_sec = length(blinkDur)/durTotal;
%     stats.blink_within2S_dur_mean = nanmean(blinkDur);
%     stats.blink_within2S_dur_median = nanmedian(blinkDur);
%     stats.blink_within2S_dur_total_proportion = sum(blinkDur)/durTotal;
else
    stats.blink_total_num = NaN;
    stats.blink_rate_per_sec = NaN;
    stats.blink_dur_mean = NaN;
    stats.blink_dur_median = NaN;
    stats.blink_dur_total_proportion = NaN;

    stats.blink_within2S_total_num = NaN;
    stats.blink_within2S_rate_per_sec = NaN;
    stats.blink_within2S_dur_mean = NaN;
    stats.blink_within2S_dur_median = NaN;
    stats.blink_within2S_dur_total_proportion = NaN;
end

%% fixation
skip = 0;
% find the idx of the fixations that are within the window
startInI = find(dataAll.gazeFix{1}.onsetTime>=startTimestamp & dataAll.gazeFix{1}.onsetTime<endTimestamp);
if isempty(startInI)
    skip = 1;
else
    onsetTimeW = dataAll.gazeFix{1}.onsetTime(startInI);
end

endInI = find(dataAll.gazeFix{1}.offsetTime>=startTimestamp & dataAll.gazeFix{1}.offsetTime<endTimestamp);
if isempty(endInI)
    skip = 1;
else
    offsetTimeW = dataAll.gazeFix{1}.offsetTime(endInI);
end

if ~skip
    % check the ones across window and modify duration to be within the
    % window
    if startInI(1)>endInI(1) % the first one started in the last window
        onsetTimeW = [startTimestamp; onsetTimeW];
    end

    if startInI(end)>endInI(end) % the last one finished in the next window
        offsetTimeW = [offsetTimeW; endTimestamp];
    end
    fixDur = offsetTimeW-onsetTimeW;

    stats.fixation_total_num = length(fixDur);
    stats.fixation_rate_per_sec = length(fixDur)/durTotal;
    stats.fixation_dur_mean = nanmean(fixDur);
    stats.fixation_dur_median = nanmedian(fixDur);
    stats.fixation_dur_total_proportion = sum(fixDur)./durTotal;
else
    stats.fixation_total_num = NaN;
    stats.fixation_rate_per_sec = NaN;
    stats.fixation_dur_mean = NaN;
    stats.fixation_dur_median = NaN;
    stats.fixation_dur_total_proportion = NaN;
end

%% VOR
skip = 0;
% find the idx of the VOR that are within the window
startInI = find(dataAll.VOR{1}.onsetTime>=startTimestamp & dataAll.VOR{1}.onsetTime<endTimestamp);
if isempty(startInI)
    skip = 1;
else
    onsetTimeW = dataAll.VOR{1}.onsetTime(startInI);
end

endInI = find(dataAll.VOR{1}.offsetTime>=startTimestamp & dataAll.VOR{1}.offsetTime<endTimestamp);
if isempty(endInI)
    skip = 1;
else
    offsetTimeW = dataAll.VOR{1}.offsetTime(endInI);
end

if ~skip
    % check the ones across window and modify duration to be within the
    % window
    if startInI(1)>endInI(1) % the first one started in the last window
        onsetTimeW = [startTimestamp; onsetTimeW];
    end

    if startInI(end)>endInI(end) % the last one finished in the next window
        offsetTimeW = [offsetTimeW; endTimestamp];
    end
    vorDur = offsetTimeW-onsetTimeW;

    stats.vor_total_num = length(vorDur);
    stats.vor_dur_mean = nanmean(vorDur);
    stats.vor_dur_median = nanmedian(vorDur);
    stats.vor_dur_total_proportion = sum(vorDur)./durTotal;

    % for head velocity info
    startI = find(dataAll.HeadInfo{1}.timestamp>=startTimestamp);
    startI = startI(1);

    endI = find(dataAll.HeadInfo{1}.timestamp<endTimestamp);
    endI = endI(end);

    dTH = dataAll.HeadInfo{1}(startI:endI, :);
    dTE = dataAll.EyeInfo{1}(startI:endI, :);
    idxV = find(dataAll.classID{1}(startI:endI)==3);

    vorHeadVel3D = dTH.rotVel3D(idxV);
    vorEyeInHeadVel2D = dTE.velOriHeadFilt2D(idxV);
    vorEyeInHeadVelHori = abs(dTE.velOriHeadFiltX(idxV));
    vorEyeInHeadVelVerti = abs(dTE.velOriHeadFiltY(idxV));
    % cleaning
    idxT = find(vorHeadVel3D>120 | vorHeadVel3D==0);
    vorHeadVel3D(idxT) = [];
    vorEyeInHeadVel2D(idxT) = [];
    vorEyeInHeadVelHori(idxT) = [];
    vorEyeInHeadVelVerti(idxT) = [];

    if ~isempty(vorHeadVel3D)
        stats.vor_headVel3D_median_magnitude = nanmedian(vorHeadVel3D);
        stats.vor_headVel3D_95prctile = prctile(vorHeadVel3D, 95); %prctile(vorHeadVel2D, 97.5)-prctile(vorHeadVel2D, 2.5);

        stats.vor_eyeInHeadVel_median_magnitude = nanmedian(vorEyeInHeadVel2D);
        stats.vor_eyeInHeadVel_95prctile = prctile(vorEyeInHeadVel2D, 95); %prctile(vorHeadVel2D, 97.5)-prctile(vorHeadVel2D, 2.5);
        stats.vor_hori_eyeInHeadVel_median_magnitude = nanmedian(vorEyeInHeadVelHori);
        stats.vor_hori_eyeInHeadVel_95prctile = prctile(vorEyeInHeadVelHori, 95); % prctile(vorHeadVelHori, 97.5)-prctile(vorHeadVelHori, 2.5);
        stats.vor_verti_eyeInHeadVel_median_magnitude = nanmedian(vorEyeInHeadVelVerti);
        stats.vor_verti_eyeInHeadVel_95prctile = prctile(vorEyeInHeadVelVerti, 95); %prctile(vorHeadVelVerti, 97.5)-prctile(vorHeadVelVerti, 2.5);
    else
        stats.vor_headVel3D_median_magnitude = NaN;
        stats.vor_headVel3D_95prctile = NaN; %prctile(vorHeadVel2D, 97.5)-prctile(vorHeadVel2D, 2.5);

        stats.vor_eyeInHeadVel_median_magnitude = NaN;
        stats.vor_eyeInHeadVel_95prctile = NaN; %prctile(vorHeadVel2D, 97.5)-prctile(vorHeadVel2D, 2.5);
        stats.vor_hori_eyeInHeadVel_median_magnitude = NaN;
        stats.vor_hori_eyeInHeadVel_95prctile = NaN; % prctile(vorHeadVelHori, 97.5)-prctile(vorHeadVelHori, 2.5);
        stats.vor_verti_eyeInHeadVel_median_magnitude = NaN;
        stats.vor_verti_eyeInHeadVel_95prctile = NaN; %prctile(vorHeadVelVerti, 97.5)-prctile(vorHeadVelVerti, 2.5);
    end
else
    stats.vor_headVel3D_median_magnitude = NaN;
    stats.vor_headVel3D_95prctile = NaN; %prctile(vorHeadVel2D, 97.5)-prctile(vorHeadVel2D, 2.5);

    stats.vor_eyeInHeadVel_median_magnitude = NaN;
    stats.vor_eyeInHeadVel_95prctile = NaN; %prctile(vorHeadVel2D, 97.5)-prctile(vorHeadVel2D, 2.5);
    stats.vor_hori_eyeInHeadVel_median_magnitude = NaN;
    stats.vor_hori_eyeInHeadVel_95prctile = NaN; % prctile(vorHeadVelHori, 97.5)-prctile(vorHeadVelHori, 2.5);
    stats.vor_verti_eyeInHeadVel_median_magnitude = NaN;
    stats.vor_verti_eyeInHeadVel_95prctile = NaN; %prctile(vorHeadVelVerti, 97.5)-prctile(vorHeadVelVerti, 2.5);
end

%% saccades--do some main sequence cleaning here!
skip = 0;
% find the idx of the saccades that are within the window
startI = find(dataAll.saccade{1}.onsetTime>=startTimestamp);
if ~isempty(startI)
    startI = startI(1);
else
    skip = 1;
end

endI = find(dataAll.saccade{1}.onsetTime<endTimestamp);
if ~isempty(endI)
    endI = endI(end);
else
    skip = 1;
end

if ~skip && endI>=startI
    ampInHead = dataAll.SaccadeInfo.ampInHead(startI:endI);
    peakVelInHead = dataAll.SaccadeInfo.peakVelHead(startI:endI);

    idxT = find(ampInHead>50 | peakVelInHead>1200 | ...
        ampInHead<2);
    ampInHead(idxT) = [];
    peakVelInHead(idxT) = [];

    stats.sac_total_num = length(ampInHead);
    stats.sac_rate_per_sec = length(ampInHead)/durTotal;
    stats.sac_amp_median = nanmedian(ampInHead);
    stats.sac_amp_95prctile = prctile(ampInHead, 95);
    stats.sac_peak_vel_median_magnitude = nanmedian(peakVelInHead);
    stats.sac_peak_vel_95prctile = prctile(peakVelInHead, 95);
else
    stats.sac_total_num = NaN;
    stats.sac_rate_per_sec = NaN;
    stats.sac_amp_median = NaN;
    stats.sac_amp_95prctile = NaN;
    stats.sac_peak_vel_median_magnitude = NaN;
    stats.sac_peak_vel_95prctile = NaN;
end

%% head velocity
%             skip = 0;
% find the idx of the saccades that are within the window
startI = find(dataAll.HeadInfo{1}.timestamp>=startTimestamp);
startI = startI(1);

endI = find(dataAll.HeadInfo{1}.timestamp<endTimestamp);
endI = endI(end);

headVel3D = dataAll.HeadInfo{1}.rotVel3D(startI:endI);
% cleaning
idxT = find(headVel3D>120 |isnan(headVel3D));
headVel3D(idxT) = [];

headRotQ = [dataAll.HeadInfo{1}.rotFiltQw dataAll.HeadInfo{1}.rotFiltQx ...
    dataAll.HeadInfo{1}.rotFiltQy dataAll.HeadInfo{1}.rotFiltQz];

if ~isempty(headVel3D)
    eulYPR = [NaN NaN NaN; ...
        quat2eul(headRotQ(2:end, :))./pi.*180.*(1./diff(dataAll.HeadInfo{1}.timestamp))]; % yaw pitch roll, velocity

    headVelHori = abs(eulYPR(startI:endI, 1));
    headVelVerti = abs(-eulYPR(startI:endI, 2));

    headVelHori(idxT) = [];
    headVelVerti(idxT) = [];

    stats.head_3DVel_median_magnitude = nanmedian(headVel3D);
    stats.head_3DVel_95prctile = prctile(headVel3D, 95);
    stats.head_horiVel_median_magnitude = nanmedian(headVelHori);
    stats.head_horiVel_95prctile = prctile(headVelHori, 95);
    stats.head_vertiVel_median_magnitude = nanmedian(headVelVerti);
    stats.head_vertiVel_95prctile = prctile(headVelVerti, 95);
else
    stats.head_3DVel_median_magnitude = NaN;
    stats.head_3DVel_95prctile = NaN;
    stats.head_horiVel_median_magnitude = NaN;
    stats.head_horiVel_95prctile = NaN;
    stats.head_vertiVel_median_magnitude = NaN;
    stats.head_vertiVel_95prctile = NaN;
end

%% eye/head movement range
startI = find(dataAll.HeadInfo{1}.timestamp>=startTimestamp);
startI = startI(1);

endI = find(dataAll.HeadInfo{1}.timestamp<endTimestamp);
endI = endI(end);

dTH = [];
dTH.EyeInfo = dataAll.EyeInfo{1}(startI:endI, :);
dTH.HeadInfo = dataAll.HeadInfo{1}(startI:endI, :);

idxT = find(~isnan(dTH.HeadInfo.oriFiltQw) & ~isnan(dTH.EyeInfo.gazeOriHeadFiltX));

if ~isempty(idxT)
    eyeOriX = dTH.EyeInfo.gazeOriHeadFiltX(idxT);
    eyeOriY = dTH.EyeInfo.gazeOriHeadFiltY(idxT);

    stats.eye_in_head_horiOri_95range = prctile(eyeOriX, 97.5)-prctile(eyeOriX, 2.5);
    stats.eye_in_head_vertiOri_95range = prctile(eyeOriY, 97.5)-prctile(eyeOriY, 2.5);

    headOriQ = [dTH.HeadInfo.oriFiltQw(idxT) dTH.HeadInfo.oriFiltQx(idxT) ...
        dTH.HeadInfo.oriFiltQy(idxT) dTH.HeadInfo.oriFiltQz(idxT)];
    eulYPR = quat2eul(headOriQ)/pi*180; % yaw pitch roll
    headOriHori = eulYPR(:, 1);
    headOriVerti = -eulYPR(:, 2);

    stats.head_horiOri_95range = prctile(headOriHori, 97.5)-prctile(headOriHori, 2.5);
    stats.head_vertiOri_95range = prctile(headOriVerti, 97.5)-prctile(headOriVerti, 2.5);
else
    stats.eye_in_head_horiOri_95range = NaN;
    stats.eye_in_head_vertiOri_95range = NaN;
    stats.head_horiOri_95range = NaN;
    stats.head_vertiOri_95range = NaN;
end

end