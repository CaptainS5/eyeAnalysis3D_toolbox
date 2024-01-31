function headTrace = filterHeadTrace(headData, sampleRate)
% calculate angular head velocity and do filtering
% currently simply use a median filter, could use the debug code to see if
% it works ok

if ismember('posX', headData.Properties.VariableNames)
    headPosRaw = [headData.posX headData.posY headData.posZ];
    % filter head position
    filtFrequency = sampleRate;
    % can modify filtOrder and cutoff frequency according to your needs
    filtOrder = 4;
    filtCutoff = 60;

    headPosFilt = butterworthFilter([headData.posX, ...
        headData.posY, headData.posZ], ...
        filtFrequency, filtOrder, filtCutoff);
end

headOri = [headData.qW headData.qX headData.qY headData.qZ];

% filter the orientations
% The interpolation parameter to slerp is in the closed-interval [0,1], 
% so the output of dist must be re-normalized to this range. However, 
% the full range of [0,1] for the interpolation parameter gives poor 
% performance, so it is limited to a smaller range hrange centered at hbias.
hrange = 0.4;
hbias = 0.4;
% Limit low and high to the interval [0, 1].
low  = max(min(hbias - (hrange./2), 1), 0);
high = max(min(hbias + (hrange./2), 1), 0);
hrangeLimited = high - low;

% Initialize the filter and preallocate outputs.
headOriQ = quaternion(headOri);
y = headOriQ(1); % initial filter state
qout = zeros(size(y), 'like', y); % preallocate filter output
qout(1) = y;

% Filter the noisy trajectory, sample-by-sample.
% b=0
% tic
for ii=2:numel(headOriQ)
    if ~isnan(headOriQ(ii))
        x = headOriQ(ii);
        d = dist(y, x);

        % Renormalize dist output to the range [low, high]
        hlpf = (d./pi).*hrangeLimited + low;
        y = slerp(y,x,hlpf);
        qout(ii) = y;
    else
        qout(ii) = quaternion(NaN(1, 4));
    end
end
% toc
headOriFilt = compact(qout);
oriZYXFilt = quat2eul(headOriFilt)/pi*180;

% calculate rotation between frames--velocity
q1 = headOriFilt(1:end-1, :);
q2 = headOriFilt(2:end, :);
q12 = quatmultiply(quatconj(q1),q2);
rotQRaw = [q12; NaN(1, 4)];
% calculate head velocity in Euler angles
velZYXRaw = quat2eul(rotQRaw)/pi*180;

% filter rotation again
rotQ = quaternion(q12);
y = rotQ(1); % initial filter state
qout = zeros(size(y), 'like', y); % preallocate filter output
qout(1) = y;

% Filter the noisy trajectory, sample-by-sample.
% b=1
% tic
for ii=2:numel(rotQ)
    if ~isnan(rotQ(ii))
        x = rotQ(ii);
        d = dist(y, x);

        % Renormalize dist output to the range [low, high]
        hlpf = (d./pi).*hrangeLimited + low;
        y = slerp(y,x,hlpf);
        qout(ii) = y;
    else
        qout(ii) = quaternion(NaN(1, 4));
    end
end
% toc
qout = quatnormalize(qout);
rotQFilt = [compact(qout); NaN(1, 4)];

velZYXFilt = quat2eul(rotQFilt)/pi*180;

% get rotation direction and velocity
rotAng = 2*acosd(rotQFilt(1:end-1, 1)); %2 * atan2d(norm(q12(ii, 2:4)),q12(ii, 1)); % in degrees
vel = [rotAng.*(1./diff(headData.timestamp)); NaN]; % angle around the rotation axis
rotAxis = [rotvecd(quaternion(rotQFilt(1:end-1, :)))./repmat(rotAng, 1, 3); NaN(1, 3)]; % rotation axis

% filter velocity
if sampleRate<500
    % median filter, works better for low sampling rate data
    velFilt = medfilt1(vel, 12); % median ~ 12 frame
else
    % use butterworth filter for smooth movements
    % can modify filtOrder and cutoff frequency according to your needs
    filtOrder = 4;
    filtCutoff = 60;
    filtFrequency = sampleRate;

    velFilt = butterworthFilter(vel, filtFrequency, filtOrder, filtCutoff);
end

% % add acceleration if you need
% headTrace.acc = [NaN; diff(headTrace.velFilt)].*sampleRate;

