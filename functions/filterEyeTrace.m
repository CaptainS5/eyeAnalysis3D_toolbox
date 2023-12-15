function eyeTrace = filterEyeTrace(eyeAligned, sampleRate)
% calculate angular eye velocity and acceleration; filtering included
% Input:
%     eyeAligned: containing eye-in-head and eye-in-world data
%     sampleRate: sampling rate of the data after alignment
% Output:
%     eyeTrace: contains position trace (raw & filtered), velocity trace (raw from filtered position,
%     and filterd velocity), and acceleration, plus timestamps

%% eye in world position data, filter
filtFrequency = sampleRate;
% can modify filtOrder and cutoff frequency according to your needs
filtOrder = 4;
filtCutoff = 30;

if ismember('gazePosWorldX', eyeAligned.Properties.VariableNames)
    gazePosWorldFilt = butterworthFilter([eyeAligned.gazePosWorldX, ...
        eyeAligned.gazePosWorldY, eyeAligned.gazePosWorldZ],...
        filtFrequency, filtOrder, filtCutoff);
%     gazePosFilt = [eyeAligned.gazePosX, ...
%         eyeAligned.gazePosY, eyeAligned.gazePosZ];
    gazePosWorldFiltT = array2table(gazePosWorldFilt, 'VariableNames', {'gazePosWorldFiltX', 'gazePosWorldFiltY', 'gazePosWorldFiltZ'}); % gaze position in world coordinates
else
    gazePosWorldFiltT = [];
end

if ismember('gazePosHeadX', eyeAligned.Properties.VariableNames)
    gazePosHeadFilt = butterworthFilter([eyeAligned.gazePosHeadX, ...
        eyeAligned.gazePosHeadY, eyeAligned.gazePosHeadZ],...
        filtFrequency, filtOrder, filtCutoff);
%     gazePosHeadFilt = [eyeAligned.gazePosHeadX, ...
%         eyeAligned.gazePosHeadY, eyeAligned.gazePosHeadZ];
    gazePosHeadFiltT = array2table(gazePosHeadFilt, 'VariableNames', {'gazePosHeadFiltX', 'gazePosHeadFiltY', 'gazePosHeadFiltZ'}); % gaze position in head coordinates
else
    gazePosHeadFiltT = [];
end

if ismember('eyePosHeadX', eyeAligned.Properties.VariableNames)
    eyePosFilt = butterworthFilter([eyeAligned.eyePosHeadX, ...
        eyeAligned.eyePosHeadY, eyeAligned.eyePosHeadZ],...
        filtFrequency, filtOrder, filtCutoff);
%     eyePosFilt = [eyeAligned.eyePosX, ...
%         eyeAligned.eyePosY, eyeAligned.eyePosZ];
    eyePosFiltT = array2table(eyePosFilt, 'VariableNames', {'eyePosHeadFiltX', 'eyePosHeadFiltY', 'eyePosHeadFiltZ'}); % eye position in head coordinates
else
    eyePosFiltT = [];
end

%% filtering eye-in-head orientation data, x and y separately
% there are several types of filters available, and butterworth filter is
% the most common one; can see more filters in the "filtering velocity trace"
% section below, and feel free to try them with position if you want
% here x means azimuth angle, and y elevation angle

filtFrequency = sampleRate;
% can modify filtOrder and cutoff frequency according to your needs
filtOrder = 9;
filtCutoff = 40;

if ismember({'gazeOriHeadX'}, eyeAligned.Properties.VariableNames)
    oriHeadFilt = butterworthFilter([eyeAligned.gazeOriHeadX, ...
        eyeAligned.gazeOriHeadY],...
        filtFrequency, filtOrder, filtCutoff);
    oriHeadFiltT = array2table(oriHeadFilt, 'VariableNames', {'gazeOriHeadFiltX', 'gazeOriHeadFiltY'}); % gaze ori in device/head frames
