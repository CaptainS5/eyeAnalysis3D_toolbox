function [VOR classID] = findVOR(eyeVelXY, headVelXY, headVel3D, vorThres, gazeFix, classID, timeStamp, sampleRate)
% identify strictly VOR sections within fixation and update classification

% calculate VOR gain during the process
% this gain takes into account both direction and speed
% VOR.gain = -dot(eyeVelXY, headVelXY, 2)./vecnorm(headVelXY, 2, 2).^2;
% perfect compensation would be 1, same velocity but opposite directions
% would be -1; basically ratio of magnitude plus how opposite the
% directions are [cos(theta)]--no this doesn't work...

VOR.gainAmp = vecnorm(eyeVelXY, 2, 2)./vecnorm(headVelXY, 2, 2); %sqrt(sum(eyeVelXY.^2, 2))./sqrt(sum(headVelXY.^2, 2));
VOR.gainDir = -dot(eyeVelXY, headVelXY, 2)./vecnorm(eyeVelXY, 2, 2)./vecnorm(headVelXY, 2, 2);
VOR.thresGain = vorThres.gain;
VOR.thresHeadVel = vorThres.head;
% 1 means perfectly opposite, -1 means in the same direction

%% 1. depending on vorThres, if VOR gain is within this range, we consider it
% use gainDir as it is more robust compared to amplitude
% similarly, let's first find peaks within each fixation duration
headVel2D = sqrt(sum(headVelXY.^2, 2));

jj = 1; % index for VOR
for ii = 1:size(gazeFix.onsetI, 1)
    idxT = gazeFix.onsetI(ii):gazeFix.offsetI(ii); % the current fixation duration
    gainT = VOR.gainDir(idxT);
    
    if sampleRate>= 800
        VOR.thresGain = 0.91;
        boolVec = (gainT>=0.91);% strict criteria for Rochester dataset
    else
        % use a combined... loose criteria here, meeting either...
        boolVec = (gainT>=vorThres.gain | headVel2D(idxT)>=vorThres.head);
    end

    % set a minimum duration for valid VOR
    minFrames = ms2frame(20, sampleRate);
%     [peakOnI, peakOffI] = findPeaks(gainT, vorThres.gain, minFrames);
    [peakOnI, peakOffI] = findPeaks(boolVec, 0.5, minFrames);

    if ~isempty(peakOnI)
%         % there shouldn't be too many peaks?... if peaks are within 20 ms, merge
%         gap = timeStamp(peakOnI(2:end))-timeStamp(peakOffI(1:end-1));
%         mergeI = find(gap>0.02);
%         if ~isempty(mergeI)            
%             
%             kk = 1;
%             while kk <= length(mergeI)
%                 if mergeI(kk)>1
%                     peakOnI = [peakOnI(1:mergeI(kk)); peakOnI(mergeI(kk)+2:end)];
%                     peakOffI = [peakOffI(1:mergeI(kk)-1); peakOffI(mergeI(kk)+1:end)];
%                 else
%                     peakOnI = [peakOnI(1); peakOnI(mergeI(kk)+2:end)];
%                     peakOffI(mergeI(kk)) = [];
%                 end
%                 kk = kk+1;
%                 mergeI = mergeI-1;
%             end
% 
%         end

        for kk = 1:length(peakOnI)
            onsetI(jj) = peakOnI(kk)+gazeFix.onsetI(ii)-1;
            offsetI(jj) = peakOffI(kk)+gazeFix.onsetI(ii)-1;
            jj = jj+1;
        end
    end
end

VOR.onsetI = onsetI; % index of onset
VOR.offsetI = offsetI; % index of offset
if ~isempty(onsetI)
    VOR.onsetTime = timeStamp(VOR.onsetI); % actual time stamp of onset
    VOR.offsetTime = timeStamp(VOR.offsetI); % actual time stamp of offset
    for ii = 1:length(onsetI)
        classID(onsetI(ii):offsetI(ii)) = 3;
    end
else
    VOR.onsetTime = []; % actual time stamp of onset
    VOR.offsetTime = [];
end

end