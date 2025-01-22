function [Colours]=GenColours;

%         Red Blue Green Purple Yellow 

Colours=[1.0000         0         0; 0         0    1.0000; 0.1961    0.8039    0.1961; 0.5804         0    0.8275; 1.0000    1.0000         0;  1.0000    0.5490         0; 0.6275    0.3216    0.1765; 0    1.0000    1.0000; 0.9333    0.5098    0.9333; 0.8471    0.290    0.8471];
tempsize=size(Colours,1);
% 
% figure
% for i=1:length(Colours)
%     scatter(i,1,40,Colours(i,:),'Filled')
%     hold on
% end

for i=1:1000
    writeline=tempsize+i;
    Colours(writeline,:)=[randi(100)/100 randi(100)/100 randi(100)/100];
end



return