else
    oriHeadFiltT = [];
end

if ismember({'gazeOriWorldX'}, eyeAligned.Properties.VariableNames)
    oriWorldFilt = butterworthFilter([eyeAligned.gazeOriWorldX, ...
        eyeAligned.gazeOriWorldY, eyeAligned.gazeDepth],...
        filtFrequency, filtOrder, filtCutoff);
    oriWorldFiltT = array2table(oriWorldFilt, 'VariableNames', {'gazeOriWorldFiltX', 'gazeOriWorldFiltY', 'gazeDepthFilt'}); % gaze ori in world/body frames
else
    oriWorldFiltT = [];
end

% x-azimuth, y-elevation

%% get raw velocity trace
% eye-in-head
% oriHeadRaw = [eyeAligned.gazeOriHeadX, eyeAligned.gazeOriHeadY];
% velHeadRawRaw = diffVel(oriHeadRaw, eyeAligned.timeStamp);
% velHeadRawRawT = array2table(velHeadRawRaw, 'VariableNames', {'velOriHeadRawRawX', 'velOriHeadRawRawY', 'velOriHeadRawRaw2D'});
% % raw velocity from raw position

velHeadRaw = diffVel(oriHeadFilt, eyeAligned.timestamp);
velHeadRawT = array2table(velHeadRaw, 'VariableNames', {'velOriHeadRawX', 'velOriHeadRawY', 'velOriHeadRaw2D'});
% raw velocity from filtered position

if ismember({'gazePosX', 'eyePosX', 'frameXYZ'}, eyeAligned.Properties.VariableNames)
    % gaze velocity based on retinal motion
    velWorldRaw = [];
    % c=0
    % tic
    for jj = 1:size(eyePosFilt, 1)-1
        vecW1 = gazePosFilt(jj, :)-eyePosFilt(jj, :); % vector from eye_pos_t1 to gaze_pos_t1
        vecW2 = gazePosFilt(jj+1, :)-eyePosFilt(jj, :); % vector from eye_pos_t0 to gaze_pos_t1

        % transform gaze vectors into eye frame at t1, unit in m
        posE1 = eyeAligned.frameXYZ{jj, 1}'*vecW1';
        pos1 = [-atand(posE1(2)/posE1(1)) ...
            atand(posE1(3)/ sqrt( posE1(1).^2 + posE1(2).^2) )]; % in deg, azimuth and elevation
        %     [visualAng1,retinalAng1,fixAng1] = RetinalImageEstimate(posE1*1000); % sanity check

        posE2 = eyeAligned.frameXYZ{jj, 1}'*vecW2';
        pos2 = [-atand(posE2(2)/posE2(1)) ...
            atand(posE2(3)/ sqrt( posE2(1).^2 + posE2(2).^2) )];
        %     [visualAng2,retinalAng2,fixAng2] = RetinalImageEstimate(posE2*1000);

        %     % rotation from pos1 to pos2 is the movement from t0 to t1
        %     rotAxis = cross(posE1, posE2);
        %     rotAxis = rotAxis./norm(rotAxis); % normalize
        %     angle = atan2( norm(cross(posE1, posE2)), dot(posE1, posE2) ); % in rad
        %
        %     rotQ = [cos(angle/2) sin(angle/2).*rotAxis(1) sin(angle/2).*rotAxis(2) sin(angle/2).*rotAxis(3)];
        %     rotE = quat2eul(rotQ)/pi*180*sampleRate; % yaw, pitch, roll, velocity
        %     velGazeRaw(jj-1, :) = [-rotE(1) rotE(2)]; % in deg

        velWorldRaw(jj, :) = (pos2-pos1).*(1./diff(eyeAligned.timestamp)); % in deg
    end
    velWorldRaw = [velWorldRaw; NaN(1, 2)];
    velWorldRaw = [velWorldRaw sqrt(sum(velWorldRaw.^2, 2))];
