function DL_animate(data, connections, BatSpeed, PelvisRot, ShoulderRot)
% Animate figure and generate video file from generated data struct and graphs of interest
%
% Inputs:
%   data        - struct from DL_read
%   connections - cell array of pairs of marker labels to connect
%   BatSpeed    - struct from calculateBatSpeed function
%   PelvisRot & ShoulderRot - vectors from calculateSegmentRotation function


trailLength = 1000; % trail length for bat 
nConn = size(connections,1);
idxConn = zeros(nConn,2);

% Map connections to indices
for c = 1:nConn
    idxConn(c,1) = find(strcmp(data.labels, connections{c,1}));
    idxConn(c,2) = find(strcmp(data.labels, connections{c,2}));
end

% Identify bat marker connections
markerLabels = {'Marker1','Marker2','Marker3'};
isMarkerConn = false(nConn,1);
for k = 1:nConn
    m1 = connections{k,1};
    m2 = connections{k,2};
    if any(strcmp(m1,markerLabels)) || any(strcmp(m2,markerLabels))
        isMarkerConn(k) = true;
    end
end

% Identify pelvis (ASI) connection
pelvisConn = false(nConn,1);
for k = 1:nConn
    m1 = connections{k,1};
    m2 = connections{k,2};
    if (strcmp(m1,'LASI') && strcmp(m2,'RASI')) || ...
       (strcmp(m1,'RASI') && strcmp(m2,'LASI'))
        pelvisConn(k) = true;
    end
end

% Identify shoulder connection
shoulderConn = false(nConn,1);
for k = 1:nConn
    m1 = connections{k,1};
    m2 = connections{k,2};
    if (strcmp(m1,'LSHO') && strcmp(m2,'RSHO')) || ...
       (strcmp(m1,'RSHO') && strcmp(m2,'LSHO'))
        shoulderConn(k) = true;
    end
end

% Setup figure with main + right-side panel
fig = figure('Color','w','Position',[100 100 1200 600]);
mainLayout = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');

% Left tile: 3D animation
ax1 = nexttile(mainLayout,1);
hold(ax1,'on'); grid(ax1,'on'); axis(ax1,'equal');
xlabel(ax1,'X'); ylabel(ax1,'Y'); zlabel(ax1,'Z');
view(ax1,3);

% Plot initial frame
lines = gobjects(nConn,1);
for k = 1:nConn
    i1 = idxConn(k,1); i2 = idxConn(k,2);
    X = [data.points(1,1,i1), data.points(1,1,i2)];
    Y = [data.points(1,2,i1), data.points(1,2,i2)];
    Z = [data.points(1,3,i1), data.points(1,3,i2)];

    if isMarkerConn(k)
        c = 'y'; % yellow for bat
    elseif pelvisConn(k)
        c = 'r'; % red for pelvis line
    elseif shoulderConn(k)
        c = 'b'; % blue for shoulder line
    else
        c = 'k'; % default black
    end
    lines(k) = plot3(ax1,X,Y,Z,'-o','LineWidth',2,'MarkerSize',5,'Color',c);
end

% Axis limits
allX = data.points(:,1,:); allY = data.points(:,2,:); allZ = data.points(:,3,:);
xlim(ax1,[min(allX,[],'all'), max(allX,[],'all')]);
ylim(ax1,[min(allY,[],'all'), max(allY,[],'all')]);
zlim(ax1,[min(allZ,[],'all'), max(allZ,[],'all')]);

% Prepare trail for Marker3
marker3Idx = find(strcmp(data.labels,'Marker3'));
trailLine = plot3(ax1,nan, nan, nan,'-','Color','y','LineWidth',2);

% Right tile: nested layout with two plots
rightLayout = tiledlayout(mainLayout,2,1,'TileSpacing','compact','Padding','compact');
rightLayout.Layout.Tile = 2;  % put this layout in the second column

% Top: Bat speed graph
ax2 = nexttile(rightLayout,1);
hold(ax2,'on'); grid(ax2,'on');

plot(ax2,BatSpeed.time,BatSpeed.speedSmooth,'y','LineWidth',1.5);
xlabel(ax2,'Time [s]');
ylabel(ax2,'Bat Speed [mph]');
title(ax2,'Bat Speed');
plot(ax2,BatSpeed.peakFrame/360, BatSpeed.peakSpeed, 'ko', 'MarkerFaceColor', 'r', 'MarkerSize', 5);
text(ax2, BatSpeed.peakFrame/360, BatSpeed.peakSpeed, sprintf('%.1f mph', BatSpeed.peakSpeed), ...
    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', ...
    'FontWeight', 'bold', 'Color', 'r')
hLine = xline(ax2,BatSpeed.time(1),'k','LineWidth',2);
hDot = plot(ax2,BatSpeed.time(1),BatSpeed.speedSmooth(1),'ko','MarkerFaceColor','k');

% Bottom: Pelvis & shoulder rotation + separation
ax3 = nexttile(rightLayout,2);
hold(ax3,'on'); grid(ax3,'on');
sep = ShoulderRot - PelvisRot;
plot(ax3,BatSpeed.time,PelvisRot,'r','LineWidth',1.5,'DisplayName','Hi');
plot(ax3,BatSpeed.time,ShoulderRot,'b','LineWidth',1.5,'DisplayName','Shoulders');
plot(ax3,BatSpeed.time,sep,'g--','LineWidth',1.2,'DisplayName','Hip–Shoulder Separation');
xlabel(ax3,'Time [s]');
ylabel(ax3,'Rotation [deg]');
title(ax3,'Hip & Shoulder Separation');
legend(ax3,'Location','northwest');
hLineRot = xline(ax3,BatSpeed.time(1),'k','LineWidth',2);
hLineRot.HandleVisibility = 'off';


% Animation loop
nFrames = data.nFrames;

    for f = 1:nFrames
        % Update stick figure
        for k = 1:nConn
            i1 = idxConn(k,1); i2 = idxConn(k,2);
            set(lines(k), 'XData', [data.points(f,1,i1), data.points(f,1,i2)], ...
                          'YData', [data.points(f,2,i1), data.points(f,2,i2)], ...
                          'ZData', [data.points(f,3,i1), data.points(f,3,i2)]);
        end

        % Update trail
        startFrame = max(1,f-trailLength+1);
        set(trailLine,'XData',data.points(startFrame:f,1,marker3Idx), ...
                      'YData',data.points(startFrame:f,2,marker3Idx), ...
                      'ZData',data.points(startFrame:f,3,marker3Idx));

        % Update bat speed & rotation cursors
        if f <= length(BatSpeed.time)
            hLine.Value = BatSpeed.time(f);
            set(hDot,'XData',BatSpeed.time(f),'YData',BatSpeed.speedSmooth(f));
            hLineRot.Value = BatSpeed.time(f);
        end

        drawnow;

    end

end
