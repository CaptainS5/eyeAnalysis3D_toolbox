nSamp = 500;
start = 6;
nRep  = 1000;

RMS_STDs    = [.25 .5 .9 sqrt(2) 1.75];
magnitude   = 0.5;
refs        = [12 24 50 60 200];
genFun      = @(x) randn(1,x);
lbl         = 'Gauss';

theFields   = {
    'RMS_STD',  'signal type', 1.8
    'PSDSlope' ,'scaling exponent ($\alpha$)', nan
    'RMS',      '$\mbox{RMS-S2S}$ ($^\circ$)', 0.45
    'STD',      '$\mbox{STD}$ ($^\circ$)', 0.5
    'rBCEA'    ,'$\sqrt{\mbox{BCEA}}$ ($^{\circ}$)', 0.9
    'lenRMSSTD','signal magnitude ($^\circ$)', 0.52
    };

if 0    % recalc measures
    if 0    % regen samples
        
        %% step 1: generate noise nRep times for each window length
        allSamp = cell(nSamp-start+1,length(RMS_STDs),nRep);
        for s=start:nSamp-1
            fprintf('nSamp: %d\n',s);
            for f=1:length(RMS_STDs)
                for r=1:nRep
                    % generate noise
                    xy = genNoise(nSamp,'Gauss',genFun,RMS_STDs(f),magnitude,1,0);
                    % store random subpart of it
                    sidx = floor(rand()*(nSamp-s))+1;
                    allSamp{s-start+1,f,r} = xy(:,sidx:sidx+s-1);
                end
            end
        end
        save allSamp allSamp -v7.3
    else
        load allSamp
    end
    
    %% step 2: calculate measures for each
    % get means, stds and std errs. Which of the latter two makes more sense?
    temp = Interleave(theFields(:,1).',repmat({nan(size(allSamp))},1,size(theFields,1)));
    myStr = struct(temp{:});
    allMeasures = myStr;
    
    for s=1:nSamp-start
        fprintf('nSamp: %d\n',s+start-1);
        for f=1:length(RMS_STDs)
            for r=1:nRep
                dataSel = allSamp{s,f,r}.';
                % 1. RMS
                allMeasures.RMS(s,f,r)      = sqrt(mean(diff(dataSel(:,1)).^2 + diff(dataSel(:,2)).^2));
                
                % 2. STD
                allMeasures.STD(s,f,r)      = sqrt(var(dataSel(:,1)) + var(dataSel(:,2)));
                
                % 3. RMS/STD
                allMeasures.RMS_STD(s,f,r)  = allMeasures.RMS(s,f,r)/allMeasures.STD(s,f,r);
                
                % 4. hypot(RMS,STD)
                allMeasures.lenRMSSTD(s,f,r)= hypot(allMeasures.RMS(s,f,r),allMeasures.STD(s,f,r));
                
                % 5. BCEA direct by formula
                stdx = std(dataSel(:,1));
                stdy = std(dataSel(:,2));
                xx   = corrcoef(dataSel(:,1),dataSel(:,2));
                rho  = xx(1,2);
                P    = 0.68; % cumulative probability of area under the multivariate normal
                k    = log(1/(1-P));
                allMeasures.BCEAarea(s,f,r)  = 2*k*pi*stdx*stdy*sqrt(1-rho.^2);
                
                % 6. periodogram, get slope
                nfft        = size(dataSel,1);      % no zero padding
                dataPSD     = bsxfun(@minus,dataSel,mean(dataSel,1));   % remove DC
                [psdx,fpsd] = periodogram(dataPSD(:,1),[],nfft);
                psdy        = periodogram(dataPSD(:,2),[],nfft);
                % fit line
                linFitX     = polyfit(log(fpsd(2:end-1)),log(mean([psdx(2:end-1) psdy(2:end-1)],2)),1);
                % output: [x DC], x is what we want
                allMeasures.PSDSlope(s,f,r) = -linFitX(1);
            end
        end
    end
    save allMeasures allMeasures -v7.3
else
    load allMeasures
end

%% step 3: get mean etc for these measures
sz = size(allMeasures.RMS);
allMeasures.rBCEA = sqrt(allMeasures.BCEAarea);
temp = Interleave(theFields(:,1).',repmat({nan([sz(1) sz(2)])},1,size(theFields,1)));
myStr = struct(temp{:});
[means,stds,sensitivity] = deal(myStr);
for f=1:size(theFields,1)
    means.(theFields{f,1})      = nanmean(allMeasures.(theFields{f,1}),3);
    stds.(theFields{f,1})       = nanstd(allMeasures.(theFields{f,1}),[],3);
end

%% final publication figure
fig=figure('Units','normalized','Position',[0 .1 1 0.7]);
legs = arrayfun(@(x) sprintf('%.2f',x),RMS_STDs,'uni',false);
meas = 'Mean';
allWinlengths = start:nSamp-1;
for f=1:size(theFields,1)
    ax(f) = subplot(2,3,f);
    
    set(ax(f),'FontSize',12)
    ax(f).XAxis.LineWidth = 1.5;
    ax(f).YAxis.LineWidth = 1.5;
    ax(f).YAxis.TickLabelFormat = '%.1f';
    ax(f).YAxis.FontName = 'Arial';
    
    if f>size(theFields,1)/2
        xlabel('window length (number of samples)','Interpreter','LaTex')
    end
    ylabel(theFields{f,2},'Interpreter','LaTex')
    title(theFields{f,2},'Interpreter','LaTex')
    set(gca, 'box', 'off')
    xlim([0 500])
    
    hold on
    theMax = max(means.(theFields{f,1})(:));
    theMin = min(means.(theFields{f,1})(:));
    if theMin > 0, theMin = 0; end
    if ~isnan(theFields{f,3}) && strcmp(meas,'Mean')
        ylim([0 theFields{f,3}])
    else
        ylim(1.05*[theMin theMax]);
    end
    for r=1:length(refs)
        plot(refs([r r]),ylim(),'--','Color',[.5 .5 .5])
    end
    hs = plot(allWinlengths,means.(theFields{f,1}),'LineWidth',2);
    
    if f==6
        lh=legend(hs,legs{:},'Location','SouthEast');
        legend boxoff
        lh.FontSize = 10;
        text(370,0.25,sprintf('signal type\nasymptote'),'HorizontalAlignment','left','VerticalAlignment','bottom','FontName',ax(f).YAxis.Label.FontName,'FontSize',11);
    end
end
print(fig,fullfile(cd,'results','NieZemBeeHol_fig7.png'),'-dpng','-r300');
print(fig,fullfile(cd,'results','NieZemBeeHol_fig7'    ),'-depsc')
