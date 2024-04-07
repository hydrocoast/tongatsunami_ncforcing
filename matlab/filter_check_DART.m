clear
close all

%% read
% --------------------------
% fname = 'dart52401_20220114to20220119_meter_resid.txt';
% lat = 19.2395;
% lon = 155.7293;
% depth = 5590;
% idref = 52401;
% % --------------------------
% fname = 'dart52402_20220114to20220119_meter_resid.txt';
% lat = 11.9303;
% lon = 153.9228;
% depth = 5978;
% idref = 52402;
% % --------------------------
% fname = 'dart52403_20220114to20220119_meter_resid.txt';
% lat = 4.0358;
% lon = 145.6083;
% depth = 4542;
% idref = 52403;
% % --------------------------
% fname = 'dart52404_20220114to20220119_meter_resid.txt';
% lat = 20.6267;
% lon = 132.1447;
% depth = 5983;
% idref = 52404;
% % --------------------------
% fname = 'dart52405_20220114to20220119_meter_resid.txt';
% lat = 12.9890;
% lon = 132.2395;
% depth = 5977;
% idref = 52404;
% % --------------------------
% fname = 'dart52406_20220114to20220119_meter_resid.txt';
% lat = -5.3737;
% lon = 164.9910;
% depth = 5977;
% idref = 52406;
% --------------------------
% fname = 'dart43412_20220114to20220119_meter_resid.txt';
% lat = 16.0015;
% lon = -106.9863+360.0;
% depth = 3121;
% idref = 43413;
% --------------------------


dat = readmatrix(fname);


time_org = datetime(dat(:,2:7));
z_org = dat(:,10);
ind = z_org==9999;
time_org(ind) = [];
z_org(ind) = [];


% time = (time_org(1):minutes(1):time_org(end))';

dt_uniform = min(diff(time_org));
fs = 1/seconds(dt_uniform);
time = (time_org(1):dt_uniform:time_org(end))';

z_interp = interp1(time_org,z_org,time);


% z_filtered = highpass(z_interp,1/60);
z_filtered = highpass(z_interp,1/7200,fs);


plot(time_org,z_org); hold on
plot(time,z_interp); hold on
plot(time,z_filtered); hold on

time_relative = seconds(time - datetime(2022,01,15,4,14,45));


load DART_records.mat

ind = find(table_DART.DART==idref);

figure
plot(time_relative./3600,z_filtered.*1e2); hold on
plot(table_DART.Time{ind}./3600,table_DART.Eta_filtered{ind});
xlim([0,20]);



