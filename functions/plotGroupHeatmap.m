function plotGroupHeatmap(figPosition, plotD, gridX, gridY, xlabelName, ylabelName, groupNames, fileName, type, varargin)
% optional parameters: cmap

% set parameters
if ~isempty(varargin)
    idx = find(strcmp(varargin, 'cmap'));
    if ~isempty(idx)
        cmap = varargin{idx+1};
    else
        cmap = [];
    end
else
    cmap = [];
    num = ceil(sqrt(length(plotD)));
end

density = {};
% xy = [gridX(:), gridY(:)];
% edges{1} = gridX(1, :)';
% edges{2} = gridY(:, 1);

for ii = 1:length(plotD)
    fig = figure('Position', figPosition);

    %% plot countour
    if type==1 % orientation
        axC = axes('InnerPosition', [0.1 0.1 0.5 0.6]); % ori
        rangeP = [2.5, 97.5];
    elseif type==2 % velocity
        axC = axes('InnerPosition', [0.1 0.1 0.6 0.6]); % vel
        rangeP = [12.5, 87.5];
    elseif type==3
        axC = axes('InnerPosition', [0.1 0.1 0.6 0.6]); % vel
        rangeP = [2.5, 97.5];
    end

    axes(axC)
    % calculate 2D and marginal histograms
    h = histogram2(plotD{ii}(:, 1), plotD{ii}(:, 2), gridX(1, :)', gridY(:, 1), 'Normalization', 'probability');
    xbinPos = (gridX(1, 1:end-1)'+gridX(1, 2:end)')/2;
    ybinPos = (gridY(1:end-1, 1)+gridY(2:end, 1))/2;
    values = h.Values;

    contour(xbinPos, ybinPos, h.Values','LineColor','none');
    set(findobj(get(gca,'children'),'type','contour'),'Fill','on')
    if ~isempty(cmap)
        colormap(cmap)
    end
    %     clim([0 max(levels)])
    contourcbar 
    hold on

    line([0 0], [min(gridY(:)) max(gridY(:))], 'LineStyle', '--', 'Color', 'k')
    line([min(gridX(:)) max(gridX(:))], [0 0], 'LineStyle', '--', 'Color', 'k')

%     % add percentile lines
%     for ii = 1:length(xbinPos)
%         yP(ii, :) = [prctile(plotD{ii}(:, 1), rangeP(1)), prctile(plotD{ii}(:, 1), 50), prctile(plotD{ii}(:, 1), rangeP(2))];
%     end
%     for ii = 1:length(ybinPos)
%         xP(ii, :) = ;
%     end

    xlabel(xlabelName)
    ylabel(ylabelName)
    set(gca, 'FontSize', 20)
    if type<=2
        axis equal
    else
        axis square
    end
    hold off
       

    %% plot first marginal histogram
    axH1 = axes('InnerPosition', [0.1 0.7 axC.InnerPosition(3) 0.15]); % head Ori
    axes(axH1)
    histogram(plotD{ii}(:, 1), gridX(1, :)', 'Normalization', 'probability', ...
        'DisplayStyle','stairs', 'LineWidth', 1)
    box off

    yRange = axH1.YLim;
    hold on
    l1 = line([prctile(plotD{ii}(:, 1), 50), prctile(plotD{ii}(:, 1), 50)], yRange, ...
        'lineStyle', '--', 'Color', [252,174,145]/255, 'lineWidth', 1.5);
    l2 = line([prctile(plotD{ii}(:, 1), rangeP(1)), prctile(plotD{ii}(:, 1), rangeP(1))], yRange, ...
        'lineStyle', '--', 'Color', [203,24,29]/255, 'lineWidth', 1.5);
    l3 = line([prctile(plotD{ii}(:, 1), rangeP(2)), prctile(plotD{ii}(:, 1), rangeP(2))], yRange, ...
        'lineStyle', '--', 'Color', [203,24,29]/255, 'lineWidth', 1.5);
    legend([l1, l2], {'median', [num2str(range(rangeP)), '% range']})

    hold off
    
    xlim([min(gridX(:)) max(gridX(:))])
    ylabel('Probability')
    set(gca, 'FontSize', 20, 'XTick', [])
    title(groupNames{ii})

    %% plot second marginal histogram
    if type==1
        axH2 = axes('InnerPosition', [0.7 0.1 0.15 axC.InnerPosition(3)/range(gridX(:))*range(gridY(:))]); % ori
    elseif type==2
        axH2 = axes('InnerPosition', [0.8 0.1 0.15 axC.InnerPosition(3)/range(gridX(:))*range(gridY(:))]); % vel
    elseif type==3
        axH2 = axes('InnerPosition', [0.8 0.1 0.15 axC.InnerPosition(3)]); % vel
    end

    axes(axH2)
    histogram(plotD{ii}(:, 2), gridY(:, 1), 'Normalization', 'probability', ...
        'DisplayStyle','stairs', 'LineWidth', 1)
    box off

    yRange = axH2.YLim;
    hold on
    l1 = line([prctile(plotD{ii}(:, 2), 50), prctile(plotD{ii}(:, 2), 50)], yRange, ...
        'lineStyle', '--', 'Color', [252,174,145]/255, 'lineWidth', 1.5);
    l2 = line([prctile(plotD{ii}(:, 2), rangeP(1)), prctile(plotD{ii}(:, 2), rangeP(1))], yRange, ...
        'lineStyle', '--', 'Color', [203,24,29]/255, 'lineWidth', 1.5);
    l3 = line([prctile(plotD{ii}(:, 2), rangeP(2)), prctile(plotD{ii}(:, 2), rangeP(2))], yRange, ...
        'lineStyle', '--', 'Color', [203,24,29]/255, 'lineWidth', 1.5);
    hold off

    xlim([min(gridY(:)) max(gridY(:))])
    ylabel('Probability')
    set(gca, 'FontSize', 20)
    view([90 -90])

    saveas(gcf, ['plots\', fileName, '_', groupNames{ii}, '_heatmap.jpg'])
    saveas(gcf, ['plots\', fileName, '_', groupNames{ii}, '_heatmap.pdf'])
end
end