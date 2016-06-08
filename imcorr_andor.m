%% Set-up
clear, clc, close all
addpath('functions') % Add scripts in functions folder to search path
baseDir = pwd;

%% Settings
frames = 1:5;       % Vector of frames to load from image
do_bgsub = true;    % Perform background subtraction

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

param_path = setparams(imgDir, do_bgsub);
load(param_path);
if ~isempty(imgName)
    imgpath = [imgDir imgName];
end

%% Load image (with optional background subtraction)
img = tifread(imgpath, frames);
if do_bgsub
    img = bgsub(img,bgpath);
end

%% Transform image so laser striations are vertical
imgT = lasertransform(img, origin, 'forward');

%% Correct for laser attenuation & non-uniform beam profile
const_y = const_molreg(2):const_molreg(4);
imgCorr = imgT;
for i = 1:length(frames)
    imgCorr(:,:,i) = beamcorrection(imgT(:,:,i), const_y);
end

%% Transform back to Cartesian frame
imgFinal = lasertransform(imgCorr, origin, 'inverse');

%% Compare results
imshowpair(imadjust(img(:,:,1)),imadjust(imgFinal(:,:,1)),'montage')
