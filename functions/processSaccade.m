function sacStats = processSaccade(saccade, eyeTrace, eyeFrame)
% calculate saccade amplitude, direction, duration, and peak velocity

% excludeN = 0; % keep track of how many abnormal saccades we excluded from the trial
% could ignore if you don't want to exclude now
sacStats = table();

if ~isempty(saccade.onsetI)
    %{
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

        ii = ii + 1;
    end
    %}

    numSaccades = length(saccade.onsetI);

    amp = zeros(numSaccades, 1);
    dir = zeros(numSaccades, 2);
    ampInHead = zeros(numSaccades, 1);
    meanVel = zeros(numSaccades, 1);
    meanVelHead = zeros(numSaccades, 1);
    peakVel = zeros(numSaccades, 1);
    peakVelHead = zeros(numSaccades, 1);
    duration = zeros(numSaccades, 1);
    
    for ii = 1:numSaccades
        sacOnI = saccade.onsetI(ii);
        sacOffI = saccade.offsetI(ii);
    
        sacAng = [eyeTrace.gazeOriWorldFiltX(sacOffI) eyeTrace.gazeOriWorldFiltY(sacOffI)] - [eyeTrace.gazeOriWorldFiltX(sacOnI) eyeTrace.gazeOriWorldFiltY(sacOnI)];
        amp(ii, 1) = norm(sacAng);
        dir(ii, :) = sacAng;
    
        sacAngInHead = [eyeTrace.gazeOriHeadFiltX(sacOffI) eyeTrace.gazeOriHeadFiltY(sacOffI)] - [eyeTrace.gazeOriHeadFiltX(sacOnI) eyeTrace.gazeOriHeadFiltY(sacOnI)];
        ampInHead(ii, 1) = norm(sacAngInHead);
    
        meanVel(ii, 1) = nanmean(eyeTrace.velOriWorldFilt2D(sacOnI:sacOffI));
        meanVelHead(ii, 1) = nanmean(eyeTrace.velOriHeadFilt2D(sacOnI:sacOffI));
    
        velSlice = eyeTrace.velOriWorldFilt2D(sacOnI:sacOffI);
        peakVel(ii, 1) = max(velSlice);
    
        velHeadSlice = eyeTrace.velOriHeadFilt2D(sacOnI:sacOffI);
        peakVelHead(ii, 1) = max(velHeadSlice);
    
        duration(ii, 1) = saccade.offsetTime(ii) - saccade.onsetTime(ii);
    end


    sacStats.amp = amp;
        sacStats.amp(isinf(sacStats.amp)) = min(sacStats.amp);
    sacStats.ampInHead = ampInHead;
        sacStats.ampInHead(isinf(sacStats.ampInHead)) = min(sacStats.ampInHead);
    sacStats.meanVel = meanVel;
        sacStats.meanVel(isinf(sacStats.meanVel)) = min(sacStats.meanVel);
    sacStats.meanVelHead = meanVelHead;
        sacStats.meanVelHead(isinf(sacStats.meanVelHead)) = min(sacStats.meanVelHead);
    sacStats.peakVel = peakVel;
        sacStats.peakVel(isinf(sacStats.peakVel)) = min(sacStats.peakVel);  
    sacStats.peakVelHead = peakVelHead;
        sacStats.peakVelHead(isinf(sacStats.peakVelHead)) = min(sacStats.peakVelHead); 
    sacStats.duration = duration;
         sacStats.duration(isinf(sacStats.duration)) = min(sacStats.duration); 
    sacStats.dirX = dir(:, 1);
    sacStats.dirY = dir(:, 2);
end

% eyeTrial.saccade.amp = amp;
% eyeTrial.saccade.peakVel = peakVel;
% eyeTrial.saccade.duration = duration;
% eyeTrial.saccade.excludeN = excludeN;