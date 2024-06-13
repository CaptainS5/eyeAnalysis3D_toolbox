% extract summary stats from the chunks
clear all; close all; warning off; clc;

datafolder = 'C:\Users\xiuyunwu\Downloads\ETDDC\postprocessed data\';
files = dir(datafolder);
files(1:2) = [];

% load pre-organized calibration scores
calibScores = readtable('calibrationScores_all.csv');

eyeHeadStats = table;
count = 1;
for fileI = 1:size(files, 1)
    load([datafolder, files(fileI).name])

    eyeHeadStats.userID(count, 1) = str2num(small_file_info.UserID{1});
    eyeHeadStats.session(count, 1) = small_file_info.Session;
    eyeHeadStats.ETDDC(count, 1) = small_file_info.ETDDC;
    eyeHeadStats.ten_min_chunk_in_session(count, 1) = small_file_info.fileInfo.count;
    eyeHeadStats.day(count, 1) = small_file_info.Day;

    chunkI = eyeHeadStats.ten_min_chunk_in_session(count, 1);

    %% calibration scores
    if mod(chunkI, 2)==1
        idxT = find(calibScores.UserID==eyeHeadStats.userID(count, 1) & ...
            calibScores.ETDDC==eyeHeadStats.ETDDC(count, 1) & calibScores.GameInSession==(chunkI+1)/2);
        if isempty(idxT)
            eyeHeadStats.calib_RMS_3D_pos(count, 1) = NaN;
            eyeHeadStats.calib_median_3D_pos(count, 1) = NaN;
            eyeHeadStats.calib_RMS_angle_deg(count, 1) = NaN;
            eyeHeadStats.calib_median_angle_deg(count, 1) = NaN;
            eyeHeadStats.calib_RMS_dist_diop(count, 1) = NaN;
            eyeHeadStats.calib_median_dist_diop(count, 1) = NaN;
        else
            if length(idxT)>1 % use the latest calibration for the session
                idxI = find(calibScores.TimeInSession_sec(idxT)==max(calibScores.TimeInSession_sec(idxT)));
                idxT = idxT(idxI);
            end

            eyeHeadStats.calib_RMS_3D_pos(count, 1) = calibScores.RMS_3D_POS(idxT);
            eyeHeadStats.calib_median_3D_pos(count, 1) = calibScores.MED_3D_POS(idxT);
            eyeHeadStats.calib_RMS_angle_deg(count, 1) = calibScores.RMS_ANGLE_DEG(idxT);
            eyeHeadStats.calib_median_angle_deg(count, 1) = calibScores.MED_ANGLE_DEG(idxT);
            eyeHeadStats.calib_RMS_dist_diop(count, 1) = calibScores.RMS_DIST_DIOP(idxT);
            eyeHeadStats.calib_median_dist_diop(count, 1) = calibScores.MED_DIST_DIOP(idxT);
        end
    else
        eyeHeadStats.calib_RMS_3D_pos(count, 1) = NaN;
        eyeHeadStats.calib_median_3D_pos(count, 1) = NaN;
        eyeHeadStats.calib_RMS_angle_deg(count, 1) = NaN;
        eyeHeadStats.calib_median_angle_deg(count, 1) = NaN;
        eyeHeadStats.calib_RMS_dist_diop(count, 1) = NaN;
        eyeHeadStats.calib_median_dist_diop(count, 1) = NaN;
    end

    if ~isempty(small_file_info.EyeInfo)
        durTotal = small_file_info.EyeInfo{1}.timestamp(end)-small_file_info.EyeInfo{1}.timestamp(1);
        % let's use from the beginning of the first classified movement to the end of the last classified movement

        % head rotation
        headRotQ = [small_file_info.HeadInfo{1}.rotFiltQw small_file_info.HeadInfo{1}.rotFiltQx ...
            small_file_info.HeadInfo{1}.rotFiltQy small_file_info.HeadInfo{1}.rotFiltQz];
        eulYPR = quat2eul(headRotQ(2:end, :))./pi.*180.*(1./diff(small_file_info.HeadInfo{1}.timestamp)); % yaw pitch roll, velocity
        
        % doing the sanity check here, go back to the eye traces and
        % classification info if needed, especially for saccades

        %% blink
        %             durTotal = small_file_info.blink{dI}.offsetTime(end)-small_file_info.blink{dI}.offsetTime(1);
        blinkDur = small_file_info.blink{1}.offsetTime-small_file_info.blink{1}.onsetTime;

