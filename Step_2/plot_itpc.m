function [fig, ppt] = plot_itpc(time_axis, itpc, ppt, inTitle)

% Author: James Ives | james.white1@bbk.ac.uk / james.ernest.ives@gmail.com
% Date: 22nd January 2025
% Released under GNU GPL v3.0: https://www.gnu.org/licenses/gpl-3.0.html
% Open to collaboration—feel free to contact me!

% The purpose of this function is to plot itpc data that has already been calculated.

% Expected lowest and highest frequency, change if this has changed in the preprocessing.
frequencies = 0.1:0.1:48;

% Plot ITPC across time and frequency for all electrodes (assumes all 20)
channel_labels = {'P7', 'P4', 'Cz', 'Pz', 'P3',...
    'P8', 'Oz', 'O2', 'T8', 'PO8',...
    'C4', 'F4', 'AF8', 'Fz', 'C3',...
    'F3', 'AF7', 'T7', 'PO7', 'FPz'};

fig = figure('units','normalized','outerposition',[0 0 1 1], 'visible', 'off');
imagesc(time_axis, frequencies, itpc); % Time-frequency plot
set(gca, 'YDir', 'normal'); % Ensure y-axis is from smallest to largest
% yticks(log10([1, 2, 3, 4, 5, 6, 10, 15, 40, 50, 100])); % Define specific tick marks
% yticklabels({'1', '2', '3', '4', '5', '6', '10', '15', '40', '50', '100'}); % Label ticks with original frequencies
xlabel('Time (s)');
ylabel('Frequency (Hz, log scale)');
title(inTitle);
colorbar;

% Save plot
[ppt] = addImgToPresentation('', ppt, inTitle, fig);

end