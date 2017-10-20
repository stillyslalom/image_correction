%% Set-up
addpath('functions') % Add scripts in functions folder to search path
baseDir = pwd;

%% Settings
frames = 11;       % Vector of frames to load from image, optionally 'all'
do_notch = false;   % Perform FFT-based notch filter to reduce striations
do_bg = false;   % Perform background subtraction
dkr1=960; dkr2=980; dkc1=100; dkc2=200; % dark region for background
rowtop=200;rowlow=500; % rows of uniform seeding, laser attenuation correction
colleft=200; colright=1200; % columns of uniform seeding
rowtopA=200;rowlowA=300; % rows of uniform seeding, final image
%% read in raw image (last in tif series)
%imgRaw = imread('1_andor.tif',frames);            % Andor
%
% imgRawBoth = imread('B00010_lavision.tif');            % Lavision
% imgRaw = imgRawBoth(1:1024,:);                % Lavision

Xlimits = [0.05, 0.95]; % Relative acetone concentration lim for img crop
pxcm = 40.72;        % Pixels per cm in imaging plane of input images
%andor_pxcm = 40.72
%lavision_pxcm = 63.47
pad_px = 1024;      % Number of pixels to pad above/below cropped image

imgRaw = lavision_a;
imgRaw = imgRaw/max(imgRaw(:));

%% read in background images (mulipage tif, not including last in series)
imgRaw = double(imgRaw);
img=imgRaw;
[nrow ncol]=size(imgRaw);
if do_bg
imgBgfull=zeros(nrow,ncol,frames-1);
for mm = 1:frames-1;
    imgBgfull(:,:,mm) = imread('1_andor.tif',mm);
end
imgBgfull = double(imgBgfull);
imgBg=mean(imgBgfull,3);
%% background subtraction
img = imgRaw-imgBg;
end
% darkreg = mean2(img(dkr1:dkr2,dkc1:dkc2)); %dark region of image
% img = img - darkreg;
img(img<0) = 0;
img = img / max(max(img));
%% place marking crosses
% img(3,3)=1;img(2,3)=1;img(4,3)=1;img(3,2)=1;img(3,4)=1;
% img(1022,1022)=1;img(1023,1022)=1;img(1021,1022)=1;
% img(1022,1021)=1;img(1022,1023)=1;
% img(1022,510)=1;img(1023,510)=1;img(1021,510)=1;
% img(1022,511)=1;img(1022,509)=1;
imagesc(img), colormap gray; colorbar
%% locate origin of laser striations
[origin, lines] = laserorigin_JGO(img);
hold on;
title(['Verify that green lines are collinear with laser striations. '...
       'Modify laserorigin.m if necessary.']);
for k = 1:length(lines)
   xy = [lines(k).point1; lines(k).point2];
   plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
end
hold off
pause(0.5); 
close
%% Transform image so laser striations are vertical
imgT = lasertransform(img, origin, 'forward');

%% Correct for laser attenuation
imgCorr=imgT*0;
imgTf=imgaussfilt(imgT,3);
imgTf=imgT;
abs_col=zeros(ncol,1);
intercept=zeros(ncol,1);
for k=1:ncol-12
    intcolumn=imgTf(:,k);
    x=[rowtop:rowlow]';
    y=intcolumn(rowtop:rowlow);
    logy=log(y);
    linefit=polyfit(x,logy,1);
    intercept(k)=real(exp(linefit(2)));
    abs_col(k)=real(linefit(1));
%    imgCorr(:,k)=imgT(:,k)./intabs'; % divides by curvefit for correction
% this makes mixed regions lighter (in error) because it assumes entire
% region is uniformly seeded
end
% obtain correction by dividing by integral of signal (Weber thesis eq 4.8)
correct=zeros(nrow,1);
for k=1:ncol-12
    correct=intercept(k)+abs_col(k)*cumtrapz(imgTf(:,k));
    imgCorr(:,k)=imgT(:,k)./correct; % corrects for attenuation
end
imgCorr(isnan(imgCorr)) = 0; 
%% Perform notch filter to remove banding
out=imgCorr;
pad_size = 64;  % Number of pixels to pad around FFT image
rm_i = (nrow/2 - 3):(nrow/2 + 3);
rm_j = [(ncol/4:ncol/2)-10 (ncol/2:3*ncol/4)+10];
if do_notch
    padded = padarray(out,[pad_size pad_size],  'symmetric');
    F = fftshift(fft2(padded)); % FFT to freq. domain, swap quadrants for clarity
    F(rm_i + pad_size, rm_j + pad_size) = 0;       % Remove banded regions
    M = (gausswin(nrow+2*pad_size,1) * gausswin(ncol+2*pad_size, 1)'); % Use Gaussian to remove noise
    G = M .* F;
    out = real(ifft2(ifftshift(G)));
    out = out(pad_size + 1:nrow + pad_size, pad_size + 1:ncol + pad_size);
end
imgCorr=out;
%% Correct for non-uniform beam profile and artifacts from notch
imgTemp=imgCorr;
% imgTf=imgaussfilt(imgTemp,3);
imgTf=imgTemp;
% meanuniform=mean2(imgTemp(rowtop:rowlow,colleft:colright));
for k=1:ncol
    imgTemp(:,k)=imgTemp(:,k)/mean(imgTf(rowtop:rowlow,k));
end
imgCorr=imgTemp;
imgCorr(isnan(imgCorr)) = 0; 
%% Transform back to Cartesian frame
imgFinal = lasertransform(imgCorr, origin, 'inverse');
imgFinal = imgFinal/mean2(imgFinal(rowtopA:rowlowA, colleft:colright));

X = acetoneX(medfilt2(imgCorr), abs_col, pxcm, Xlimits, pad_px);

% Xm = nanmean(X');
% Xm = Xm/max(Xm(:));
% for i = 1:801
% X2(:,i) = X(:,i)./Xm';
% end
% 
% Xm = nanmean(X);
% Xm = Xm/max(Xm(:));
% for i = 1:701
% X2(i,:) = X2(i,:)./Xm;
% end


imagesc(imgFinal,[0 1.05]); colormap gray; colorbar;
set(gcf,'color','w');