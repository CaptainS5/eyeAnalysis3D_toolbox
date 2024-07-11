function updatePlots(plotMode, eyeTrial, axSub, fig)
set(0, 'CurrentFigure', fig)
time = eyeTrial.eyeTrace.timestamp-min(eyeTrial.eyeTrace.timestamp);
xRange = [1, 2]; %time(1) time(end)]; %
yRange = [-200 200]; % [-100 100];%

if plotMode==0 % final result plots with saccades
    subplot(axSub(1)) % horizontal gaze vel
    l1 = plot(time, eyeTrial.eyeTrace.velOriWorldFiltX, '-');
    hold on
    l2 = plot(time, eyeTrial.eyeTrace.velOriHeadFiltX, '--');
    
    %
    if ~isempty(eyeTrial.blink.onsetTime) % mark blinks if we have any
        p1 = plot(eyeTrial.blink.onsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.velOriWorldFiltX(max([eyeTrial.blink.onsetI-1, ones(size(eyeTrial.blink.onsetI))], [], 2)), 'or');
        p2 = plot(eyeTrial.blink.offsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.velOriWorldFiltX(...
            min([eyeTrial.blink.offsetI+1, ones(size(eyeTrial.blink.onsetI)).*length(eyeTrial.eyeTrace.velOriWorldFiltX)], [], 2) ), 'og');
        %     for ii = 1:length(eyeTrial.saccade.offsetTime)
        %         text(eyeTrial.saccade.offsetTime(ii)-min(eyeTrial.eyeTrace.timestamp), ...
        %             eyeTrial.eyeTrace.velFilt(eyeTrial.saccade.offsetI(ii)), ...
        %             [num2str(eyeTrial.saccade.amp(ii), '%2.0f'), 'deg, ', num2str(eyeTrial.saccade.duration(ii)*1000, '%3.0f'), 'ms'])
        %     end
        legend([l1, l2, p1, p2], {'gaze in world', 'eye-in-head', 'blink onset', 'blink offset'}, 'box', 'off', 'location', 'best')
    else
        legend([l1 l2], {'gaze in world', 'eye-in-head'}, 'location', 'best', 'box', 'off');
    end

    if ~isempty(eyeTrial.saccade.onsetTime) % mark saccades if we have any
        line([min(time), max(time)], [eyeTrial.saccade.sacThres, eyeTrial.saccade.sacThres], 'LineStyle', '--') % saccade threshold for finding peaks
        p1 = plot(eyeTrial.saccade.onsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.velOriWorldFiltX(eyeTrial.saccade.onsetI), '*r');
        p2 = plot(eyeTrial.saccade.offsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.velOriWorldFiltX(eyeTrial.saccade.offsetI), '*g');
        %     for ii = 1:length(eyeTrial.saccade.offsetTime)
        %         text(eyeTrial.saccade.offsetTime(ii)-min(eyeTrial.eyeTrace.timestamp), ...
        %             eyeTrial.eyeTrace.velFilt(eyeTrial.saccade.offsetI(ii)), ...
        %             [num2str(eyeTrial.saccade.amp(ii), '%2.0f'), 'deg, ', num2str(eyeTrial.saccade.duration(ii)*1000, '%3.0f'), 'ms'])
        %     end
