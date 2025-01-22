function [ppt] = addImgToPresentation(outDir, ppt, title, fig)

% 
% Written by James Ives - u2067263@uel.ac.uk 06/11/2021
% 

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