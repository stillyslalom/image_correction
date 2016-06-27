function [out, A] = beamcorrection(I,const_y)
%% img_out = beamcorrection(img_in, const_y)
% img_in: input image with vertical laser striations
% const_y: region of image with constant mole-fraction acetone
% Corrects for non-uniform beam profile, attenuation, and banding

%% Settings
sigma = 3; % For Gaussian filter of reference image for beam profile corr.
[ni, nj] = size(I);
% Select regions to remove: horizontal stripes corresponding to bands
rm_i = (ni/2 - 3):(ni/2 + 3);
rm_j = [(nj/4:nj/2)-10 (nj/2:3*nj/4)+10];

%% Constants
Irange = [min(min(I)); max(max(I))];
ymin = const_y(1); ymax = const_y(end);

%% Reference values
Ig = imgaussfilt(I,sigma);
row_avg = mean(Ig(ymax,:)); % Avg intensity at bottom of const concentration
col_avg = mean(Ig,2); % Average intensity along laser path
% Absorption per pixel in uniform region ~ exp((1-A)x)
A = 1 - mean(col_avg(ymin:ymax-1)./col_avg(ymin+1:ymax)); 

%% Correct for non-uniform beam profile
out = I;
for j = 1:nj
    out(:,j) = out(:,j)*row_avg/Ig(ymax,j);
end

%% Correct for attenuation
I_int_scale = row_avg * ones(ni,nj) + A * cumtrapz(Ig);
out = out ./ I_int_scale;
% Re-normalize to intensity of input image
outrange = [min(min(out)); max(max(out))];
out = (out + Irange(1) - outrange(1)) * diff(Irange)/diff(outrange);


%% Perform notch filter to remove banding
F = fftshift(fft2(out)); % FFT to freq. domain, swap quadrants for clarity
F(rm_i, rm_j) = 0;       % Remove banded regions
M = (gausswin(ni,1) * gausswin(nj, 1)'); % Use Gaussian to remove noise
G = M .* F;
out = real(ifft2(ifftshift(G)));

return
%imshowpair(imadjust(I),imadjust(out),'montage')