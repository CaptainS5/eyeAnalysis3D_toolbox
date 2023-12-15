function [verDist verAngle gazePoints] = getVergence(leftEyePos, leftEyeDir, rightEyePos, rightEyeDir)
% calculate vergence distance and angle 
% the coordinate system is x+ forward, y+ left, z+ up
% Input: 
%   each variable should be a 3 by n matrix, each column is one position/direction vector 
%   xxxEyeDir should direction vectors poiting from the corresponding eye position
% Output: 
%   unit of verDist is whatever the unit of the input coordinate system
%   verAngle is in degs
% Xiuyun Wu, Jun. 2023

% gaze point is defined as the point in 3D space that has the smallest sum
% of squared distances to the two gaze lines
% ref: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7880627/

% note that I didn't directly use the method described in the paper since I
% don't want to redefine the coordinate system... so just find the
% point closest to both lines directly using current coordinates
% ref: https://en.wikipedia.org/wiki/Skew_lines#Nearest_Points

% line of the left gaze vector: leftEyePos + a*leftEyeDir
% line of the right gaze vector: rightEyePos + a*rightEyeDir

% normalize the direction vectors
leftEyeDir = leftEyeDir./repmat(vecnorm(leftEyeDir), size(leftEyeDir, 1), 1);
rightEyeDir = rightEyeDir./repmat(vecnorm(rightEyeDir), size(rightEyeDir, 1), 1);

% cross product of the two gaze directions, perpendicular to both lines
n = cross(leftEyeDir, rightEyeDir);

n1 = cross(leftEyeDir, n); % plane of the left eye gaze sliding along n 
n2 = cross(rightEyeDir, n); % plane of the right eye gaze sliding along n

c1 = leftEyePos + dot((rightEyePos-leftEyePos), n2)./dot(leftEyeDir, n2).*leftEyeDir; % intersection of left eye gaze with n2
% also the point on the left gaze vector line that's closest to the right gaze vector line

c2 = rightEyePos + dot((leftEyePos-rightEyePos), n1)./dot(rightEyeDir, n1).*rightEyeDir; % intersection of right eye gaze with n1
% also the point on the right gaze vector line that's closest to the right gaze vector line

gazePoints = (c1+c2)/2;

% now we have the triangle of leftEyePos, rightEyePos, gazePoint
v1 = leftEyePos-gazePoints;
v2 = rightEyePos-gazePoints;

% % distance from the gaze point to the line connecting left and right eye
% verDist = vecnorm(cross(leftEyePos-rightEyePos, gazePoints-rightEyePos))./vecnorm(leftEyePos-rightEyePos);  

% use cyclopean eye to calculate depth distance
verDist = vecnorm(gazePoints-(leftEyePos+rightEyePos)./2);
verAngle = atan2d(vecnorm(cross(v1, v2)), dot(v1, v2));

% if gaze directions are parallel, give inf to verDist
% rest of the NaNs should be missing signals
idx = find(all(n==repmat([0; 0; 0], 1, size(n, 2))));
verDist(idx) = inf;