else
    velWorldRaw = diffVel(oriWorldFilt(:, 1:2), eyeAligned.timestamp);
end
velWorldRawT = array2table(velWorldRaw, 'VariableNames', {'velOriWorldRawX', 'velOriWorldRawY', 'velOriWorldRaw2D'});

%% filtering velocity trace
% velocity trace based on filtered position is already very smooth, could just
% use an additional step to emphasize the saccade shape (e.g. Gaussian).
% Butterworth filter would make the trace too smooth and is unlikely to work well here,
% especially if you care about saccades; for pursuit analysis, butterworth
% would be good to exclude the quick phases of eye movements.

% when working directly on the velocity trace, starting with median filter,
% then choose another one such as Gaussian/FIR/Sgolay to smooth would
% likely work better

% % gaussian filter
% w = gausswin(5);
% w = w/sum(w);
% eyeTrace.velFilt = filter(w, 1, eyeTrace.velRaw);
% no matter how many filters you used, always make sure velFilt is the final trace

% % median filter, if directly work on velocity trace then will likely need
% % this
% windowL = 5; % how many frames
% eyeTrace.velFilt0 = medfilt1(eyeTrace.velRaw, windowL, 'omitnan');

% % FIR filter, could use a kernel with similar shape as a saccade
% kernel = [0 1 2 1 0]; % could add -1 around if want to emphasize saccade onset and offset
% kernel = kernel/sum(kernel(kernel>0)); % normalize is a bit tricky...
% % make sure you don't change peak velocity too much
% eyeTrace.velFilt1 = conv(eyeTrace.velFilt0, kernel, 'same');

% % lowpass filter, doesn't really work well as our sampling rate is not high
% eyeTrace.velFilt = lowpass(eyeTrace.velRaw, 30, 240);

% if you have multiple filters, make sure velFilt is the final filtered
% trace; sometimes people may use median first, FIR/Gaussian second, then
% SgoLay the last... just see what suits your data the best
% eyeTrace.velFilt = eyeTrace.velFilt2;

% can modify filtOrder and cutoff frequency according to your needs
if sampleRate >= 600
filtOrder = 9;
filtCutoff = 55;
% 
velWorldFilt = butterworthFilter(velWorldRaw(:, 1:2), ...
    filtFrequency, filtOrder, filtCutoff);

% velHeadFiltRaw = butterworthFilter(velHeadRawRaw(:, 1:2), ...
%     filtFrequency, filtOrder, filtCutoff);

velHeadFilt = butterworthFilter(velHeadRaw(:, 1:2), ...
    filtFrequency, filtOrder, filtCutoff);
else
    % SgoLay to smooth the signal, another common filter
    order = 9;
    framelen = 17;
    b = sgolay(order,framelen);

    ycenter = conv(velWorldRaw(:, 1),b((framelen+1)/2,:),'valid');
    ybegin = b(end:-1:(framelen+3)/2,:) * velWorldRaw(framelen:-1:1, 1);
    yend = b((framelen-1)/2:-1:1,:) * velWorldRaw(end:-1:end-(framelen-1), 1);
    velWorldFilt(:, 1) = [ybegin; ycenter; yend];

    ycenter = conv(velWorldRaw(:, 2),b((framelen+1)/2,:),'valid');
    ybegin = b(end:-1:(framelen+3)/2,:) * velWorldRaw(framelen:-1:1, 2);
    yend = b((framelen-1)/2:-1:1,:) * velWorldRaw(end:-1:end-(framelen-1), 2);
    velWorldFilt(:, 2) = [ybegin; ycenter; yend];

