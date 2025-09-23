function BatSpeed = calculateBatSpeed(data, batTipLabel, units)
% computeBatSpeed - Computes bat speed from marker trajectory
%
% INPUTS:
%   data        - struct from DL_Read (must contain .points, .labels, .frameRate)
%   batTipLabel - string, marker name for bat tip (Marker 3)
%
% OUTPUT:
%   BatSpeed struct containing:
%       .time      - time vector [s]
%       .speed     - instantaneous bat speed [m/s]
%       .speedSmooth - smoothed bat speed [m/s] (if doSmooth = true)
%       .peakSpeed - peak bat speed [m/s]
%       .peakFrame - frame index at peak speed

   cutoffFreq = data.frameRate/10 ; % Nyquist Theorum
   
    if nargin < 3
         units = 'm/s';
    end

    % Find marker index
    idxBatTip = find(strcmp(data.labels, batTipLabel));

    % Extract trajectory
    batTip = squeeze(data.points(:,:,idxBatTip));  % [nFrames x 3]
    nFrames = size(batTip,1);
    frameRate = data.frameRate;

    % Compute velocity
    dPos = diff(batTip,1,1);        % [nFrames-1 x 3]
    vBat = dPos * frameRate;        % convert to velocity (m/s)
    speed = vecnorm(vBat,2,2);      % magnitude of velocity vector

     % Convert units
    switch lower(units)
        case 'mph'
            speed = speed * 2.23694;
        case 'km/h'
            speed = speed * 3.6;
        case 'm/s'
            % do nothing
        otherwise
            warning('Unknown units requested. Using m/s.');
    end

    % Create time vector 
    time = (1:(nFrames-1))'/frameRate;

    % Apply filter to smooth
        [b,a] = butter(4, cutoffFreq/(frameRate/2), 'low');  % 4th order LPF
        speedFilt = filtfilt(b,a,speed);  % zero-phase filter

    % Find peak 
    [peakSpeed, peakFrame] = max(speedFilt);

    % Build struct
    BatSpeed.time = time;
    BatSpeed.speed = speed;
    BatSpeed.speedSmooth = speedFilt;
    BatSpeed.peakSpeed = peakSpeed;
    BatSpeed.peakFrame = peakFrame;

end
