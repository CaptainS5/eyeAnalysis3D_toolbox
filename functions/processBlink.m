function blinkStats = processBlink(blink)
% get blink duration

blinkStats = table();
if ~isempty(blink.onsetTime) % if we have blinks
    for ii = 1:length(blink.onsetTime)
        blinkStats.dur(ii, 1) = blink.offsetTime(ii)-blink.onsetTime(ii);
    end
end

end