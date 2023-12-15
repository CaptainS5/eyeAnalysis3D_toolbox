function frameN = ms2frame(duration, sampleRate)
% calculate the corresponding frames of duration (ms) under the current
% sampling rate

frameN = round(duration/1000*sampleRate);