function out = particleize(img)
%% Settings
sigma = 1;

%% Binary morphology
im = imgaussfilt(img, sigma);
BW1 = imregionalmax(im);
BW2 = bwmorph(BW1, 'thicken',1);

%% Application of particle mask to input image
BW3 = imgaussfilt(double(BW2),1);
BW4 = imadjust(BW3);

out = img .* BW4;