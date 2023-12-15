function plotGroupDistribution(figPosition, plotD, probType, xlabelName, titleNames, fileName, varargin)
% optional parameters: xRange, yRange, subplotGrid

% set parameters
if ~isempty(varargin)
    idx = find(strcmp(varargin, 'xRange'));
    if ~isempty(idx)
        xRange = varargin{idx+1};
    else
        xRange = [];
    end

    idx = find(strcmp(varargin, 'yRange'));
    if ~isempty(idx)
        yRange = varargin{idx+1};
    else
        yRange = [0 1];
    end

    idx = find(strcmp(varargin, 'subplotGrid'));
    if ~isempty(idx)
        subplotGrid = varargin{idx+1};
    else
        num = ceil(sqrt(length(plotD)));
        subplotGrid = [num num];
    end
else
    xRange = [];
    yRange = [0 1];
    num = ceil(sqrt(length(plotD)));
    subplotGrid = [num num];
end

fig = figure('Position', figPosition);
plotDAll = [];
for ii = 1:size(plotD, 1) % get individual task median and ranges
    plotDAll = [plotDAll; plotD{ii}];

    [values{ii}, edges{ii}] = histcounts(plotD{ii}, 'Normalization', probType);
    centers{ii} = (edges{ii}(1:end-1)+edges{ii}(2:end))/2;

    medianD(ii) = prctile(plotD{ii}, 50);
    yD(ii) = interp1(centers{ii}, values{ii}, medianD(ii));
    ciD(:, ii) = [prctile(plotD{ii}, 2.5); prctile(plotD{ii}, 97.5)];
end

% [values1, edges1] = histcounts(plotDAll, 'Normalization', probType);
% centers1 = (edges1(1:end-1)+edges1(2:end))/2;

% p1 = plot(centers1, values1, 'k-', 'linewidth', 1);
hold on

% % draw percentiles
% l1 = line([prctile(plotDAll, 25), prctile(plotDAll, 25)], [0, 1], ...
%     'lineStyle', '--', 'Color', [254,229,217]/255, 'lineWidth', 1.5);
% text(prctile(plotDAll, 25), 0.1, ...
%     [num2str(prctile(plotDAll, 25), '%.1f')], 'color', [254,229,217]/255, 'FontSize', 20)
% 
% l2 = line([prctile(plotDAll, 50), prctile(plotDAll, 50)], [0, 1], ...
%     'lineStyle', '--', 'Color', [252,174,145]/255, 'lineWidth', 1.5);%
% text(prctile(plotDAll, 50), 0.1, ...
%     [num2str(prctile(plotDAll, 50), '%.1f')], 'color', [252,174,145]/255, 'FontSize', 20)
% 
% l3 = line([prctile(plotDAll, 75), prctile(plotDAll, 75)], yRange, ...
%     'lineStyle', '--', 'Color', [251,106,74]/255, 'lineWidth', 1.5);
% text(prctile(plotDAll, 75), 0.1, ...
%     [num2str(prctile(plotDAll, 75), '%.1f')], 'color', [251,106,74]/255, 'FontSize', 20)
% 
% l4 = line([prctile(plotDAll, 95), prctile(plotDAll, 95)], yRange, ...
%     'lineStyle', '--', 'Color', [203,24,29]/255, 'lineWidth', 1.5);
% text(prctile(plotDAll, 95), 0.1, ...
%     [num2str(prctile(plotDAll, 95), '%.1f')], 'color', [203,24,29]/255, 'FontSize', 20)

