function blinkI = cleanEyeDir(eyeDir)
% getting the indices of blink frames in eyeDir (local eye direction vector x/y/z)
% also could exclude some really abnormal data points here, not doing this
% right now... some left over codes to be organized later

eyeTemp = eyeDir;

% mark blink (no signal) as NaN
% in my piloting I found blinks to be simply (0,0,0)
% currently not doing anything else, but could consider including a few
% frames before and after the blink frames, as the eye dir won't turn to
% (0,0,0) right away when starting to blink, same for when ending a blink
idxB = find(all(eyeTemp==repmat([0 0 0], size(eyeTemp, 1), 1), 2));
blinkI = idxB; % indices of blink frames in eyeDir

% % also remove outliers in z, which shouldn't change much in our case... 
% % not in use right now, as we are filtering position then velocity
% % use the same outlier calculation as boxplot
% qt = prctile(eyeTemp(:, 3), [25, 75]);
% w = 6; % 1.5 is the default of boxplot
% rangeZ = [qt(1)-w*range(qt), qt(2)+w*range(qt)];
% idxD = find(eyeTemp(:, 3)>rangeZ(2) | eyeTemp(:, 3)<rangeZ(1));

% % smooth the 3d raw direction... but shape is changed after smoothing?... not doing it now
% dirRaw = reshape(eyeTemp{:, 10:12}, [size(eyeTemp, 1), 1, 3]);
% dirFilt2 = reshape(smooth3(dirRaw, 'gaussian', 13), [size(dirRaw, 1), 3]);
% 
% for ii = 1:size(dirFilt2, 1) % normalize
%     dirFilt2norm(ii, :) = dirFilt2(ii, :)/norm(dirFilt2(ii, :));
% end
% 
% figure
% plot3(eyeAligned{:, 10}, eyeAligned{:, 11}, eyeAligned{:, 12}, 'r') % camera relative
% hold on
% plot3(dirFilt(:, 1), dirFilt(:, 2), dirFilt(:, 3), 'b')
% % plot3(dirFilt2(:, 1), dirFilt2(:, 2), dirFilt2(:, 3), 'g')
% % plot3(dirFilt2norm(:, 1), dirFilt2norm(:, 2), dirFilt2norm(:, 3), 'y')
% plot3(0, 0, 0, 'xr')
% xlabel('x')
% ylabel('y')
% zlabel('z')
% 
% close all