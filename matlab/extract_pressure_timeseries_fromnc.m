clear
close all

%% load obs
load('obs_airpressure_anomaly.mat');

lat_obs = [table_obs_pres.Lat];
lon_obs = [table_obs_pres.Lon];
np_obs = size(table_obs_pres,1);

%% pressure ncfile
% ========================================================
% savefile = 'pres_jaguar_obslocation.mat';
% ncdir = '../jaguar';
% dt_file = 60.0;
% flist = dir(fullfile(ncdir,'slp_jaguar5_*.nc'));
% t_offset = 0.0;
% ========================================================
savefile = 'pres_dNami_obslocation.mat';
ncdir = '../nc_dNami';
dt_file = 300.0;
flist = dir(fullfile(ncdir,'groundPressure_*.nc'));
t_offset = 2.25*3600;
% ========================================================
nfile = size(flist,1);
t = linspace(0.0,(nfile-1)*dt_file,nfile);


% [lon,lat,tmp] = grdread2(fullfile(ncdir,flist(1).name));
lon = ncread(fullfile(ncdir,flist(1).name),'lon');
lat = ncread(fullfile(ncdir,flist(1).name),'lat');
tmp = permute(ncread(fullfile(ncdir,flist(3).name),'slp'),[2,1]);

[LON,LAT] = meshgrid(lon,lat);

%% location set
for k = 1:np_obs
    [~,indobs_lon(k)] = min(abs(lon_obs(k)-lon));
    [~,indobs_lat(k)] = min(abs(lat_obs(k)-lat));
end
indobs = sub2ind(size(tmp),indobs_lat,indobs_lon);

% %% check
% figure;
% pcolor(lon,lat,tmp); axis equal tight; shading flat; hold on
% plot(LON(indobs), LAT(indobs), 'ko', 'MarkerFaceColor','m');

%% extract
slp = zeros(nfile,np_obs);
for i = 1:nfile
    if mod(i,50)==0; fprintf('%d/%d\n',i,nfile); end
    slp_snap = permute(ncread(fullfile(ncdir,flist(i).name),'slp'),[2,1]);
    slp(i,:) = slp_snap(indobs);
    clear slp_snap
end

%% save
save(savefile,'slp','lon_obs','lat_obs','t','lon','lat','dt_file','nfile','indobs*','t_offset','-v7.3');


%% plot
fig1 = figure;
gax = geoaxes;
geoplot(lat(indobs_lat), lon(indobs_lon), 'ko', 'MarkerFaceColor','m');


fig2 = figure;
tile = tiledlayout(2,1);

i = 6;
ax(1) = nexttile;
p1 = plot((t+t_offset)./3600, slp(:,i)); hold on
p2 = plot(cell2mat(table_obs_pres{i,"Time"})./3600,cell2mat(table_obs_pres{i,"Pressure_anomaly"}));
xlim(ax(1),[-0.5,16.0]);
grid on
set(ax(1),'FontName','Helvetica','FontSize',12)
% xlabel(ax(1),'Time (hour)','FontName','Helvetica','FontSize',14);
% ylabel(ax(1),'Pressure anomaly (hPa)','FontName','Helvetica','FontSize',14);
ax(1).XAxis.TickLabels = [];
ax(1).YAxis.TickLabelFormat = '%0.1f';
% text(ax(1), 0.1*(ax(1).XLim(end)-ax(1).XLim(1))+ax(1).XLim(1), 0.9*(ax(1).YLim(end)-ax(1).YLim(1))+ax(1).YLim(1), table_obs_pres{i,"Station"},'FontName','Helvetica','FontSize',14);
text(ax(1),1.0,1.5,table_obs_pres{i,"Station"},'FontName','Helvetica','FontSize',14)
legend(ax(1),[p1,p2],{'cal.','obs.'},'FontName','Helvetica','FontSize',14)

i = 15;
ax(2) = nexttile;
p1 = plot((t+t_offset)./3600, slp(:,i)); hold on
p2 = plot(cell2mat(table_obs_pres{i,"Time"})./3600,cell2mat(table_obs_pres{i,"Pressure_anomaly"}));
xlim(ax(2),[-0.5,16.0]);
grid on
set(ax(2),'FontName','Helvetica','FontSize',12)
xlabel(ax(2),'Time (hour)','FontName','Helvetica','FontSize',14);
ylabel(ax(2),'Pressure anomaly (hPa)','FontName','Helvetica','FontSize',14);
ax(2).YAxis.TickLabelFormat = '%0.1f';
% text(ax(2), 0.1*(ax(2).XLim(end)-ax(2).XLim(1))+ax(2).XLim(1), 0.9*(ax(2).YLim(end)-ax(2).YLim(1))+ax(1).YLim(1), table_obs_pres{i,"Station"},'FontName','Helvetica','FontSize',14);
text(ax(2),1.0,1.5,table_obs_pres{i,"Station"},'FontName','Helvetica','FontSize',14)
legend([p1,p2],{'cal.','obs.'},'FontName','Helvetica','FontSize',14)

linkaxes(ax,'xy');
tile.Padding = 'compact';
tile.TileSpacing = 'tight';



