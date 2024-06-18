% extract summary stats from the chunks
clear all; close all; warning off;% clc; 

%% set parameters
windowLength = [30, 60, 120]; %, 300, 600]; % in secs
windowGap = [10, 20, 30]; %, 60, 120]; % secs

sampleRate = 240;
frameLength = 1/sampleRate; % in secs

varTraces = {'EyeInfo', 'HeadInfo'};
varClassification = {'gazeFix', 'saccade', 'blink', 'VOR'};
varOnOffI = {'onsetI', 'offsetI'};
varOnOffTime = {'onsetTime', 'offsetTime'};
varSac = {'baseVel', 'sacThres', 'ampInHead', 'peakVelInHead'};
varVOR = {'gainAmp', 'gainDir'};

datafolder = 'C:\Users\xiuyunwu\Downloads\ETDDC\postprocessed data\';
files = dir(datafolder);
files(1:2) = [];

% files that we need to delete the duration after calibration
calibUser = [44, 59, 61];
calibSession = [1, 2, 2];
calibChunk = [2, 7, 8];

% find out the shortest duration among all chunks across all participants
chunkDurs = table;
count = 1;
tic
for fileI = 1:size(files, 1)
    load([datafolder, files(fileI).name])

    chunkDurs.userID(count, 1) = str2num(small_file_info.UserID{1});
    chunkDurs.session(count, 1) = small_file_info.Session;
    chunkDurs.ETDDC(count, 1) = small_file_info.ETDDC;
    chunkDurs.chunk(count, 1) = small_file_info.fileInfo.count;

    if (chunkDurs.userID(count, 1)==44 && chunkDurs.session(count, 1)==1 && chunkDurs.chunk(count, 1)==2) || ...
            (chunkDurs.userID(count, 1)==59 && chunkDurs.session(count, 1)==2 && chunkDurs.chunk(count, 1)==7) || ...
            (chunkDurs.userID(count, 1)==61 && chunkDurs.session(count, 1)==2 && chunkDurs.chunk(count, 1)==8)
        preFilename = ['C:\Users\xiuyunwu\Downloads\ETDDC\preprocessed data\prep_', ...
            num2str(chunkDurs.userID(count, 1), '%03i'), '_s', num2str(chunkDurs.session(count, 1)), '_f', num2str(chunkDurs.chunk(count, 1)), '.mat'];
        load(preFilename)

        % find when the calibration was done
        calibStartTimestamp = sub_file_info.calibInfo.startTimestamp(end);
        timeInDataS = (calibStartTimestamp-sub_file_info.EyeTrial.rawTimestampAfterCleaning(1))./ 1000000;

        % delete data after calibration
        idxT = find(small_file_info.EyeInfo{1}.timestamp>=timeInDataS);
        small_file_info.EyeInfo{1}(idxT:end, :) = [];
    end

    chunkDurs.dur(count, 1) = small_file_info.EyeInfo{1}.timestamp(end)-small_file_info.EyeInfo{1}.timestamp(1);
    count = count+1;
end
chunkDur_min = min(chunkDurs.dur)
save('chunkDur.mat', 'chunkDurs', 'chunkDur_min');
writetable(chunkDurs, 'chunkDur.csv')
toc

