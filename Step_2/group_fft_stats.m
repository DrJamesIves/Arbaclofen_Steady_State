function group_fft_stats

% Author: James Ives | james.white1@bbk.ac.uk / james.ernest.ives@gmail.com
% Date: 22nd January 2025
% Released under GNU GPL v3.0: https://www.gnu.org/licenses/gpl-3.0.html
% Open to collaboration—feel free to contact me!

% The purpose of this function is to take SNR values and calculate group stats.
% These are saved in the output files along with a presentation of figures.

%% Define paths
% This is done manually with each group and suffix put in manually. This was subsequently changed for group_itpc_stats
% and could be implemented here.

% Root to the scripts
addpath(genpath('E:\Birkbeck\Scripts\James Common'));
% Path to the main folder
root = 'E:\Birkbeck\Arbaclofen';
% Subfolder path
root_path = fullfile(root, '500ms audio');
snr_data_path = fullfile(root_path, 'SNR_data_Fz_Cz_only');
% Output data paths
output_path = fullfile(root_path, 'Averages');
indiv_outpath = fullfile(output_path, 'Individual Conditions');
group_outpath = fullfile(output_path, 'Grouped by factor');
output_paths = {output_path; indiv_outpath; group_outpath};

for path = 1:length(output_paths)
    if ~exist(output_paths{path}, 'dir')
        mkdir(output_paths{path});
    end
end

% Create presentations
% All fft groups will go into one presentation
[ppt] = createPresentation(output_path, 'fft_averages.pptx', 'Averages');

% Load files
files = dir(fullfile(snr_data_path, '*.mat'));
data = struct('Hz', {}, 'site', {}, 'test_retest', {}, 'freq', {}, 'power', {});

% Parse filenames and load data
for i = 1:length(files)
    % Skip hidden files
    if startsWith(files(i).name, '.')
        continue;
    end

    % Extract factors from filename
    file_parts = split(files(i).name, ' ');
    file_parts = split(file_parts(end), '_');
    data(i).Hz = str2double(extractBefore(file_parts{1}, 'Hz'));
    data(i).site = file_parts{4};

    % The paris dataset is formatted slightly differently to the rest
    if strcmp(data(i).site, 'paris')
        data(i).test_retest = extractBefore(file_parts{6}, '.mat');
    else
        data(i).test_retest = extractBefore(file_parts{5}, '.mat');
    end

    % Load data, grab frequency and power data and load into struct
    loaded_data = load(fullfile(files(i).folder, files(i).name));
    field_name = fieldnames(loaded_data);
    loaded_data = loaded_data.(field_name{1});
    data(i).freq = loaded_data(:, 1); % Frequency scale
    data(i).power = loaded_data(:, 2); % Power
end

% Identify unique factors
Hz_levels = unique([data.Hz]);
sites = unique({data.site});
tests = unique({data.test_retest});

% Initialize results
results = struct;

% Calculate averages for each specific combination
for h = 1:length(Hz_levels)
    for s = 1:length(sites)
        for t = 1:length(tests)
            % Filter relevant data
            subset = data([data.Hz] == Hz_levels(h) & strcmp({data.site}, sites{s}) & strcmp({data.test_retest}, tests{t}));

            % If empty skip to next subset
            if isempty(subset)
                continue;
            end

            % Aggregate frequency and power data
            freq_combined = subset(1).freq; % Assuming all share the same frequency scale
            power_combined = mean(cell2mat({subset.power}), 2, 'omitnan');

            % Save results
            results(h, s, t).Hz = Hz_levels(h);
            results(h, s, t).site = sites{s};
            results(h, s, t).test_retest = tests{t};
            results(h, s, t).freq = freq_combined;
            results(h, s, t).power = power_combined;

            % Save to file
            save_name = sprintf('%dHz_%s_%s.mat', Hz_levels(h), sites{s}, tests{t});
            save(fullfile(indiv_outpath, save_name), 'freq_combined', 'power_combined');
        end
    end
end

% Plot data
for h = 1:length(Hz_levels)
    fig = figure('units','normalized','outerposition',[0 0 1 1], 'visible', 'off');
    hold on;
    for s = 1:length(sites)
        for t = 1:length(tests)
            if ~isempty(results(h, s, t))
                plot(results(h, s, t).freq, results(h, s, t).power, ...
                    'DisplayName', sprintf('%s %s', sites{s}, tests{t}));
                fprintf(sprintf('Plotting %dHz - %s - %s\n', Hz_levels(h), sites{s}, tests{t}))
            end
        end
    end
    title(sprintf('%d Hz Averages', Hz_levels(h)));
    xlabel('Frequency (Hz)'); ylabel('SNR Power'); 
    xline(Hz_levels(h), '--', 'DisplayName', sprintf('%dHz', Hz_levels(h))); xlim([1 48])
    legend show;
    set(gcf, 'color', 'w')
    hold off;

    % Save plot
    [ppt] = addImgToPresentation('', ppt, sprintf('%d Hz Averages', Hz_levels(h)), fig);
    % saveas(gcf, fullfile(output_path, sprintf('%dHz_Averages.png', Hz_levels(h))));
