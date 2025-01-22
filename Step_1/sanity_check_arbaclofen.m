function sanity_check_arbaclofen

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

% These are some sanity checks before we start.
% Checking the saved names of the data when loaded (not consistent), 
% number of samples and number of events (ideally above 0), 
% and if there are events what are they.

files = dir('E:\Birkbeck\Arbaclofen\Raw_data\');

main_ssvep_codes = [101, 102, 103, 104, 105];
intervening_codes = [111, 112];

% Set up a structure for the sanity check
info = struct;
[info.saveNames, info.numSamples, info.numEvents, info.events, info.assrEvents, info.ssvepEvents, info.avg10HzASSRLength, info.avg40HzASSRLength, ...
    info.avg1HzSSVEPLength, info.avg3HzSSVEPLength, info.avg6HzSSVEPLength, info.avg10HzSSVEPLength, info.avg15HzSSVEPLength, ...
    info.mainSSVEPLengths, info.interveningLengths] = deal([]);

% Loop through the files
for idx = 1:length(files)
    % Do not process any hidden files
    if startsWith(files(idx).name, '.')
        continue
    end

    % Load in with a surrogate variable
    loadIn = load(fullfile(files(idx).folder, files(idx).name));

    % Find the fieldname and use that to replace ft (some names were different)
    fieldname = fieldnames(loadIn);
    if size(fieldname) ~= [1 1]
        fprintf([files(idx).name, ' - ', size(fieldname)])
    else
        fieldname = fieldname{1,1};
    end

    % Save the save name
    info.saveNames = [info.saveNames; {fieldname}];

    % save the number of samples, events, assr events, ssvep events and the actual event numbers/values etc
    ft = loadIn.(fieldname);
    info.numSamples = [info.numSamples; size(ft.trial{1,1}, 2)];
    info.numEvents = [info.numEvents; size(ft.events, 1)];
    info.events = [info.events; {ft.events}];
    info.assrEvents = [info.assrEvents; [length(find(vertcat(ft.events.value) == 40)), length(find(vertcat(ft.events.value) == 41)), ...
        length(find(vertcat(ft.events.value) == 70)), length(find(vertcat(ft.events.value) == 71))]];
    info.ssvepEvents = [info.ssvepEvents; [length(find(vertcat(ft.events.value) == 111)), length(find(vertcat(ft.events.value) == 112)), ...
        length(find(vertcat(ft.events.value) == 101)), length(find(vertcat(ft.events.value) == 102)), ...
        length(find(vertcat(ft.events.value) == 103)), length(find(vertcat(ft.events.value) == 104)), ...
        length(find(vertcat(ft.events.value) == 105)), length(find(vertcat(ft.events.value) == 110))]];

    % Create an array with the sample of the 10/40Hz onset and the next sample along, then take the difference, then average per ppt
    avg10HzASSRLength = [vertcat(ft.events(find(vertcat(ft.events.value) == 40)).sample), ...
        vertcat(ft.events(find(vertcat(ft.events.value) == 40) + 1).sample)];
    if isempty(avg10HzASSRLength)
        avg10HzASSRLength = NaN; 
    else
        info.avg10HzASSRLength = [info.avg10HzASSRLength; mean(avg10HzASSRLength(:, 2) - avg10HzASSRLength(:, 1))/ft.fsample];
    end

    avg40HzASSRLength = [vertcat(ft.events(find(vertcat(ft.events.value) == 41)).sample), ...
        vertcat(ft.events(find(vertcat(ft.events.value) == 41) + 1).sample)];
    if isempty(avg40HzASSRLength)
        avg40HzASSRLength = NaN;
    else
        info.avg40HzASSRLength = [info.avg40HzASSRLength; mean(avg40HzASSRLength(:, 2) - avg40HzASSRLength(:, 1))/ft.fsample];
    end

    %% Tried to replicate the above but for the ssvep, but it doesn't work in that way because of the intervening events (111, 112) which show when
    % the stimuli were shown.
    %
    % avg1HzSSVEPLength = [vertcat(ft.events(find(vertcat(ft.events.value) == 41)).sample), ...
    %     vertcat(ft.events(find(vertcat(ft.events.value) == 41) + 1).sample)];
    % if isempty(avg1HzSSVEPLength)
    %     avg1HzSSVEPLength = NaN; 
    % else
    %     info.avg1HzSSVEPLength = [info.avg1HzSSVEPLength; mean(avg1HzSSVEPLength(:, 2) - avg1HzSSVEPLength(:, 1))/ft.fsample];
    % end
    % 
    % avg3HzSSVEPLength = [vertcat(ft.events(find(vertcat(ft.events.value) == 41)).sample), ...
    %     vertcat(ft.events(find(vertcat(ft.events.value) == 41) + 1).sample)];
    % if isempty(avg3HzSSVEPLength)
    %     avg3HzSSVEPLength = NaN; 
    % else
    %     info.avg3HzSSVEPLength = [info.avg3HzSSVEPLength; mean(avg3HzSSVEPLength(:, 2) - avg3HzSSVEPLength(:, 1))/ft.fsample];
    % end
    % 
    % avg6HzSSVEPLength = [vertcat(ft.events(find(vertcat(ft.events.value) == 41)).sample), ...
    %     vertcat(ft.events(find(vertcat(ft.events.value) == 41) + 1).sample)];
    % if isempty(avg6HzSSVEPLength)
    %     avg6HzSSVEPLength = NaN; 
    % else
    %     info.avg6HzSSVEPLength = [info.avg6HzSSVEPLength; mean(avg6HzSSVEPLength(:, 2) - avg6HzSSVEPLength(:, 1))/ft.fsample];
    % end
    % 
    % avg10HzSSVEPLength = [vertcat(ft.events(find(vertcat(ft.events.value) == 41)).sample), ...
    %     vertcat(ft.events(find(vertcat(ft.events.value) == 41) + 1).sample)];
    % if isempty(avg10HzSSVEPLength)
    %     avg10HzSSVEPLength = NaN; 
    % else
    %     info.avg10HzSSVEPLength = [info.avg10HzSSVEPLength; mean(avg10HzSSVEPLength(:, 2) - avg10HzSSVEPLength(:, 1))/ft.fsample];
    % end
    % 
    % avg15HzSSVEPLength = [vertcat(ft.events(find(vertcat(ft.events.value) == 41)).sample), ...
    %     vertcat(ft.events(find(vertcat(ft.events.value) == 41) + 1).sample)];
    % if isempty(avg15HzSSVEPLength)
    %     avg15HzSSVEPLength = NaN; 
    % else
    %     info.avg15HzSSVEPLength = [info.avg15HzSSVEPLength; mean(avg15HzSSVEPLength(:, 2) - avg15HzSSVEPLength(:, 1))/ft.fsample];
    % end

    %% Second (chat GPT attempt) does a good job with some issues, but generally good

    % % Define main and intervening codes
    % main_codes = [101, 102, 103, 104, 105];
    % intervening_codes = [111, 112];
    % 
    % Filter for relevant events
    % relevant_codes = [main_codes, intervening_codes];
    % filtered_events = ft.events(ismember([ft.events.value], relevant_codes));
    % 
    % % Find indices of main codes
    % main_indices = find(ismember([filtered_events.value], main_codes));
    % 
    % % Create sections
    % sections = cell(1, length(main_indices));
    % for i = 1:length(main_indices)
    %     if i < length(main_indices)
    %         sections{i} = filtered_events(main_indices(i):main_indices(i+1)-1);
    %     else
    %         sections{i} = filtered_events(main_indices(i):end);
    %     end
    % end
    % 
    % % Initialize results array
    % results = zeros(length(sections), 4); % Columns: [MainCode, SampleDiff, MeanInterveningDiff, StdInterveningDiff]
    % 
    % for i = 1:length(sections)
    %     % Get the main code for this section
    %     main_event = sections{i}(1);
    %     results(i, 1) = main_event.value;
    % 
    %     % Compute difference to next section's first event
    %     if i < length(sections)
    %         next_main_event = sections{i+1}(1);
    %         results(i, 2) = next_main_event.sample - main_event.sample;
    %     else
    %         results(i, 2) = NaN; % No next section
    %     end
    % end
    % 
    % for i = 1:length(sections)
    %     % Extract intervening events
    %     intervening_events = sections{i}(ismember([sections{i}.value], intervening_codes));
    % 
    %     if length(intervening_events) > 1
    %         % Compute differences between intervening samples
    %         intervening_diffs = diff([intervening_events.sample]);
    % 
    %         % Store mean and std in the results array
    %         results(i, 3) = mean(intervening_diffs);
    %         results(i, 4) = std(intervening_diffs);
    %     else
    %         % Not enough intervening events to calculate differences
    %         results(i, 3:4) = NaN;
    %     end
    % end
    % 
    % function results = analyze_event_sections(ft, main_codes, intervening_codes)
    %     % Filter for relevant events
    %     relevant_codes = [main_codes, intervening_codes];
    %     filtered_events = ft.events(ismember([ft.events.value], relevant_codes));
    % 
    %     % Find indices of main codes
    %     main_indices = find(ismember([filtered_events.value], main_codes));
    % 
    %     % Create sections
    %     sections = cell(1, length(main_indices));
    %     for i = 1:length(main_indices)
    %         if i < length(main_indices)
    %             sections{i} = filtered_events(main_indices(i):main_indices(i+1)-1);
    %         else
    %             sections{i} = filtered_events(main_indices(i):end);
    %         end
    %     end
    % 
    %     % Initialize results array
    %     results = zeros(length(sections), 4); % [MainCode, SampleDiff, MeanInterveningDiff, StdInterveningDiff]
    % 
    %     for i = 1:length(sections)
    %         % Get main code and compute sample difference
    %         main_event = sections{i}(1);
    %         results(i, 1) = main_event.value;
    %         if i < length(sections)
    %             next_main_event = sections{i+1}(1);
    %             results(i, 2) = next_main_event.sample - main_event.sample;
    %         else
    %             results(i, 2) = NaN; % No next section
    %         end
    % 
    %         % Compute intervening differences
    %         intervening_events = sections{i}(ismember([sections{i}.value], intervening_codes));
    %         if length(intervening_events) > 1
    %             intervening_diffs = diff([intervening_events.sample]);
    %             results(i, 3) = mean(intervening_diffs);
    %             results(i, 4) = std(intervening_diffs);
    %         else
    %             results(i, 3:4) = NaN;
    %         end
    %     end
    % end


    % Print data that has no samples or events to save for later.
    if size(ft.trial{1,1}, 2) == 0
        fprintf('No samples in\t\t%s\n', files(idx).name)
    end
    if size(ft.events, 1) == 0
        fprintf('No events in\t\t%s\n', files(idx).name)
    end 
end

tdisp('Here')

end