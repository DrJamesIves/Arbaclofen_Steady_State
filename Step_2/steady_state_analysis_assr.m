function steady_state_analysis_assr

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

% This code takes in preprocessed EEG data and does a quick search for spikes across the frequency spectrum for the ASSR trials.
% There are two types of trial that are created, a concatenated trial where all the data are concatenated together and an averaged
% trial where the data are set as trials, the analysis is run and then these are averaged together.

%% Settings
% Basic settings
highpass = 0.1;
lowpass = 48;
trial_duration = 1000;
trial_length = trial_duration/2;
trial_type = 'audio';

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

% Create presentations
% Trials concatenated, fft/snr run over continuous data
[concat_ppt] = createPresentation(presentation_path, 'concatenated_trials.pptx', 'concatenated_trials');
% FFT run first then averaged across spectra
[avg_ppt] = createPresentation(presentation_path, 'averaged_freq_trials.pptx', 'concatenated_trials');

% Grab the files from raw_data_path
files = dir(raw_data_path);

% Settings to let the script know whether to run fft and/or itpc
run_fft = 0;
run_itpc = 1;

% Loop through the files, ignoring hidden files which start with .
for idx = 1:length(files)
    if startsWith(files(idx).name, '.')
        continue
    end

    % Extra code to skip analyses that have already been run
    % if exist(fullfile(itpc_path, files(idx).name), 'file') & exist(fullfile(fft_path, files(idx).name))
    %     disp(sprintf('Already analysed %s,\tmoving onto the next one'))
    %     continue
    % end

    % Establishes and loads file
    fprintf('Analysing: %s\n', files(idx).name)
    eeg_file = fullfile(files(idx).folder, files(idx).name);
    load(eeg_file);

    % If no events then skip
    if isempty(EEG.event)
        continue
    end
    
    %% Epoch to just trials of interest
    % Grab the relevant events either epoched strictly to 500ms/1000ms (short) or until the next event (long)
    assrShort10HzEvents = [vertcat(EEG.event(find(vertcat(EEG.event.value) == 40)).sample), (vertcat(EEG.event(find(vertcat(EEG.event.value) == 40)).sample))+trial_length];
    assrLong10HzEvents = [vertcat(EEG.event(find(vertcat(EEG.event.value) == 40)).sample), vertcat(EEG.event(find(vertcat(EEG.event.value) == 40)+1).sample)];
    
    if isempty(assrShort10HzEvents)
        continue
    end

    tooShort = find(assrLong10HzEvents(:, 2) - assrLong10HzEvents(:, 1) < trial_length);
    assrShort10HzEvents(tooShort, :) = [];
    assrLong10HzEvents(tooShort, :) = [];
    num10HzTrials = size(assrShort10HzEvents, 1);

    assrShort40HzEvents = [vertcat(EEG.event(find(vertcat(EEG.event.value) == 41)).sample), (vertcat(EEG.event(find(vertcat(EEG.event.value) == 41)).sample))+trial_length];
    assrLong40HzEvents = [vertcat(EEG.event(find(vertcat(EEG.event.value) == 41)).sample), vertcat(EEG.event(find(vertcat(EEG.event.value) == 41)+1).sample)];
    
    tooShort = find(assrLong40HzEvents(:, 2) - assrLong40HzEvents(:, 1) < trial_length);
    assrShort40HzEvents(tooShort, :) = [];
    assrLong40HzEvents(tooShort, :) = [];
    num40HzTrials = size(assrShort40HzEvents, 1);
    
    % Epoch out the data
    assrShort10Hz = [];
    for i = 1:num10HzTrials
        assrShort10Hz = [assrShort10Hz; {EEG.data(:, assrShort10HzEvents(i,1):assrShort10HzEvents(i,2))}];
    end

    clear assrShort10HzEvents assrLong10HzEvents num10HzTrials
    
    assrShort40Hz = [];
    for i = 1:num40HzTrials
        assrShort40Hz = [assrShort40Hz; {EEG.data(:, assrShort40HzEvents(i,1):assrShort40HzEvents(i,2))}];
    end

    clear assrShort40HzEvents assrLong40HzEvents num40HzTrials
    
    concatShort10Hz = horzcat(assrShort10Hz{:});
    concatShort40Hz = horzcat(assrShort40Hz{:});
    
    % ## spare code 1 goes here if reused, this created time averages and trimmed/padded long segments

    single_array = {concatShort10Hz; concatShort40Hz};
    single_array_titles = {'Concat short trials 10Hz'; 'Concat short trials 40Hz'};
    array_sets = {assrShort10Hz; assrShort40Hz};
    array_sets_titles = {'Epoched short trials 10Hz'; 'Epoched short trials 40Hz'};

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
            temp_data = zeros(size(array_sets{a}{1,1}, 1), size(array_sets{a}{1,1}, 2), size(array_sets{a}, 1));
            for i = 1:size(array_sets{a}, 1)
                temp_data(:, :, i) = array_sets{a}{i, 1};
            end
            EEG.data = temp_data;
            EEG.pnts = size(EEG.data, 2);
            EEG.times = linspace(2,EEG.pnts * 2,EEG.pnts);
            
            % Expects EEG.data in a electrode x times x trial format
            [~, ~, ~] = itpc_snr(itpc_path, [array_sets_titles{a}, '_', ppt_name], EEG, highpass, lowpass, 0);
        end
    end

    clear assrShort10Hz assrShort40Hz concatShort10Hz concatShort40Hz dataInfo EEG temp_data
    
