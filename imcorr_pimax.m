%% Set-up
clear, clc, close all
addpath('functions') % Add scripts in functions folder to search path
baseDir = pwd;

%% Settings
framesA = 3:2:11;    % Vector of frames to load from image
framesB = framesA + 1;
%viewFrame = 1;      % Img frame to use for parameter generation
do_bgsub = true;    % Perform background subtraction
Xlimits = [0.05, 0.95]; % Relative acetone concentration lim for img crop
pxcm = 55.5;        % Pixels per cm in imaging plane of input images
pad_px = 0;         % Number of pixels to pad above/below cropped image
remove_speckle = false; % Time-consuming intensifier speckle removal

% Set directory containing image files via GUI. 
% Comment out & set directory directly if desired.
imgDir = uigetdir(baseDir, 'Select folder containing images');

% Set to '<image name>.tif to process image other than the one used to
% generate 'params.mat' (located in same imgDir, with same parameters)
imgName = '';

%% Run script
% Attempt to load pre-existing image parameters. 
% Loads 'pxcm', 'imgpath', 'const_molreg', 'origin'
% If do_bgsub = true, also loads 'bgpath', 'bkgd'
%
% 'pxcm': pixels/cm attenuation coef.
% 'imgpath', 'bgpath': absolute paths to image and background files
% 'const_molreg', 'bkgd'::[xmin ymin xmax ymax]: ROIs within image
% 'origin': [x, y] pixel location of laser sheet origin

param_path = setparams(imgDir, do_bgsub, framesB(1));
load(param_path);
if ~isempty(imgName)
    imgpath = [imgDir imgName];
end

%% Load image (with optional background subtraction)
imgA = tifread(imgpath, framesA);
imgB = tifread(imgpath, framesB);
[ni, nj, n] = size(imgA); % Number of input images to process

if do_bgsub
    bg = tifread(bgpath, 'all');
    bgA = bg(:,:,3:2:end-1);
    bgB = bg(:,:,4:2:end);
    imgA = bgsub(imgA, bgA);
    imgB = bgsub(imgB, bgB);
end

%% Median-filter images
for i = 1:n
    imgA(:,:,i) = medfilt2(imgA(:,:,i));
    imgB(:,:,i) = medfilt2(imgB(:,:,i));
end

%% Normalize intensity of image A to align with image B
imgAbar = median(imgA, 3);
imgBbar = median(imgB, 3);

imgstack = cat(3, imgA, imgB);

%% Transform image so laser striations are vertical
imgT = lasertransform(imgstack, origin, 'forward');

%% Correct for laser attenuation & non-uniform beam profile
const_y = const_molreg(2):const_molreg(4);
imgCorr = imgT;
A = zeros(2*n,1);

for i = 1:2*n
    [imgCorr(:,:,i), A(i)] = beamcorrection(imgT(:,:,i), const_y);
    imgCorr(:,:,i) = imadjust(imgCorr(:,:,i));
end

%% Remove speckle noise using anisotropic diffusion
if remove_speckle
    for i = 1:2*n
        I = imgCorr(:,:,i);
        out=dpad(I,.2,80,'cnoise',5,'big',15,'aja','aos');
        pctile = [2, 98];
        Irange = prctile(I(:),pctile);
        outrange = prctile(out(:),pctile);

        Ia = clamp(out, outrange(1), outrange(2));

        % Re-normalize to intensity of input image
        Ia = (Ia + Irange(1) - outrange(1)) * diff(Irange)/diff(outrange);
        imgCorr(:,:,i) = imadjust(Ia);
    end
end
%% Transform back to Cartesian frame
imgFinal = lasertransform(imgCorr, origin, 'inverse');

%% Find acetone concentration
X{2*n} = imgFinal(:,:,1); % Initialize output cell array for concentration
for i = 1:2*n
    X{i} = acetoneX(imgFinal(:,:,i), A(i), pxcm, Xlimits, pad_px);
end

%% Show results
crop_i = const_molreg(4):bkgd(2);
imgCrop = imgFinal(crop_i,:,:);
imgCompare = cat(2,imgFinal(:,:,1:n),imgFinal(:,:,n+1:end));

% Reshape to conform to Matlab's requirement of ni x nj x 1 x n array
imgCrop = reshape(imgCrop,[length(crop_i),nj,1,2*n]);
imgCompare = reshape(imgCompare,[ni,2*nj,1,n]);

montage(imgCrop)
m = implay(imgCompare,1);
mp = m.parent;
mp.Position = ceil(get(0,'ScreenSize')/2);
mp.Name = 'Image correction results';

pause(0.5) % Wait for screen to appear
% Simulate 'alt-t-m-p' keypress to make image player zoom to fit images
% using 'alt-t-m', then start playback using 'p'
keys = {'alt', 't', 'm', 'p'};
keyrobot(keys, 0.1);