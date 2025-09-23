clear all
close all
clc

%% FILE NAME FOR SINGLE FILE VIEW OR FOLDER FOR DATABASE CONSTRUCTION
filename = 'c3d\000004\000004_000103_75_236_R_003_972.c3d';

folderPath ='c3d';

%% READ IN DATA
disp("Reading in Data")
tic
[data] = DL_read(filename);
toc

%% BATCH READ DATA
disp("Generating Database")
tic
db = DL_batch(folderPath);
toc

%% CALCULATE BAT SPEED

BatSpeed = calculateBatSpeed(data,'Marker3','mph');

%% CALCULATE PELVIS AND SHOULDER ROTATION

[PelvisRotation, ShoulderRotation] = computeSegmentRotation(data);

%% ANIMATE
connections = {
    'RSHO','RELB';
    'RELB','RWRB';
    'RWRB','RFIN';
    'LSHO','LELB';
    'LELB','LWRB';
    'LWRB','LFIN';
    'RASI','RKNE';
    'RKNE','RANK';
    'LASI','LKNE';
    'LKNE','LANK';
    'RANK','RTOE';
    'LANK','LTOE';
    'RSHO','RASI';
    'RSHO','LSHO';
    'LSHO','LASI';
    'CLAV','RBHD';
    'CLAV','LBHD';
    'LSHO','LASI';
    'RSHO','RASI';
    'LASI','RASI';
    'RBHD','LBHD';
    'Marker1','Marker2';
    'Marker1','Marker3';
    'Marker2','Marker3';
};

%% SINGLE ANIMATION
% enter number for swing selection
SwingNum = 45;

disp ("Generating Swing Animation Video")
tic
DL_animate(db(SwingNum).data, connections, db(SwingNum).data.BatSpeed, db(SwingNum).data.PelvisRot, db(SwingNum).data.ShoulderRot)
toc


%% DATABASE ANIMATION

% select file index for animation
SelectedIdx = 1;
SpeedThreshold = 85; % set threshold for peak bat speed in mph to filter files
HighSpeedTrials = filterBatSpeed(db, SpeedThreshold);

disp ("Generating Swing Animation Video")
tic
DL_animateDatabase(db, SelectedIdx, HighSpeedTrials, connections, 'true');
toc
