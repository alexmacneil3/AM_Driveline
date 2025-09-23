function data = DL_read(filename)
% Reads a C3D file using BTK, returns marker data struct, and aligns to peak bat speed
%
%   data = DL_read(filename)
%
% Returns a struct:
%   data.points  = [nFrames x 3 x nMarkers] marker positions (cropped & aligned)
%   data.labels  = {nMarkers x 1} cell array of marker names
%   data.nFrames = number of frames after cropping
%   data.nMarkers= number of markers
%   data.frameRate = sampling rate of data (DriveLine mocap 360Hz)
%   data.BatSpeed, data.PelvisRot, data.ShoulderRot
%   data.time    = time vector, aligned so t=0 is peak bat speed

% Read acquisition 
acq = btkReadAcquisition(filename);
points = btkGetPoints(acq);
nFrames = btkGetLastFrame(acq) - btkGetFirstFrame(acq) + 1;
markerNames = fieldnames(points);
nMarkers = numel(markerNames);
[values, info] = btkGetAnalog(acq,5);

% Allocate arrays
data.points = zeros(nFrames,3,nMarkers);
data.labels = cell(nMarkers,1);

for i = 1:nMarkers
    data.labels{i} = markerNames{i};
    point = points.(markerNames{i});
    data.points(:,:,i) = point(:,1:3);  % keep only XYZ
end

% Forceplate 
data.forcePlate.values = values;
data.forcePlate.info   = info;

%  Metadata 
data.nFrames   = nFrames;
data.nMarkers  = nMarkers;
data.frameRate = btkGetPointFrequency(acq);

% Auto-detect stance 
idxL = find(strcmp(data.labels,'LTOE'));
idxR = find(strcmp(data.labels,'RTOE'));

if isempty(idxL) || isempty(idxR)
    error('Markers LTOE or RTOE not found.');
end

% Auto-detect stance (based on X) 
idxL = find(strcmp(data.labels,'LTOE'));
idxR = find(strcmp(data.labels,'RTOE'));

if isempty(idxL) || isempty(idxR)
    error('Markers LTOE or RTOE not found.');
end

% Compare X positions (positive X = toward mound)
xL = data.points(1,1,idxL);
xR = data.points(1,1,idxR);

if xL > xR
    data.stance = 'RightHanded';  % left foot closer to mound -> right-handed batter
    frontFootName = 'LTOE';
else
    data.stance = 'LeftHanded';   % right foot closer to mound -> left-handed batter
    frontFootName = 'RTOE';
end

% Calculate bat speed & segment rotations 
data.BatSpeed = calculateBatSpeed(data,'Marker3','mph');
[data.PelvisRot, data.ShoulderRot] = computeSegmentRotation(data);

% Align to peak bat speed
[~, peakIdx] = max(data.BatSpeed.speedSmooth);

% Set pre/post windows (adjustable)
preFrames  = round(0.4 * data.frameRate);  % 0.3s before peak
postFrames = round(0.3 * data.frameRate);  % 0.3s after peak

% Skip file if not enough frames
if (peakIdx - preFrames < 1) || (peakIdx + postFrames > nFrames)
    warning('File %s skipped: not enough frames around peak bat speed.', filename);
    data = [];
    return
end

startIdx = max(1, peakIdx - preFrames);
endIdx   = min(nFrames, peakIdx + postFrames);

% Crop data arrays
data.points = data.points(startIdx:endIdx,:,:);
data.BatSpeed.speedSmooth = data.BatSpeed.speedSmooth(startIdx:endIdx);
data.PelvisRot = data.PelvisRot(startIdx:endIdx);
data.ShoulderRot = data.ShoulderRot(startIdx:endIdx);

% Update metadata
data.nFrames = size(data.points,1);

% Time vector aligned so that t=0 is peak bat speed
newPeakIdx = peakIdx - startIdx + 1;
data.time = ((1:data.nFrames) - newPeakIdx) / data.frameRate;
data.peakFrame = newPeakIdx;

end

