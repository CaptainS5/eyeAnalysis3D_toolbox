function [eyeTrial] = processTrial(dataPath, currentTrial, loadEyeTrial, blinkThres, sacThres, fixThres, vorThres)
% process head & eye data for the current trial
% this is the main function where we outline all the processing steps
% Pre-req: should go from a starting script (i.e. viewTrialAnalysis)
% After processing, you should have
%       - a .mat file saved with eyeTrial containing all processed eye/head
%           traces, classification, and eye movement stats for the current trial
%       - output: eyeTrial
% Everything is aligned to x+ forward, y+ left, z+ up, and right-handed rotation;
% Azimuth (0 = north, 90 = east), Elevation (up is positive), and depth in m

%% Filtering
if isfile([dataPath, num2str(currentTrial), '.mat']) && loadEyeTrial
    load([dataPath, num2str(currentTrial), '.mat'])
else
    load([dataPath, num2str(currentTrial), '.mat'])
    %     eyeTrial.errorStatus = 0; % valid by default
    % will be marked in later analysis either through the GUI or auto analysis
    eyeTrial.headTrace = filterHeadTrace(eyeTrial.headAligned, eyeTrial.sampleRate);
    eyeTrial.eyeTrace = filterEyeTrace(eyeTrial.eyeAligned, eyeTrial.sampleRate);
end

%% Classification
% first identify blinks and saccades
% then identify fixation, and potentially VOR
% lastly, potential smooth pursuit - not implemented yet
% classID:
% 0 = blink (0.5 means blink is longer than expected), 1 = saccade, 
% 2 = fixation, 3 = VOR, 4 = pursuit, NaN = undefined

%% identify blink (0)
% for coil data, look for 2-peak-in-opposite-direction peak pairs -- not
% implemented yet
dataType = 2; % video-based eye tracker or whenever blinks will result in loss of signal
[eyeTrial.blink, eyeTrial.classID] = findBlink(eyeTrial.eyeTrace, eyeTrial.sampleRate, dataType, blinkThres);
% 0/0.5 = blink (0 means it is within a normal blink duration, 0.5 means the duration is a bit long)

%% identify saccade (1) - TBD
[eyeTrial.saccade, eyeTrial.classID] = findSaccade(eyeTrial.eyeTrace, eyeTrial.sampleRate, eyeTrial.classID, sacThres);

%% identify fixation (2) - TBD
% check dispersion of this gaze position, to be within a radius
% threshold to count as a fixation (with a min duration required)
if ismember({'frameXYZ'}, eyeTrial.eyeAligned.Properties.VariableNames)
    [eyeTrial.gazeFix eyeTrial.classID] = findGazeFix(eyeTrial.eyeTrace, eyeTrial.eyeAligned.frameXYZ, ...
        fixThres, eyeTrial.classID, eyeTrial.sampleRate, eyeTrial.eyeTrace.timestamp);
else
    [eyeTrial.gazeFix eyeTrial.classID] = findGazeFix(eyeTrial.eyeTrace, [], ...
        fixThres, eyeTrial.classID, eyeTrial.sampleRate, eyeTrial.eyeTrace.timestamp);
end