%% loop through different windows and users...
for wI = 1:length(windowLength)
    eyeHeadStats = table;

    wStartTime = [0:windowGap(wI):(chunkDur_min-windowLength(wI))];
    wEndTime = wStartTime + windowLength(wI);

    for fileI = 1:size(files, 1)
        load([datafolder, files(fileI).name])
        chunk = small_file_info.fileInfo.count;

        % figure out how many windows and their start/end point,
        % pre-allocate space into the table
        timestamp = small_file_info.EyeInfo{1}.timestamp;
        timePassed = timestamp-timestamp(1);

        wStartI = [];
        wEndI = [];
        for ii = 1:length(wStartTime)
            idxT = find(timePassed>=wStartTime(ii));
            wStartI(ii) = idxT(1);

            idxT = find(timePassed<=wEndTime(ii));
            wEndI(ii) = idxT(end);
        end

        eyeHeadSub = table;
        disp(['processing window length ', num2str(windowLength(wI)), ...
            's, gap ', num2str(windowGap(wI)), 's, user ', small_file_info.UserID{1}, ...
            ', session ', num2str(small_file_info.Session), ', ETDDC ', num2str(small_file_info.ETDDC)])

        for stepI = 1:length(wStartI)
            eyeHeadSub(stepI, :) = getWindowStats(small_file_info, wStartI(stepI), wEndI(stepI), stepI+(chunk-1)*length(wStartI));
        end

        eyeHeadStats = [eyeHeadStats; eyeHeadSub];
    end

    save(['ETDDC_summaryEyeHeadStats_slidingWindow_', num2str(windowLength(wI)), 'length_', num2str(windowGap(wI)), 'gap.mat'], 'eyeHeadStats', '-v7.3')
    writetable(eyeHeadStats, ['ETDDC_summaryEyeHeadStats_slidingWindow_', num2str(windowLength(wI)), 'length_', num2str(windowGap(wI)), 'gap.csv'])
end

% getDataInfo

function stats = getWindowStats(dataAll, wStartI, wEndI, windowN)
stats = table;

stats.userID = str2num(dataAll.UserID{1});
stats.session = dataAll.Session;
stats.ETDDC = dataAll.ETDDC;
stats.windowN = windowN; % which window this is
stats.chunk = dataAll.fileInfo.count;
stats.windowStartTimestamp = dataAll.EyeInfo{1}.timestamp(wStartI);
stats.windowEndTimestamp = dataAll.EyeInfo{1}.timestamp(wEndI);

durTotal = stats.windowEndTimestamp - stats.windowStartTimestamp;

%% blink
skip = 0;
% find the idx of the blinks that are within the window
startInI = find(dataAll.blink{1}.onsetTime>=stats.windowStartTimestamp & dataAll.blink{1}.onsetTime<stats.windowEndTimestamp);
if isempty(startInI)
    skip = 1;
else
    onsetTimeW = dataAll.blink{1}.onsetTime(startInI);
end

endInI = find(dataAll.blink{1}.offsetTime>=stats.windowStartTimestamp & dataAll.blink{1}.offsetTime<stats.windowEndTimestamp);
if isempty(endInI)
    skip = 1;
else
    offsetTimeW = dataAll.blink{1}.offsetTime(endInI);
end

% startI = find(dataAll.blink{1}.onsetTime>=stats.windowStartTime);
% if ~isempty(startI)
%     startI = startI(1);
% else
%     skip = 1;
% end
% 
% endI = find(dataAll.blink{1}.onsetTime<stats.windowEndTime);
% if ~isempty(endI)
%     endI = endI(end);
% else
%     skip = 1;
% end

if ~skip
    % check the ones across window and modify duration to be within the
    % window
    if startInI(1)>endInI(1) % the first one started in the last window
        onsetTimeW = [stats.windowStartTimestamp; onsetTimeW];
    end
    
    if startInI(end)>endInI(end) % the last one finished in the next window
        offsetTimeW = [offsetTimeW; stats.windowEndTimestamp];
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

%     stats.blink_within2S_total_num = NaN;
%     stats.blink_within2S_rate_per_sec = NaN;
%     stats.blink_within2S_dur_mean = NaN;
%     stats.blink_within2S_dur_median = NaN;
%     stats.blink_within2S_dur_total_proportion = NaN;
end

%% fixation
skip = 0;
% find the idx of the fixations that are within the window
startInI = find(dataAll.gazeFix{1}.onsetTime>=stats.windowStartTimestamp & dataAll.gazeFix{1}.onsetTime<stats.windowEndTimestamp);
if isempty(startInI)
    skip = 1;
else
    onsetTimeW = dataAll.gazeFix{1}.onsetTime(startInI);
