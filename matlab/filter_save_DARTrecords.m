clear
close all

fname_base = 'dartXXXXX_20220114to20220119_meter_resid.txt';

DART = [52401;52402;52403;52404;52405;52406];
Lat = [ 19.2395; 11.9303;  4.0358; 20.6267; 12.9890; -5.3737];
Lon = [155.7293;153.9228;145.6083;132.1447;132.2395;164.9910];

nDART = size(DART,1);
if size(Lat,1)~=nDART || size(Lon,1)~=nDART
    error('Size of lon or lat is inconsistent with that of id.');
end

for i = 1:nDART
    fname = strrep(fname_base,'XXXXX',sprintf('%05d',DART(i)));

    %% read a file
    dat = readmatrix(fname);
    time_org = datetime(dat(:,2:7));
    z_org = dat(:,10);
    ind = z_org==9999;
    time_org(ind) = [];
    z_org(ind) = [];


    %% interp
    dt_uniform = min(diff(time_org));
    fs = 1/seconds(dt_uniform);
    time = (time_org(1):dt_uniform:time_org(end))';
    z_interp = interp1(time_org,z_org,time);

    %% filter
    passband = 1/7200;
    z_filtered = highpass(z_interp,passband,fs);


    %% check
    figure
    plot(time_org,z_org); hold on
    plot(time,z_interp); hold on
    plot(time,z_filtered); hold on
    title(sprintf('%05d',DART(i)),'FontName','Helvetica','FontSize',16);
    set(gca,'FontName','Helvetica','FontSize',12);
    grid on
    

    torigin = datetime(2022,01,15,4,14,45);
    time_relative = seconds(time - torigin);

    %% for save
    TimeOrg{i,1} = time_org;
    EtaOrg{i,1} = 1e2.*z_org;
    dt_minimum(i,1) = dt_uniform;
    Fpass(i,1) = passband;
    Time{i,1} = time_relative;
    Eta_filtered{i,1} = 1e2.*z_filtered;
    TimeOrigin(i,1) = torigin;


end


table_DART = table(DART,Lat,Lon,TimeOrg,EtaOrg,dt_minimum,Fpass,Time,Eta_filtered,TimeOrigin);

save('DART_records_rev.mat','-v7.3','table_DART');