%% within the fixation period, identify VOR - TBD
%     eyeVelXY = [eyeTrial.eyeTrace.velHeadFiltX eyeTrial.eyeTrace.velHeadFiltY]; % eye-in-head velocity
%     % for the head, we need to know both translation and rotation, and to
%     % do this we also need to know where the 3D gaze position is
%     % just calculate the "combined" head movement that needs to be canceled
%     % by VOR
%
%     headRot = [eyeTrial.headTrace.rotFiltQw eyeTrial.headTrace.rotFiltQx ...
%         eyeTrial.headTrace.rotFiltQy eyeTrial.headTrace.rotFiltQz];
%     % headRot takes care of the head rotational part, in world/body
%     % coordinates, already velocity
%
%     if ismember({'gazePosFiltX', 'eyePosFiltX'}, eyeTrial.eyeTrace.Properties.VariableNames)
%         % for the rochester data base, just skip middle steps with eye-in-head
%         % position and directly use final eye position to see how much perfect
%         % compensation should be
%         gazePos = [eyeTrial.eyeTrace.gazePosFiltX eyeTrial.eyeTrace.gazePosFiltY eyeTrial.eyeTrace.gazePosFiltZ];
%         % gaze position in world/body coordinates
%
%         eyePos = [eyeTrial.eyeTrace.eyePosFiltX eyeTrial.eyeTrace.eyePosFiltY eyeTrial.eyeTrace.eyePosFiltZ];
%         % eyepos takes care of all translational movement, including those
%         % induced by head translation and head rotation
%
%         headVelXY = getHeadVelXY(eyePos, gazePos, headRot, eyeTrial.headAligned.frameXYZ, eyeTrial.sampleRate);
%         % headVelXY indicates the amount that needs to be compensated
%     else
%         % let's use the simplified thing for SE... just turn head rotation
%         % into angles; use the quaternion representing rotation between
%         % frames--velocity
%         refVec = [1; 1; 1];
%         refVec = refVec/norm(refVec); % just a reference vector to be rotated
%         rotVec(1, :) = refVec; % shoulder coordinates
%
%         % rotate
%         for ii = 2:size(headRot, 1)
%                 rotVec(ii, :) = (quat2rotm(headRot(ii, :))*rotVec(ii-1, :)')';
%             if all(isnan(rotVec(ii, :))) && all(~isnan(headRot(ii, :)))
%                 % end of the NaN period, set up the reference again
%                 rotVec(ii, :) = [1; 1; 1]/norm([1; 1; 1]);
%             end
%         end
%
%         % transform into head frame
%         angRot = [-atan2d(rotVec(:, 2), rotVec(:, 1)) ...
%             atan2d(rotVec(:, 3), sqrt( rotVec(:, 1).^2 + rotVec(:, 2).^2) )];
%         % ref: https://www.mathworks.com/matlabcentral/answers/101590-how-can-i-determine-the-angle-between-two-vectors-in-matlab
%         % atan is recommended instead of acos to recover small angles
%
%         diffAng = diff(angRot);
%         % deal with the extreme values when crossing the non-continuous
%         % border...
%         idxT = find(angRot(1:end-1, 1).*angRot(2:end, 1)<0 & abs(angRot(1:end-1, 1)) > 90 & abs(angRot(2:end, 1)) > 90);
%         diffAng(idxT, 1) = 360-abs(angRot(idxT, 1))-abs(angRot(idxT+1, 1));
%
%         rotVel = diffAng.*eyeTrial.sampleRate; % in deg
%         rotVel = [rotVel; NaN(1, 2)];
%         headVelXY = rotVel;
%
%         % calculate the translation part using an assumed head radius and
%         % gaze depth
%         d = eyeTrial.eyeTrace.gazeDepth; % in m
%         headR = 0.1; % in m
%         transVel = atan2d(headR*sin(rotVel/180*pi), ...
%             headR + repmat(d, 1, 2) - headR*cos(rotVel/180*pi));
%         transVel(isnan(transVel)) = 0;
%
%         headVelXY = rotVel + transVel;
% %     end
%     eyeTrial.headTrace.displaceX = headVelXY(:, 1);
%     eyeTrial.headTrace.displaceY = headVelXY(:, 2);
%     eyeTrial.headTrace.displace2D = sqrt(sum(headVelXY.^2, 2));
%
%     [eyeTrial.VOR eyeTrial.classID] = findVOR(eyeVelXY, headVelXY, eyeTrial.headTrace.rotVel3DFilt, ...
%         vorThres, eyeTrial.gazeFix, eyeTrial.classID, eyeTrial.eyeTrace.timestamp, eyeTrial.sampleRate);

save(['data\eyeTrial_', num2str(currentTrial), '.mat'], 'eyeTrial')

%% Eye movement stats - TBD
% blinkStats = processBlink(eyeTrial.blink);
% if ismember({'frameXYZ'}, eyeTrial.eyeAligned.Properties.VariableNames)
%     sacStats = processSaccade(eyeTrial.saccade, eyeTrial.eyeTrace, eyeTrial.eyeAligned.frameXYZ);
% else
%     sacStats = processSaccade(eyeTrial.saccade, eyeTrial.eyeTrace, []);
% end
% 
% eyeDirHead = [eyeTrial.eyeTrace.oriHeadFiltX eyeTrial.eyeTrace.oriHeadFiltY];
% fixStats = processFixation(eyeTrial.gazeFix, eyeDirHead);

% headVelXY = [eyeTrial.headTrace.displaceX eyeTrial.headTrace.displaceY];
% vorStats = processVOR(eyeTrial.VOR, headVelXY, eyeTrial.sampleRate);