function gazePos = getRetinalPos(gazeRef, eyePos, eyeFrameXYZ)
% not retinal position, but position in your visual field, need to change
% the name...
% coordinate system is x+forward, y+left, z+up
% azimuth is 0-forward, left negative
% elevation is 0-horizontal forward leve, down negative

gazePos = [];
for ii = 1:size(eyeFrameXYZ, 1)
    vec = gazeRef-eyePos(ii, :);

    % transform gaze vectors into eye frame at t1, unit in m
    posE1 = eyeFrameXYZ{ii, 1}'*vec';
    gazePos(ii, :) = [-atand(posE1(2)/posE1(1)) ...
        atand(posE1(3)/ sqrt( posE1(1).^2 + posE1(2).^2) )]; % in deg
end

end