end

endInI = find(dataAll.gazeFix{1}.offsetTime>=stats.windowStartTimestamp & dataAll.gazeFix{1}.offsetTime<stats.windowEndTimestamp);
if isempty(endInI)
    skip = 1;
else
    offsetTimeW = dataAll.gazeFix{1}.offsetTime(endInI);
end
% startI = find(dataAll.gazeFix{1}.onsetTime>=stats.windowStartTime);
% if ~isempty(startI)
%     startI = startI(1);
% else
%     skip = 1;
% end
% 
% endI = find(dataAll.gazeFix{1}.onsetTime<stats.windowEndTime);
% if ~isempty(endI)
%     endI = endI(end);
% else
%     skip = 1;
% end

if ~skip
    % check the ones across window and modify duration to be within the
    % window
    if startInI(1)>endInI(1) % the first one started in the last window
        onsetTimeW = [stats.windowStartTimestamp; onsetTimeW];
    end
    
    if startInI(end)>endInI(end) % the last one finished in the next window
        offsetTimeW = [offsetTimeW; stats.windowEndTimestamp];
    end
    fixDur = offsetTimeW-onsetTimeW;
    
%     fixDur = dataAll.gazeFix{1}.offsetTime(startI:endI)-dataAll.gazeFix{1}.onsetTime(startI:endI);
    
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
startInI = find(dataAll.VOR{1}.onsetTime>=stats.windowStartTimestamp & dataAll.VOR{1}.onsetTime<stats.windowEndTimestamp);
if isempty(startInI)
    skip = 1;
else
    onsetTimeW = dataAll.VOR{1}.onsetTime(startInI);
end

endInI = find(dataAll.VOR{1}.offsetTime>=stats.windowStartTimestamp & dataAll.VOR{1}.offsetTime<stats.windowEndTimestamp);
if isempty(endInI)
    skip = 1;
else
    offsetTimeW = dataAll.VOR{1}.offsetTime(endInI);
end
% startI = find(dataAll.VOR{1}.onsetTime>=stats.windowStartTime);
% if ~isempty(startI)
%     startI = startI(1);
% else
%     skip = 1;
% end
% 
% endI = find(dataAll.VOR{1}.onsetTime<stats.windowEndTime);
% if ~isempty(endI)
%     endI = endI(end);
% else
%     skip = 1;
% end

if ~skip
    % check the ones across window and modify duration to be within the
    % window
    if startInI(1)>endInI(1) % the first one started in the last window
        onsetTimeW = [stats.windowStartTimestamp; onsetTimeW];
    end
    
    if startInI(end)>endInI(end) % the last one finished in the next window
        offsetTimeW = [offsetTimeW; stats.windowEndTimestamp];
    end
    vorDur = offsetTimeW-onsetTimeW;
%     vorDur = dataAll.VOR{1}.offsetTime(startI:endI)-dataAll.VOR{1}.onsetTime(startI:endI);

    stats.vor_total_num = length(vorDur);
    stats.vor_dur_mean = nanmean(vorDur);
    stats.vor_dur_median = nanmedian(vorDur);
    stats.vor_dur_total_proportion = sum(vorDur)./durTotal;

    % for head velocity info
    startI = find(dataAll.HeadInfo{1}.timestamp>=stats.windowStartTimestamp);
    startI = startI(1);

    endI = find(dataAll.HeadInfo{1}.timestamp<stats.windowEndTimestamp);
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
    stats.vor_total_num = NaN;
    stats.vor_dur_mean = NaN;
    stats.vor_dur_median = NaN;
    stats.vor_dur_total_proportion = NaN;

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
startI = find(dataAll.saccade{1}.onsetTime>=stats.windowStartTimestamp);
if ~isempty(startI)
    startI = startI(1);
else
    skip = 1;
end

