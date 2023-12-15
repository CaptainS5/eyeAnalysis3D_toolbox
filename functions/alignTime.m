function [sampleRate, eyeAligned, headAligned] = alignTime(eyeFrameTrial, varargin)
% This function takes in original eye and head data, then resample and align the timestamps. 
% if only eye data, can still do resampling
%
% Followed the principles here for aligning data: 
%   https://link.springer.com/article/10.3758/s13428-022-01888-3
% In general, a ground-truth timeline is generated based on desired
%   sampling rate, and then each data is interpolated to match the time
%   points.
% When no input for desired sampling rate, by default it upsamples all data
%   to match the highest sampling rate data
% A general suggestion is to upsample if your original sampling rate is 
%   below 240 Hz for better estimation of saccade peak velocity 
%   (Mack, Belfanti, & Schwarz, Behav. Res., 2017).
% If a desired sampling rate is assigned, then everything is resampled to 
%   match the desired sampling rate. 
%
% Input: 
%     You should at least have the eyeFrameTrial data to process;
%     Use -"headFrameTrial" for head data, 
%         -"sampleRateDesired" for a desired sampling rate to be
%               up/downsampled to;
%     For eyeFrameTrial & headFrameTrial, each row should be 
%       one frame, and we will use the variable "timestamp" to align all
%       columns; 
%     The unit of the timestamp should be second, but it doesn't have to 
%       start from 0, just make sure the difference between timestamps are
%       meaningful as of xx (seconds);
%     Sampling rate should be in Hz
%
% Output: 
%     the aligned data for all that had an input, with the new "timestamp"; 
%     sampleRate: actual sample rate from data after alignment

%% initialize
diffEye = diff(eyeFrameTrial.timestamp);
sampleRateRaw = round(1/mode(diffEye)); % sampling rate of eye data
timeStart = eyeFrameTrial.timestamp(1); % for deciding the range of the ground-truth timeline later
timeEnd = eyeFrameTrial.timestamp(end);

if ~isempty(varargin)
    idx = find(strcmp(varargin, 'headFrameTrial'));
    if ~isempty(idx)
        headFrameTrial = varargin{idx+1};

        headYes = 1;
        diffHead = diff(headFrameTrial.timestamp);
        sampleRateRaw(2) = round(1/mode(diffHead));
        timeStart = max([timeStart headFrameTrial.timestamp(1)]);
        timeEnd = min([timeEnd headFrameTrial.timestamp(end)]);
    else
        headYes = 0;
    end

    idx = find(strcmp(varargin, 'sampleRateDesired'));
    if ~isempty(idx)
        sampleRateDesired = varargin{idx+1};
    else
        sampleRateDesired = max(sampleRateRaw);
    end
else
    headYes = 0;
    sampleRateDesired = max(sampleRateRaw);
end
sampleRate = sampleRateDesired;

%% first, build a ground-truth timeline
% using the overlapping time range of available data
timeStep = 1/sampleRateDesired;
timePoints = [timeStart:timeStep:timeEnd]'; 

% then, align all data to this ground truth timeline
% need to take care of two things: interpolate data for the corresponding
% time points, but not interpolating for missing time periods (fill NaN)

% first, work on eye data
% trim data to the range including timePoint
idxMin = find(eyeFrameTrial.timestamp > timePoints(1));
idxMin = max(1, idxMin(1)-1);
idxMax = find(eyeFrameTrial.timestamp < timePoints(end));
idxMax = min(size(eyeFrameTrial, 1), idxMax(end)+1);
eyeFrameTrimmed = eyeFrameTrial(idxMin:idxMax, :);

% fill NaN to the missing data
[NaNtime eyeFull] = fillNaN(eyeFrameTrimmed); 

% then interpolate to the ground truth time points
eyeInterp = [];
ignoreN = 3;
for ii = 1:size(eyeFull, 2)-ignoreN % the last two columns are trial and timestamp
    eyeInterp(:, ii) = interp1(eyeFull.timestamp(:), eyeFull{:, ii}, timePoints, 'makima');
end
% put the NaN back in
for ii = 1:size(NaNtime, 1)
    startI = find(timePoints>=NaNtime.start(ii, 1));
    startI = startI(1);
    endI = find(timePoints<=NaNtime.end(ii, 1));
    endI = endI(end);
    eyeInterp(startI:endI, :) = NaN;