% % sanity check...
% rawOriEuler = quat2eul(headOri)/pi*180;
% filtOriEuler = quat2eul(headOriFilt)/pi*180;
% 
% figure
% subplot(3, 1, 1)
% plot(rawOriEuler(:, 1), 'k-')
% hold on
% plot(filtOriEuler(:, 1), 'k--')
% plot(rotVelFilt(:, 1), 'b--')
% ylabel('yaw')
% hold off
% 
% subplot(3, 1, 2)
% plot(rawOriEuler(:, 2), 'k-')
% hold on
% plot(filtOriEuler(:, 2), 'k--')
% plot(rotVelFilt(:, 2), 'b--')
% ylabel('pitch')
% hold off
% 
% subplot(3, 1, 3)
% plot(rawOriEuler(:, 3), 'k-')
% hold on
% plot(filtOriEuler(:, 3), 'k--')
% plot(velEul(:, 3)*sampleRate, 'b--')
% ylabel('roll')
% hold off

% put into table
% "ori" is the quaternion of each frame, representing the head pose in that
% frame
% "rot" is the rotation between frames, basically the rotational quaternion
% or axis-angle; rotVel3D is the rotation velocity around the rotation axis

% only save the filtered data, raw data stored in "headAligned"
if ismember('posX', headData.Properties.VariableNames)
    headTrace = array2table([headPosFilt headOriFilt oriZYXFilt rotQRaw velZYXRaw ...
        rotQFilt velZYXFilt vel rotAxis velFilt headData.timestamp], ...
        'VariableNames', {'posFiltX', 'posFiltY', 'posFiltZ', ...
        'oriFiltQw', 'oriFiltQx', 'oriFiltQy', 'oriFiltQz', ...
        'oriFilt_yaw', 'oriFilt_pitch', 'oriFilt_roll', ...
        'rotRawQw', 'rotRawQx', 'rotRawQy', 'rotRawQz', ...
        'velRaw_yaw', 'velRaw_pitch', 'velRaw_roll', ...
        'rotFiltQw', 'rotFiltQx', 'rotFiltQy', 'rotFiltQz', ...
        'velFilt_yaw', 'velFilt_pitch', 'velFilt_roll', ...
        'rotVel3D', 'rotAxisX', 'rotAxisY', 'rotAxisZ', 'rotVel3DFilt', 'timestamp'});
else
    headTrace = array2table([headOriFilt rotQFilt vel rotAxis velFilt headData.timestamp], ...
        'VariableNames', {'oriFiltQw', 'oriFiltQx', 'oriFiltQy', 'oriFiltQz', ...
        'rotFiltQw', 'rotFiltQx', 'rotFiltQy', 'rotFiltQz', ...
        'rotVel3D', 'rotAxisX', 'rotAxisY', 'rotAxisZ', 'rotVel3DFilt', 'timestamp'});
end


% if ismember('posX', headData.Properties.VariableNames)
%     headTrace = array2table([headPosRaw headPosFilt headOri headOriFilt rotQRaw rotQFilt vel rotAxis velFilt], ...
%         'VariableNames', {'posRawX', 'posRawY', 'posRawZ', ...
%         'posFiltX', 'posFiltY', 'posFiltZ', ...
%         'oriRawQw', 'oriRawQx', 'oriRawQy', 'oriRawQz', ...
%         'oriFiltQw', 'oriFiltQx', 'oriFiltQy', 'oriFiltQz', ...
%         'rotQw', 'rotQx', 'rotQy', 'rotQz', ...
%         'rotFiltQw', 'rotFiltQx', 'rotFiltQy', 'rotFiltQz', ...
%         'rotVel3D', 'rotAxisX', 'rotAxisY', 'rotAxisZ', 'rotVel3DFilt'});
% else
%     headTrace = array2table([headOri headOriFilt rotQRaw rotQFilt vel rotAxis velFilt], ...
%         'VariableNames', {'oriRawQw', 'oriRawQx', 'oriRawQy', 'oriRawQz', ...
%         'oriFiltQw', 'oriFiltQx', 'oriFiltQy', 'oriFiltQz', ...
%         'rotQw', 'rotQx', 'rotQy', 'rotQz', ...
%         'rotFiltQw', 'rotFiltQx', 'rotFiltQy', 'rotFiltQz', ...
%         'rotVel3D', 'rotAxisX', 'rotAxisY', 'rotAxisZ', 'rotVel3DFilt'});
% end
end