function [pelvisRot, shoulderRot] = computeSegmentRotation(data)
% computeSegmentRotation - Computes transverse plane rotation of pelvis and shoulders
% Adjusts for batter stance so that positive rotation = opening toward pitcher
%
% INPUT:
%   data - struct from DL_read (must include data.stance = 'RightHanded' or 'LeftHanded')
%
% OUTPUT:
%   pelvisRot    - [nFrames x 1] pelvis rotation (degrees)
%   shoulderRot  - [nFrames x 1] shoulder rotation (degrees)

cutoffFreq = data.frameRate/10; % low-pass cutoff
nFrames = data.nFrames;

% Marker indices
idxL_ASIS = find(strcmp(data.labels,'LASI'));
idxR_ASIS = find(strcmp(data.labels,'RASI'));
idxL_Sh   = find(strcmp(data.labels,'LSHO'));
idxR_Sh   = find(strcmp(data.labels,'RSHO'));

pelvisRot   = zeros(nFrames,1);
shoulderRot = zeros(nFrames,1);

for f = 1:nFrames
    % ---- Pelvis ----
    L_ASIS = squeeze(data.points(f,1:2,idxL_ASIS));
    R_ASIS = squeeze(data.points(f,1:2,idxR_ASIS));
    deltaPelvis = R_ASIS - L_ASIS;                % left-to-right vector
    forwardPelvis = [-deltaPelvis(2), deltaPelvis(1)]; % rotate 90° CCW
    pelvisRot(f) = atan2d(forwardPelvis(2), forwardPelvis(1));

    % ---- Shoulders ----
    L_Sh = squeeze(data.points(f,1:2,idxL_Sh));
    R_Sh = squeeze(data.points(f,1:2,idxR_Sh));
    deltaShoulder = R_Sh - L_Sh;
    forwardShoulder = [-deltaShoulder(2), deltaShoulder(1)];
    shoulderRot(f) = atan2d(forwardShoulder(2), forwardShoulder(1));
end

% ---- Unwrap & Adjust Orientation ----
pelvisRot   = rad2deg(unwrap(deg2rad(pelvisRot))) + 90;
shoulderRot = rad2deg(unwrap(deg2rad(shoulderRot))) + 90;

% ---- Adjust for Left-Handed Batters ----
if isfield(data, 'stance') && strcmpi(data.stance, 'LeftHanded')
    pelvisRot   = -pelvisRot;
    shoulderRot = -shoulderRot;
end

% ---- Low-Pass Filter ----
[b,a] = butter(4, cutoffFreq/(data.frameRate/2));
pelvisRot   = filtfilt(b,a,pelvisRot);
shoulderRot = filtfilt(b,a,shoulderRot);

% ---- Remove last frame to match other data ----
pelvisRot   = pelvisRot(1:end-1);
shoulderRot = shoulderRot(1:end-1);

end