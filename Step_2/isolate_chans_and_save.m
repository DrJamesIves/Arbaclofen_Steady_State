function isolate_chans_and_save

% Author: James Ives | james.white1@bbk.ac.uk / james.ernest.ives@gmail.com
% Date: 22nd January 2025
% Released under GNU GPL v3.0: https://www.gnu.org/licenses/gpl-3.0.html
% Open to collaboration—feel free to contact me!

% The purpose of this funtion is to take analysed data, open each file and isolate the channels of interest
% If there are multiple versions of the same data that are requested that can also be accomodated here.

% This is useful to allow the analysis to run over all channels then look at a whole head vs regional model.
% There is also the option "plotMe" to plot for the average of the regional data and save in a powerpoint.

%% Channel settings
% Expected channel locations
channel_labels = {'P7', 'P4', 'Cz', 'Pz', 'P3',...
    'P8', 'Oz', 'O2', 'T8', 'PO8',...
    'C4', 'F4', 'AF8', 'Fz', 'C3',...
    'F3', 'AF7', 'T7', 'PO7', 'FPz'};

% Generates more than the standard colours Matlab uses
Colours=GenColours;

%% Loop settings
% Set paths
root_path = 'E:\Birkbeck\Arbaclofen\';
root_paths = {fullfile(root_path, '500ms audio'); fullfile(root_path, '1000ms audio'); fullfile(root_path, '1000ms video')};
outpath_suffixes = {'_Fz_Cz_only'; '_Fz_Cz_only'; '_Occipital_only'};
% Indices based on the channel location in the order of channel_labels
chan_groups_of_interest = {[3, 14]; [3, 14]; [7,10,19]};

%% Switch settings
% Controls which analyses to isolate channels for.
run_fft = 0;
run_snr = 0;
run_itpc = 1;
plotMe = 0;

%% Warnings
warning('off', 'MATLAB:legend:IgnoringExtraEntries');