%         legend([p1, p2], {'saccade onset', 'saccade offset'}, 'box', 'off', 'location', 'best')
    end

    xlabel('Time (s)')
    ylabel('Filtered horizontal gaze velocity (deg/s)')
    xlim(xRange)
    % ylim(yRange)
    hold off

    subplot(axSub(2)) % veritcal gaze vel
    plot(time, eyeTrial.eyeTrace.velOriWorldFiltY, '-')
    hold on
    plot(time, eyeTrial.eyeTrace.velOriHeadFiltY, '--')
    %
    if ~isempty(eyeTrial.saccade.onsetTime) % mark saccades if we have any
        line([min(time), max(time)], [eyeTrial.saccade.sacThres, eyeTrial.saccade.sacThres], 'LineStyle', '--') % saccade threshold for finding peaks
        p1 = plot(eyeTrial.saccade.onsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.velOriWorldFiltY(eyeTrial.saccade.onsetI), '*r');
        p2 = plot(eyeTrial.saccade.offsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.velOriWorldFiltY(eyeTrial.saccade.offsetI), '*g');
        %     for ii = 1:length(eyeTrial.saccade.offsetTime)
        %         text(eyeTrial.saccade.offsetTime(ii)-min(eyeTrial.eyeTrace.timestamp), ...
        %             eyeTrial.eyeTrace.velFilt(eyeTrial.saccade.offsetI(ii)), ...
        %             [num2str(eyeTrial.saccade.amp(ii), '%2.0f'), 'deg, ', num2str(eyeTrial.saccade.duration(ii)*1000, '%3.0f'), 'ms'])
        %     end
        legend([p1, p2], {'saccade onset', 'saccade offset'}, 'box', 'off', 'location', 'best')
    end
    
    if ~isempty(eyeTrial.blink.onsetTime) % mark blinks if we have any
        p1 = plot(eyeTrial.blink.onsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.velOriWorldFiltY(max([eyeTrial.blink.onsetI-1, ones(size(eyeTrial.blink.onsetI))], [], 2)), 'or');
        p2 = plot(eyeTrial.blink.offsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.velOriWorldFiltY(...
            min([eyeTrial.blink.offsetI+1, ones(size(eyeTrial.blink.onsetI)).*length(eyeTrial.eyeTrace.velOriWorldFiltY)], [], 2) ), 'og');
        %     for ii = 1:length(eyeTrial.saccade.offsetTime)
        %         text(eyeTrial.saccade.offsetTime(ii)-min(eyeTrial.eyeTrace.timestamp), ...
        %             eyeTrial.eyeTrace.velFilt(eyeTrial.saccade.offsetI(ii)), ...
        %             [num2str(eyeTrial.saccade.amp(ii), '%2.0f'), 'deg, ', num2str(eyeTrial.saccade.duration(ii)*1000, '%3.0f'), 'ms'])
        %     end
%         legend([p1, p2], {'blink onset', 'blink offset'}, 'box', 'off', 'location', 'best')
    end 

    xlabel('Time (s)')
    ylabel('Filtered vertical gaze velocity (deg/s)')
    xlim(xRange)
    % ylim(yRange)
    hold off

    subplot(axSub(3)) % filtered gaze velocity plot
    plot(time, eyeTrial.eyeTrace.velOriWorldFilt2D)
    hold on
    plot(time, eyeTrial.eyeTrace.velOriHeadFilt2D, '--')
    % add fixation duration detected
    for ii = 1:length(eyeTrial.gazeFix.onsetTime)
        plot(time(eyeTrial.gazeFix.onsetI(ii):eyeTrial.gazeFix.offsetI(ii)), eyeTrial.eyeTrace.velOriWorldFilt2D(eyeTrial.gazeFix.onsetI(ii):eyeTrial.gazeFix.offsetI(ii)), 'k-')
    end
    %
    if ~isempty(eyeTrial.blink.onsetTime) % mark blinks if we have any
        p3 = plot(eyeTrial.blink.onsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.velOriWorldFilt2D(max([eyeTrial.blink.onsetI, ones(size(eyeTrial.blink.onsetI))], [], 2)), 'or');
        p4 = plot(eyeTrial.blink.offsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.velOriWorldFilt2D(...
            min([eyeTrial.blink.offsetI, ones(size(eyeTrial.blink.onsetI)).*length(eyeTrial.eyeTrace.velOriWorldFilt2D)], [], 2) ), 'og');
        %     for ii = 1:length(eyeTrial.saccade.offsetTime)
        %         text(eyeTrial.saccade.offsetTime(ii)-min(eyeTrial.eyeTrace.timestamp), ...
        %             eyeTrial.eyeTrace.velFilt(eyeTrial.saccade.offsetI(ii)), ...
        %             [num2str(eyeTrial.saccade.amp(ii), '%2.0f'), 'deg, ', num2str(eyeTrial.saccade.duration(ii)*1000, '%3.0f'), 'ms'])
        %     end
    end

    if ~isempty(eyeTrial.saccade.onsetTime) % mark saccades if we have any
        line([min(time), max(time)], [eyeTrial.saccade.sacThres, eyeTrial.saccade.sacThres], 'LineStyle', '--') % saccade threshold for finding peaks
        p1 = plot(eyeTrial.saccade.onsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.velOriWorldFilt2D(eyeTrial.saccade.onsetI), '*r');
        p2 = plot(eyeTrial.saccade.offsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.velOriWorldFilt2D(eyeTrial.saccade.offsetI), '*g');
        %     for ii = 1:length(eyeTrial.saccade.offsetTime)
        %         text(eyeTrial.saccade.offsetTime(ii)-min(eyeTrial.eyeTrace.timestamp), ...
        %             eyeTrial.eyeTrace.velFilt(eyeTrial.saccade.offsetI(ii)), ...
        %             [num2str(eyeTrial.saccade.amp(ii), '%2.0f'), 'deg, ', num2str(eyeTrial.saccade.duration(ii)*1000, '%3.0f'), 'ms'])
        %     end
        legend([p1, p2], {'saccade onset', 'saccade offset'}, 'box', 'off', 'location', 'best')
    end

    xlabel('Time (s)')
    ylabel('Filtered gaze 2D velocity (deg/s)')
    xlim(xRange)
    %     ylim(yRange)
    hold off

    %         subplot(axSub(3)) % filtered acceleration plot
    %         plot(time, eyeTrial.eyeTrace.accGazeFilt2D)
    %         hold on
    %         if ~isempty(eyeTrial.saccade.onsetTime) % mark saccades if we have any
    %             plot(eyeTrial.saccade.onsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.accGazeFilt2D(eyeTrial.saccade.onsetI), '*r')
    %             plot(eyeTrial.saccade.offsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.accGazeFilt2D(eyeTrial.saccade.offsetI), '*g')
    %             line([min(time), max(time)], [eyeTrial.saccade.baseAcc, eyeTrial.saccade.baseAcc], 'LineStyle', '--') % acceleration base threshold range
    %             line([min(time), max(time)], [-eyeTrial.saccade.baseAcc, -eyeTrial.saccade.baseAcc], 'LineStyle', '--') % acceleration base threshold range
    %         end
    %         xlabel('Time (s)')
    %         ylabel('Gaze-in-world 2D Acceleration (deg/s^2)')
    %         xlim(xRange)
    %         % ylim([-25000, 25000])
    %         hold off

