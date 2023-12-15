function output = butterworthFilter(input, filtFrequency, filtOrder, filtCutoff)
% apply the butterworth filter as needed, 1d at a time
% input: m by n matrix, each column is filtered as one array at one time
% output: filtered m by n matrix

output = [];
for ii = 1:size(input, 2)
    vec = input(:, ii);
    idxNaN = find(isnan(vec));
    % replace NaN with 0
    vec(idxNaN) = 0;

    [a, b] = butter(filtOrder, filtCutoff/filtFrequency);
    vecFilt = filtfilt(a, b, vec);

    vecFilt(idxNaN) = NaN;
    output = [output vecFilt]; % put NaN back into the trace
end