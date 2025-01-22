function [ppt] = createPresentation(savePath, saveName, title)
% 
% Written by James Ives - u2067263@uel.ac.uk 06/11/2021
% 

% Note, if you don't close the presentation then it won't save you can save
% it with close(ppt);

% Create a presentation
import mlreportgen.ppt.*

if nargin < 3
    title = saveName;
end

ppt = Presentation(strcat(savePath, '/', saveName, ".pptx"));
open(ppt);

% Add a slide to the presentation
slide = add(ppt,"Title and Content");

% Add title to the slide
replace(slide,"Title",title);

end