elseif plotMode==1 % plot head velocity... maybe start with Euler angles...
    % calculate head velocity in Euler angles
    eulZYX = quat2eul([eyeTrial.headTrace.rotFiltQw eyeTrial.headTrace.rotFiltQx ...
        eyeTrial.headTrace.rotFiltQy eyeTrial.headTrace.rotFiltQz])/pi*180;
    
    subplot(axSub(1))
    plot(time, eulZYX(:, 3))
    %     p1 = plot(time, eyeTrial.eyeTrace.velOriHeadFiltX(:, 1), '-');
    %     hold on
    %     line([min(xRange), max(xRange)], [0, 0], 'lineStyle', '--')
    %     p2 = plot(time, eyeTrial.headTrace.displaceX(:, 1), '-');
    %     legend([p1, p2], {'eye-in-head', 'head offset'}, 'box', 'off', 'location', 'best')
    xlabel('Time (s)')
    %     ylabel('Horizontal velocity (deg/s)')
    ylabel('Head roll velocity (deg/s)')
    xlim(xRange)
    %     ylim(yRange)
    hold off

    subplot(axSub(2))
    plot(time, eulZYX(:, 2))
    %     p1 = plot(time, eyeTrial.eyeTrace.velOriHeadFiltY(:, 1), '-');
    %     hold on
    %     line([min(xRange), max(xRange)], [0, 0], 'lineStyle', '--')
    %     p2 = plot(time, eyeTrial.headTrace.displaceY(:, 1), '-');
    %     legend([p1 p2], {'eye-in-head', 'head offset'}, 'box', 'off', 'location', 'best')
    xlabel('Time (s)')
    %     ylabel('Vertical velocity (deg/s)')
    ylabel('Head pitch velocity (deg/s)')
    xlim(xRange)
    %     ylim(yRange)
    hold off

    subplot(axSub(3))
    plot(time, eulZYX(:, 1))
    %     p1 = plot(time, eyeTrial.eyeTrace.velOriHeadFilt2D(:, 1), '-');
    %     hold on
    %     line([min(xRange), max(xRange)], [0, 0], 'lineStyle', '--')
    %     p2 = plot(time, eyeTrial.headTrace.displace2D(:, 1), '-');
    %     legend([p1 p2], {'eye-in-head', 'head offset'}, 'box', 'off', 'location', 'best')
    xlabel('Time (s)')
    ylabel('Head yaw velocity (deg/s)')
    %     ylabel('2D velocity (deg/s)')
    xlim(xRange)
    %     ylim(yRange)
    hold off



    %     plot(time, eyeTrial.VOR.gain, 'k--')
    %     p1 = plot(time, eyeTrial.eyeTrace.velHeadFilt2D(:, 1), '-');
    %     p1 = plot(time, eyeTrial.VOR.gainAmp, '-');
