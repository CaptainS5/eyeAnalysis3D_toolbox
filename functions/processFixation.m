function fixStats = processFixation(fix, eyeDir)
% get fixation duration and position

fixStats = table();
warning('off','all')
if ~isempty(fix.onsetTime) % if we have blinks
    for ii = 1:length(fix.onsetTime)
        fixStats.dur(ii, 1) = fix.offsetTime(ii)-fix.onsetTime(ii);

        % calculate gaze position... relative to the head, so use
        % eye-in-head angle
        idxF = fix.onsetI(ii):fix.offsetI(ii);
        fixStats.oriHeadX(ii, 1) = nanmean(eyeDir(idxF, 1));
        fixStats.oriHeadY(ii, 1) = nanmean(eyeDir(idxF, 2));
    end
end

end