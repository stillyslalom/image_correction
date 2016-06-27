function [origin, lines] = laserorigin(I)
%% [origin, lines] = laserorigin(img)
% I: 2D image with radial striations due to laser divergence
% origin: [x, y] location of laser origin with respect to top left pixel
% lines: set of detected striation lines used to calculate origin

%% Detect edges
threshold = 0.05;   % Edges with magnitude below threshold are discarded
sigma = 7;          % For Gaussian smoothing of image and edges
BW = edge(I,'canny',threshold,'vertical',sigma);
[GX, GY] = gradient(imgaussfilt(I,sigma));
% Take ratio of average gradients in x and y along y-axis to identify 
% horizontal edge of window (small gratio) and imaging region (large gratio
% due to striations)
gratio = mean(abs(GX),2)./mean(abs(GY),2);
% Mask top of image, which contains small gratio (degrades Hough transform)
mask_end = find(gratio > prctile(gratio,85),1);
BW(1:mask_end,:) = 0;

[H,theta,rho] = hough(BW, 'Theta', -10:.1:10);
% Find the peaks in the Hough transform matrix, H
% P   = houghpeaks(H,50,'threshold',ceil(0.5*max(H(:))));
P   = houghpeaks(H,50,'threshold',prctile(H(:),85));
lines = houghlines(BW,theta,rho,P,'FillGap',40,'MinLength',20);

YY  = tand(theta(P(:,2)))';
XX  = (rho(P(:,1))./cosd(theta(P(:,2))) )';
p = fit(XX,YY,'poly1','Robust','on');

% intersection of lines:
intY=1/p.p1;
intX=-p.p2/p.p1;
origin = [intX intY];
