function [ppt] = fft_snr(ppt, root, dataToTest, Fs, min_hz, max_hz, inTitle, isMultiple, plotMe)

% Author: James Ives | james.white1@bbk.ac.uk / james.ernest.ives@gmail.com
% Date: 22nd January 2025
% Released under GNU GPL v3.0: https://www.gnu.org/licenses/gpl-3.0.html
% Open to collaboration—feel free to contact me!

% This is a quick version of the fft/snr scripts, the idea is that we quickly run these across whatever data is presented so we can get an
% idea of what we're working with.

if ~exist('root', 'var')
    root = 'E:\Birkbeck\Arbaclofen';
end

% If there are multiple arrays then we need to perform the fft across each array individually,then averaged across the spectra before snr
if isMultiple
    fft_all = [];
    fig = 0;
    for segment = 1:length(dataToTest)  
        % fft setup
        data = dataToTest{segment};

        if sum(data, 'all') == 0
            continue
        end

        % figure; plot(data')
        t = 0:1/Fs:size(data,2)-1/Fs; % Time vector

        %% Calc fft
        fft = [];
        for fftElec = 1:size(data, 1)
            [fftRes, fftHzScale, ~] = myFFT(squeeze(data(fftElec, :)),Fs,0,max_hz);
            [minValue, closestIndex] = min(abs(fftHzScale-max_hz)); % We're filtering at 100Hz so no point keeping anything past that.
            fftRes = fftRes(1:closestIndex);
            fftHzScale = fftHzScale(1:closestIndex);
    
            fft(1, fftElec, :) = fftRes;
            fft(2, fftElec, :) = fftHzScale;

            % figure; plot(fftHzScale, fftRes)        
        end
        
        try
            fft_all(segment, :, :, :) = fft;
        catch
            % This saves everything that is in the workspace to an error file, which can be looked at later.
            save(fullfile(root, 'Rejects', ['Error_', inTitle, '.mat']));
        end
    end
    fft = squeeze(mean(fft_all, 1, 'omitnan'));
else
    data = dataToTest;
    t = 0:1/Fs:size(data,2)-1/Fs; % Time vector

    %% Calc fft
    fft = [];
    for fftElec = 1:size(data, 1)
        [fftRes, fftHzScale, ~] = myFFT(squeeze(data(fftElec, :)),Fs,0,max_hz);
        [minValue, closestIndex] = min(abs(fftHzScale-max_hz)); % We're filtering at 100Hz so no point keeping anything past that.
        fftRes = fftRes(1:closestIndex);
        fftHzScale = fftHzScale(1:closestIndex);

        fft(1, fftElec, :) = fftRes;
        fft(2, fftElec, :) = fftHzScale;
    end
end

% Save the file
save(fullfile(root, 'FFT_data', [inTitle, '.mat']), 'fft')

% Clean up
clear closestIndex data dataToTest fftElec fftRes fftHzScale minValue t

% SNR setup
freqAndRes = [0.1 min_hz max_hz 10];
scale = squeeze(fft(2,1,:))';
data = squeeze(fft(1,:,:));
Colours=GenColours;

% clear fft

if plotMe
    fig(1) = figure('units','normalized','outerposition',[0 0 1 1], 'visible', 'off'); % 
end
clear SNR_Ret
for chans=1:size(data, 1)
    freqcnt=0;
    forlegend{chans}=num2str(chans);

    for freq=freqAndRes(2):freqAndRes(1):freqAndRes(3)
        % Finds the closes index to the target freq (ignore the minValue, unused)
        [minValue,closestIndex] = min(abs(freq-scale));

        % Calcs the bounds of the indices to be used for SNR, trims if necessary
        beforestart=closestIndex-12;
        if beforestart<1
            beforestart=1;
        end

        afterend=closestIndex+12;
        if afterend>length(data)
            afterend=length(data);
        end

        % Finds the index values before and after the target index,
        % excluding the indices adjacent
        beforeend=closestIndex-2;
        afterstart=closestIndex+2;

        ValueAtFreq=data(chans, closestIndex);
        ComparisonVals=horzcat(data(chans, beforestart:beforeend),data(chans, afterstart:afterend))';
        % drop off the value showing the biggest absolute difference from the ValueAtFreq
        [maxValue,closestIndex2] = max(abs(ValueAtFreq-ComparisonVals));
        ComparisonVals(closestIndex2)=NaN;
        % do it again
        [maxValue,closestIndex3] = max(abs(ValueAtFreq-ComparisonVals));
        ComparisonVals(closestIndex3)=NaN;
        freqcnt=freqcnt+1;
        SNR_Ret(freqcnt,1,chans)=freq;
        SNR_Ret(freqcnt,2,chans)=ValueAtFreq/mean(ComparisonVals, 'omitnan');
    end
    squeeze(SNR_Ret(:,1:2,chans));
    if plotMe
        plot(squeeze(SNR_Ret(:,1,chans)'),squeeze(SNR_Ret(:,2,chans)'),'Color',Colours(chans,:))
        hold on
    end
end

% Plots an average
if plotMe
    mSNR = mean(SNR_Ret,3);
    plot(squeeze(SNR_Ret(:,1,chans)),mSNR(:,2), 'k', 'LineWidth', 2);
    ylabel('SNR'); xlabel(strcat('freq (Hz)'));
    xlim([floor(freqAndRes(2)), ceil(freqAndRes(3))]);
    [maxVal, closestIdx] = max(mSNR(:, 2));
    title([replace(inTitle, '_', ' '), ' maxHz at', ' ', num2str(mSNR(closestIdx, 1)), 'Hz'], 'Interpreter','none');
    [ppt] = addImgToPresentation('', ppt, inTitle, fig);
end

save(fullfile(root, 'SNR_data', [inTitle, '.mat']), 'mSNR', 'SNR_Ret')

end