end

% Close presentations to save them
close(concat_ppt);
close(avg_ppt);

end


%% Unused code
% Unused code 1

% assrShort10Hz = [];
% % assrLong10Hz = [];
% for i = 1:num10HzTrials
%     assrShort10Hz = [assrShort10Hz; {EEG.data(:, assrShort10HzEvents(i,1):assrShort10HzEvents(i,2))}];
%     % assrLong10Hz = [assrLong10Hz; {EEG.data(:, assrLong10HzEvents(i,1):assrLong10HzEvents(i,2))}];
% end
%
% clear assrShort10HzEvents assrLong10HzEvents num10HzTrials
%
% assrShort40Hz = [];
% % assrLong40Hz = [];
% for i = 1:num40HzTrials
%     assrShort40Hz = [assrShort40Hz; {EEG.data(:, assrShort40HzEvents(i,1):assrShort40HzEvents(i,2))}];
%     % assrLong40Hz = [assrLong40Hz; {EEG.data(:, assrLong40HzEvents(i,1):assrLong40HzEvents(i,2))}];
% end
%
% clear assrShort40HzEvents assrLong40HzEvents num40HzTrials
%
% % Concatenating the 10/40Hz trials and rerunning the fft
% concatShort10Hz = horzcat(assrShort10Hz{:});
% % concatLong10Hz = horzcat(assrLong10Hz{:});
% concatShort40Hz = horzcat(assrShort40Hz{:});
% % concatLong40Hz = horzcat(assrLong40Hz{:});

% Create average short trials
% allShort10Hz = [];
% for i = 1:length(assrShort10Hz)
%     allShort10Hz(i, :, :) = assrShort10Hz{i};
% end
% avgTimeShort10Hz = squeeze(mean(allShort10Hz, 1, 'omitnan'));
%
% allShort140Hz = [];
% for i = 1:length(assrShort40Hz)
%     allShort40Hz(i, :, :) = assrShort40Hz{i};
% end
% avgTimeShort40Hz = squeeze(mean(allShort40Hz, 1, 'omitnan'));
%
% clear allShort10Hz allShort40Hz

% Create a trimmed and padded version of the long trials

% Find the minimum column length across all cells
% min10Length = min(cellfun(@(x) size(x, 2), assrLong10Hz));
% min40Length = min(cellfun(@(x) size(x, 2), assrLong40Hz));
%
% % Trim all arrays to the minimum length
% trimmed10Arrays = cellfun(@(x) x(:, 1:min10Length), assrLong10Hz, 'UniformOutput', false);
% trimmed40Arrays = cellfun(@(x) x(:, 1:min40Length), assrLong40Hz, 'UniformOutput', false);
%
% % Find the maximum column length for padding
% max10Length = max(cellfun(@(x) size(x, 2), assrLong10Hz));
% max40Length = max(cellfun(@(x) size(x, 2), assrLong40Hz));
%
% % Pad arrays with NaNs to match the maximum length
% padded10Arrays = cellfun(@(x) [x, NaN(size(x, 1), max10Length - size(x, 2))], assrLong10Hz, 'UniformOutput', false);
% padded40Arrays = cellfun(@(x) [x, NaN(size(x, 1), max40Length - size(x, 2))], assrLong40Hz, 'UniformOutput', false);
%
% Then create averages
% trimmedAll = [];
% for i = 1:length(trimmed10Arrays)
%     trimmedAll(i, :, :) = trimmed10Arrays{i};
% end
% avgTrimmed10Array = squeeze(mean(trimmedAll, 1, 'omitnan'));
%
% trimmedAll = [];
% for i = 1:length(trimmed40Arrays)
%     trimmedAll(i, :, :) = trimmed40Arrays{i};
% end
% avgTrimmed40Array = squeeze(mean(trimmedAll, 1, 'omitnan'));
%
% paddedAll = [];
% for i = 1:length(padded10Arrays)
%     paddedAll(i, :, :) = padded10Arrays{i};
% end
% avgPadded10Array = squeeze(mean(paddedAll, 1, 'omitnan'));
%
% paddedAll = [];
% for i = 1:length(padded40Arrays)
%     paddedAll(i, :, :) = padded40Arrays{i};
% end
% avgPadded40Array = squeeze(mean(paddedAll, 1, 'omitnan'));
