function sacStats = processSaccade(saccade, eyeTrace, eyeFrame)
% calculate saccade amplitude, direction, duration, and peak velocity

% excludeN = 0; % keep track of how many abnormal saccades we excluded from the trial
% could ignore if you don't want to exclude now
sacStats = table();

if ~isempty(saccade.onsetI)
    ii = 1;
    while ii <= length(saccade.onsetI) % loop through all saccades identified in findSaccade.m
        sacOnI = saccade.onsetI(ii);
        sacOffI = saccade.offsetI(ii);

        % get amplitude from position trace
        sacAng = [eyeTrace.gazeOriWorldFiltX(sacOffI) eyeTrace.gazeOriWorldFiltY(sacOffI)] - [eyeTrace.gazeOriWorldFiltX(sacOnI) eyeTrace.gazeOriWorldFiltY(sacOnI)];

        amp(ii, 1) = sqrt(sum(sacAng.^2));
        dir(ii, :) = sacAng;
        %         dir(ii, :) = dir(ii, :)/norm(dir(ii, :));

        sacAngInHead = [eyeTrace.gazeOriHeadFiltX(sacOffI) eyeTrace.gazeOriHeadFiltY(sacOffI)] - [eyeTrace.gazeOriHeadFiltX(sacOnI) eyeTrace.gazeOriHeadFiltY(sacOnI)];
        ampInHead(ii, 1) = sqrt(sum(sacAngInHead.^2));

        meanVel(ii, 1) = nanmean(eyeTrace.velOriWorldFilt2D(sacOnI:sacOffI));
        meanVelHead(ii, 1) = nanmean(eyeTrace.velOriHeadFilt2D(sacOnI:sacOffI));

        maxP = nanmax(eyeTrace.velOriWorldFilt2D(sacOnI:sacOffI));
        peakVel(ii, 1) = maxP(1);

        maxPHead = nanmax(eyeTrace.velOriHeadFilt2D(sacOnI:sacOffI));
        peakVelHead(ii, 1) = maxPHead(1);

        duration(ii, 1) = saccade.offsetTime(ii)-saccade.onsetTime(ii);

        %     % clean up the saccades that are abnormal--this would depend on your specific
        %     % situation, but in general the detection of small saccades are
        %     % unreliable due to the restriction of sample rate + noise
        %     % feel free to comment out if you want to analyze these in details
        %     % later
        %     if amp(ii) < 5 || amp(ii)>30 || duration(ii)>200
        %         eyeTrial.saccade.onsetI(ii) = [];
        %         eyeTrial.saccade.offsetI(ii) = [];
        %         eyeTrial.saccade.onsetTime(ii) = [];
        %         eyeTrial.saccade.offsetTime(ii) = [];
        %         amp(ii) = [];
        %         peakVel(ii) = [];
        %         duration(ii) = [];
        % %         dir(ii, :) = [];
        %
        %         excludeN = excludeN+1;
        %         continue
        %     end

        ii = ii + 1;
    end

    sacStats.amp = amp;
    sacStats.ampInHead = ampInHead;
%     sacStats.ampInHeadRaw = ampInHeadRaw;
    sacStats.meanVel = meanVel;
    sacStats.meanVelHead = meanVelHead;
    sacStats.peakVel = peakVel;
    sacStats.peakVelHead = peakVelHead;
%     sacStats.peakVelRaw = peakVelRaw;
%     sacStats.peakVelHeadRaw = peakVelHeadRaw;
%     sacStats.peakVelHeadFiltRaw = peakVelHeadFiltRaw;
    sacStats.duration = duration;
    sacStats.dirX = dir(:, 1);
    sacStats.dirY = dir(:, 2);
end

% eyeTrial.saccade.amp = amp;
% eyeTrial.saccade.peakVel = peakVel;
% eyeTrial.saccade.duration = duration;
% eyeTrial.saccade.excludeN = excludeN;