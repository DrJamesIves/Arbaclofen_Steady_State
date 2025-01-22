function eeg_clean

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

% Quick clean of the EEG data ready for analysis looking for frequency tagging spikes in step 2.

%% Settings
% Paths
root_path = 'E:\Birkbeck\Arbaclofen\';
raw_data_path = fullfile(root_path, 'Raw_data');
save_path = fullfile(root_path, 'Preprocessed_data');
rej_path = fullfile(root_path, 'Rejected_data');

% Preprocessing settings
highpass = 0.1;             % Hz
lowpass = 48;               % Hz
notch = 50;                 % Hz

% Other settings
trial_length = 500;         % samples
chan_rej_threshold = 0.25;  % percent; noisy channel rejection threshold
seg_rej_threshold = 0.25;   % percent; noisy segment rejection threshold

% Channel labels
channel_labels = {'P7', 'P4', 'Cz', 'Pz', 'P3',...
    'P8', 'Oz', 'O2', 'T8', 'PO8',...
    'C4', 'F4', 'AF8', 'Fz', 'C3',...
    'F3', 'AF7', 'T7', 'PO7', 'FPz'};


% Load EEGLAB
eeglab

% Grab the files from raw_data_path
files = dir(raw_data_path);

% Loop through the files, ignoring hidden files which start with .
for idx = 1:length(files)
    if startsWith(files(idx).name, '.')
        continue
    end

    fprintf('Processing: %s\n', files(idx).name)
    eeg_file = fullfile(files(idx).folder, files(idx).name);

    load(eeg_file);
    
    %% Convert to eeglab
    EEG = pop_importdata('data', cat(2, ft.trial{:}), ...
        'srate', ft.fsample, ...
        'xmin', ft.time{1}(1), ...
        'chanlocs', struct('labels', {ft.label}));
    
    % Setting additional fields if needed
    EEG.setname = 'Converted from FieldTrip';
    EEG.times = cat(2, ft.time{:}) * 1000; % convert to ms if necessary
    EEG.trials = length(ft.trial);
    
    % Optional: Add event information if available in ft.events
    if isfield(ft, 'events') && ~isempty(ft.events)
        EEG.event = ft.events; % Adjust event field formatting as necessary
    end
    
    % Optional: If abstime or enobio_hdr are needed for reference
    EEG.abstime = ft.abstime;
    EEG.enobio_hdr = ft.enobio_hdr;
    
    % Save the ft if needed
    EEG = eeg_checkset(EEG);
    
    %% Check channel location info
    
    if isempty(EEG.chanlocs)
        EEG.chanlocs = struct('labels', channel_labels');
    end
    
    % Checks whether the correct set of channel labels was loaded, if Ch1 then it is default and needs
    % to be fixed, assumes that the channels are in the right order.
    if strcmp(EEG.chanlocs(1).labels, 'Ch1')
        for i = 1:length(EEG.chanlocs)
            EEG.chanlocs(i).labels = channel_labels{i};
        end
    end
    
    % Creates a copy of the EEG file otherwise the next step crashes
    EEG2 = EEG;
    
    % Add in channel coordinates
    EEG = pop_select(EEG2, 'channel',{'P7', 'P4', 'Cz', 'Pz', 'P3', 'P8', 'Oz', 'O2', 'T8', 'PO8', 'C4', 'F4', 'AF8', 'Fz', 'C3', 'F3', 'AF7', 'T7', 'PO7', 'FPz'}); %'2-EXG1' '2-EXG2' '2-EXG3' '2-EXG4' '2-EXG5' '2-EXG6' '2-EXG7' '2-EXG8'
    EEG = pop_chanedit(EEG, 'lookup', fullfile(root_path, 'standard-10-5-cap385.elp'),'load',{fullfile(root_path, 'Enobio20Arbaclofen.loc') 'filetype' 'autodetect'});
    
    clear EEG2 ft

    %% Preprocess
    % 0. Clean out low frequency drifts from the data
    % Uses default settings, quite a few channels are overwhelmed with low-freq drifts that cause a lot of problems.
    % EEG = clean_drifts(EEG);

    % 1. Bandpass the EEG
    EEG = pop_eegfiltnew(EEG, lowpass, highpass, 8250, 0, [], 0);

    % 2. Notch filter the EEG
    % This is used to remove a specific frequency, which usually represents the electrical frequency where the data
    % were recorded.
    if lowpass > 49
        EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',(1:EEG.nbchan) ,'computepower',1,'linefreqs', notch,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',[],'scanforlines',1,'sigtype','Channels','tau',100,'verb',1,'winsize',3,'winstep',3);
    end

    % 3. Robust average reference
    % First identify and temporarily remove bad channels, compute and average and remove that average from all channels. dataInfo will be stored with the
    % saved data at the end with relevant info. clean_channels doesn't take data with multiple trials, so first we create a copy and feed in one trial
    % at a time. This may mean that some trials have more rejected channels than others, which is why we're keeping this info.

    % This will be used to store the data quality info for later analysis
    [dataInfo.chansRemovedFromRobustAvg, dataInfo.channelsRejectedForNoise, dataInfo.channelsRejectedForBridging, dataInfo.rejectedSections] = deal([]);

    % Identify noisy channels
    try
        [EEGOUT, removedChans] = clean_channels(EEG);
    catch
        % If there are too many noisy channels it will crash, this just moves that file to the auto reject folder and moves to the next iteration of the loop.
        % movefile(strcat(files(file).folder, '\', files(file).name), strcat(files(file).folder, '\Auto rejected\', files(file).name))
        disp('## Too many noisy channels for robust average')
        continue
    end

    % Average the clean channels and remove the average from all channels
    EEG.data = EEG.data-mean(EEGOUT.data,1);
    % Clear EEGOUT variable we no longer need and store the number of channels removed from the robust average for later
    clear EEGOUT
    dataInfo.chansRemovedFromRobustAvg = [dataInfo.chansRemovedFromRobustAvg, removedChans];

    %% 4. Check for bad channels, bridging and interpolate
    % Use a slightly narrower check to identify bad channels that are either noisy or bridged.
    try
        [~,chans2interp] = clean_channels(EEG,0.7,4,[],[],[],[]); noisyChans = find(chans2interp==1);
    catch
        % If there are too many noisy channels it will crash, this just moves that file to the auto reject folder and moves to the next iteration of the loop.
        % movefile(strcat(files(file).folder, '\', files(file).name), strcat(files(file).folder, '\Auto rejected\', files(file).name))
        disp('## Too many noisy channels after robust average')
        save(fullfile(rej_path, files(idx).name), 'EEG', 'dataInfo');
        continue
    end

    dataInfo.channelsRejectedForNoise = [dataInfo.channelsRejectedForNoise, chans2interp]; % Store these electrodes

    % If detecting noisy and bridged channels they need to be included here.
    toReject = [noisyChans]; %; bridgedChans'];

    % Reject noisy and bridged channels. If there are less channels to interpolate than the rejection threshold, then interpolate them to replace them.
    % Below is commented code to not reject noisy channel sets but instead replace the bad channels with nan vectors.
    % If there are more than the threshold of rejected channels then just reject those channels and replace them with NaNs (this keeps the structure
    % of the channels, which is important for spatial analyses later on).
    if length(toReject) > EEG.nbchan * chan_rej_threshold
        disp('## Too many noisy and bridged channels to reject')
        save(fullfile(rej_path, files(idx).name), 'EEG', 'dataInfo');
        continue
        % nanVector = nan(1, EEG.pnts);
        % for r = 1:length(toReject)
        %     EEG.data(toReject(r), :) = nanVector;
        % end
    else
        % This interpolates channels using nearest neighbours.
        EEG = eeg_interp(EEG, toReject, 'spherical');
    end

    %% 5. Remove bad sections of continuous data
    % If 70% of channels are bad get rid of data
    [~,mask]=clean_windows(EEG,0.7);
    % Get column index of bad data segments and mark as 0 within EEG data
    [~,indx]=find(mask==0);EEG.data(:,indx)=0;
    dataInfo.rejectedSections = [dataInfo.rejectedSections; {mask'}];

    % Reject if there are too many sections of noisy data as a percentage of the whole trial (currently set at 25%). Otherwise save as normal and continue
    % on with fft and other parts.
    if EEG.pnts - sum(mask) > EEG.pnts * seg_rej_threshold
        disp('## Too many noisy noisy segments to reject')
        save(fullfile(rej_path, files(idx).name), 'EEG', 'dataInfo');
        continue
    else
        fprintf(strcat('Saving ...\n'))
        save(fullfile(save_path, files(idx).name), 'EEG', 'dataInfo');
    end

    clear chans2interp dataInfo EEG indx mask

end

end