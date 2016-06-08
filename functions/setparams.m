function param_path = setparams(imgDir, do_bgsub)
%% setparams('path/to/imgfolder/', true|false)
%% Attempt to load parameters from file 
try 
    if imgDir(end) ~= '\' % Make concatenation w/ file lead to valid path
        imgDir(end+1) = '\';
    end
    param_path = [imgDir 'params.mat'];
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
pxcm = 55.5; % input('Pixels/cm (for attenuation coefficient): ');
frame = 1; % input('Choose TIF frame used to select ROIs: ');

%% Load first image frame
baseDir = pwd;
cd(imgDir)
[iname,idir] = uigetfile('*.tif','Select the signal .tif file');
imgpath = [idir iname];
img = im2double(imread(imgpath, frame));

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
       'Modify laserorigin.m if necessary. Press any key to close.']);
for k = 1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
end
hold off
waitforbuttonpress; close

%% Save parameters to file
param_path = [imgDir 'params.mat']; % Save params in same dir as signal img
if do_bgsub
    save(param_path, 'pxcm', 'imgpath', 'const_molreg', 'origin', ...
                    'bgpath', 'bkgd')
else
    save(param_path, 'pxcm', 'imgpath', 'const_molreg', 'origin')
end

return