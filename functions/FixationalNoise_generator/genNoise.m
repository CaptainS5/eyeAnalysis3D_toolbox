function data = genNoise(N,lbl,genFun,RMS_STD,magnitude,AR,rotAng)

persistent lookupTable;
persistent lookupTableTxt;

% check input, set defaults
if nargin<7 || isempty(rotAng)
    rotAng      = 0;
end
if nargin<6 || isempty(AR)
    AR          = 1;
end
if nargin<5 || isempty(magnitude)
    magnitude   = 1;
end
assert(isscalar(N) || (ischar(N) && nargin==1),'Number of samples input should be a scalar')
if nargin>1
    assert(isa(genFun,'function_handle'),'genFun input should be a function_handle')
    assert(isscalar(RMS_STD),'RMS/STD input should be a scalar')
    assert(isscalar(magnitude),'magnitude input should be a scalar')
    assert(isscalar(AR),'aspect ratio input should be a scalar')
    assert(isscalar(rotAng),'rotation angle input should be a scalar')
end

% special case, get the contents of the lookup table
if ischar(N)
    data = [];
    if ~isempty(lookupTable)
        q = strcmp(lookupTableTxt,N);
        data = lookupTable(q,:);
    end
    return;
end

% first find what spectral slope we need for this N and RMS_STD
slope = [];
if ~isempty(lookupTable)
    qSlope = lookupTable(:,1)==N & lookupTable(:,2)==RMS_STD & strcmp(lookupTableTxt,lbl);
    slope = lookupTable(qSlope,3);
end
if isempty(slope)
    % slightly smart starting point
    start = [];
    if ~isempty(lookupTable)
        qN = lookupTable(:,1)==N & strcmp(lookupTableTxt,lbl);
        RMS_STDs = lookupTable(qN,2);
        if ~isempty(N) && any(RMS_STDs>RMS_STD & RMS_STDs<RMS_STD)
            start = interp1(RMS_STDs,lookupTable(qN,3),RMS_STD);
        end
    end
    if isempty(start)
        if RMS_STD>sqrt(2)
            start = -1;
        else
            start = 1;
        end
    end
    searchFun = @(x) abs(RMSSTD_from_slope(N,x,genFun,lbl)-RMS_STD);
    slope = fminsearch(searchFun,start);
    lookupTable(end+1,1:3)  = [N RMS_STD slope];
    lookupTableTxt{end+1,1} = lbl;
end

% then generate data
data = genData(N,slope,genFun);
% make anisotropic, rotate
if AR~=1
    data(1,:) = data(1,:)*AR;
    % data has zero mean, so can just rotate
    data = [cosd(rotAng) -sind(rotAng); sind(rotAng) cosd(rotAng)]*data;
end
% scale to desired magnitude
[RMS,STD] = calcRMSSTD(data);
data = data./hypot(RMS,STD).*magnitude;




% helper function to find PSD slope alpha that generates noise of requested
% RMS/STD. Fills lookup table at each iteration to speed up next search
    function RMSSTD = RMSSTD_from_slope(N,slope,genFun,lbl)
        nIter = 1000;
        RMSSTDs = zeros(1,nIter);
        for p=1:nIter
            [RMS_,STD_] = calcRMSSTD(genData(N,slope,genFun));
            RMSSTDs(p) = RMS_/STD_;
        end
        RMSSTD = mean(RMSSTDs);     % for extreme slopes, the distribution of RMS/STD values for the samples is not completely normal, but mean and median are nonetheless very close (tested for slopes -5 and 5), so mean is fine.
        
        % add to lookupTable as well
        lookupTable(end+1,1:3) = [N RMSSTD slope];
        lookupTableTxt{end+1,1} = lbl;
    end
end


% further helpers
function data = genData(N,slope,genFun)
data    = cat(1,genFun(N),genFun(N));
data    = signalSloper(data,slope);
end

function [RMS,STD] = calcRMSSTD(data)
RMS     = sqrt(mean(sum(diff(data,[],2).^2)));
STD     = sqrt(var(data(1,:))+var(data(2,:)));
end
