function [saccade classID] = findSaccade(eyeTrace, sampleRate, classID, initialThres)
% mark saccade onsets and offsets; see more details in the in-line comments
% below; things could get tricky as your signal gets noisy, also how you
% detect saccade will depend on your purpose of the experiment, so the
% current method is mostly a reference

% exclude blinks from saccade detection
excludeI = find(classID==0 | classID==0.5);
vel = eyeTrace.velOriWorldFilt2D;
vel(excludeI) = NaN;
acc = eyeTrace.accOriWorld2D;
acc(excludeI) = NaN;

%% Saccade threshold determined by the data-driven algorithm from NYSTRÖM & HOLMQVIST (2010)
% check if it makes sense to your data! not to crystal's, very unstable...
% depending largely on signal quality

% Using an interative method to find a proper velocity threshold for the
% current trial
% if sampleRate<500
thres = initialThres; % intial threshold
restV = vel(vel<thres);
if sampleRate >= 600
    n = 6;
    error = 1;
else
    n = 6;
    error = 3*nanstd(restV); % nanstd(restV);
end

thresNew = nanmean(restV) + n*nanstd(restV); % the next threshold

while abs(thres-thresNew) > error % iterate until the difference is less than some error
    thres = thresNew;
    restV = vel(vel<thres);
    thresNew = nanmean(restV) + n*nanstd(restV);
    if error > 1
        error = 3*nanstd(restV);
    end
end

if thres > 150 % saccade peak threshold should not be too low or too high...
    thres = 150;
elseif thres < 20
    thres = 20;
end
restV = vel(vel<thres);
sacThres = thres;
baseVel = nanmean(restV); %+3*nanstd(restV);

baseAcc = 1000; % lower than this is likely pursuit, fairly conservative now. see Dash and Thier, 2013
% else
%% adaptive threshold based on local noise level--also not stable in crystal's data...
%     % find fixation period: define a time window, then make the window with the
%     % smallest variance + mean as the fixation period
%     wL = ms2frame(100, sampleRate); % 100 ms in frames
%     % calculating the sliding mean & std of vel
%     velM = movmean(vel, wL);
%     velStd = movstd(vel, wL);
%     minI = find(velM==nanmin(velM));
%
%     % find the highest vel, then the difference between highest and mean during
%     % this minimum period, use min mean + 0.1 diff as the threshold
%     maxV = nanmax(vel);
%     % minV = nanmean(velM(minI(1)));
%     %
%     if sampleRate>1000
%         baseVel = velM(minI(1));
%         sacThres = velM(minI(1)) + 6 * velStd(minI(1));
%     else
%         baseVel = velM(minI(1))+3*velStd(minI(1));
%         sacThres = baseVel + 0.05*maxV;
%         % sacThres = baseVel + 0.05*(maxV-baseVel);
%     end
%
%     % if baseVel>50
%     %     baseVel=50;
%     % end
%     % sacThres = baseVel; %*4;
%     if sacThres < 20
%         sacThres = 20;
%     elseif sacThres>150
%         sacThres = 150;
%     end
%
%     baseAcc = 1000;
% end
% % accM = movmean(acc, wL*2, 'omitnan');
% % accStd = movstd(acc, wL*2, 'omitnan');
% % baseAcc = accM(minI(1))+6*accStd(minI(1));
% % if baseAcc < 3000
% %     baseAcc = 3000;
% % end
% % if baseAcc<3000
% %     baseAcc = 3000;
% % elseif baseAcc>6000
% %     baseAcc=6000;
% % end

%% or just manually set fixed thresholds...
% % could differ across participants, again depends on what works best for
% % your data; there are many different ways for saccade detection as well,
% % feel free to adjust/fine tune based on your needs
% baseVel = 30;
% % for finding saccade onsets & offsets, where the regression line of the
% % saccade velocity slopes should intersect
%
% sacThres = initialThres;
% % threshold used for finding velocity peaks that are potentially saccades
%
% baseAcc = 3000; % also for finding saccade onsets & offsets, to idenfity the
% "reliable" downpeak of acceleration for a saccade
%
%% output to keep a record
saccade.baseVel = baseVel;
saccade.sacThres = sacThres;
saccade.baseAcc = baseAcc;

%% finding velocity peaks that are potentially saccades
% first, find all peaks with a velocity larger than the threshold
frameN = ms2frame(10, sampleRate);
[peakOnI, peakOffI] = findPeaks(vel, sacThres, frameN);
% there is also a matlab "findpeaks" function in the Signal Processing Toolbox, but
% I haven't tried it yet; this is now a customized simpler function
% % for debugging
% onTime = eyeTrace.timestamp(peakOnI);
% offTime = eyeTrace.timestamp(peakOffI);

%% then for each vel peak, go backward and forward to find onsets & offsets
% the general method is, for both onsets & offsets, we fit a regression
% line of the velocity slope, then the intersection of the regression line
% with the baseline velocity is the onset/offset.

