function out = bgsub(img, bg)
bgmedian = median(bg,3);
out = img;
dims = size(out); 

if length(dims) == 3
    n = dims(3);
else
    n = 1;
end

for i = 1:n
    min_vals = min(out(:,:,i), bgmedian);
    out(:,:,i) = out(:,:,i) - min_vals;
end

%out(out < 0) = 0; % Replace values less than zero with zero
return