%     plot(time, eyeTrial.VOR.gainDir, 'k-');
%     hold on
%     %     p2 = plot(time, sqrt(sum(eyeTrial.headTrace.displaceX.^2+eyeTrial.headTrace.displaceY.^2, 2)), '-');
%     %     p3 = plot(time, eyeTrial.VOR.gainAmp.*eyeTrial.VOR.gainDir, '-');
% 
%     line([min(xRange), max(xRange)], [1, 1], 'lineStyle', '-')
%     line([min(xRange), max(xRange)], [eyeTrial.VOR.thresGain, eyeTrial.VOR.thresGain], 'lineStyle', '--')
%     %     line([min(xRange), max(xRange)], [2, 2], 'lineStyle', '--')
%     % add fixation duration detected
%     for ii = 1:length(eyeTrial.gazeFix.onsetTime)
%         plot(time(eyeTrial.gazeFix.onsetI(ii):eyeTrial.gazeFix.offsetI(ii)), eyeTrial.VOR.gainDir(eyeTrial.gazeFix.onsetI(ii):eyeTrial.gazeFix.offsetI(ii)), 'b-')
%     end
% 
%     for ii = 1:length(eyeTrial.VOR.onsetTime)
%         plot(time(eyeTrial.VOR.onsetI(ii):eyeTrial.VOR.offsetI(ii)), eyeTrial.VOR.gainDir(eyeTrial.VOR.onsetI(ii):eyeTrial.VOR.offsetI(ii)), 'r--')
%     end
%     %     idx = find(eyeTrial.classID==4.2);
%     %     scatter(time(idx), eyeTrial.VOR.gain(idx), 'MarkerFaceColor','r')
%     %     legend([p1 p2 p3], {'gain amp', 'gain dir', 'gain multiply'}, 'box', 'off', 'location', 'best')
%     xlabel('Time (s)')
%     ylabel('VOR gain') %
%     xlim(xRange)
%     ylim([-5, 5])
%     hold off

    %     % plot position traces with saccades
    %     % look at x, y, and 2d at the same time, just redraw in the current subplots
    %     subplot(axSub(1))
    %     plot(time, eyeTrial.eyeTrace.posRaw(:, 1), '--')
    %     hold on
    %     plot(time, eyeTrial.eyeTrace.posFilt(:, 1), '-')
    % %     plot(eyeTrial.saccade.onsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.onsetI, 1), '*y')
    % %     plot(eyeTrial.saccade.offsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.offsetI, 1), '*g')
    % %     legend({'raw position', 'filtered position', 'saccade onset', 'saccade offset'}, 'box', 'off', 'location', 'best')
    %     xlabel('Time (s)')
    %     ylabel('X position')
    %     hold off
    %
    %     subplot(axSub(2))
    %     plot(time, eyeTrial.eyeTrace.posRaw(:, 2), '--')
    %     hold on
    %     plot(time, eyeTrial.eyeTrace.posFilt(:, 2), '-')
    % %     plot(eyeTrial.saccade.onsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.onsetI, 2), '*y')
    % %     plot(eyeTrial.saccade.offsetTime-min(eyeTrial.eyeTrace.timestamp), eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.offsetI, 2), '*g')
    %     xlabel('Time (s)')
    %     ylabel('Y position')
    %     hold off
    %
    %     subplot(axSub(3))
    %     plot(eyeTrial.eyeTrace.posRaw(:, 1), eyeTrial.eyeTrace.posRaw(:, 2), '--o')
    %     hold on
    %     plot(eyeTrial.eyeTrace.posFilt(:, 1), eyeTrial.eyeTrace.posFilt(:, 2), '-o')
    % %     plot(eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.onsetI, 1), eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.onsetI, 2), '*y', 'MarkerSize', 5);
    % %     plot(eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.offsetI, 1), eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.offsetI, 2), '*g', 'MarkerSize', 5);
    %     % add number to saccade onsets & offsets so it's easier to recognize
    % %     for ii = 1:length(eyeTrial.saccade.onsetI)
    % %         text(eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.onsetI(ii), 1), ...
    % %             eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.onsetI(ii), 2), ...
    % %             [num2str(ii, '%2.0f')])
    % %         text(eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.offsetI(ii), 1), ...
    % %             eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.offsetI(ii), 2), ...
    % %             [num2str(ii, '%2.0f')])
    % %     end
    %     xlabel('X position')
    %     ylabel('Y position')
    %     hold off