%         % sanity check
%         figure
%         histogram(blinkDur, 'normalization', 'probability')
%         xlabel('Blink duration (s)')
%         pause
%         close
        
        idxE = find(blinkDur>2);
%         disp(['user ', num2str(eyeHeadStats.userID(count, 1)), ' s', num2str(eyeHeadStats.session(count, 1)), ' chunk ', num2str(eyeHeadStats.ten_min_chunk_in_session(count, 1))])
%         disp(['num outlier ', num2str(length(idxE)), ' max dur ', num2str(nanmax(blinkDur(idxE)))])
        blinkDur(idxE) = [];
        
        eyeHeadStats.blink_total_num(count, 1) = length(blinkDur);
        eyeHeadStats.blink_rate_per_sec(count, 1) = length(blinkDur)/durTotal;
        eyeHeadStats.blink_dur_mean(count, 1) = nanmean(blinkDur);
        eyeHeadStats.blink_dur_median(count, 1) = nanmedian(blinkDur);
        eyeHeadStats.blink_dur_total_proportion(count, 1) = sum(blinkDur)/durTotal;
 
%         eyeHeadStats.blink_within2S_total_num(count, 1) = length(blinkDur);
%         eyeHeadStats.blink_within2S_rate_per_sec(count, 1) = length(blinkDur)/durTotal;
%         eyeHeadStats.blink_within2S_dur_mean(count, 1) = nanmean(blinkDur);
%         eyeHeadStats.blink_within2S_dur_median(count, 1) = nanmedian(blinkDur);
%         eyeHeadStats.blink_within2S_dur_total_proportion(count, 1) = sum(blinkDur)/durTotal;

        %                 % save the blink info...
        %                 small_file_info.blink{dI}.timestamp = small_file_info.EyeInfo{dI}.timestamp;
        %                 eyeHeadStats.blinkInfo{count, 1} = small_file_info.blink{dI};

        %% fixation
        %             durTotal = small_file_info.gazeFix{dI}.offsetTime(end)-small_file_info.gazeFix{dI}.offsetTime(1);
        fixDur = small_file_info.gazeFix{1}.offsetTime-small_file_info.gazeFix{1}.onsetTime;

        %             % sanity check
        %             figure
        %             histogram(fixDur, 'normalization', 'probability')
        %             xlabel('Fixation duration (s)')
        %             pause
        %             close

        eyeHeadStats.fixation_total_num(count, 1) = length(fixDur);
        eyeHeadStats.fixation_rate_per_sec(count, 1) = length(fixDur)/durTotal; %small_file_info.FixationInfo{dI}.fix_per_sec;
        eyeHeadStats.fixation_dur_mean(count, 1) = nanmean(fixDur);
        eyeHeadStats.fixation_dur_median(count, 1) = nanmedian(fixDur);
        eyeHeadStats.fixation_dur_total_proportion(count, 1) = sum(fixDur)./durTotal;

        %% VOR
        %             durTotal = small_file_info.VOR{dI}.offsetTime(end)-small_file_info.VOR{dI}.offsetTime(1);
        vorDur = small_file_info.VOR{1}.offsetTime-small_file_info.VOR{1}.onsetTime;

        idxV = find(small_file_info.classID{1}==3);
        vorHeadVel3D = small_file_info.HeadInfo{1}.rotVel3D(idxV);
        vorEyeInHeadVel2D = small_file_info.EyeInfo{1}.velOriHeadFilt2D(idxV);
        vorEyeInHeadVelHori = abs(small_file_info.EyeInfo{1}.velOriHeadFiltX(idxV));
        vorEyeInHeadVelVerti = abs(small_file_info.EyeInfo{1}.velOriHeadFiltY(idxV));
        % cleaning
        idxT = find(vorHeadVel3D>120 | vorHeadVel3D==0);
        vorHeadVel3D(idxT) = [];
        vorEyeInHeadVel2D(idxT) = [];
        vorEyeInHeadVelHori(idxT) = [];
        vorEyeInHeadVelVerti(idxT) = [];

        %             % sanity check
        %             figure % sanity check
        %             subplot(4, 1, 1)
        %             histogram(vorDur, 'normalization', 'probability')
        %             xlabel('VOR duration (s)')
        %
        %             subplot(4, 1, 2)
        %             histogram(vorHeadVel2D, 'normalization', 'probability')
        %             xlabel('VOR 2D vel (deg/s)')
        %             subplot(4, 1, 3)
        %             histogram(small_file_info.HeadInfo{dI}.displaceX(idxV), 'normalization', 'probability')
        %             xlabel('VOR horizontal vel (deg/s)')
        %             subplot(4, 1, 4)
        %             histogram(small_file_info.HeadInfo{dI}.displaceY(idxV), 'normalization', 'probability')
        %             xlabel('VOR vertical vel (deg/s)')
        %             pause
        %             close

        eyeHeadStats.vor_total_num(count, 1) = length(vorDur);
        eyeHeadStats.vor_dur_mean(count, 1) = nanmean(vorDur);
        eyeHeadStats.vor_dur_median(count, 1) = nanmedian(vorDur);
        eyeHeadStats.vor_dur_total_proportion(count, 1) = sum(vorDur)./durTotal;

        eyeHeadStats.vor_headVel3D_median_magnitude(count, 1) = nanmedian(vorHeadVel3D);
        eyeHeadStats.vor_headVel3D_95prctile(count, 1) = prctile(vorHeadVel3D, 95); %prctile(vorHeadVel2D, 97.5)-prctile(vorHeadVel2D, 2.5);

        eyeHeadStats.vor_eyeInHeadVel_median_magnitude(count, 1) = nanmedian(vorEyeInHeadVel2D);
        eyeHeadStats.vor_eyeInHeadVel_95prctile(count, 1) = prctile(vorEyeInHeadVel2D, 95); %prctile(vorHeadVel2D, 97.5)-prctile(vorHeadVel2D, 2.5);
        eyeHeadStats.vor_hori_eyeInHeadVel_median_magnitude(count, 1) = nanmedian(vorEyeInHeadVelHori);
        eyeHeadStats.vor_hori_eyeInHeadVel_95prctile(count, 1) = prctile(vorEyeInHeadVelHori, 95); % prctile(vorHeadVelHori, 97.5)-prctile(vorHeadVelHori, 2.5);
        eyeHeadStats.vor_verti_eyeInHeadVel_median_magnitude(count, 1) = nanmedian(vorEyeInHeadVelVerti);
        eyeHeadStats.vor_verti_eyeInHeadVel_95prctile(count, 1) = prctile(vorEyeInHeadVelVerti, 95); %prctile(vorHeadVelVerti, 97.5)-prctile(vorHeadVelVerti, 2.5);

        %% saccades--do some main sequence cleaning here!
        %                 durTotal = small_file_info.saccade{dI}.offsetTime(end)-small_file_info.saccade{dI}.offsetTime(1);

        ampInHead = small_file_info.SaccadeInfo.ampInHead;
        peakVelInHead = small_file_info.SaccadeInfo.peakVelHead;

        idxT = find(ampInHead>50 | peakVelInHead>1200 | ...
            ampInHead<2);
        ampInHead(idxT) = [];
        peakVelInHead(idxT) = [];

        %             % main sequence fitting
        %             [params, CI, idxOutliers] = fitMainSequence(ampInHead, peakVelInHead);
        % %             % further cleaning based on mean sequence
        % %             % 6 times out?...
        % %             outlierBound = [CI(1, 1)-5*(params.K-CI(1, 1)), CI(1, 2)-5*(params.L-CI(1, 2)); ...
        % %                 CI(2, 1)-5*(params.K-CI(2, 1)), CI(2, 2)-5*(params.L-CI(2, 2))];
        %
        % %             % plot to check
        % %             figure
        % %             scatter(ampInHead, peakVelInHead)
        % %             hold on
        % %             x = 0:0.005:50;
        % %             plot(x, params.K.*x.^params.L, 'k-', 'lineWidth', 2)
        % %             plot(x, CI(1, 1).*x.^CI(1, 2), 'k--', 'lineWidth', 1.5)
        % %             plot(x, CI(2, 1).*x.^CI(2, 2), 'k--', 'lineWidth', 1.5)
        % %
        % % %             plot(x, outlierBound(1, 1).*x.^outlierBound(1, 2), 'r--', 'lineWidth', 1.5)
        % % %             plot(x, outlierBound(2, 1).*x.^outlierBound(2, 2), 'r--', 'lineWidth', 1.5)
        % %             pause
        % %             close

        eyeHeadStats.sac_total_num(count, 1) = length(ampInHead);
        eyeHeadStats.sac_rate_per_sec(count, 1) = length(ampInHead)/durTotal;
        eyeHeadStats.sac_amp_median(count, 1) = nanmedian(ampInHead);
        eyeHeadStats.sac_amp_95prctile(count, 1) = prctile(ampInHead, 95);
        eyeHeadStats.sac_peak_vel_median_magnitude(count, 1) = nanmedian(peakVelInHead);
        eyeHeadStats.sac_peak_vel_95prctile(count, 1) = prctile(peakVelInHead, 95);

        %% head velocity
        headVel3D = small_file_info.HeadInfo{1}.rotVel3DFilt;

        headVelHori = abs(eulYPR(:, 1));
        headVelVerti = abs(-eulYPR(:, 2));
        headVelRoll = abs(eulYPR(:, 3));

        % cleaning
        idxT = find(headVel3D>120 | isnan(headVel3D));
        headVel3D(idxT) = [];

        idxT =  find(isnan(headVelHori));
        headVelHori(idxT) = [];
        headVelVerti(idxT) = [];
        headVelRoll(idxT) = [];

        eyeHeadStats.head_3DVel_median_magnitude(count, 1) = nanmedian(headVel3D);
        eyeHeadStats.head_3DVel_95prctile(count, 1) = prctile(headVel3D, 95); %prctile(headVel3D, 97.5)-prctile(headVel3D, 2.5);
        eyeHeadStats.head_horiVel_median_magnitude(count, 1) = nanmedian(headVelHori);
        eyeHeadStats.head_horiVel_95prctile(count, 1) = prctile(headVelHori, 95); %prctile(headVelHori, 97.5)-prctile(headVelHori, 2.5);
        eyeHeadStats.head_vertiVel_median_magnitude(count, 1) = nanmedian(headVelVerti);
        eyeHeadStats.head_vertiVel_95prctile(count, 1) = prctile(headVelVerti, 95); %prctile(headVelVerti, 97.5)-prctile(headVelVerti, 2.5);
        eyeHeadStats.head_rollVel_median_magnitude(count, 1) = nanmedian(headVelRoll);
        eyeHeadStats.head_rollVel_95prctile(count, 1) = prctile(headVelRoll, 95); %prctile(headVelVerti, 97.5)-prctile(headVelVerti, 2.5);
        
        %
        %             % sanity check plots
        %             figure
        %             subplot(3, 1, 1)
        %             histogram(headVel3D, 'normalization', 'probability')
        %             xlabel('Head 3D vel (deg/s)')
        %             subplot(3, 1, 2)
        %             histogram(eulYPR(:, 1), 'normalization', 'probability')
        %             xlabel('Head horizontal vel (deg/s)')
        %             subplot(3, 1, 3)
        %             histogram(-eulYPR(:, 2), 'normalization', 'probability')
        %             xlabel('Head vertical vel (deg/s)')
        %             pause
        %             close

        %% eye/head movement range
        idxT = find(~isnan(small_file_info.HeadInfo{1}.oriFiltQw) & ~isnan(small_file_info.EyeInfo{1}.gazeOriHeadFiltX));
        eyeOriX = small_file_info.EyeInfo{1}.gazeOriHeadFiltX(idxT);
        eyeOriY = small_file_info.EyeInfo{1}.gazeOriHeadFiltY(idxT);
        eyeHeadStats.eye_in_head_horiOri_95range(count, 1) = prctile(eyeOriX, 97.5)-prctile(eyeOriX, 2.5);
        eyeHeadStats.eye_in_head_vertiOri_95range(count, 1) = prctile(eyeOriY, 97.5)-prctile(eyeOriY, 2.5);

        headOriQ = [small_file_info.HeadInfo{1}.oriFiltQw(idxT) small_file_info.HeadInfo{1}.oriFiltQx(idxT) ...
            small_file_info.HeadInfo{1}.oriFiltQy(idxT) small_file_info.HeadInfo{1}.oriFiltQz(idxT)];
        eulYPR = quat2eul(headOriQ)/pi*180; % yaw pitch roll
        headOriHori = eulYPR(:, 1);
        headOriVerti = -eulYPR(:, 2);
        headOriRoll = eulYPR(:, 3);

        eyeHeadStats.head_horiOri_95range(count, 1) = prctile(headOriHori, 97.5)-prctile(headOriHori, 2.5);
        eyeHeadStats.head_vertiOri_95range(count, 1) = prctile(headOriVerti, 97.5)-prctile(headOriVerti, 2.5);
        eyeHeadStats.head_rollOri_95range(count, 1) = prctile(headOriRoll, 97.5)-prctile(headOriRoll, 2.5);

        %             % sanity check plots
        %             figure
        %             subplot(4, 1, 1)
        %             histogram(eyeOriX, 'normalization', 'probability')
        %             xlabel('Eye zaimuth (deg)')
        %             subplot(4, 1, 2)
        %             histogram(eyeOriY, 'normalization', 'probability')
        %             xlabel('Eye elevation (deg)')
        %
        %             subplot(4, 1, 3)
        %             histogram(headOriHori, 'normalization', 'probability')
        %             xlabel('Head horizontal ori (deg)')
        %             subplot(4, 1, 4)
        %             histogram(headOriVerti, 'normalization', 'probability')
        %             xlabel('Head vertical ori (deg)')
        %
        %             pause
        %             close
    else
        eyeHeadStats{count, 12:end} = NaN;
    end

    count = count + 1;
end

%% final round of sanity check
% figure
% % for columnI = 6:size(eyeHeadStats, 2)
% %     columnI
% subplot(1, 2, 1)
% histogram(eyeHeadStats.blink_dur_mean)
% subplot(1, 2, 2)
% histogram(eyeHeadStats.blink_dur_median)
% %     pause
% % end
%
% figure
% % for columnI = 6:size(eyeHeadStats, 2)
% %     columnI
% subplot(1, 2, 1)
% histogram(eyeHeadStats.blink_within2S_dur_mean)
% subplot(1, 2, 2)
% histogram(eyeHeadStats.blink_within2S_dur_median)

save('ETDDC_summaryEyeHeadStats.mat', 'eyeHeadStats')
% exclude the blink traces and save again in csv
% eyeHeadStats.blinkInfo = [];
writetable(eyeHeadStats, 'ETDDC_summaryEyeHeadStats.csv')
% 
% getDataInfo
sortSummaryStats_slidingWindow