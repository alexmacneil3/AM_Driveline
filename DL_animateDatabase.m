function DL_animateDatabase(database, selectedTrialIdx, selectedMeanIdx, connections, saveVideo)
% Animate a trial with mean comparison and optional video
%
% Inputs:
%   database          - struct array with trial data
%   selectedTrialIdx  - index of trial to animate
%   selectedMeanIdx   - indices to compute mean
%   connections       - cell array of marker pairs for stick figure
%   saveVideo         - option to save animation as video

if nargin < 5
    saveVideo = false;
end

%% Prepare data 
trial = database(selectedTrialIdx).data;
nFrames = trial.nFrames;
timeVec = trial.time;

% Extract mean & std across selected trials
nTrials = numel(selectedMeanIdx);
batSpeedMat = zeros(nTrials, nFrames);
sepMat = zeros(nTrials, nFrames);

for i = 1:nTrials
    d = database(selectedMeanIdx(i)).data;
    batSpeedMat(i,:) = d.BatSpeed.speedSmooth;
    sepMat(i,:) = d.ShoulderRot - d.PelvisRot;
end

meanBatSpeed = mean(batSpeedMat, 1);
meanSep      = mean(sepMat, 1);
stdSep       = std(sepMat, [], 1);

%% Setup connections
nConn = size(connections,1);
idxConn = zeros(nConn,2);
isMarkerConn = false(nConn,1);
pelvisConn = false(nConn,1);
shoulderConn = false(nConn,1);

for c = 1:nConn
    idxConn(c,1) = find(strcmp(trial.labels, connections{c,1}));
    idxConn(c,2) = find(strcmp(trial.labels, connections{c,2}));
    m1 = connections{c,1}; m2 = connections{c,2};
    if any(strcmp(m1,{'Marker1','Marker2','Marker3'})) || any(strcmp(m2,{'Marker1','Marker2','Marker3'}))
        isMarkerConn(c) = true;
    end
    if (strcmp(m1,'LASI') && strcmp(m2,'RASI')) || (strcmp(m1,'RASI') && strcmp(m2,'LASI'))
        pelvisConn(c) = true;
    end
    if (strcmp(m1,'LSHO') && strcmp(m2,'RSHO')) || (strcmp(m1,'RSHO') && strcmp(m2,'LSHO'))
        shoulderConn(c) = true;
    end
end

%% Setup figure
fig = figure('Color','w','Position',[100 100 1200 600], 'Resize','off');
mainLayout = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');

% Left: 3D animation axes
ax1 = nexttile(mainLayout,1); hold(ax1,'on'); grid(ax1,'on'); axis(ax1,'equal');
xlabel(ax1,'X'); ylabel(ax1,'Y'); zlabel(ax1,'Z'); view(ax1,3);

% Fix axes once using trial data
allX = trial.points(:,1,:);
allY = trial.points(:,2,:);
allZ = trial.points(:,3,:);

pad = 0.05; % 5% padding
xmin = min(allX,[],'all'); xmax = max(allX,[],'all'); dx = xmax-xmin;
ymin = min(allY,[],'all'); ymax = max(allY,[],'all'); dy = ymax-ymin;
zmin = min(allZ,[],'all'); zmax = max(allZ,[],'all'); dz = zmax-zmin;

axis(ax1, [xmin-pad*dx xmax+pad*dx ymin-pad*dy ymax+pad*dy zmin-pad*dz zmax+pad*dz]);

% Initialize stick figure lines
lines = gobjects(nConn,1);
for k = 1:nConn
    i1 = idxConn(k,1); i2 = idxConn(k,2);
    X = [trial.points(1,1,i1), trial.points(1,1,i2)];
    Y = [trial.points(1,2,i1), trial.points(1,2,i2)];
    Z = [trial.points(1,3,i1), trial.points(1,3,i2)];
    if isMarkerConn(k)
        c = 'y';
    elseif pelvisConn(k)
        c = 'r';
    elseif shoulderConn(k)
        c = 'b';
    else
        c = 'k';
    end
    lines(k) = plot3(ax1,X,Y,Z,'-o','LineWidth',2,'MarkerSize',5,'Color',c);
end

marker3Idx = find(strcmp(trial.labels,'Marker3'));
trailLines = gobjects(nFrames-1,1);

%% Right: Bat speed & rotation
rightLayout = tiledlayout(mainLayout,2,1,'TileSpacing','compact','Padding','compact');
rightLayout.Layout.Tile = 2;

% Bat speed
ax2 = nexttile(rightLayout,1); hold(ax2,'on'); grid(ax2,'on');

