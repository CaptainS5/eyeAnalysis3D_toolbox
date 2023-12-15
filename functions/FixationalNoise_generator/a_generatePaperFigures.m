

% NieZemBeeHol Figure 5
if 1
    dist        = 'gauss';
    N           = 100;
    RMS_STDs    = [0.09 0.2:0.25:1.7 1.91];
    magnitudes  = [0.2:0.2:1];
    AR          = 1;
    rotAng      = 0;
    
    % Gaussian
    genFun = @(x) randn(1,x);
    
    generatedNoise  = cell(length(magnitudes),length(RMS_STDs));
    
    for p=1:length(magnitudes)
        for q=1:length(RMS_STDs)
            generatedNoise{p,q} = genNoise(N,'Gauss',genFun,RMS_STDs(q),magnitudes(p),AR,rotAng);
        end
    end
    
    
    % some further processing for plot:
    % scale uniformly and arbitrarily so that range of largest bit of data is 1
    sFac = cellfun(@(x) max([range(x(1,:)) range(x(2,:))]),generatedNoise);
    generatedNoise  = cellfun(@(x) x./max(sFac(:)),generatedNoise,'uni',false);
    
    % plot
    f=figure('Units','normalized'); hold on
    f.Position = [0.2 f.Position(2)-.2 0.8 f.Position(4)+.1];
    voffs = [1 .45 .55 .85 .95];
    for p=1:size(generatedNoise,1)
        voff = sum(voffs(1:p));
        for q=1:size(generatedNoise,2)
            plot(q+[generatedNoise{p,q}(1,:) generatedNoise{p,q}(1,1)],voff+[generatedNoise{p,q}(2,:) generatedNoise{p,q}(2,1)],'k')   % close the shape
        end
    end
    axis equal
    ax=gca;
    ax.XTick = [1:size(generatedNoise,2)];
    ax.YTick = cumsum(voffs);
    ax.XTickLabel = arrayfun(@(x) sprintf('%.2f',x),RMS_STDs,'uni',false);
    ax.YTickLabel = arrayfun(@(x) sprintf('%.1f',x),magnitudes,'uni',false);
    xlabel('signal type')
    ylabel('signal magnitude (°)')
    if ~isfolder('results')
        mkdir('results')
    end
    print(f,'results/NieZemBeeHol_fig5.png','-dpng','-r300');
    print(f,'results/NieZemBeeHol_fig5'    ,'-depsc');
end


% NieZemBeeHol Figure 6a, 6b, 6c
if 1
    N           = 200;
    nSamp       = 6;
    RMS_STDs    = linspace(0.1,1.9,nSamp);
    magnitudes  = [0.2:0.2:1];
    AR          = 1;
    rotAng      = 0;
    
    
    generatedNoise  = cell(length(magnitudes),length(RMS_STDs),3);
    
    for d=1:3
        % choose distribution
        switch d
            case 1
                % Gaussian
                genFun = @(x) randn(1,x);
                lbl = 'Gauss';
            case 2
                % uniform
                genFun = @(x) rand(1,x);
                lbl = 'uniform';
            case 3
                % empirical cdf
                % TX 300 data, distance from mean pos during window, in deg
                dat = load('TX300noise');
                % pool X and Y for all eyes of all subjects
                lefts  = [dat.dat.left];
                rights = [dat.dat.right];
                dat = cat(1,lefts.pos,rights.pos);
                dat = sort(dat(:)).';
                dat(isnan(dat)) = [];
                genFun = @(x) dat(floor(rand(1,x)*length(dat))+1);
                lbl = 'eCDF_TX300';
        end
        
        for p=1:length(magnitudes)
            for q=1:length(RMS_STDs)
                generatedNoise{p,q,d} = genNoise(N,lbl,genFun,RMS_STDs(q),magnitudes(p),AR,rotAng);
            end
        end
    end
    
    % some further processing for plot:
    % scale uniformly and arbitrarily so that range of largest bit of data is 1
    sFac = cellfun(@(x) max([range(x(1,:)) range(x(2,:))]),generatedNoise);
    generatedNoise  = cellfun(@(x) x./max(sFac(:)),generatedNoise,'uni',false);
    
    % plot
    lbls = {'a','b','c'};
    axs = gobjects(1,3);
    fs  = gobjects(1,3);
    for d=1:3
        f=figure('Units','normalized'); hold on
        fs(d) = f;
        f.Position = [0.2 f.Position(2)-.2 0.52 f.Position(4)];
        voffs = [1 .35 .55 .70 .80];
        for p=1:size(generatedNoise,1)
            voff = sum(voffs(1:p));
            for q=1:size(generatedNoise,2)
                plot(q+[generatedNoise{p,q,d}(1,:) generatedNoise{p,q,d}(1,1)],voff+[generatedNoise{p,q,d}(2,:) generatedNoise{p,q,d}(2,1)],'k')   % close the shape
            end
        end
        axis equal
        ax=gca;
        axs(d)=ax;
        ax.XTick = [1:size(generatedNoise,2)];
        ax.YTick = cumsum(voffs);
        ax.XTickLabel = arrayfun(@(x) sprintf('%.2f',x),RMS_STDs,'uni',false);
        ax.YTickLabel = arrayfun(@(x) sprintf('%.1f',x),magnitudes,'uni',false);
        ax.XAxis.FontSize = 12;
        ax.XAxis.Label.FontSize = 14;
        ax.YAxis.FontSize = 12;
        ax.YAxis.Label.FontSize = 14;
        ax.Position(2) = ax.Position(2)+0.03;
        xlabel('signal type')
        ylabel('signal magnitude (°)')
        if ~isfolder('results')
            mkdir('results')
        end
    end
    xlims = cat(1,axs.XLim);
    [axs.XLim] = deal([min(xlims(:,1)) max(xlims(:,2))]);
    ylims = cat(1,axs.YLim);
    [axs.YLim] = deal([min(ylims(:,1)) max(ylims(:,2))]);
    for d=1:3
        print(fs(d),sprintf('results/NieZemBeeHol_fig6%s.png',lbls{d}),'-dpng','-r300');
        print(fs(d),sprintf('results/NieZemBeeHol_fig6%s'    ,lbls{d}),'-depsc');
    end