% % draw percentiles
% l1 = line([prctile(plotDAll, 75), prctile(plotDAll, 75)], [0, 1], ...
%     'lineStyle', '--', 'Color', [254,229,217]/255, 'lineWidth', 1.5);
% text(prctile(plotDAll, 75), 0.15, ...
%     [num2str(prctile(plotDAll, 75), '%.1f')], 'color', [254,229,217]/255, 'FontSize', 20)
% 
% l2 = line([prctile(plotDAll, 50), prctile(plotDAll, 50)], [0, 1], ...
%     'lineStyle', '--', 'Color', [252,174,145]/255, 'lineWidth', 1.5);%
% text(prctile(plotDAll, 50), 0.15, ...
%     [num2str(prctile(plotDAll, 50), '%.1f')], 'color', [252,174,145]/255, 'FontSize', 20)
% 
% l3 = line([prctile(plotDAll, 25), prctile(plotDAll, 25)], yRange, ...
%     'lineStyle', '--', 'Color', [251,106,74]/255, 'lineWidth', 1.5);
% text(prctile(plotDAll, 25), 0.15, ...
%     [num2str(prctile(plotDAll, 25), '%.1f')], 'color', [251,106,74]/255, 'FontSize', 20)
% 
% l4 = line([prctile(plotDAll, 5), prctile(plotDAll, 5)], yRange, ...
%     'lineStyle', '--', 'Color', [203,24,29]/255, 'lineWidth', 1.5);
% text(prctile(plotDAll, 5), 0.15, ...
%     [num2str(prctile(plotDAll, 5), '%.1f')], 'color', [203,24,29]/255, 'FontSize', 20)

cmap = cbrewer('qual', 'Paired', length(plotD)+1);
idx = find(cmap(:, 1)==1 & cmap(:, 2)==1);
cmap(idx, :) = []; % light yellow that is hard to see

% cmap = [158,202,225; 66,146,198; 8,81,156; 8,48,107; ...
%     229,245,224; 199,233,192; 65,171,93; 0,109,44; ...
%     161,217,155; 0,68,27; 35,139,69; 116,196,118; ...
%     0, 0, 0]/255;

for ii = 1:length(plotD)
    l(ii) = plot(centers{ii}, values{ii}, '-', 'color', cmap(ii, :), 'LineWidth', 1);
    if ~strcmp(probType, 'CDF')
        eH(ii) = errorbar(medianD(ii), (0.25+0.005*ii)*ones(size(medianD(ii))), [], [], medianD(ii)-ciD(1, ii), ciD(2, ii)-medianD(ii), 'LineStyle', 'none', 'Color', cmap(ii, :), 'Marker','square', 'LineWidth', 1);
    else
        pc95(ii) = line([prctile(plotD{ii}, 95) prctile(plotD{ii}, 95)], [0, max(yRange)], 'LineStyle', '--', 'color', cmap(ii, :), 'LineWidth', 2);
        text(prctile(plotD{ii}, 95), (0.05+0.03*ii), [num2str(prctile(plotD{ii}, 95), '%.1f'), '°/s'], 'color', cmap(ii, :), 'FontSize', 20)
    end
    %     eH(ii) = errorbar(medianD(ii), yD(ii), [], [], medianD(ii)-ciD(1, ii), ciD(2, ii)-medianD(ii), 'LineStyle', 'none', 'Color', cmap(ii, :), 'Marker','square', 'LineWidth', 1);
end
% errorbar(medianD, yD, [], [], medianD-ciD(1, :), ciD(2, :)-medianD, 'LineStyle', 'none', 'Color', [53, 116, 140]/255, 'Marker','square');
xlim(xRange)
ylim(yRange)
xlabel(xlabelName)
ylabel(probType)
grid on
grid minor

% legend([l1 l2 l3 l4], {'25% percentile', '50% percentile', '75% percentile', '95% percentile'}, ...
%     'location', 'southeast', 'box', 'off')

set(gca, 'FontSize', 20, 'box', 'off')%, 'xdir', 'reverse')
grid on
grid minor

ah1=axes('position',get(gca,'position'),'visible','off');
legend(ah1, l(:), titleNames,'Location','NorthEast', 'box', 'off', 'FontSize', 20)

% % for depth, add diopter... 1/x(m)
% ax2 = axes;
% plot(ax2, [1:1:11], NaN(1, 11))
% xlabel('Gaze depth (diopter)')
% ax2.YAxis.Visible = 'off';
% set(ax2, 'XTickLabel', {'Inf', '2', '1', '0.67', '0.5', '0.4', '0.33', '0.29', '0.25', '0.22', '0.2'}, 'FontSize', 20)
% ax2.XAxisLocation = 'top';
% ax2.YAxisLocation = 'right';
% ax2.Color = 'none';
% ax2.Box = 'off';

% medianD
% if ~isempty(titleNames)
%     title(titleNames{ii})
% end
saveas(gcf, ['plots\', fileName, '_', probType, '.jpg'])
saveas(gcf, ['plots\', fileName, '_', probType, '.pdf'])

end