% Colormap for bat speed
batSpeed = trial.BatSpeed.speedSmooth;
batSpeedNorm = (batSpeed - min(batSpeed)) / (max(batSpeed) - min(batSpeed));
cmap = jet(256);

% Plot BatSpeed line with color based on magnitude
for i = 1:numel(timeVec)-1
    colorIdx = max(1, round(batSpeedNorm(i) * 255) + 1); % index into cmap
    if i == 1
        % First segment gets legend entry
        plot(ax2, timeVec(i:i+1), trial.BatSpeed.speedSmooth(i:i+1), ...
            'Color', cmap(colorIdx,:), 'LineWidth', 2, ...
            'DisplayName', 'Selected Swing');
    else
        % Hide the rest from the legend
        plot(ax2, timeVec(i:i+1), trial.BatSpeed.speedSmooth(i:i+1), ...
            'Color', cmap(colorIdx,:), 'LineWidth', 2, ...
            'HandleVisibility','off');
    end
end

% Mean bat speed line
plot(ax2, timeVec, meanBatSpeed, 'k','LineWidth',1.5,'DisplayName','Group Mean');

% Peak marker
[peakSpeed, peakIdx] = max(batSpeed);
peakTime = timeVec(peakIdx);
plot(ax2, peakTime, peakSpeed, 'ro', 'MarkerFaceColor','r','MarkerSize',3, 'HandleVisibility','off');
text(ax2, peakTime, peakSpeed, sprintf('%.1f mph', peakSpeed), ...
    'VerticalAlignment','bottom','HorizontalAlignment','right','FontWeight','bold','Color','r', 'HandleVisibility','off');
legend(ax2,'Location','northwest');

xlabel(ax2,'Time [s]'); ylabel(ax2,'Bat Speed [mph]'); title(ax2,'Bat Speed');

hLine = xline(ax2,timeVec(1),'k','LineWidth',2, 'HandleVisibility','off');
hDot  = plot(ax2,timeVec(1),batSpeed(1),'ko','MarkerFaceColor','k');

% Separation
ax3 = nexttile(rightLayout,2); hold(ax3,'on'); grid(ax3,'on');

fill([timeVec fliplr(timeVec)], [meanSep+stdSep fliplr(meanSep-stdSep)], ...
    [0.8 0.8 0.8],'FaceAlpha',0.4,'EdgeColor','none', 'HandleVisibility','off'); % variance
plot(ax3,timeVec,meanSep,'k','LineWidth',1.5,'DisplayName','Group Mean');
plot(ax3,timeVec,trial.ShoulderRot - trial.PelvisRot,'r','LineWidth',1.5,'DisplayName','Selected Swing');
xlabel(ax3,'Time [s]'); ylabel(ax3,'Rotational Separation [deg]');
title(ax3,'Hip & Shoulder Separation (X Factor)');
legend(ax3,'Location','northwest');

hLineRot = xline(ax3,timeVec(1),'k','LineWidth',2,  'HandleVisibility','off'); hLineRot.HandleVisibility = 'off';

%% Video setup
if saveVideo
    v = VideoWriter('DL_animation.mp4','MPEG-4');
    v.FrameRate = min(trial.frameRate, 60);
    open(v);
end

%% Animation loop
for f = 1:nFrames-1
    % Update stick figure
    for k = 1:nConn
        i1 = idxConn(k,1); i2 = idxConn(k,2);
        set(lines(k),'XData',[trial.points(f,1,i1), trial.points(f,1,i2)],...
                     'YData',[trial.points(f,2,i1), trial.points(f,2,i2)],...
                     'ZData',[trial.points(f,3,i1), trial.points(f,3,i2)]);
    end

    % Plot bat path segment
    colorIdx = max(1, round(batSpeedNorm(f)*255)+1);
    trailLines(f) = plot3(ax1, ...
        trial.points(f:f+1,1,marker3Idx), ...
        trial.points(f:f+1,2,marker3Idx), ...
        trial.points(f:f+1,3,marker3Idx), ...
        'Color', cmap(colorIdx,:), 'LineWidth', 2);

    % Update cursors on BatSpeed plot
    hLine.Value = timeVec(f);
    set(hDot,'XData',timeVec(f),'YData',batSpeed(f), 'HandleVisibility','off');
    hLineRot.Value = timeVec(f);

    drawnow;
    
    % Write frame
    if saveVideo
        frame = getframe(fig);
        writeVideo(v, frame);
    end
    
    pause(1/trial.frameRate);
end

if saveVideo
    close(v);
    fprintf('Video saved as DL_animation.mp4\n');
end

end