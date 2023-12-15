function vorStats = processVOR(VOR, headVel, sampleRate)
% calculate VOR duration, peak velocity, mean velocity, gain, and
% direction, mostly based on head velocity (translation + rotation)

vorStats = table();

if ~isempty(VOR.onsetI)
    for ii = 1:length(VOR.onsetI)
        vorOnI = VOR.onsetI(ii);
        vorOffI = VOR.offsetI(ii);

        duration(ii, 1) = VOR.offsetTime(ii)-VOR.onsetTime(ii);

        dir(ii, :) = sum(headVel(vorOnI:vorOffI, :))/sampleRate;
        %         dir(ii, :) = dir(ii, :)/norm(dir(ii, :));

        ampVecs = abs(headVel(vorOnI:vorOffI, :))/sampleRate;
        ampSum(ii, 1) = sum(sqrt(sum(ampVecs.^2, 2)));

        gainAmp(ii, 1) = nanmean(VOR.gainAmp(vorOnI:vorOffI));
        gainDir(ii, 1) = nanmean(VOR.gainDir(vorOnI:vorOffI));

        meanVelX(ii, 1) = nanmean(abs(headVel(vorOnI:vorOffI, 1)));
        maxP = nanmax(abs(headVel(vorOnI:vorOffI, 1)));
        peakVelX(ii, 1) = maxP(1);

        meanVelY(ii, 1) = nanmean(abs(headVel(vorOnI:vorOffI, 2)));
        maxP = nanmax(abs(headVel(vorOnI:vorOffI, 2)));
        peakVelY(ii, 1) = maxP(1);

        meanVel2D(ii, 1) = nanmean(sqrt(sum(headVel(vorOnI:vorOffI, :).^2, 2)));
        maxP = nanmax( sqrt( sum(headVel(vorOnI:vorOffI, :).^2, 2) ));
        peakVel2D(ii, 1) = maxP(1);
    end

    vorStats.dirX = dir(:, 1);
    vorStats.dirY = dir(:, 2);
    vorStats.ampSum = ampSum;
    vorStats.gainAmp = gainAmp;
    vorStats.gainDir = gainDir;

    vorStats.meanVelX = meanVelX;
    vorStats.peakVelX = peakVelX;
    vorStats.meanVelY = meanVelY;
    vorStats.peakVelY = peakVelY;
    
    vorStats.meanVel2D = meanVel2D;
    vorStats.peakVel2D = peakVel2D;
    vorStats.duration = duration;
end
end