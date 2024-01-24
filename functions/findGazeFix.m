function [gazeFix classID] = findGazeFix(eyeTrace, eyeFrameXYZ, fixThres, classID, sampleRate, timestamp)
% find index for gaze fixation (including VOR) within the non-saccade periods;
% use dispersion algorithm to decide each fixation duration
% Input: we need eye pos, gaze pos, and eye frame to get gaze retinal pos
%        fixThres.rad--dispersion threshold
%        fixThres.dur--minimum duration required
% Output:
%   gaze fixation (including VOR) start and end indices, one pair for each
%   classID with gaze fixation (3) added

gazeFix.thresDur = fixThres.dur;
gazeFix.thresRad = fixThres.rad;

% find unclassified chunks
iAll = isnan(classID) & eyeTrace.velOriWorldFilt2D<30;
if sum(iAll)>0 % there are unclassified chunks
    % get the start and end of each chunk
    iDiff = diff(iAll);
    startI = find(iDiff==1)+1;
    endI = find(iDiff==-1);
    if iAll(1)==1
        startI = [1; startI];
    end
    if iAll(end)==1
        endI = [endI; length(iDiff)];
    end

    % go through each chunk to find fixation that fits both duration and
    % dispersion (radius);
    % currently using the Salvucci dispersion (Slv) (Salvucci & Goldberg, 2000)
    % variation in Blignaut (2009). [(Max X - Min X ) + (Max Y - Min Y )]/2 <= Threshold
    gazeFix.onsetI = [];
    gazeFix.offsetI = [];
    gazeFix.onsetTime = [];
    gazeFix.offsetTime = [];
    ii = 1;
    
    while ii<=length(startI)
        %     for ii = 1:length(startI)
        if timestamp(endI(ii))-timestamp(startI(ii))>=fixThres.dur % if duration is long enough to start with
            gazeOri = [eyeTrace.gazeOriWorldFiltX(startI(ii):endI(ii)) ...
                eyeTrace.gazeOriWorldFiltY(startI(ii):endI(ii))];

            startT = 1; %startI(ii);
            endT = min(find(timestamp-timestamp(startI(ii))>=fixThres.dur))-startI(ii)+1; %startT + ms2frame(fixThres.dur*1000, sampleRate)-2;
            valid = 0;

            %{
            while startI(ii)+startT+endT-1 < endI(ii)
                window = gazeOri(startT:endT+1, :);
                rad = ( range(window(:, 1)) + range(window(:, 2)) )/2;

                if rad<=fixThres.rad
                    endT = endT+1;
                    valid = 1;
                else
                    if (endT-startT+1) < ms2frame(fixThres.dur*1000, sampleRate)
                        startT = startT+1;
                        endT = endT+1;
                        valid = 0;
                    elseif valid==1
                        break
                    end
                end
            end
            %}
            while startI(ii) + startT + endT - 1 < endI(ii)
                window = gazeOri(startT:endT + 1, :);
                rad = (range(window(:, 1)) + range(window(:, 2))) / 2;
            
                if rad <= fixThres.rad
                    endT = endT + 1;
                    valid = 1;
                elseif valid == 0 && (endT - startT + 1) < ms2frame(fixThres.dur * 1000, sampleRate)
                    startT = startT + 1;
                    endT = endT + 1;
                elseif valid == 1
                    break;
                else
                    startT = startT + 1;
                    endT = endT + 1;
                end
            end

            if valid==1
                sI = startI(ii)+startT-1;
                eI = startI(ii)+startT-1+endT;
                gazeFix.onsetI = [gazeFix.onsetI; sI];
                gazeFix.offsetI = [gazeFix.offsetI; eI];
                gazeFix.onsetTime = [gazeFix.onsetTime; timestamp(sI)];
                gazeFix.offsetTime = [gazeFix.offsetTime; timestamp(eI)];
                classID(sI:eI) = 2;

                if timestamp(endI(ii))-timestamp(eI) >=fixThres.dur % if the rest is still longer than allowed... see if there's another fixation
                    % insert this new vel peak duration to check next
                    startI = [startI(1:ii); eI+1; startI(ii+1:end)];
                    endI = [endI(1:ii-1); eI; endI(ii:end)];
                end
            end
        end

        ii = ii+1;
    end



else
    gazeFix = [];
end

end