end

% Group results by Hz, test/retest, and sites
group_results = struct;

% Group by Hz level
for h = 1:length(Hz_levels)
    subset = data([data.Hz] == Hz_levels(h));
    freq_combined = subset(1).freq;
    power_combined = mean(cell2mat({subset.power}), 2, 'omitnan');
    group_results(h).Hz = Hz_levels(h);
    group_results(h).freq = freq_combined;
    group_results(h).power = power_combined;

    % Save to file
    save_name = sprintf('%dHz_Group.mat', Hz_levels(h));
    save(fullfile(group_outpath, save_name), 'freq_combined', 'power_combined');
end

% Group by test/retest
for t = 1:length(tests)
    subset = data(strcmp({data.test_retest}, tests{t}));
    freq_combined = subset(1).freq;
    power_combined = mean(cell2mat({subset.power}), 2, 'omitnan');
    group_results(t + length(Hz_levels)).test_retest = tests{t};
    group_results(t + length(Hz_levels)).freq = freq_combined;
    group_results(t + length(Hz_levels)).power = power_combined;

    % Save to file
    save_name = sprintf('%s_Group.mat', tests{t});
    save(fullfile(group_outpath, save_name), 'freq_combined', 'power_combined');
end

% Group by site
for s = 1:length(sites)
    subset = data(strcmp({data.site}, sites{s}));
    freq_combined = subset(1).freq;
    power_combined = mean(cell2mat({subset.power}), 2, 'omitnan');
    group_results(s + length(Hz_levels) + length(tests)).site = sites{s};
    group_results(s + length(Hz_levels) + length(tests)).freq = freq_combined;
    group_results(s + length(Hz_levels) + length(tests)).power = power_combined;

    % Save to file
    save_name = sprintf('%s_Group.mat', sites{s});
    save(fullfile(group_outpath, save_name), 'freq_combined', 'power_combined');
end

%% Plot group results
% First grab the indices of the data to be plotted
t_rt_idx = [0 0];
for i = 1:length(group_results); if ~isempty(group_results(i).test_retest); if strcmp(group_results(i).test_retest, 'test'); t_rt_idx(1) = i; end; end; end
for i = 1:length(group_results); if ~isempty(group_results(i).test_retest); if strcmp(group_results(i).test_retest, 'retest'); t_rt_idx(2) = i;  end; end; end

Hz_idx = zeros(1, length(Hz_levels));
for h = 1:length(Hz_levels); for i = 1:length(group_results); if ~isempty(group_results(i).Hz); if group_results(i).Hz == Hz_levels(h); Hz_idx(h) = i; end; end; end; end

site_idx = zeros(1, length(sites));
for s = 1:length(sites); for i = 1:length(group_results); if ~isempty(group_results(i).site); if strcmp(group_results(i).site, sites{s}); site_idx(s) = i; end; end; end; end

% Next plot based on these indices
% Test vs retest
fig = figure('units','normalized','outerposition',[0 0 1 1], 'visible', 'off'); hold on;
for i = 1:length(t_rt_idx)
    plot(group_results(t_rt_idx(1)).freq, group_results(t_rt_idx(i)).power)
end

title('Grouped by test vs retest, across all sites and frequencies')
xlabel('Frequency (Hz)'); ylabel('SNR Power');
xlim([1 48]); xline([Hz_levels], '--');
set(gcf, 'Color', 'white'); legend({'test', 'retest'});

[ppt] = addImgToPresentation('', ppt, 'Group_test_vs_retest', fig);
close all

% By frequency
fig = figure('units','normalized','outerposition',[0 0 1 1], 'visible', 'off'); hold on;
for i = 1:length(Hz_idx)
    plot(group_results(Hz_idx(1)).freq, group_results(Hz_idx(i)).power)
end

title('Grouped by frequency, across sites and test/retest')
xlabel('Frequency (Hz)'); ylabel('SNR Power');
xlim([1 48]); xline([Hz_levels], '--');
set(gcf, 'Color', 'white'); legend(split(num2str(Hz_levels), '  '));

[ppt] = addImgToPresentation('', ppt, 'Group_by_freq', fig);
close all

% By Site
fig = figure('units','normalized','outerposition',[0 0 1 1], 'visible', 'off'); hold on;
for i = 1:length(site_idx)
    plot(group_results(site_idx(1)).freq, group_results(site_idx(i)).power)
end

title('Grouped by site, across freqs and test/retest')
xlabel('Frequency (Hz)'); ylabel('SNR Power');
xlim([1 48]); xline([Hz_levels], '--');
set(gcf, 'Color', 'white'); legend(sites);

[ppt] = addImgToPresentation('', ppt, 'Group_by_site', fig);
close all

disp('Saving ...')
close(ppt);
disp('Group results computed, saved, and plotted.');

end