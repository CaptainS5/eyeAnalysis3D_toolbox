function dataB = bootIdx(dataAll, sampleN)
% bootstrap sampleN times for each cell in dataAll

dataB = NaN(length(dataAll), sampleN);
for ii = 1:length(dataAll)
    idxB = randi(length(dataAll{ii}), sampleN, 1);
    dataB(ii, :) = dataAll{ii}(idxB);
end