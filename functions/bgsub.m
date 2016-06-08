function out = bgsub(img, bgpath)
bg = tifread(bgpath, 'all');
bgmean = mean(bg,3);
out = img;
dims = size(out); n = dims(3);
for i = 1:n
    out(:,:,i) = out(:,:,i) - bgmean;
end

out(out < 0) = 0; % Replace values less than zero with zero
return