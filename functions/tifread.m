function tif_img = tifread(path,frames)
%% tif_img = tifread(path, frames)
% path: absolute path to TIFF image file
% frames: scalar or vector of image frames to load.
%         Use frames = 'all' to load all frames in file.
% tif_img: array of image(s) converted to float64 in the range 0:1

n_img = length(imfinfo(path)); % Get number of frames in file
if strcmp(frames,'all')
    frames = 1:n_img;
    n_frames = n_img;
else
    n_frames = length(frames);
end

mf = max(frames); smf = num2str(mf);
if mf > n_img
    error(['Error: tried to access frame ' smf ...
           ' from file with ' n_img ' frames'])
end

tif_img = imread(path,frames(1));

if n_frames > 1
    tif_img = repmat(tif_img, [1 1 n_frames]);
    for i = 2:length(frames)
        tif_img(:,:,i) = imread(path,i);
    end
end

tif_img = im2double(tif_img);
return