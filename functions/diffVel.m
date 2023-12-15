function vel = diffVel(pos, timestamps)
% Calculate velocity based on position data
% Input: pos--each column is one variable, azimuth, elevation (and depth)
% Output: vel--corresponding velocity in each traces, plus an additional
% trace of the 2D velocity magnitude

vel = [diff(pos); NaN(1, size(pos, 2))].*[1./diff(timestamps); NaN];
vel = [vel sqrt(sum(vel.^2, 2))];
end