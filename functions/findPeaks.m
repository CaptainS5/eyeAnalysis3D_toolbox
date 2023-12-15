function [peakOnI, peakOffI] = findPeaks(trace, threshold, minFrames)
% return the start and end indices of each peak above the threshold, which
% is also longer than the length of data points defined by minFrames

isAbove = find(trace>=threshold);
if isempty(isAbove)
    peakOnI = [];
    peakOffI = [];
    return
end

startI = [1; find(diff(isAbove)>1)+1]; % index in isAbove indicating potential starts of the peak
if length(startI)==1 && length(isAbove)>=minFrames % if only one peak
    peakOnI = isAbove(1);
    peakOffI = isAbove(end);
else % multiple peak durations
    % choose the peak durationa that have a certain length
    validStartI = find(diff([startI; length(isAbove)])>=minFrames); % peak should be at least minFrames long
    peakOnI = isAbove(startI(validStartI));
    if isempty(peakOnI)
        peakOffI = [];
        return
    end
    if validStartI(end)~=length(startI)
        peakOffI = isAbove(startI(validStartI+1)-1);
    else
        peakOffI = isAbove([startI(validStartI(1:end-1)+1)-1; end]);
    end
end




