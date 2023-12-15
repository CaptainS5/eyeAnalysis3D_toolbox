function [params, CI, idxOutliers] = fitMainSequence(amp, peakVel)
% fit the main sequence, and find outlier saccades outside of the 95% CI

% % sqrt... somehow super small CI???
% funFit = fittype({'sqrt(x)'});
% f = fit(amp, peakVel, funFit);
% params.V = f.a;
% CI = confint(f);

% power function, peakVel = K*amp^L
fo = fitoptions('Method', 'NonlinearLeastSquares', 'Lower',[-inf, 0]);
ft = fittype(@(a, b, x) a*x.^b, 'options', fo);
f = fit(amp, peakVel, ft);
params.K = f.a;
params.L = f.b;
CI = confint(f); % first column is a, second column is b, first row is lower, second row is upper

%% find outliers out side of confidence interval
% % sqrt
% idxOutliers = find(CI(1, 1)*sqrt(amp)>peakVel | CI(2, 1)*sqrt(amp)<peakVel);

% power function
idxOutliers = find(CI(1, 1)*amp.^CI(1, 2)>peakVel | CI(2, 1)*amp.^CI(2, 2)<peakVel);
end