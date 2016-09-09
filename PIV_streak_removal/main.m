%% Load scripts
addpath(genpath('..\functions'));

%% Load images
[iname1,idir] = uigetfile('*.tif','Select the signal .tif file');
iname2 = [iname1(1:end-5), 'B.tif'];
img1 = tifread(fullfile(idir,iname1),'all');
img2 = tifread(fullfile(idir,iname2),'all');

%%
imshowpair(imadjust(img1),imadjust(img2))
set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
title('Select the constant mole fraction region', 'FontSize', 16)
streak_reg = round(getrect);
% Change to [xmin ymin xmax ymax]: 
streak_reg(3:4) = streak_reg(1:2) + streak_reg(3:4) - 1;

%%
xstreak = streak_reg(1):streak_reg(3);
ystreak = streak_reg(2):streak_reg(4);
streak1 = img1(ystreak,xstreak);
streak2 = img2(ystreak,xstreak);
% imshowpair(imadjust(streak1),imadjust(streak2))

%%
A = particleize(img1);
B = particleize(img2);
imshow(imadjust(A))

%%
imwrite(A,'imgA.tif')
imwrite(B,'imgB.tif')