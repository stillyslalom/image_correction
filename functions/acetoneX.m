function out = acetoneX(I, A, pxcm, Xlimits, pad_px)
%% out = acetoneX(I, A, pxcm, Ylimits, pad_px, maxval)
% I: input image
%
% A: Attenuation coefficient (typically 0 <= A < 0.1)
%
% pxcm: pixels per centimeter at imaging plane
%
% Xlimits: crops the returned image 'out' so row-median values fall in the
%   defined fractional limits relative to X0, e.g. [0.05, 0.95]. 
%
% pad_px: # of pixels to pad above and below concentration limits. Set to
%   the vertical dimension of the image to override concentration cropping.
% I = imgFinal(:,:,1);
% A = A(1);
% Xlimits = [0.1, 0.9];
% pad_px = 1024;

%% Define constants (units: g, cm, mol)
B = A;              % counts/pix Measured attenuation
%B = -(1 - A);      % Definition given in JGO's ref doc; gives bad X0 vals
sigma = 1.5e-20;    % cm^2  Photo-physical absorption coefficient at 308 nm
rho = 2.33e-3;      % g/cm^3 Acetone density at STP
MW = 58.08;         % g/mol Molecular weight of acetone
NA = 6.022e23;      % 1/mol Avogadro's constant

%% Calculate variables
C0 = B*pxcm/sigma;  % 1/cm^3 Molecular number density in uniform region
X0 = C0*MW/(rho*NA); % Mole fraction of acetone in uniform region

%% Calculate concentration in image
for i = 1:length(B)
Ibar = I(:,i); % Median column intensity
[~, imax] = max(Ibar);
[~, imin] = min(Ibar(imax:end)); imin = imin + imax - 1;

% Scale input image intensity to known peak concentration value
% Assumes that concentration is zero near the bottom of the image
Irange = [Ibar(imin), Ibar(imax)];

X(:,i) = (I(:,i) - Irange(1))* X0(i)/diff(Irange);
end

% X(X > mean(X0)) = mean(X0);
% X(X < 0) = 0;


Xbar = imgaussfilt(median(X,2), 2.0);

%% Calculate output limits; return output mole fraction array
Xlimits  = Xlimits * mean(X0);
iupper = find(Xbar > max(Xlimits), 1, 'last') - pad_px;
ilower = find(Xbar > min(Xlimits), 1, 'last') + pad_px;
if iupper < 0; iupper = 1; end
if ilower > length(Xbar); ilower = length(Xbar); end

out = X;%(iupper:ilower, :);

return