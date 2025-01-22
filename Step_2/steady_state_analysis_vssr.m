function steady_state_analysis_vssr

% ------------------------------------------------------------------------------------------------------
% Author: James Ives
% Email: james.white1@bbk.ac.uk / james.ernest.ives@gmail.com
% Date: 22nd January 2025
%
% This script was written by James Ives and is released under the GNU General Public License v3.0.
%
% You are free to redistribute and/or modify this script under the terms of the GNU General Public
% License as published by the Free Software Foundation, either version 3 of the License, or (at
% your option) any later version.
%
% This script is provided "as-is" without any warranty; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details: https://www.gnu.org/licenses/gpl-3.0.html
%
% I am happy to collaborate on any projects related to this script.
% Feel free to contact me at the email addresses provided.
% -----------------------------------------------------------------------------------------------------

% This code takes in preprocessed EEG data and does a quick search for spikes across the frequency spectrum for the VSSR trials.

%% Settings
% Basic settings
highpass = 0.1;
lowpass = 48;
trial_duration = 1000;
trial_length = trial_duration/2;
trial_type = 'video';

% Paths
root_path = 'E:\Birkbeck\Arbaclofen\';
save_path = fullfile(root_path, sprintf('%dms %s', trial_duration, trial_type));
itpc_path = fullfile(save_path, 'ITPC_data');
fft_path = fullfile(save_path, 'FFT_data');
snr_path = fullfile(save_path, 'SNR_data');
raw_data_path = fullfile(root_path, 'Preprocessed_data');
presentation_path = fullfile(save_path, 'Presentations');

warning('off', 'MATLAB:MKDIR:DirectoryExists');

% Check paths exist and if not make them
paths = {save_path, fft_path, itpc_path, snr_path, presentation_path};
for p = 1:length(paths)
    if ~exist(paths{p}, 'dir')
        mkdir(paths{p})
    end
end

plotMe = 0;
main_codes = [101, 102, 103, 104, 105];
intervening_codes = [111, 112];
end_code = 110;
run_fft = 0;
run_itpc = 1;

if plotMe
    % Create presentations
    % Trials concatenated, fft/snr run over continuous data
    [concat_ppt] = createPresentation(presentation_path, 'concatenated_trials.pptx', 'concatenated_trials');
    % FFT run first then averaged across spectra
    [avg_ppt] = createPresentation(presentation_path, 'averaged_freq_trials.pptx', 'concatenated_trials');
else
    concat_ppt = 0;
    avg_ppt = 0;
end

% Load EEGLAB
eeglab

% Grab the files from raw_data_path
files = dir(raw_data_path);

% Loop through the files, ignoring hidden files which start with .
for idx = 6:length(files)
    if startsWith(files(idx).name, '.')
        continue
    end

    fprintf('Analysing: %s\n', files(idx).name)
    eeg_file = fullfile(files(idx).folder, files(idx).name);

    load(eeg_file);

    if isempty(EEG.event)
        continue
    end

    %% Epoch to just trials of interest
    % Grab the relevant events either epoched strictly to 500ms/1000ms (short) or until the next event (long)

    % Filter the events to keep only relevant codes
    filtered_events = EEG.event(ismember([EEG.event.value], [main_codes, intervening_codes, end_code]));

    if isempty(filtered_events)
        continue
    end

    % Initialize results
    results = [];
    results.Code_101 = [];
    results.Code_102 = [];
    results.Code_103 = [];
    results.Code_104 = [];
    results.Code_105 = [];
    section_start_idx = [];

    % Identify the indices where sections start and end
    for i = 1:length(filtered_events)
        if ismember(filtered_events(i).value, main_codes)
            section_start_idx(end + 1) = i; % Start of a new section
        elseif filtered_events(i).value == end_code
            % Check if this is the end of a section
            if ~isempty(section_start_idx)
                current_start = section_start_idx(end);
                % Process the section
                section_events = filtered_events(current_start:i);

                results.(['Code_', num2str(filtered_events(current_start).value)])...
                    = [results.(['Code_', num2str(filtered_events(current_start).value)]); ...
                    {EEG.data(:, filtered_events(current_start).sample:filtered_events(i).sample)}];
            end
        end
    end

    % Concatenating the 10/40Hz trials and rerunning the fft
    concatShort6Hz = horzcat(results.Code_103{:});
    concatShort10Hz = horzcat(results.Code_104{:});
    concatShort15Hz = horzcat(results.Code_105{:});

    single_array = {concatShort6Hz; concatShort10Hz; concatShort15Hz}; % concatLong10Hz; concatLong40Hz;
    single_array_titles = {'Concat short trials 6Hz'; 'Concat short trials 10Hz'; 'Concat short trials 15Hz'}; % 'Concat long trials 10Hz'; 'Concat long trials 40Hz';
    array_sets = {results.Code_103; results.Code_104; results.Code_105}; % ...
    array_sets_titles = {'Epoched short trials 6Hz'; 'Epoched short trials 10Hz'; 'Epoched short trials 15Hz'}; %...

    ppt_name = files(idx).name(1:end-4);

    for s = 1:length(single_array)
        if run_fft
            [concat_ppt] = fft_snr(concat_ppt, save_path, single_array{s}, EEG.srate, highpass, lowpass, [single_array_titles{s}, '_', ppt_name], 0, 1);
        end
    end

    for a = 1:length(array_sets)
        if run_fft
            [avg_ppt] = fft_snr(avg_ppt, save_path, array_sets{a}, EEG.srate, highpass, lowpass, [array_sets_titles{a}, '_', ppt_name], 1, 1);
        end
        if run_itpc
            max_array_size = max(cellfun(@length, array_sets{a}));
            temp_data = zeros(size(array_sets{a}{1,1}, 1), max_array_size, size(array_sets{a}, 1));
            for i = 1:size(array_sets{a}, 1)
                temp_set = array_sets{a}{i, 1};
                temp_data(:, :, i) = [temp_set, zeros(size(temp_set, 1), max_array_size - size(temp_set, 2))];
            end
            EEG.data = temp_data;
            EEG.pnts = size(EEG.data, 2);
            EEG.times = linspace(2,EEG.pnts * 2,EEG.pnts);

            % Expects EEG.data in a electrode x times x trial format
            % Optional return of time axis, log frequencies and itpc but this data is saved so not needed here
            [~, ~, ~] = itpc_snr_gpu(itpc_path, [array_sets_titles{a}, '_', ppt_name], EEG, highpass, lowpass, 0);
        end
    end


    clear array_sets array_set_titles concatShort10Hz concatShort15hz concatShort6Hz dataInfo EEG filtered_events section_events section_start_idx
    clear temp_data temp_set

end

if plotMe
    % Close presentations to save them
    close(concat_ppt);
    close(avg_ppt);
end

end
