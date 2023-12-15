function plotHeatmap(figPosition, plotD, gridX, gridY, xlabelName, ylabelName, titleNames, fileName, database, varargin)
% optional parameters: cmap, subplotGrid

% set parameters
if ~isempty(varargin) 
    idx = find(strcmp(varargin, 'cmap'));
    if ~isempty(idx)
        cmap = varargin{idx+1};
    else
        cmap = [];
    end

    idx = find(strcmp(varargin, 'subplotGrid'));
    if ~isempty(idx)
        subplotGrid = varargin{idx+1};
    else
        num = ceil(sqrt(length(plotD)));
        subplotGrid = [num num];
    end
else
    cmap = [];
    num = ceil(sqrt(length(plotD)));
    subplotGrid = [num num];
end

density = {};
% xy = [gridX(:), gridY(:)];
% edges{1} = gridX(1, :)';
% edges{2} = gridY(:, 1);

fig = figure('Position', figPosition);

for ii = 1:length(plotD)
    subplot(subplotGrid(1), subplotGrid(2), ii)

    %     % using ksdensity, but doesn't look good...
    %     denT = ksdensity(plotD{ii}, xy);
    %     density{ii} = reshape(denT, size(gridX));
    % [c, h] = contour(gridX, gridY, density{ii},'LineColor','none');
    
    h = histogram2(plotD{ii}(:, 1), plotD{ii}(:, 2), gridX(1, :)', gridY(:, 1), 'Normalization', 'probability');
    xbinPos = (gridX(1, 1:end-1)'+gridX(1, 2:end)')/2;
    ybinPos = (gridY(1:end-1, 1)+gridY(2:end, 1))/2;
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

    % add histograms?

    title(titleNames{ii})
    xlabel(xlabelName)
    ylabel(ylabelName)
    axis square

    hold off
end

saveas(gcf, ['plots\', fileName, '_heatmap_', database, '.pdf'])

end