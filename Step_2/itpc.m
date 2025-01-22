function [time_axis, log_frequencies, itpc] = itpc(save_path, inTitle, EEG, highpass, lowpass, plotMe)

% Author: James Ives | james.white1@bbk.ac.uk / james.ernest.ives@gmail.com
% Date: 22nd January 2025
% Released under GNU GPL v3.0: https://www.gnu.org/licenses/gpl-3.0.html
% Open to collaboration—feel free to contact me!

% The purpose of this function is to take in preprocessed EEG data and run an ITPC analysis on it.

% Load EEGLAB data
% Ensure EEG structure is loaded (e.g., after using `pop_loadset`)
% Expected variables: EEG.data (channels x time x trials), EEG.srate (sampling rate), EEG.times (time vector)

% Define parameters
frequencies = highpass:0.1:lowpass; % Frequency range for analysis (e.g., 1-100 Hz)
time_axis = EEG.times / 1000; % Convert times to seconds
n_trials = size(EEG.data, 3); % Number of trials
n_elecs = size(EEG.data, 1); % Number of electrodes to test
fs = EEG.srate; % Sampling frequency

% Preallocate for ITPC computation
n_freq = length(frequencies);
n_time = size(EEG.data, 2);
phase_data = nan(n_elecs, n_trials, n_freq, n_time);

% Loop through trials
for trial = 1:n_trials
    for elec = 1:n_elecs
        % Get trial data (assuming single-channel analysis, modify for multi-channel as needed)
        trial_data = squeeze(EEG.data(elec, :, trial)); % Change '1' to desired channel index
        
        % Compute time-frequency decomposition
        for f = 1:n_freq
            % Define wavelet for frequency f
            freq = frequencies(f);
            t = -1:1/fs:1; % Wavelet time axis
            sigma_t = 3 / (2 * pi * freq); % Standard deviation in time
            wavelet = exp(2 * 1i * pi * freq * t) .* exp(-t.^2 / (2 * sigma_t^2));
            
            % Convolve wavelet with trial data
            conv_result = conv(trial_data, wavelet, 'same');
            phase_data(elec, trial, f, :) = angle(conv_result);
        end
    end
end

% Compute ITPC
itpc = squeeze(abs(mean(exp(1i * phase_data), 2))); % Average across trials

% Log-transform frequencies
log_frequencies = log10(frequencies);

% Save the data
save(fullfile(save_path, [inTitle, '.mat']), 'time_axis', 'log_frequencies', 'itpc');

if plotMe
    % Plot ITPC across time and frequency for all electrodes (assumes all 20)
    channel_labels = {'P7', 'P4', 'Cz', 'Pz', 'P3',...
    'P8', 'Oz', 'O2', 'T8', 'PO8',...
    'C4', 'F4', 'AF8', 'Fz', 'C3',...
    'F3', 'AF7', 'T7', 'PO7', 'FPz'};

    figure;
    for i = 1:size(itpc, 1)
        subplot(4,5,i);
        imagesc(time_axis, log_frequencies, squeeze(itpc(i, :, :))); % Time-frequency plot
        set(gca, 'YDir', 'normal'); % Ensure y-axis is from smallest to largest
        yticks(log10([1, 2, 3, 4, 5, 6, 10, 15, 40, 50, 100])); % Define specific tick marks
        yticklabels({'1', '2', '3', '4', '5', '6', '10', '15', '40', '50', '100'}); % Label ticks with original frequencies
        xlabel('Time (s)');
        ylabel('Frequency (Hz, log scale)');
        title(sprintf('ITPC - %s', channel_labels{i}));
        colorbar;
    end
    
    % If time-frequency not possible, calculate frequency-only ITPC
    if size(itpc, 3) == 1
        itpc_freq = squeeze(mean(itpc, 3)); % Average across time
        figure;
        semilogx(frequencies, itpc_freq); % Plot on log scale
        xlabel('Frequency (Hz)');
        ylabel('ITPC');
        title('ITPC Across Frequency');
    end
end

end