%     ycenter = conv(velHeadRawRaw(:, 1),b((framelen+1)/2,:),'valid');
%     ybegin = b(end:-1:(framelen+3)/2,:) * velHeadRawRaw(framelen:-1:1, 1);
%     yend = b((framelen-1)/2:-1:1,:) * velHeadRawRaw(end:-1:end-(framelen-1), 1);
%     velHeadFiltRaw(:, 1) = [ybegin; ycenter; yend];
% 
%     ycenter = conv(velHeadRawRaw(:, 2),b((framelen+1)/2,:),'valid');
%     ybegin = b(end:-1:(framelen+3)/2,:) * velHeadRawRaw(framelen:-1:1, 2);
%     yend = b((framelen-1)/2:-1:1,:) * velHeadRawRaw(end:-1:end-(framelen-1), 2);
%     velHeadFiltRaw(:, 2) = [ybegin; ycenter; yend];    

    ycenter = conv(velHeadRaw(:, 1),b((framelen+1)/2,:),'valid');
    ybegin = b(end:-1:(framelen+3)/2,:) * velHeadRaw(framelen:-1:1, 1);
    yend = b((framelen-1)/2:-1:1,:) * velHeadRaw(end:-1:end-(framelen-1), 1);
    velHeadFilt(:, 1) = [ybegin; ycenter; yend];

    ycenter = conv(velHeadRaw(:, 2),b((framelen+1)/2,:),'valid');
    ybegin = b(end:-1:(framelen+3)/2,:) * velHeadRaw(framelen:-1:1, 2);
    yend = b((framelen-1)/2:-1:1,:) * velHeadRaw(end:-1:end-(framelen-1), 2);
    velHeadFilt(:, 2) = [ybegin; ycenter; yend];
end

velWorldFilt = [velWorldFilt sqrt(sum(velWorldFilt.^2, 2))];
velWorldFiltT = array2table(velWorldFilt, 'VariableNames', ...
    {'velOriWorldFiltX', 'velOriWorldFiltY', 'velOriWorldFilt2D'});

% velHeadFiltRaw = [velHeadFiltRaw sqrt(sum(velHeadFiltRaw.^2, 2))];
% velHeadFiltRawT = array2table(velHeadFiltRaw, 'VariableNames', ...
%     {'velHeadFiltRawX', 'velHeadFiltRawY', 'velHeadFiltRaw2D'});

velHeadFilt = [velHeadFilt sqrt(sum(velHeadFilt.^2, 2))];
velHeadFiltT = array2table(velHeadFilt, 'VariableNames', ...
    {'velOriHeadFiltX', 'velOriHeadFiltY', 'velOriHeadFilt2D'});

%% get acceleration
accHead = diffVel(velHeadFilt(:, 1:2), eyeAligned.timestamp);
accHead(:, 3) = [diff(velHeadFilt(:, 3)); NaN].*[1./diff(eyeAligned.timestamp); NaN]; % correct 2D acc... not the same as how we get 2D vel from pos
accHeadT = array2table(accHead, 'VariableNames', {'accOriHeadX', 'accOriHeadY', 'accOriHead2D'});

accWorld = diffVel(velWorldFilt(:, 1:2), eyeAligned.timestamp);
accWorld(:, 3) = [diff(velWorldFilt(:, 3)); NaN].*[1./diff(eyeAligned.timestamp); NaN]; % correct 2D acc... not the same as how we get 2D vel from pos

% depending on your signals, can choose to filter acceleration as well
% w = gausswin(5);
% w = w/sum(w);
% eyeTrace.accFilt = filter(w, 1, eyeTrace.acc);
% eyeTrace.accFilt = medfilt1(eyeTrace.acc, 5);
accWorldT = array2table(accWorld, 'VariableNames', {'accOriWorldX', 'accOriWorldY', 'accOriWorld2D'});

eyeTrace = [eyePosFiltT gazePosHeadFiltT gazePosWorldFiltT ...
    oriHeadFiltT oriWorldFiltT velHeadRawT velHeadFiltT accHeadT ...
    velWorldRawT velWorldFiltT accWorldT];
eyeTrace.timestamp = eyeAligned.timestamp;
end