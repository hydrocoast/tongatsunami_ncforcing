clear
close all

%% color set
cmap = lines(7);
LC1 = cmap(1,:);
LC2 = cmap(2,:);
LC3 = cmap(5,:);

palette = crameri('imola');
palette = palette(1:250,:);

%% filename
matdir = '.';

mat_pres_obs = 'obs_airpressure_anomaly.mat';
mat_pres_1 = 'pres_lg_A.mat';
mat_pres_2 = 'pres_jaguar_obslocation.mat';
mat_pres_3 = 'pres_dNami_obslocation.mat';

load(mat_pres_obs); 
ifix = find(cellfun(@(x) strcmp(x,'Hachijyoujima'),table_obs_pres.Station));
table_obs_pres{ifix,"Station"} = {'Hachijojima'};

D1 = load(mat_pres_1);
D2 = load(mat_pres_2,'t','dt_file','slp','t_offset');
D3 = load(mat_pres_3,'t','dt_file','slp','t_offset');

lon = D1.lon;
lat = D1.lat;



% stationname = 'Naze';
% stationname = 'Hachijojima';
stationname = 'TATO';
istation = find(cellfun(@(x) strcmp(x,stationname),table_obs_pres.Station));

dt_obs = 1;
label_station = table_obs_pres.Station{istation};
%% 時系列データを等間隔に内挿
t_obs = table_obs_pres.Time{istation};
t_uniform = t_obs(1):dt_obs:t_obs(end);
pres_obs = table_obs_pres.Pressure_anomaly{istation};
pres_interp = interp1(t_obs,pres_obs,t_uniform(:),"spline");
%% wavelet analysis
[wt0,f0] = cwt(pres_interp.*1e2,'morse',1/dt_obs);
perT0 = 1./f0;


% checkpoint = [129.4977,28.3991];
checkpoint = table2array(table_obs_pres(istation,["Lon","Lat"]));
[~,indchk_lon] = min(abs(checkpoint(1)-lon));
[~,indchk_lat] = min(abs(checkpoint(2)-lat));

pres_point1 = squeeze(D1.pres(indchk_lat,indchk_lon,:));
pres_point2 = squeeze(D2.slp(:,istation));
pres_point3 = squeeze(D3.slp(:,istation));

%% wavelet analysis
[wt1,f1] = cwt(pres_point1.*1e2,'morse',(1/D1.dt));
[wt2,f2] = cwt(pres_point2.*1e2,'morse',(1/D2.dt_file));
[wt3,f3] = cwt(pres_point3.*1e2,'morse',(1/D3.dt_file));
perT1 = 1./f1;
perT2 = 1./f2;
perT3 = 1./f3;

%% plot
range_p = [-1.4,2.4];
range_c = [0,18];
range_t = [4,16];
tick_t = 0:1:20;
range_perT = [8,120];
tick_perT = [5,10,20,50,100,200];

fig = figure;
p = fig.Position;
fig.Position = [p(1),p(2)-p(4),p(3),2.0*p(4)];
tile = tiledlayout(5,1);

%% time-series
axt = nexttile;
hold on
p0 = plot(t_obs./3600,pres_obs,'k-','LineWidth',2);
p1 = plot(D1.t./3600, pres_point1, '-','Color',LC1,'LineWidth',2);
p2 = plot((D2.t+D2.t_offset)./3600, pres_point2, '-','Color',LC2,'LineWidth',2);
p3 = plot((D3.t+D3.t_offset)./3600, pres_point3, '-','Color',LC3,'LineWidth',2);
p1.Color(4) = 0.6;
p2.Color(4) = 0.6;
p3.Color(4) = 0.6;

ylim(axt,range_p);
legend([p0,p1,p2,p3],{'Obs.','Synthetic','JAGUAR','dNami'},'FontName','Helvetica','FontSize',16,'NumColumns',2,'Location','northeast');
grid on; box on
set(axt,'FontName','Helvetica','FontSize',14);
ylabel(axt,'Pressure anomaly (hPa)','FontName','Helvetica','FontSize',14);
axt.XAxis.TickLabels = [];
axt.XAxis.TickValues = tick_t;

text(4.50, 1.5, stationname,'FontSize',20,'FontName','Helvetica','HorizontalAlignment','left','VerticalAlignment','middle');

