function [output] = autoProcess(databaseName, fixThres, vorThres, sacThresAll, blinkThresAll, samplingRate)

if strcmp(databaseName, 'Rochester')
    trialN = 76;
    dataType = 1;
elseif strcmp(databaseName, 'SoaringEagle')
    trialN = 169;
    dataType = 2; % video-based eye tracker
end

sacThres = sacThresAll(dataType);
blinkThres = blinkThresAll(dataType);

output.blink = table();
output.saccade = table();
output.fixation = table();
output.VOR = table();
output.pursuit = table();

for trialI = 1:trialN
    trialI

    dataFile = ['data\', num2str(samplingRate), 'Hz\eyeTrial_', databaseName, num2str(trialI), '.mat'];

    if isfile(dataFile)
        load(dataFile)
    else
        % load raw data
        load(['data\raw\', num2str(samplingRate), 'Hz\data', databaseName, num2str(trialI), '.mat'])

        eyeTrial.headTrace = filterHeadTrace(eyeTrial.headAligned, eyeTrial.sampleRate);
        eyeTrial.headTrace.timeStamp = eyeTrial.headAligned.timeStamp;
        if ~ismember('gazeWorldX', eyeTrial.eyeAligned.Properties.VariableNames) % calculate gaze re. body
            % in Rochester dataset, since participants are sitting down, just take the
            % referencel head frame as the body-fixed coordinates; eye centered,
            % so the origin is always eye position; the raw data of these are
            % all in the world coordinates
            bodyFrame = eyeTrial.headRefXYZ;
            % gaze orientation vector in the body-fixed coordinates
            % x-forward, y-left, z-up
            gazeVWorld = [eyeTrial.eyeAligned.gazePosX-eyeTrial.eyeAligned.eyePosX, ...
                eyeTrial.eyeAligned.gazePosY-eyeTrial.eyeAligned.eyePosY, ...
                eyeTrial.eyeAligned.gazePosZ-eyeTrial.eyeAligned.eyePosZ];

            for ii = 1:size(eyeTrial.eyeAligned, 1)
                gazeVBody = bodyFrame'*gazeVWorld(ii, :)';

                eyeTrial.eyeAligned.gazeWorldX(ii, 1) = -atand(gazeVBody(2)/gazeVBody(1));
                eyeTrial.eyeAligned.gazeWorldY(ii, 1) = atand(gazeVBody(3)/ sqrt( gazeVBody(1).^2 + gazeVBody(2).^2) );
            end
        end
    end
        eyeTrial.eyeTrace = filterEyeTrace(eyeTrial.eyeAligned, eyeTrial.sampleRate);
%     end

    % classification
    [eyeTrial.blink eyeTrial.classID] = findBlink(eyeTrial.eyeTrace, eyeTrial.sampleRate, dataType, blinkThres);
    [eyeTrial.saccade eyeTrial.classID] = findSaccade(eyeTrial.eyeTrace, eyeTrial.sampleRate, eyeTrial.classID, sacThres);
    if ismember({'frameXYZ'}, eyeTrial.eyeAligned.Properties.VariableNames)
        [eyeTrial.gazeFix eyeTrial.classID] = findGazeFix(eyeTrial.eyeTrace, eyeTrial.eyeAligned.frameXYZ, ...
            fixThres, eyeTrial.classID, eyeTrial.sampleRate, eyeTrial.eyeTrace.timeStamp);
    else
        [eyeTrial.gazeFix eyeTrial.classID] = findGazeFix(eyeTrial.eyeTrace, [], ...
            fixThres, eyeTrial.classID, eyeTrial.sampleRate, eyeTrial.eyeTrace.timeStamp);
    end

    % for VOR
    eyeVelXY = [eyeTrial.eyeTrace.velHeadFiltX eyeTrial.eyeTrace.velHeadFiltY]; % eye-in-head velocity
    % for the head, we need to know both translation and rotation, and to
    % do this we also need to know where the 3D gaze position is
    % just calculate the "combined" head movement that needs to be canceled
    % by VOR

    headRot = [eyeTrial.headTrace.rotFiltQw eyeTrial.headTrace.rotFiltQx ...
        eyeTrial.headTrace.rotFiltQy eyeTrial.headTrace.rotFiltQz];
    % headRot takes care of the head rotational part, in world/body
    % coordinates, already velocity

    if ismember({'gazePosFiltX', 'eyePosFiltX'}, eyeTrial.eyeTrace.Properties.VariableNames)
        % for the rochester data base, just skip middle steps with eye-in-head
        % position and directly use final eye position to see how much perfect
        % compensation should be
        gazePos = [eyeTrial.eyeTrace.gazePosFiltX eyeTrial.eyeTrace.gazePosFiltY eyeTrial.eyeTrace.gazePosFiltZ];
        % gaze position in world/body coordinates

        eyePos = [eyeTrial.eyeTrace.eyePosFiltX eyeTrial.eyeTrace.eyePosFiltY eyeTrial.eyeTrace.eyePosFiltZ];
        % eyepos takes care of all translational movement, including those
        % induced by head translation and head rotation

        headVelXY = getHeadVelXY(eyePos, gazePos, headRot, eyeTrial.headAligned.frameXYZ, eyeTrial.sampleRate);
        % headVelXY indicates the amount that needs to be compensated
    else
        % let's use the simplified thing for SE... just turn head rotation
        % into angles; use the quaternion representing rotation between
        % frames--velocity
        refVec = [1; 1; 1];
        refVec = refVec/norm(refVec); % just a reference vector to be rotated
        rotVec = [];
        rotVec(1, :) = refVec; % shoulder coordinates

        % rotate
        for ii = 2:size(headRot, 1)
            rotVec(ii, :) = (quat2rotm(headRot(ii, :))*rotVec(ii-1, :)')';
            if all(isnan(rotVec(ii, :))) && all(~isnan(headRot(ii, :)))
                % end of the NaN period, set up the reference again
                rotVec(ii, :) = [1; 1; 1]/norm([1; 1; 1]);
            end
        end

        % transform into head frame
        angRot = [-atan2d(rotVec(:, 2), rotVec(:, 1)) ...
            atan2d(rotVec(:, 3), sqrt( rotVec(:, 1).^2 + rotVec(:, 2).^2) )];
        diffAng = diff(angRot);
        % deal with the extreme values when crossing the non-continuous
        % border...
        idxT = find(angRot(1:end-1, 1).*angRot(2:end, 1)<0 & abs(angRot(1:end-1, 1)) > 90 & abs(angRot(2:end, 1)) > 90);
        diffAng(idxT, 1) = 360-abs(angRot(idxT, 1))-abs(angRot(idxT+1, 1));

        rotVel = diffAng.*eyeTrial.sampleRate; % in deg
        rotVel = [rotVel; NaN(1, 2)];
        headVelXY = rotVel;

        %             % calculate the translation part using an assumed head radius and
        %             % gaze depth
        %             d = eyeTrial.eyeTrace.gazeDepth; % in m
        %             headR = 0.1; % in m
        %             transVel = atan2d(headR*sin(rotVel/180*pi), ...
        %                 headR + repmat(d, 1, 2) - headR*cos(rotVel/180*pi));
        %             transVel(isnan(transVel)) = 0;
        %
        %             headVelXY = rotVel + transVel;
    end
    eyeTrial.headTrace.displaceX = headVelXY(:, 1);
    eyeTrial.headTrace.displaceY = headVelXY(:, 2);

    [eyeTrial.VOR eyeTrial.classID] = findVOR(eyeVelXY, headVelXY, eyeTrial.headTrace.rotVel3DFilt, ...
        vorThres, eyeTrial.gazeFix, eyeTrial.classID, eyeTrial.eyeTrace.timeStamp, eyeTrial.sampleRate);
    % save processed data files
    save(['data\', num2str(samplingRate), 'Hz\eyeTrial_', databaseName, num2str(trialI), '.mat'], 'eyeTrial')
%         end

    % processing of gaze events
    blinkT = processBlink(eyeTrial.blink);
    if ismember({'frameXYZ'}, eyeTrial.eyeAligned.Properties.VariableNames)
        saccadeT = processSaccade(eyeTrial.saccade, eyeTrial.eyeTrace, eyeTrial.eyeAligned.frameXYZ, eyeTrial.eyeAligned);
    else
        saccadeT = processSaccade(eyeTrial.saccade, eyeTrial.eyeTrace, []);
    end

    eyeDirHead = [eyeTrial.eyeTrace.oriHeadFiltX eyeTrial.eyeTrace.oriHeadFiltY];
    fixationT = processFixation(eyeTrial.gazeFix, eyeDirHead);

    headVelXY = [eyeTrial.headTrace.displaceX eyeTrial.headTrace.displaceY];
    VORT = processVOR(eyeTrial.VOR, headVelXY, eyeTrial.sampleRate);
    %     pursuitT = processPursuit(eyeTrial);

    % sort into the output file
    % add timestamps, classification and velocities
    output.timeStamp{trialI} = eyeTrial.eyeTrace.timeStamp;
    output.classID{trialI} = eyeTrial.classID;
    output.traces{trialI} = [eyeTrial.eyeTrace(:, 1:end-1) eyeTrial.headTrace];

    if ~isempty(blinkT)
        blinkT.trial(:, 1) = trialI;
        output.blink = [output.blink; blinkT];
    end
    if ~isempty(saccadeT)
        saccadeT.trial(:, 1) = trialI;
        output.saccade = [output.saccade; saccadeT];
    end
    if ~isempty(fixationT)
        fixationT.trial(:, 1) = trialI;
        output.fixation = [output.fixation; fixationT];
    end
    if ~isempty(VORT)
        VORT.trial(:, 1) = trialI;
        output.VOR = [output.VOR; VORT];
    end
    %     pursuitT.trial(:, 1) = trialI;
    %     output.pursuit = [output.pursuit; pursuitT];
end

end