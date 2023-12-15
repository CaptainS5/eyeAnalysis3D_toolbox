function [blink classID] = findBlink(eyeTrace, sampleRate, dataType, initialThres)
% use gaze velocity to identify blinks--since we want to exclude those from
% saccades
% should be two consecutive peaks in opposite directions
classID = NaN(size(eyeTrace.velOriWorldFiltX)); % initialize
blink.maxDur = 0.6; % to account for data losses due to other issues

% "a blink is associated with the eyes moving primarily downwards and
% towards the nose (first component) followed by a return towards the
% starting position (second component). This alternation of components is
% completed within 50 ms". --Khazali, Pomper & Thier, 2017, Scientific
% Reports
vel = eyeTrace.velOriHeadFilt2D; % use retinal gaze change to identify "suspects"

% video-based eye tracking, blinks as no signal in data
% blinkIdx = isnan(eyeTrace.velOriWorldFilt2D);
blinkIdx = (eyeTrace.blinkFlag ~= 0 | isnan(eyeTrace.velOriHeadFiltX));

% on and offsets of the missing signal frames
iDiff = diff(blinkIdx);
onsetBI = find(iDiff==1)+1;
offsetBI = find(iDiff==-1);

if blinkIdx(1)==1
    onsetBI = [1; onsetBI];
end
if blinkIdx(end)==1
    offsetBI = [offsetBI; length(iDiff)];
end

% locate on- and off-sets by finding the intersection before and after
% the missing signal frames...
velDiff = [NaN; diff(vel)];
signChange = [NaN; sign(velDiff(1:end-1).*velDiff(2:end))];
ii = 1;
while ii <= length(onsetBI)
    if onsetBI(ii)~=1
        startI = find(signChange(1:onsetBI(ii))==-1 & sign(velDiff(1:onsetBI(ii)))==1, 1, "last");
        if ~isempty(startI)
            onsetBI(ii) = startI-ms2frame(50, sampleRate); % pad in a little bit... to deal with the noise around blinks in the current dataset

            if onsetBI(ii) < 1 % if padding too much...
                onsetBI(ii) = 1;
            end
        end
    end

    if offsetBI(ii)~=length(iDiff)
        endI = find(signChange(offsetBI(ii):end)==-1 & sign(velDiff(offsetBI(ii):end))==1, 1, "first");
        if ~isempty(endI)
            offsetBI(ii) = endI+offsetBI(ii)-1 + ms2frame(50, sampleRate); % pad in a little bit... to deal with the noise around blinks in the current dataset

            if offsetBI(ii) > length(eyeTrace.timestamp) % longer than the recorded period, just move back to the end
                offsetBI(ii) = length(eyeTrace.timestamp);
            end
        end
    end   

    % some edge cases
    if ii>1 && onsetBI(ii) <= offsetBI(ii-1) % overlap with the last blink, merge with the previous
        onsetBI(ii) = [];
        offsetBI(ii-1) = [];
        ii = ii - 1;
    end

    ii = ii + 1;
end

blink.onsetI = onsetBI; % index of onset
blink.offsetI = offsetBI; % index of offset
if ~isempty(blink.onsetI)
    blink.onsetTime = eyeTrace.timestamp(blink.onsetI); % actual time stamp of onset
    blink.offsetTime = eyeTrace.timestamp(blink.offsetI); % actual time stamp of offset

    for ii = 1:length(blink.onsetI)
        if blink.offsetTime(ii)-blink.onsetTime(ii) <= blink.maxDur
            classID(blink.onsetI(ii):blink.offsetI(ii)) = 0;
        else
            classID(blink.onsetI(ii):blink.offsetI(ii)) = 0.5;
        end
    end
else
    blink.onsetTime = []; % actual time stamp of onset
    blink.offsetTime = [];
end

end