% there are more details, mostly to deal with a certain level of noise,
% e.g. we make sure there is always a pair of peaks of acceleration for a saccade,
% and we would separate multiple peaks contained within the same chunk above threshold
% as potentially multiple saccades... the choice of the interval to fit for
% the regression line could also be tricky, and a lot of edge situations...
% have fun with the saccade detection. I always spend most of my time fine-
% tuning for this... it never ends but we can only do as much to trade off
% with the noises

ii = 1; % the index of the velocity peaks identified above threshold
jj = 1; % the index for valid saccade onsets & offsets detected
validP = []; % mark if the vel peak chunk has a valid saccade; useful to avoid being trapped in an endless loop later...
onsetI = [];
offsetI = [];

% since there might be situation when multiple saccades are included in one
% large chunk o velocity above threshold, ii and jj could be different.
% although in such cases, maybe try playing a bit more with filtering would
% be the first step
while ii <= length(peakOnI)

    %     if ii==118
    %         % for debugging
    %         onTime = eyeTrace.timestamp(peakOnI);
    %         offTime = eyeTrace.timestamp(peakOffI);
    %     end
    %% for coil data... it's so clean that we just need to find when acc changes signs as the saccade on- and offset :)
        signAcc = sign(acc);
        signDiffAcc = [NaN; diff(signAcc)];
        changeSign = find(abs(signDiffAcc)==2);
    %
    %     onSignI = max(find(changeSign<peakOnI(ii)));
    %     if isempty(onSignI) && ii == 1
    %         onsetI(jj) = 1;
    %     else
    %         onsetI(jj) = changeSign(onSignI);
    %     end
    %
    %     if jj>1 && onsetI(jj)<offsetI(jj-1)
    %         onsetI(jj) = offsetI(jj-1)+1;
    %     end
    %
    %     offSignI = min(find(changeSign>peakOffI(ii)));
    %     if isempty(offSignI) && ii==length(peakOnI)
    %         offsetI(jj) = length(vel);
    %     else
    %         offsetI(jj) = changeSign(offSignI);
    %     end
    %% end of coil data processing...

    %% for much noisier data such as from crystal ET...
    onsetT = [];
    offsetT = [];
    % initialize for the current peak

    accTemp = acc(peakOnI(ii):peakOffI(ii)); % the acceleration within the current vel peak

    % index of up peaks in accTemp
    [accUpPeakOnI, accUpPeakOffI] = findPeaks(accTemp, baseAcc, 1);
    if length(accUpPeakOnI)<1 % if no up-peak in acceleration, skip and go to the next one
        validP(ii) = 0;
        ii = ii+1;
        continue
    end

    %% for onset, linear regression & intersection point
    % first, find the proper interval to fit: the duration when acceleration is
    % highest (the first up-peak in accTemp)

    interval = [accUpPeakOnI(1):1:accUpPeakOffI(1)]'+peakOnI(ii)-1;
    %     % mark the average acc here, so that the down peak could be comparable
    %     % (and should be)
    %     downBaseAcc = max([nanmean(acc(interval)-baseAcc)/3+baseAcc, baseAcc]);

    % linear regression, y=b(1)+b(2)*x
    x = [ones(size(interval)) interval];
    y = vel(interval);
    b = x\y;
    if b(2)>0 % positive slope for onset
        onsetT = round((baseVel-b(1))/b(2));
    else
        validP(ii) = 0;
        ii = ii+1;
        continue
    end

    % some special edge conditions
    % if onset vel > threshold... keep searching backward
    if ~isempty(onsetT) && onsetT > 0
        if vel(onsetT) > sacThres
            onsetT = find(vel(1:onsetT)<=sacThres, 1, "last");
            if isempty(onsetT)
                validP(ii) = 0;
                ii = ii+1;
                continue
            end
        end
    else
        validP(ii) = 0;
        ii = ii+1;
        continue
    end

    % make sure onset doesn't go outside the current time frames... if yes, just skip for now
    if onsetT<=1
        validP(ii) = 0;
        ii = ii+1;
        continue
    end

    %     if isnan(vel(onsetT)) % onset during missing signal
    %         onsetT = find(~isnan(vel(onsetT:end)), 1, "first")+onsetT-1;
    %     end

    if jj>1 && onsetT<=offsetI(jj-1) % the current saccade onset is before the last saccade offset
        % could be that the regression fitting interval is too flat, or the
        % two saccades are really close;
        % just go for the first point where acceleration drops below
        % threshold before the vel peak chunk, or right after the last saccade offset, whichever is later
        onsetT = max([find(acc(1:peakOnI(ii))<baseAcc); offsetI(jj-1)]);

        if vel(onsetT) > sacThres
            validP(ii) = 0;
            ii = ii+1;
            continue
            %             onsetT = changeSign(find(changeSign<peakOnI(ii), 1, "last")); % find the first acceleration change point before the peak
        end
        %         end
    end

    %% for offset, similar process as onset, but look for the down slope of velocity
    % use the duration when acceleration is lowest (large negative values),
    % corresponding to the down-peak

    % find if there's a comparable downpeak after onsetI, smaller is ok but not too small
    % make sure the downpeak is after an up-peak...
    accTemp2 = acc(accUpPeakOffI(1)+peakOnI(ii)-1:peakOffI(ii));

    % index of down peaks in accTemp2, which is after the up peak found
    [accDownPeakOnI, accDownPeakOffI] = findPeaks(-accTemp2, baseAcc, 1);
    % if you want to further define how large the acc down-peak has to be
    % in order to be counted as a valid downpeak, could replace baseAcc
    % here; this is mostly if your signal is noisy... but then again maybe
    % go back to filtering first
    % on example is could use the the median of all acc below threshold
    % as the min size of a valid acc down-peak
    if length(accDownPeakOnI)<1
        % if no down-peak in acceleration after saccade onset, skip
        validP(ii) = 0;
        ii = ii+1;
        continue
    end

    % similar to finding onset, fit a regression line for velocity and
    % find the intersection point
    % here we use the slope of the longest down peak found
    durDown = accDownPeakOffI-accDownPeakOnI;
    dI = find(durDown==max(durDown));
    dI = dI(1);
    downOnI = accDownPeakOnI(dI);
    downOffI = accDownPeakOffI(dI);

    interval = [downOnI:1:downOffI]'+accUpPeakOffI(1)+peakOnI(ii)-1;
    x = [ones(size(interval)) interval];
    y = vel(interval);
    b = x\y;
    if b(2)<0 % negative slope for offset
        offsetT = round((baseVel-b(1))/b(2));
    else
        validP(ii) = 0;
        ii = ii+1;
        continue
    end

    % again, deal with edge conditions
    if vel(offsetT) > sacThres
        offsetT = find(vel(offsetT:end)<=sacThres, 1, "first")+offsetT-1;
        if isempty(offsetT)
            validP(ii) = 0;
            ii = ii+1;
            continue
        end
    end

    % make sure saccades don't go outside/offset is before onset

    if offsetT>=length(eyeTrace.timestamp) || offsetT<=onsetT
        validP(ii) = 0;
        ii = ii+1;
        continue
    end


    %     if isnan(vel(offsetT)) % offset during missing signal
    %         offsetT = find(~isnan(vel(1:offsetT)), 1, "last");
    %     end

    % make sure saccades don't overlap
    if ii<length(peakOnI) && offsetT > peakOnI(ii+1)
        if peakOnI(ii+1) > accDownPeakOffI(1)+onsetT-1
            offsetT = peakOnI(ii+1)-1;
        else
            validP(ii) = 0;
            ii = ii+1;
            continue
        end
    end

    %     if offsetT < peakOffI(ii)-3 % there might be another saccade in this duration
    %         % insert this new vel peak duration to check next
    %         peakOnI = [peakOnI(1:ii); offsetT+1; peakOnI(ii+1:end)];
    %         peakOffI = [peakOffI(1:ii-1); offsetT; peakOffI(ii:end)];
    %     end
    %% end of crystal's algorithm

    %% sanity check, if abnormal or containing a blink/labeled noise chunk, then exclude
    peakVel = nanmax(vel(onsetT:offsetT));
    peakAcc = nanmax(abs(acc(onsetT:offsetT)));
    %     if peakVel>noiseThres.vel || peakAcc>noiseThres.acc || peakVel<150 ...
    %             || ~isempty(find(excludeI<offsetI(jj) & excludeI>onsetI(jj) ))
    %         onsetI(jj) = [];
    %         offsetI(jj) = [];
    %         jj = jj-1;
    %         validP(ii) = 0;
    %     end

    if max(abs(acc(peakOnI(ii):peakOffI(ii))))>=baseAcc ...
            && peakVel<1500 ...
            && isempty(find(isnan(vel(onsetT:offsetT)))) % only count as a saccade if passing certain acceleration threshold
        onsetI(jj) = onsetT;
        offsetI(jj) = offsetT;
        jj = jj+1;
        %     else
        %         classID(onsetT:offsetT) = 40; % mark it as potential smooth movement, fit slope as well
    end
    ii = ii+1;
end
% for debugging within the while loop, could use
% "time = eyeTrace.timestamp-eyeTrace.timestamp(1);" to locate the index of
% onset & offset

saccade.onsetI = onsetI'; % index of onset
saccade.offsetI = offsetI'; % index of offset
if ~isempty(onsetI)
    saccade.onsetTime = eyeTrace.timestamp(saccade.onsetI); % actual time stamp of onset
    saccade.offsetTime = eyeTrace.timestamp(saccade.offsetI); % actual time stamp of offset
    for ii = 1:length(onsetI)
        classID(onsetI(ii):offsetI(ii)) = 1;
    end
else
    saccade.onsetTime = []; % actual time stamp of onset
    saccade.offsetTime = [];
end