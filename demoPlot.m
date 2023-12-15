
% if isfile(['data\post_processed\study2\S2-small-post-data.mat']) 
%   load(['data\post_processed\study2\S2-small-post-data.mat'])
%   all_user_info = small_all_user_info;
% end


eyeTrial = all_user_info.EyeInfo{1};
gazeFix = all_user_info.gazeFix{1};
saccade = all_user_info.saccade{1};

gaze_time = gazeFix.onsetTime;
gaze_end_time = gazeFix.offsetTime;
sacc_time = saccade.onsetTime;


figure;
set(gcf, 'Color', [0.96, 0.96, 1]); % RGB values for light blue


time = eyeTrial.timestamp-min(eyeTrial.timestamp);
xRange = [35, 38]; %[time(1) time(end)]; %


subplot(3,1,1) % horizontal gaze vel
l1 = plot(time, eyeTrial.gazePosWorldFiltX, '-', 'LineWidth', 1.5, 'Color', [0.85 0.33 0.1]);


xlabel('Time (s)')
ylabel('Gaze (X)')
set(gca, 'XTickLabel', []);
set(gca, 'YTickLabel', []);
xlim(xRange)
hold off

subplot(3,1,2) % veritcal gaze vel
l1 = plot(time, eyeTrial.gazePosWorldFiltY, '-', 'LineWidth', 1.5, 'Color', [0.33 0.85 0.1]);


xlabel('Time (s)')
ylabel('Gaze (Y)')
set(gca, 'XTickLabel', []);
set(gca, 'YTickLabel', []);
xlim(xRange)
hold off

subplot(3,1,3) % filtered gaze velocity plot
l1 = plot(time, eyeTrial.gazePosWorldFiltZ, '-', 'LineWidth', 1.5, 'Color', [0.33 0.1 0.85 ]);



xlabel('Time (s)')
ylabel('Gaze (Z)')
set(gca, 'XTickLabel', []);
set(gca, 'YTickLabel', []);
xlim(xRange)
hold off

