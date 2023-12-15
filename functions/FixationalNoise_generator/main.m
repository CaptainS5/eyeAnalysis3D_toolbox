% params
N           = 200;
RMS_STDs    = linspace(0.1,1.9,7);
magnitudes  = [0.2:0.2:1];
AR          = 1;
rotAng      = 0;


% choose distribution
switch 1
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

generatedNoise  = cell(length(magnitudes),length(RMS_STDs));

for p=1:length(magnitudes)
    for q=1:length(RMS_STDs)
        generatedNoise{p,q} = genNoise(N,lbl, genFun,RMS_STDs(q),magnitudes(p),AR,rotAng);
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
xlabel('$\frac{\mbox{RMS-S2S}}{\mbox{STD}}$','interpreter','latex')
ylabel('$\sqrt{\mbox{RMS-S2S}^2+\mbox{STD}^2}$ ($^\circ$)','Interpreter','LaTex')
