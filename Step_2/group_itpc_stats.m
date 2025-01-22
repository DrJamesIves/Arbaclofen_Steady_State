function group_itpc_stats

% Author: James Ives | james.white1@bbk.ac.uk / james.ernest.ives@gmail.com
% Date: 22nd January 2025
% Released under GNU GPL v3.0: https://www.gnu.org/licenses/gpl-3.0.html
% Open to collaboration—feel free to contact me!

% The purpose of this function is to take SNR values and calculate group stats.
% These are saved in the output files along with a presentation of figures.

% Define paths
root = 'E:\Birkbeck\Arbaclofen';
% Takes a list of the data types that are to be grouped and analysed
root_paths = {fullfile(root, '500ms audio'); fullfile(root, '1000ms audio'); fullfile(root, '1000ms video')};
% Adds suffixes to the above, this is for regional groupings and could be replaced with '' for no suffix
outpath_suffixes = {'_Fz_Cz_only'; '_Fz_Cz_only'; '_Occipital_only'};

% Cycle through the root_paths
for r = length(root_paths)

    % Sets the input and output paths
    root_path = root_paths{r};
    itpc_data_path = fullfile(root_path, ['ITPC_data', outpath_suffixes{r}]);
    output_path = fullfile(root_path, 'Averages');
    indiv_outpath = fullfile(output_path, 'Individual Conditions');
    group_outpath = fullfile(output_path, 'Grouped by factor');
    output_paths = {output_path; indiv_outpath; group_outpath};

    % If output paths don't exist then create them
    for path = 1:length(output_paths)
        if ~exist(output_paths{path}, 'dir')
            mkdir(output_paths{path});
        end
    end

    clear output_paths

    % Create presentations
    % All groups will go into one presentation
    [ppt] = createPresentation(output_path, 'itpc_averages.pptx', 'Averages');

    % Load files
    files = dir(fullfile(itpc_data_path, '*.mat'));
    data = struct('Hz', {}, 'site', {}, 'test_retest', {}, 'itpc', {});

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

        % The paris cohort have been formatted slightly differently
        if strcmp(data(i).site, 'paris')
            data(i).test_retest = extractBefore(file_parts{6}, '.mat');
        else
            data(i).test_retest = extractBefore(file_parts{5}, '.mat');
        end

        % Load data
        load(fullfile(files(i).folder, files(i).name));
        data(i).itpc = squeeze(itpc); % Power
    end

    clear files file_parts itpc

    % Get the minimum time length and trim all data to be consistent with that
    third_dim_size = zeros(size(data, 2), 1);
    for i = 1:size(data, 2)
        if ~isempty(data(i).itpc)
            third_dim_size(i) = size(data(i).itpc, 3);
        end
    end

    min_size = min(third_dim_size);

    for i = 1:size(data, 2)
        if ~isempty(data(i).itpc)
            data(i).itpc = data(i).itpc(:, :, 1:min_size);
        end
    end

    % Calculate a new time_axis for the shortened data
    time_axis = linspace(2,min_size * 2, min_size);

    clear min_size third_dim_size

    % Identify unique factors
    Hz_levels = unique([data.Hz]);
    sites = unique({data.site});
    tests = unique({data.test_retest});

    % Calculate averages for each specific combination
    for h = 1:length(Hz_levels)
        for s = 1:length(sites)
            for t = 1:length(tests)
                % Filter relevant data
                subset = data([data.Hz] == Hz_levels(h) & strcmp({data.site}, sites{s}) & strcmp({data.test_retest}, tests{t}));

                if isempty(subset)
                    continue;
                end

                % Aggregate frequency and itpc data
                itpc_combined = cat(4, subset.itpc);
                clear subset
                itpc_combined = squeeze(mean(mean(itpc_combined, 4), 1));

                % Save to file
                save_name = sprintf('%dHz_%s_%s.mat', Hz_levels(h), sites{s}, tests{t});
                save(fullfile(indiv_outpath, save_name), 'log_frequencies', 'time_axis', 'itpc_combined');

                [~, ppt] = plot_itpc(time_axis, log_frequencies, itpc_combined, ppt, sprintf('%dHz %s %s', Hz_levels(h), sites{s}, tests{t}));

                clear itpc_combined
            end
        end
    end

     %% Sub groups
    % Grouped across one variable but split by others.

    % subgroup_results = struct;
    for h = 1:length(Hz_levels)
        for t = 1:length(tests)
            subset = data([data.Hz] == Hz_levels(h) & strcmp({data.test_retest}, tests{t}));
            itpc_combined = cat(4, subset.itpc);
            clear subset
            itpc_combined = squeeze(mean(mean(itpc_combined, 4), 1));

            % Save to file
            save_name = sprintf('%dHz_%s_all_sites.mat', Hz_levels(h), tests{t});
            save(fullfile(group_outpath, save_name), 'log_frequencies', 'time_axis', 'itpc_combined');

            % Add to the powerpoint
            [~, ppt] = plot_itpc(time_axis, log_frequencies, itpc_combined, ppt, sprintf('%dHz %s %s', Hz_levels(h), sites{s}, tests{t}));

            clear itpc_combined
        end
    end

    % Group by Hz level
    for h = 1:length(Hz_levels)
        subset = data([data.Hz] == Hz_levels(h));
        itpc_combined = cat(4, subset.itpc);
        clear subset
        itpc_combined = squeeze(mean(mean(itpc_combined, 4), 1));
        group_results(h).Hz = Hz_levels(h);
        group_results(h).itpc = itpc_combined;

        % Save to file
        save_name = sprintf('%dHz_Group.mat', Hz_levels(h));
        save(fullfile(group_outpath, save_name), 'log_frequencies', 'time_axis', 'itpc_combined');

        % Add to the powerpoint
        [~, ppt] = plot_itpc(time_axis, log_frequencies, itpc_combined, ppt, sprintf('%dHz, grouped across sites and test-retest', Hz_levels(h)));

        clear itpc_combined
    end

    % Group by test/retest
    for t = 1:length(tests)
        subset = data(strcmp({data.test_retest}, tests{t}));
        itpc_combined = cat(4, subset.itpc);
        clear subset
        itpc_combined = squeeze(mean(mean(itpc_combined, 4), 1));
        group_results(t + length(Hz_levels)).test_retest = tests{t};
        group_results(t + length(Hz_levels)).itpc = itpc_combined;

        % Save to file
        save_name = sprintf('%s_Group.mat', tests{t});
        save(fullfile(group_outpath, save_name), 'log_frequencies', 'time_axis', 'itpc_combined');

        % Add to the powerpoint
        [~, ppt] = plot_itpc(time_axis, log_frequencies, itpc_combined, ppt, sprintf('%s, grouped across freqs and sites', tests{t}));

        clear itpc_combined
    end

    % Group by site
    for s = 1:length(sites)
        subset = data(strcmp({data.site}, sites{s}));
        itpc_combined = cat(4, subset.itpc);
        clear subset
        itpc_combined = squeeze(mean(mean(itpc_combined, 4), 1));
        group_results(s + length(Hz_levels) + length(tests)).site = sites{s};
        group_results(s + length(Hz_levels) + length(tests)).itpc = itpc_combined;

        % Save to file
        save_name = sprintf('%s_Group.mat', sites{s});
        save(fullfile(group_outpath, save_name), 'log_frequencies', 'time_axis', 'itpc_combined');

        % Add to the powerpoint
        [~, ppt] = plot_itpc(time_axis, log_frequencies, itpc_combined, ppt, sprintf('%s, grouped across freqs and test-retest', sites{s}));

        clear itpc_combined
    end

    disp('Saving ...')
    close(ppt);
    clear ppt
    disp('Group results computed, saved, and plotted.');
end

end