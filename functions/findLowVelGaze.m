function [lowVelIdx classID] = findLowVelGaze(gazeVel, fixThresVel, classID)
% find index for gaze fixation (including VOR) based on velocity threshold;
% sanity check with minimum duration
% Input: gazeVel--2D gaze-in-world velocity
%        fixThresVel--velocity threshold
%        fixThresDur--minimum duration required
% Output: indices of fixation periods

belowThres = (gazeVel<fixThresVel & isnan(classID));
diffBelow = diff(belowThres);

% get the indices marking start and end of fixation
fixStartI = find(diffBelow==1)+1;
fixEndI = find(diffBelow==-1)+1;
if belowThres(1)==1 && belowThres(2)==1 % check if start with fixation
    fixStartI = [1; fixStartI];
end
if belowThres(end)==1 && belowThres(end-1)==1 % check if end with fixation
    fixEndI = [fixEndI; length(belowThres)];
end

lowVelIdx.startI = fixStartI;
lowVelIdx.endI = fixEndI;

for ii = 1:length(fixStartI)
    classID(fixStartI(ii):fixEndI(ii)) = 3;
end

% exclude too short durations--to be done later, after VOR identification
% in processFixation.m
end