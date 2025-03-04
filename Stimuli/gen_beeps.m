function gen_beeps

% Author: James Ives | james.white1@bbk.ac.uk / james.ernest.ives@gmail.com
% Date: 3rd March 2025
% Released under GNU GPL v3.0: https://www.gnu.org/licenses/gpl-3.0.html
% Open to collaboration—feel free to contact me!

% The purpose of this function is to produce sinusoidally perfect audio stimuli
% at a desired AM/FM frequency and duration.

% Parameters
save_dir = 'C:\Users\james\Music\Beeps';
fs = 48000;  % Sampling frequency (Hz)
carrier_freq = 1000;  % Carrier frequency (Hz)
mod_freqs = [2, 4, 6, 8, 10, 12];  % Modulation frequencies (Hz)
duration = 240;  % Duration of each file (seconds)
t = 0:1/fs:duration-1/fs;  % Time vector

% Generate and save audio stimuli
for i = 1:length(mod_freqs)
    mod_freq = mod_freqs(i);
    
    % Generate amplitude modulation envelope (sinusoidal)
    mod_signal = 0.5 * (1 + sin(2 * pi * mod_freq * t));  % Scaled between 0 and 1
    
    % Generate carrier tone
    carrier_signal = sin(2 * pi * carrier_freq * t);
    
    % Apply amplitude modulation
    audio_signal = mod_signal .* carrier_signal;
    
    % Normalize to range [-1, 1]
    audio_signal = audio_signal / max(abs(audio_signal));
    
    % Save audio file
    filename = fullfile(save_dir, sprintf('audio_stim_%dHz.wav', mod_freq));
    audiowrite(filename, audio_signal, fs);
    
    fprintf('Saved: %s\n', filename);
end

disp('All audio stimuli generated and saved.');

end