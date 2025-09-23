function selectedIdx = filterBatSpeed(database, speedThreshold)
% Select trials where BatSpeed.speedSmooth exists and the max exceeds threshold
%
% Inputs:
%   database       - struct array with field .data, each containing .BatSpeed.speedSmooth
%   speedThreshold - numeric threshold in mph
%
% Output:
%   selectedIdx    - numeric array of indices of trials meeting the criteria

selectedIdx = [];

for i = 1:numel(database)
    % Check fields exist
    if isfield(database(i).data,'BatSpeed') && ...
       isfield(database(i).data.BatSpeed,'speedSmooth')
   
        % Ensure speedSmooth is numeric and non-empty
        speedVec = database(i).data.BatSpeed.speedSmooth;
        if ~isempty(speedVec) && isnumeric(speedVec) && max(speedVec) > speedThreshold
            selectedIdx(end+1) = i; 
        end
    end
end

if isempty(selectedIdx)
    warning('No trials found exceeding BatSpeed threshold of %.1f mph.', speedThreshold);
end

end
