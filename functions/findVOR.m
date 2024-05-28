function [VOR classID] = findVOR(headVel, vorThres, gazeFix, classID, timeStamp, sampleRate)
% identify VOR sections with a simple threshold of head velocity within fixation and update classification
VOR.thresHeadVel = vorThres.head;

onsetI = [];
offsetI = [];
jj = 1; % index for VOR
for ii = 1:size(gazeFix.onsetI, 1)
    boolVec = headVel(idxT)>=vorThres.head);

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