endI = find(dataAll.saccade{1}.onsetTime<stats.windowEndTimestamp);
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
startI = find(dataAll.HeadInfo{1}.timestamp>=stats.windowStartTimestamp);
%             if ~isempty(startI)
startI = startI(1);
%             else
%                 skip = 1;
%             end

endI = find(dataAll.HeadInfo{1}.timestamp<stats.windowEndTimestamp);
%             if ~isempty(endI)
endI = endI(end);
%             else
%                 skip = 1;
%             end

%             if ~skip
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
    headVelRoll = abs(-eulYPR(startI:endI, 3));    
    
    headVelHori(idxT) = [];
    headVelVerti(idxT) = [];
    headVelRoll(idxT) = [];
    
    stats.head_3DVel_median_magnitude = nanmedian(headVel3D);
    stats.head_3DVel_95prctile = prctile(headVel3D, 95);
    stats.head_horiVel_median_magnitude = nanmedian(headVelHori);
    stats.head_horiVel_95prctile = prctile(headVelHori, 95);
    stats.head_vertiVel_median_magnitude = nanmedian(headVelVerti);
    stats.head_vertiVel_95prctile = prctile(headVelVerti, 95);
    stats.head_rollVel_median_magnitude = nanmedian(headVelRoll);
    stats.head_rollVel_95prctile = prctile(headVelRoll, 95);
else
    stats.head_3DVel_median_magnitude = NaN;
    stats.head_3DVel_95prctile = NaN;
    stats.head_horiVel_median_magnitude = NaN;
    stats.head_horiVel_95prctile = NaN;
    stats.head_vertiVel_median_magnitude = NaN;
    stats.head_vertiVel_95prctile = NaN;
    stats.head_rollVel_median_magnitude = NaN;
    stats.head_rollVel_95prctile = NaN;
end

%% eye/head movement range
startI = find(dataAll.HeadInfo{1}.timestamp>=stats.windowStartTimestamp);
startI = startI(1);

endI = find(dataAll.HeadInfo{1}.timestamp<stats.windowEndTimestamp);
endI = endI(end);

dT = [];
dT.EyeInfo = dataAll.EyeInfo{1}(startI:endI, :);
dT.HeadInfo = dataAll.HeadInfo{1}(startI:endI, :);

idxT = find(~isnan(dT.HeadInfo.oriFiltQw) & ~isnan(dT.EyeInfo.gazeOriHeadFiltX));

if ~isempty(idxT)
    eyeOriX = dT.EyeInfo.gazeOriHeadFiltX(idxT);
    eyeOriY = dT.EyeInfo.gazeOriHeadFiltY(idxT);

    stats.eye_in_head_horiOri_95range = prctile(eyeOriX, 97.5)-prctile(eyeOriX, 2.5);
    stats.eye_in_head_vertiOri_95range = prctile(eyeOriY, 97.5)-prctile(eyeOriY, 2.5);
    
    headOriQ = [dT.HeadInfo.oriFiltQw(idxT) dT.HeadInfo.oriFiltQx(idxT) ...
        dT.HeadInfo.oriFiltQy(idxT) dT.HeadInfo.oriFiltQz(idxT)];
    eulYPR = quat2eul(headOriQ)/pi*180; % yaw pitch roll
    headOriHori = eulYPR(:, 1);
    headOriVerti = -eulYPR(:, 2);
    headOriRoll = eulYPR(:, 3);
    
    stats.head_horiOri_95range = prctile(headOriHori, 97.5)-prctile(headOriHori, 2.5);
    stats.head_vertiOri_95range = prctile(headOriVerti, 97.5)-prctile(headOriVerti, 2.5);
    stats.head_rollOri_95range = prctile(headOriRoll, 97.5)-prctile(headOriRoll, 2.5);
else
    stats.eye_in_head_horiOri_95range = NaN;
    stats.eye_in_head_vertiOri_95range = NaN;
    stats.head_horiOri_95range = NaN;
    stats.head_vertiOri_95range = NaN;
    stats.head_rollOri_95range = NaN;
end

end