elseif plotMode==2 % plots with raw & filtered velocity trace after getEyeTrace.m
    % might also be useful when you have multiple filters and you want to check
    % if each makes sense, or if acceleration looks good, edit as you need
    subplot(axSub(1))
%     plot(time, eyeTrial.eyeAligned.gazeOriHeadX, '-')
    plot(time, eyeTrial.eyeTrace.velOriHeadRawX, '-')
    hold on
    plot(time, eyeTrial.eyeTrace.velOriHeadFiltX, '--')
% plot(time, eyeTrial.eyeTrace.gazeOriHeadFiltX, '--')
    legend({'Raw velocity', 'Filtered velocity'}) % now showing the eye-in-head velocities
    xlabel('Time (s)')
    ylabel('Vel from filtered horizontal pos (deg/s)')
    xlim(xRange)
    hold off

    subplot(axSub(2))
    plot(time, eyeTrial.eyeTrace.velOriHeadRawY, '-')
% plot(time, eyeTrial.eyeAligned.gazeOriHeadY, '-')
    hold on
    plot(time, eyeTrial.eyeTrace.velOriHeadFiltY, '--')
% plot(time, eyeTrial.eyeTrace.gazeOriHeadFiltY, '--')
    legend({'Raw velocity', 'Filtered velocity'})
    xlabel('Time (s)')
    ylabel('Vel from filtered vertical pos (deg/s)')
    xlim(xRange)
    hold off

    subplot(axSub(3))
    plot(time, eyeTrial.eyeTrace.velOriHeadRaw2D, '-')
    hold on
    plot(time, eyeTrial.eyeTrace.velOriHeadFilt2D, '--')
    legend({'Raw velocity', 'Filtered velocity'})
    xlabel('Time (s)')
%     ylabel('2D velocity (deg/s)')
    xlim(xRange)
    hold off

elseif plotMode==3 % open a new figure for 2d position data only, can see better in this case rather than the subplots
    set(0, 'units', 'pixels')
    screenSize = get(groot,'ScreenSize'); % or specify which screen you are using
    figPosition = [25 50 screenSize(3)-900, screenSize(4)-150]; % define how large your figure is on the screen
    figure('Position', figPosition); % open a new figure as the suplots are not suitable for the 2d position trace
    plot(eyeTrial.eyeTrace.posRaw(:, 1), eyeTrial.eyeTrace.posRaw(:, 2), '--o')
    hold on
    plot(eyeTrial.eyeTrace.posFilt(:, 1), eyeTrial.eyeTrace.posFilt(:, 2), '-o')
    plot(eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.onsetI, 1), eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.onsetI, 2), '*y', 'MarkerSize', 5);
    plot(eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.offsetI, 1), eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.offsetI, 2), '*g', 'MarkerSize', 5);
    % add number to saccade onsets & offsets so it's easier to recognize
    for ii = 1:length(eyeTrial.saccade.onsetI)
        text(eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.onsetI(ii), 1), ...
            eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.onsetI(ii), 2), ...
            [num2str(ii, '%2.0f')])
        text(eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.offsetI(ii), 1), ...
            eyeTrial.eyeTrace.posFilt(eyeTrial.saccade.offsetI(ii), 2), ...
            [num2str(ii, '%2.0f')])
    end
    legend({'raw position', 'filtered position', 'saccade onset', 'saccade offset'}, 'box', 'off', 'location', 'best')
    hold off
else
    close all
    disp('Error: non-existing plot mode!')
end
