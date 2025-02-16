function [ppt] = addImgToPresentation(outDir, ppt, title, fig)

% Author: James Ives | james.white1@bbk.ac.uk / james.ernest.ives@gmail.com
% Date: 6th November 2021
% Released under GNU GPL v3.0: https://www.gnu.org/licenses/gpl-3.0.html
% Open to collaboration—feel free to contact me!

% Note, if you don't close the presentation then it won't save you can save
% it with close(ppt);

% The purpose of this function is to add images to a presentation object that can
% has been created by createPresentation.

warning('off', 'MATLAB:MKDIR:DirectoryExists');

if isempty(outDir)
    outDir = 'C:\Users\james\Pictures\Temp\';
    if ~exist("outDir", 'dir')
        mkdir(outDir)
    end
end

% Note you must have imported mlreportgen.ppt* for this to work, see next
% line
import mlreportgen.ppt.*

title = replace(title, ' ', '_');
% ppt = Presentation(strcat(savePath, '/', saveName, ".pptx"));
% open(ppt);

% Add a slide to the presentation
slide = add(ppt,"Title and Content");

% Add title to the slide
replace(slide,"Title",title);

% Save that figure as an image
% We add in a random number each time in case your images and slide
% generation are part of a loop where there might not be different titles
% (and therefore different image filenames)
figImage = strcat(outDir, title, num2str(round(rand * 1000)), ".png");
print(fig,"-dpng",figImage);

% Create a Picture object using the figure snapshot image file
figPicture = Picture(figImage);

% Add the figure snapshot picture to the slide
replace(slide,"Content",figPicture);

% close(ppt);

end