end

eyeAligned.timestamp(:) = timePoints;
eyeAligned.trial(:) = eyeFull.trial(1);

% do the same for head data
if headYes
    % trim data to the range including timePoint
    idxMin = find(headFrameTrial.timestamp > timePoints(1));
    idxMin = max(1, idxMin(1)-1);
    idxMax = find(headFrameTrial.timestamp < timePoints(end));
    idxMax = min(size(headFrameTrial, 1), idxMax(end)+1);
    headFrameTrimmed = headFrameTrial(idxMin:idxMax, :);

    % fill NaN to the missing data
    [NaNtime headFull] = fillNaN(headFrameTrimmed);

    % interpolate the quaternions, just linearly for now...
    headInterp = [];
    % calculate the fractions of interpolation
    for ii = 1:length(headFull.timestamp)-1 % go through each gap in the original timestamps, to see how much needs to be interpolated between them
        oldTimes = headFull.timestamp(ii:ii+1, 1);

        if ii<length(headFull.timestamp)-1
            newTimeI = find(timePoints>=oldTimes(1) & timePoints<oldTimes(2));
        else % the last gap, include the last point if it's on the timeline
            newTimeI = find(timePoints>=oldTimes(1) & timePoints<=oldTimes(2));
        end
        newTimes = timePoints(newTimeI);
        path = (newTimes-oldTimes(1))./(range(oldTimes));
        q1 = quaternion(headFull{ii, 1:4});
        q2 = quaternion(headFull{ii+1, 1:4});
        newQs = slerp(q1, q2, path);
        headInterp = [headInterp; compact(newQs)];
    end

    % interpolate positions
    for ii = 1:3 % the last two columns are trial and timestamp
        headInterp(:, ii+4) = interp1(headFull.timestamp(:), headFull{:, ii+4}, timePoints, 'makima');
    end
end

% put the NaNs back in... do we need this?
for ii = 1:size(NaNtime, 1)
    startI = find(timePoints>=NaNtime.start(ii, 1));
    startI = startI(1);
    endI = find(timePoints<=NaNtime.end(ii, 1));
    endI = endI(end);
    headInterp(startI:endI, :) = NaN;
end

headAligned = array2table(headInterp, 'VariableNames', ...
    {'qW', 'qX', 'qY', 'qZ', 'posX', 'posY', 'posZ'});
headAligned.timestamp(:) = timePoints;
headAligned.trial(:) = headFull.trial(1);


%% helper function
function [NaNtime dataFull] = fillNaN(dataRaw)
    % fill missing frames of dataRaw--in between points more than 100 ms away 
    % also return the start and end time of each NaN gap, so we can put
    % them back in after interpolation
    warning('off','all')
    diffData = diff(dataRaw.timestamp);
    step = mode(diffData);
    fillI = find(diffData>0.1);
    NaNtime = table();

    if fillI % if there are missing time periods

        for ii = 1:length(fillI)            
            timeMiddle = [dataRaw.timestamp(fillI(ii)):step:dataRaw.timestamp(fillI(ii)+1)]';
            NaNtime.start(ii, 1) = dataRaw.timestamp(fillI(ii)); % NaN after this time
            NaNtime.end(ii, 1) = dataRaw.timestamp(fillI(ii)+1); % NaN before this time

            timeMiddle(1) = [];
            if abs(timeMiddle(end)-dataRaw.timestamp(fillI(ii)+1))<step/2 % in case there are some glitches
                timeMiddle(end) = [];
            end          
            
            if ii==1 % copy over the first chunk before the missing period
                dataFull = dataRaw(1:fillI(ii), :);
            end
            dataFull{end+1 : end+length(timeMiddle), 1 : end-2} = NaN;
            dataFull.timestamp(end-length(timeMiddle)+1 : end) = timeMiddle;
            if ii<length(fillI) % copy the chunk before the next missing period
                dataFull = [dataFull; dataRaw(fillI(ii)+1 : fillI(ii+1), :)];
            end
        end
        dataFull = [dataFull; dataRaw(fillI(end)+1:end, :)];
        dataFull.trial(:) = dataRaw.trial(1);
    else
        dataFull = dataRaw;
    end
end

end
