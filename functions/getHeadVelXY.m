function headVelXY = getHeadVelXY(eyePos, gazePos, headRot, headFrameXYZ, sampleRate)
% based on head rotation and translation, plus the gaze target position,
% calculate the corresponding azimuth and elevation that needs to be
% compensated by eye rotation, if it's during VOR

% make sure that all angles are in the same head-based coordinate system,
% since eye-in-head angle is also in head frames

% first, the translation part
vec1 = gazePos(1:end-1, :)-eyePos(2:end, :); % 
vec2 = gazePos(1:end-1, :)-eyePos(1:end-1, :); % 
% vec1 = eyePos(1:end-1, :)-gazePos(1:end-1, :); % previous eye pos to target
% vec2 = eyePos(2:end, :)-gazePos(1:end-1, :); % new eye pos to previous target, assuming perfect fixation
% rotation from vec1 to vec2 is the rotation caused by translation that the
% eye needs to compensate for, currently in world coordinates

% transform into head frames
for ii = 1:size(vec1, 1)
    vecE1 = headFrameXYZ{ii+1, 1}'*vec1(ii, :)';
    ang1(ii, :) = [-atand(vecE1(2)/vecE1(1)) ...
        atand(vecE1(3)/ sqrt( vecE1(1).^2 + vecE1(2).^2) )]; % in deg, azimuth and elevation

    vecE2 = headFrameXYZ{ii, 1}'*vec2(ii, :)';
    ang2(ii, :) = [-atand(vecE2(2)/vecE2(1)) ...
        atand(vecE2(3)/ sqrt( vecE2(1).^2 + vecE2(2).^2) )]; % in deg, azimuth and elevation
end
transVel = (ang2-ang1).*sampleRate;

% rotAxis = cross(vec1, vec2, 2);
% rotAxis = rotAxis./repmat(vecnorm(rotAxis, 2, 2), 1, 3); % normalize
% angle = atan2( vecnorm(cross(vec1, vec2), 2, 2), dot(vec1, vec2, 2) ); % in rad
% % % sanity check
% % rot1 = vrrotvec(vec1(1, :), vec2(1, :))
% 
% rotQ = [cos(angle/2) sin(angle/2).*rotAxis(:, 1) sin(angle/2).*rotAxis(:, 2) sin(angle/2).*rotAxis(:, 3)];
% transRotE = quat2eul(rotQ)/pi*180*sampleRate; % yaw, pitch, roll, velocity
% transVel = [transRotE(:, 1) -transRotE(:, 2)]; % in deg
transVel = [transVel; NaN(1, 2)];

% then, the rotation part
refVec = [1; 1; 1]; 
refVec = refVec/norm(refVec); % just a reference vector to be rotated, we eventually care about velocity (difference)
rotVec(1, :) = refVec; % world coordinate

% rotate in world coordinate
for ii = 2:size(headRot, 1)
    rotVec(ii, :) = (quat2rotm(headRot(ii, :))*rotVec(ii-1, :)')';
end

% transform into head frame
for ii = 1:size(headFrameXYZ, 1)
    rotVecH(ii, :) = headFrameXYZ{ii, 1}'*rotVec(ii, :)';
    angRot(ii, :) = [-atand(rotVecH(ii, 2)./rotVecH(ii, 1)) ...
        atand(rotVecH(ii, 3)./ sqrt( rotVecH(ii, 1).^2 + rotVecH(ii, 2).^2) )];
end
rotVel = diff(angRot).*sampleRate; % in deg

% rotEul = quat2eul(headRot(1:end-1, :))/pi*180;
% rotVel = rotEulE(:, 1:2)*sampleRate; % yaw and pitch, horizontal and vertical
% rotVel(:, 2) = -rotVel(:, 2); % flip vertical so it's positive upward
rotVel = [rotVel; NaN(1, 2)]; 

% add up to have the final change
headVelXYRaw = transVel + rotVel; % x-azimuth, y-elevation

if sampleRate>=1000
    filtOrder = 9;
    filtCutoff = 55;%min([sampleRate*0.75, 75]);
    % filter to smooth the trace
    filtFrequency = sampleRate;

    headVelXY = butterworthFilter(headVelXYRaw, filtFrequency, filtOrder, filtCutoff);
else
    % SgoLay to smooth the signal, another common filter
    order = 9;
    framelen = 17;
    b = sgolay(order,framelen);

    ycenter = conv(headVelXYRaw(:, 1),b((framelen+1)/2,:),'valid');
    ybegin = b(end:-1:(framelen+3)/2,:) * headVelXYRaw(framelen:-1:1, 1);
    yend = b((framelen-1)/2:-1:1,:) * headVelXYRaw(end:-1:end-(framelen-1), 1);
    headVelXY(:, 1) = [ybegin; ycenter; yend];

    ycenter = conv(headVelXYRaw(:, 2),b((framelen+1)/2,:),'valid');
    ybegin = b(end:-1:(framelen+3)/2,:) * headVelXYRaw(framelen:-1:1, 2);
    yend = b((framelen-1)/2:-1:1,:) * headVelXYRaw(end:-1:end-(framelen-1), 2);
    headVelXY(:, 2) = [ybegin; ycenter; yend];
end

end