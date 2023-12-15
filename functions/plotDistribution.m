function plotDistribution(figPosition, plotD, probType, xlabelName, titleNames, fileName, database, varargin)
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
for ii = 1:size(plotD, 1)
    subplot(subplotGrid(1), subplotGrid(2), ii)

    for dfN = 1:length(probType)
        h1 = histogram(plotD{ii, 1}, 'Normalization', probType{dfN});
        [values{dfN, 1}, edges{dfN, 1}] = histcounts(plotD{ii, 1}, 'Normalization', probType{dfN});
        centers{dfN, 1} = (edges{dfN, 1}(1:end-1)+edges{dfN, 1}(2:end))/2;

        if size(plotD, 2)>1 && ~isempty(plotD{ii, 2}) % specifically for Rochester data, head fixed vs. head free
            h2 = histogram(plotD{ii, 2}, 'Normalization', probType{dfN});
            [values{dfN, 2}, edges{dfN, 2}] = histcounts(plotD{ii, 2}, 'Normalization', probType{dfN});
            centers{dfN, 2} = (edges{dfN, 2}(1:end-1)+edges{dfN, 2}(2:end))/2;
        end
    end

    p1 = plot(centers{1, 1}, values{1, 1}, 'k-', 'linewidth', 1);
    hold on
    % draw percentiles
    l1 = line([prctile(plotD{ii, 1}, 25), prctile(plotD{ii, 1}, 25)], yRange, ...
        'lineStyle', '--', 'Color', [254,229,217]/255, 'lineWidth', 1.5);
    text(prctile(plotD{ii, 1}, 25), 0.01, ...
        [num2str(prctile(plotD{ii, 1}, 25), '%.1f'), '°/s'], 'color', [254,229,217]/255, 'FontSize', 20)

    l2 = line([prctile(plotD{ii, 1}, 50), prctile(plotD{ii, 1}, 50)], yRange, ...
        'lineStyle', '--', 'Color', [252,174,145]/255, 'lineWidth', 1.5);% 
    text(prctile(plotD{ii, 1}, 50), 0.02, ...
        [num2str(prctile(plotD{ii, 1}, 50), '%.1f'), '°/s'], 'color', [252,174,145]/255, 'FontSize', 20)

    l3 = line([prctile(plotD{ii, 1}, 75), prctile(plotD{ii, 1}, 75)], yRange, ...
        'lineStyle', '--', 'Color', [251,106,74]/255, 'lineWidth', 1.5);
    text(prctile(plotD{ii, 1}, 75), 0.03, ...
        [num2str(prctile(plotD{ii, 1}, 75), '%.1f'), '°/s'], 'color', [251,106,74]/255, 'FontSize', 20)

    l4 = line([prctile(plotD{ii, 1}, 95), prctile(plotD{ii, 1}, 95)], yRange, ...
        'lineStyle', '--', 'Color', [203,24,29]/255, 'lineWidth', 1.5);
    text(prctile(plotD{ii, 1}, 95), 0.04, ...
        [num2str(prctile(plotD{ii, 1}, 95), '%.1f'), '°/s'], 'color', [203,24,29]/255, 'FontSize', 20)

    if ii==1
%         legend([l2, l4], {'50% percentile', '95% percentile'}, ...
%             'location', 'northeast')
legend([l1, l2, l3, l4], {'25% percentile', '50% percentile', '75% percentile', '95% percentile'}, ...
            'location', 'northeast')
    end

    if size(plotD, 2)>1 && ~isempty(plotD{ii, 2})
        p2 = plot(centers{1, 2}, values{1, 2}, 'k--', 'linewidth', 1);

%         line([prctile(plotD{ii, 2}, 50), prctile(plotD{ii, 2}, 50)], yRange, ...
%             'lineStyle', '--', 'Color', [252,174,145]/255, 'lineWidth', 1.5);%
%         text(prctile(plotD{ii, 2}, 50), 0.5, ...
%             [num2str(prctile(plotD{ii, 2}, 50), '%.1f'), '°/s'], 'color', [252,174,145]/255, 'FontSize', 20)
%         line([prctile(plotD{ii, 2}, 95), prctile(plotD{ii, 2}, 95)], yRange, ...
%             'lineStyle', '--', 'Color', [203,24,29]/255, 'lineWidth', 1.5);
%         text(prctile(plotD{ii, 2}, 95), 0.95, ...
%             [num2str(prctile(plotD{ii, 2}, 95), '%.1f'), '°/s'], 'color', [203,24,29]/255, 'FontSize', 20)

        % create legend
        if ii==1
            legend([p1 p2 l2 l4], {'head free', 'head fixed', '50% percentile', '95% percentile'}, 'location', 'northeast', 'box', 'off')
        end
    end

    if ~isempty(titleNames)
        title(titleNames{ii})
    end
    if ~isempty(xRange) && ~(strcmp(database, 'Rochester') && strcmp(fileName, 'fixDur'))
        xlim(xRange)
    end
    ylim(yRange)
    xlabel(xlabelName)
    ylabel(probType{1})

    if length(probType)==2 % second y axis
        yyaxis right
        p5 = plot(centers{2, 1}, values{2, 1}, 'b-', 'linewidth', 1);

        if size(plotD, 2)>1 && ~isempty(plotD{ii, 2})
            p6 = plot(centers{2, 2}, values{2, 2}, 'b--', 'linewidth', 1);
        end
        ax = gca;
        ax.YAxis(2).Color = 'b';
        ylabel(probType{2})
        ylim([0, 1])
    end

    hold off
    grid on
    grid minor
    set(gca, 'FontSize', 15)
end

if length(probType)==2
    saveas(gcf, ['plots\', fileName, '_bothDF_headCom_', database, '.jpg'])
    saveas(gcf, ['plots\', fileName, '_bothDF_headCom', database, '.pdf'])
%     saveas(gcf, ['plots\appendix\', fileName, '_bothDF_', database, '.jpg'])
%     saveas(gcf, ['plots\appendix\', fileName, '_bothDF_', database, '.pdf'])
else
    saveas(gcf, ['plots\', fileName, '_', probType{1}, '_', database, '.jpg'])
    saveas(gcf, ['plots\', fileName, '_', probType{1}, '_', database, '.pdf'])
end

end