end


% NieZemBeeHol Figure 6d
if 1
    dist        = 'gauss';
    N           = 200;
    RMS_STDs    = linspace(0.1,1.9,nSamp);
    magnitudes  = [0.5];
    AR          = linspace(2,3.5,5);
    rotAng      = linspace(0,90,5);
    
    % Gaussian
    genFun = @(x) randn(1,x);
    
    generatedNoise  = cell(length(magnitudes),length(RMS_STDs));
    
    for p=1:length(AR)
        for q=1:length(RMS_STDs)
            generatedNoise{p,q} = genNoise(N,lbl,genFun,RMS_STDs(q),magnitudes,AR(p),rotAng(p));
        end
    end
    
    
    % some further processing for plot:
    % scale uniformly and arbitrarily so that range of largest bit of data is 1
    sFac = cellfun(@(x) max([range(x(1,:)) range(x(2,:))]),generatedNoise);
    generatedNoise  = cellfun(@(x) x./max(sFac(:)),generatedNoise,'uni',false);
    
    % plot
    f=figure('Units','normalized'); hold on
    f.Position = [0.2 f.Position(2)-.2 0.52 f.Position(4)];
    voffs = [1 .45 .55 .85 .95];
    for p=1:size(generatedNoise,1)
        voff = sum(voffs(1:p));
        for q=1:size(generatedNoise,2)
            generatedNoise{p,q} = [q+generatedNoise{p,q}(1,:); voff+generatedNoise{p,q}(2,:)];
            plot([generatedNoise{p,q}(1,:) generatedNoise{p,q}(1,1)],[generatedNoise{p,q}(2,:) generatedNoise{p,q}(2,1)],'k')   % close the shape
        end
    end
    axis equal
    ax=gca;
    ax.XTick = [1:size(generatedNoise,2)];
    ax.YTick = cumsum(voffs);
    ax.XTickLabel = arrayfun(@(x) sprintf('%.2f',x),RMS_STDs,'uni',false);
    ax.YTickLabel = arrayfun(@(x) sprintf('%.1f',x),AR,'uni',false);
    ax.XAxis.FontSize = 12;
    ax.XAxis.Label.FontSize = 14;
    ax.YAxis.FontSize = 12;
    ax.YAxis.Label.FontSize = 14;

    all = cat(2,generatedNoise{:});
    mins = min(all,[],2);
    maxs = max(all,[],2);
    rngs = maxs-mins;
    ax.XLim = [mins(1)-.02*rngs(1) maxs(1)+.02*rngs(1)];
    ax.YLim = [mins(2)-.02*rngs(2) maxs(2)+.02*rngs(2)];
    xlabel('signal type','interpreter','latex')
    ylabel('aspect ratio','Interpreter','LaTex')
    if ~isfolder('results')
        mkdir('results')
    end
    print(f,'results/NieZemBeeHol_fig6d.png','-dpng','-r300');
    print(f,'results/NieZemBeeHol_fig6d'    ,'-depsc');
end