for r = 1:length(root_paths)
    
    %% Paths
    % Input paths
    root = root_paths{r};
    % root = 'E:\Birkbeck\Arbaclofen\1000ms video';
    fft_path = fullfile(root, 'FFT_data');
    snr_path = fullfile(root, 'SNR_data');
    itpc_path = fullfile(root, 'ITPC_data');
    
    % Setup/create new output paths
    % outpath_suffix = '_Occipital_only';
    outpath_suffix = outpath_suffixes{r};
    
    fft_outpath = fullfile(root, ['FFT_data', outpath_suffix]);
    snr_outpath = fullfile(root, ['SNR_data', outpath_suffix]);
    itpc_outpath = fullfile(root, ['ITPC_data', outpath_suffix]);
    new_outpaths = {fft_outpath, snr_outpath, itpc_outpath};
    
    for i = 1:length(new_outpaths)
        if ~exist(new_outpaths{i}, 'dir')
            mkdir(new_outpaths{i})
        end
    end
    
    %% Presentation settings
    if plotMe
        pres_path = fullfile(root, 'Presentations');
        if run_snr
            % Create presentations
            % Trials concatenated, fft/snr run over continuous data
            [concat_fft_ppt] = createPresentation(pres_path, ['concatenated_trials', outpath_suffix, '.pptx'], 'concatenated_trials');
            % FFT run first then averaged across spectra
            [avg_fft_ppt] = createPresentation(pres_path, ['averaged_freq_trials', outpath_suffix, '.pptx'], 'averaged_trials');
        end
        if run_itpc
            % ITPC
            [itpc_ppt] = createPresentation(pres_path, ['itpc_trials', outpath_suffix, '.pptx'], 'itpc_trials');
        end
    end
    
    %% Channel settings
    chans_of_interest = chan_groups_of_interest{r};
    
    %% FFT
    if run_fft
    files = dir(fft_path);
    
    for idx = 1:length(files)
        if startsWith(files(idx).name, '.')
            continue
        end
    
        % Load the file
        load(fullfile(files(idx).folder, files(idx).name));
    
        % Seperate out the channels of interest
        fft = fft(:, chans_of_interest, :);
    
        % Save the file
        save(fullfile(fft_outpath, files(idx).name), 'fft');
    end
    end

    %% SNR
    if run_snr
    files = dir(snr_path);
    
    for idx = 1:length(files)
        if startsWith(files(idx).name, '.')
            continue
        end
    
        % Load the file
        load(fullfile(files(idx).folder, files(idx).name));
    
        % Seperate out the channels of interest
        SNR_Ret = SNR_Ret(:, :, chans_of_interest);
        mSNR = squeeze(mean(SNR_Ret, 3, 'omitnan'));
    
        % Save the file
        save(fullfile(snr_outpath, files(idx).name), 'mSNR', 'SNR_Ret');
    
        if plotMe
            % Generate a full screen but invisible figure
            fig(1) = figure('units','normalized','outerposition',[0 0 1 1], 'visible', 'off'); hold on
            hold on
            for chan = 1:size(SNR_Ret, 3)
                plot(squeeze(SNR_Ret(:,1,chan)'),squeeze(SNR_Ret(:,2,chan)'),'Color',Colours(chan,:))
            end
            plot(squeeze(SNR_Ret(:,1,chan)),mSNR(:,2), 'k', 'LineWidth', 2);
            ylabel('SNR'); xlabel(strcat('freq (Hz)'));
            xlim([0 48]); 
            a = split(files(idx).name, '_'); a = split(a(1), ' '); a = a(end);
            if ~isempty(str2num(a{1}(1:2)))
                xline(str2num(a{1}(1:2)), '--', 'DisplayName', a{:});
            end
            [maxVal, closestIdx] = max(mSNR(:, 2));
            inTitle = [files(idx).name(1:end-4), ' maxHz at', ' ', num2str(mSNR(closestIdx, 1)), 'Hz'];
            title(inTitle, 'Interpreter','none');
            set(gcf, 'color', 'w')
            legend([channel_labels(chans_of_interest), 'Average', a])
    
            if startsWith(inTitle, 'Concat')
                [concat_fft_ppt] = addImgToPresentation('', concat_fft_ppt, inTitle, fig);
            elseif startsWith(inTitle, 'Epoched')
                [avg_fft_ppt] = addImgToPresentation('', avg_fft_ppt, inTitle, fig);
            else
                crashMe
            end
    
        end
    end
    end
    
    %% ITPC   
    if run_itpc
    files = dir(itpc_path);
    
    for idx = 1:length(files)
        if startsWith(files(idx).name, '.')
            continue
        end
    
        % Load the file
        load(fullfile(files(idx).folder, files(idx).name));
    
        % Seperate out the channels of interest
        itpc = squeeze(itpc(chans_of_interest, :, :, :));
    
        % Save the file
        save(fullfile(itpc_outpath, files(idx).name), 'itpc', 'time_axis', 'log_frequencies');

        if plotMe
            for chan = 1:size(itpc, 1)
                fig(1) = figure('units','normalized','outerposition',[0 0 1 1], 'visible', 'off');
                imagesc(time_axis, log_frequencies, squeeze(itpc(chan, :, :))); % Time-frequency plot
                set(gca, 'YDir', 'normal'); % Ensure y-axis is from smallest to largest
                yticks(log10([1, 2, 3, 4, 5, 6, 10, 15, 40, 50, 100])); % Define specific tick marks
                yticklabels({'1', '2', '3', '4', '5', '6', '10', '15', '40', '50', '100'}); % Label ticks with original frequencies
                xlabel('Time (s)');
                ylabel('Frequency (Hz, log scale)');
                inTitle = sprintf('ITPC-%s', channel_labels{i});
                title(inTitle);
                colorbar;
                set(gcf, 'color', 'w')

                [itpc_ppt] = addImgToPresentation('', itpc_ppt, inTitle, fig);

            end
        end
    end
    end
    
    %% Close
    if plotMe
    close(concat_fft_ppt);
    close(avg_fft_ppt);
    close(itpc_ppt);
    end
end

end