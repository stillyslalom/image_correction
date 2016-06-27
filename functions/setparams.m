function param_path = setparams(imgDir, do_bgsub, frame)
%% param_path = setparams('path/to/imgfolder/', true|false, viewFrame)
%% Attempt to load parameters from file 
try 
    param_path = fullfile(imgDir, 'params.mat');
    load(param_path);
    return
catch
    choice = questdlg('Parameter file not found in image directory.', ...
        'Load parameters', ...
        'Load from file', 'Generate new params', 'Generate new params');
    if strcmp(choice, 'Load from file')
        [fname,dir] = uigetfile('*.mat','Select parameter file');
        param_path = [dir fname];
        return
    end
end

%% Set parameters if they cannot be loaded


%% Load first image frame
baseDir = pwd;
cd(imgDir)
[iname,idir] = uigetfile('*.tif','Select the signal .tif file');
imgpath = [idir iname];
img = im2double(imread(imgpath, frame));
img = medfilt2(img); % Perform median filtering to reduce noise

%% Load path to background subtraction region
if do_bgsub
    [bgname,bgdir] = uigetfile('*.tif','Select the background .tif file');
    bgpath = [bgdir bgname];
end
cd(baseDir)

%% Select normalization regions
norm_img = imadjust(img);
imshow(norm_img)
set(gcf, 'units','normalized','outerposition',[0 0 1 1]);

title('Select the constant mole fraction region', 'FontSize', 16)
const_molreg = round(getrect); % [xmin ymin width height]
% Change to [xmin ymin xmax ymax]: 
const_molreg(3:4) = const_molreg(1:2) + const_molreg(3:4) - 1;

if do_bgsub
    title('Select the background region')
    bkgd = round(getrect);
    bkgd(3:4) = bkgd(1:2) + bkgd(3:4) - 1;
end

%% Find laser beam origin
[origin, lines] = laserorigin(img);
hold on;
title(['Verify that green lines are collinear with laser striations. '...
       'Modify laserorigin.m if necessary.']);
for k = 1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
end
hold off
pause(2); 
close

%% Save params in same dir as signal img
param_path = fullfile(imgDir,'params.mat'); 
if do_bgsub
    save(param_path, 'imgpath', 'const_molreg', 'origin', ...
                    'bgpath', 'bkgd')
else
    save(param_path, 'imgpath', 'const_molreg', 'origin')
end

return