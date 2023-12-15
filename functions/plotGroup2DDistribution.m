function plotGroup2DDistribution(figPosition, plotD, xlabelName, ylabelName, legendNames, fileName, varargin)
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
for ii = 1:size(plotD, 1) % get individual task median and ranges
    medianX(ii) = prctile(plotD{ii}(:, 1), 50);
    ciX(:, ii) = [prctile(plotD{ii}(:, 1), 2.5); prctile(plotD{ii}(:, 1), 97.5)];

    medianY(ii) = prctile(plotD{ii}(:, 2), 50);
    ciY(:, ii) = [prctile(plotD{ii}(:, 2), 2.5); prctile(plotD{ii}(:, 2), 97.5)];
end

hold on

% cmap = cbrewer('qual', 'Paired', length(plotD)+1);
% idx = find(cmap(:, 1)==1 & cmap(:, 2)==1);
% cmap(idx, :) = []; % light yellow that is hard to see
cmap = cbrewer('qual', 'Set1', 5);

for ii = 1:size(plotD, 1)
    if ii<=5
        eH(ii) = errorbar(medianX(ii), medianY(ii), medianY(ii)-ciY(1, ii), ciY(2, ii)-medianY(ii), medianX(ii)-ciX(1, ii), ciX(2, ii)-medianX(ii), ...
            'LineStyle', 'none', 'Color', cmap(ii, :), 'Marker','square', 'LineWidth', 1, 'MarkerSize', 20);
    else
        eH(ii) = errorbar(medianX(ii), medianY(ii), medianY(ii)-ciY(1, ii), ciY(2, ii)-medianY(ii), medianX(ii)-ciX(1, ii), ciX(2, ii)-medianX(ii), ...
            'LineStyle', 'none', 'Color', cmap(ii-5, :), 'Marker','*', 'LineWidth', 1, 'MarkerSize', 20);
    end
    %     text(medianX(ii), medianY(ii), [num2str(length(plotD{ii})) ' saccades'], 'Color', cmap(ii, :))
end
% errorbar(medianD, yD, [], [], medianD-ciD(1, :), ciD(2, :)-medianD, 'LineStyle', 'none', 'Color', [53, 116, 140]/255, 'Marker','square');
xlim(xRange)
ylim(yRange)
xlabel(xlabelName)
ylabel(ylabelName)
set(gca, 'FontSize', 20, 'box', 'off')%, 'xdir', 'reverse')
grid on
grid minor

legend(eH(:), legendNames,'Location','NorthEast', 'box', 'off', 'FontSize', 20)

% medianD
% if ~isempty(titleNames)
%     title(titleNames{ii})
% end
saveas(gcf, ['plots\', fileName, '.jpg'])
saveas(gcf, ['plots\', fileName, '.pdf'])

end