%% scalogram
%% Obs
axw0 = nexttile;
pcolor(t_uniform./3600, perT0/60, 20*log10(abs(wt0))); shading flat
ylim(gca,range_perT);
ylabel(gca,'Period (min)','FontName','Helvetica','FontSize',16);
yline([1,10,100],'-','Color',[.8,.8,.8]);
yline([2:1:9,20:10:90,200],'--','Color',[.8,.8,.8],'Alpha',0.5,'LineWidth',0.5);
clim(gca,range_c);
set(gca,'YScale','log','YDir','reverse','FontName','Helvetica','FontSize',14);
axw0.YAxis.TickValues = tick_perT;
axw0.XAxis.TickValues = tick_t;
axw0.XAxis.TickLabels = [];

cb = colorbar(axw0,'east','FontName','Helvetica','FontSize',14);
cb.Label.String = 'Power (dB)';
cb.Label.Color = 'w';
cb.Color = 'w';

%% A
axw1 = nexttile;
pcolor(D1.t./3600, perT1/60, 20*log10(abs(wt1))); shading flat
ylim(gca,range_perT);
% ylabel(gca,'Period (min)','FontName','Helvetica','FontSize',14);
yline(gca,[1,10,100],'-','Color',[.8,.8,.8]);
yline(gca,[2:1:9,20:10:90,200],'--','Color',[.8,.8,.8],'Alpha',0.5,'LineWidth',0.5);
clim(gca,range_c);
set(gca,'YScale','log','YDir','reverse','FontName','Helvetica','FontSize',14);
axw1.YAxis.TickValues = tick_perT;
axw1.XAxis.TickValues = tick_t;
axw1.XAxis.TickLabels = [];

%% B
axw2 = nexttile;
pcolor((D2.t+D2.t_offset)./3600, perT2/60, 20*log10(abs(wt2))); shading flat
ylim(gca,range_perT);
% ylabel(gca,'Period (min)','FontName','Helvetica','FontSize',14);
yline(gca,[1,10,100],'-','Color',[.8,.8,.8]);
yline(gca,[2:1:9,20:10:90,200],'--','Color',[.8,.8,.8],'Alpha',0.5,'LineWidth',0.5);
clim(gca,range_c);
set(gca,'YScale','log','YDir','reverse','FontName','Helvetica','FontSize',14);
axw2.YAxis.TickValues = tick_perT;
axw2.XAxis.TickValues = tick_t;
axw2.XAxis.TickLabels = [];

%% C
axw3 = nexttile;
pcolor((D3.t+D3.t_offset)./3600, perT3/60, 20*log10(abs(wt3))); shading flat
ylim(gca,range_perT);
% ylabel(gca,'Period (min)','FontName','Helvetica','FontSize',14);
yline(gca,[1,10,100],'-','Color',[.8,.8,.8]);
yline(gca,[2:1:9,20:10:90,200],'--','Color',[.8,.8,.8],'Alpha',0.5,'LineWidth',0.5);
clim(gca,range_c);
set(gca,'YScale','log','YDir','reverse','FontName','Helvetica','FontSize',14);
axw3.YAxis.TickValues = tick_perT;
axw3.XAxis.TickValues = tick_t;
% axw3.XAxis.TickLabels = [];
xlabel(axw3,'Elapsed time (hour)','FontName','Helvetica','FontSize',16);
linkaxes([axw0,axw1,axw2,axw3],'xy');
linkaxes([axt,axw0,axw1,axw2,axw3],'x');
xlim(axt,range_t);

tile.TileSpacing = 'tight';
tile.Padding = 'compact';


%% text
text(axw0,4.5,15,'Obs.','FontName','Helvetica','FontSize',20,'HorizontalAlignment','left','VerticalAlignment','middle','Color','w');
text(axw1,4.5,15,'Synthetic','FontName','Helvetica','FontSize',20,'HorizontalAlignment','left','VerticalAlignment','middle','Color','w');
text(axw2,4.5,15,'JAGUAR','FontName','Helvetica','FontSize',20,'HorizontalAlignment','left','VerticalAlignment','middle','Color','w');
text(axw3,4.5,15,'dNami','FontName','Helvetica','FontSize',20,'HorizontalAlignment','left','VerticalAlignment','middle','Color','w');


colormap(axw0,palette);
colormap(axw1,palette);
colormap(axw2,palette);
colormap(axw3,palette);


% %% print
% filename_png = ['wavelet_pres_',label_station,'.png'];
% filename_pdf = strrep(filename_png,'.png','.pdf');
% exportgraphics(gcf,filename_png,'ContentType','image','Resolution',300);
% exportgraphics(gcf,filename_pdf,'ContentType','vector');


