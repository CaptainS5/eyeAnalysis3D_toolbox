function output = butterworthFilter(input, filtFrequency, filtOrder, filtCutoff)
% apply the butterworth filter as needed, 1d at a time
% input: m by n matrix, each column is filtered as one array at one time
% output: filtered m by n matrix

%output = [];
%for ii = 1:size(input, 2)
%    vec = input(:, ii);
%    idxNaN = find(isnan(vec));
    % replace NaN with 0
%    vec(idxNaN) = 0;

%    [a, b] = butter(filtOrder, filtCutoff/filtFrequency);
%    vecFilt = filtfilt(a, b, vec);

%view    vecFilt(idxNaN) = NaN;
%    output = [output vecFilt]; % put NaN back into the trace
%end

% Find NaN values and replace them with 0
input(isnan(input)) = 0;

% Create Butter
[b, a] = butter(filtOrder, filtCutoff/filtFrequency);

% Apply the filter to all columns simultaneously
output = filtfilt(b, a, input);

% Restore NaN values in the filtered output
output(isnan(input)) = NaN;