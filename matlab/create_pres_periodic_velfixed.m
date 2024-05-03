clear
close all

%% 気圧データの作成
% --- 様々な周期を持つ正弦波 --- %

%% filenames
matname_pres_base = 'pres_TXXXmin_CVVV_NNwaves.mat';
  
%% origin 原点
lat0 =  -20.544686;
lon0 = -175.393311 + 360.0;

%% lonlat
latrange = [-60,60];
lonrange = [110,200.2];
dl = 0.10;
% dl = 1.0;
nlon = round(abs(diff(lonrange))/dl)+1;
nlat = round(abs(diff(latrange))/dl)+1;
lon = linspace(lonrange(1),lonrange(2),nlon);
lat = linspace(latrange(1),latrange(2),nlat);
[LON,LAT] = meshgrid(lon,lat);

degmesh = sqrt((LON-lon0).^2 + (LAT-lat0).^2);
kmmesh = deg2km(degmesh);

checkpoint = [129.5,28.3];
[~,indchk_lon] = min(abs(checkpoint(1)-lon));
[~,indchk_lat] = min(abs(checkpoint(2)-lat));



%% parameters below are based on Gusman et al.(2022), PAGEOPH
cs = 310.0; % m/s
amp = @(r,a) sign(a)*min(abs(a),abs(a*r^(-0.5))); % km

%% parameters for air gravity waves

g = 9.8; % m/s^2

nrepeat = 3;

c_g = 195.0;
c_g = repmat(c_g,[nrepeat,1]); %同じ波長の繰り返し

T_g = 12.0*60;
T_g = repmat(T_g,[nrepeat,1]); %同じ波長の繰り返し
sigma_g = 2*pi./T_g;

wavelength_g = c_g.*T_g/2*1e-3;
k_g = 2*pi./(2*wavelength_g.*1e3);

coef_g = 45; %振幅(peak)

nwave_g = length(wavelength_g);  


%% parameters
dt = 60;
t_start = dt*round(5000e3/c_g(1)/dt); % 中心から5,000km離れた地点に到達した時刻から
t_end = dt*round(10000e3/c_g(1)/dt); % 中心から10,000km離れた地点に到達した時刻まで
Tduration = t_end-t_start;
t = t_start:dt:t_end;
nt = length(t);


%% create pressure data
pres = zeros(nlat, nlon, nt);

fprintf('\n');
%t_line = linspace(0, 2*pi,dt);
    %% Gravity wave(s)
    for k = 1:nt
        if mod(k,20)==0; fprintf('%03d,',k); end
        
        for i = 1:nlat
            for j = 1:nlon
                pres_grav = 0.0;
                for iwave = 1:nwave_g
                    dist_peak = c_g(iwave)*t(k)*1e-3 - 2*(iwave-1)*wavelength_g(iwave); % km
                    pres_add = 0.0;
                    amp_peak = amp(dist_peak,coef_g);
                    %% peak side
                    dist_from_antinode = kmmesh(i,j)-dist_peak; % km
%                     if abs(dist_from_antinode) <= 0.5*wavelength_g(iwave)
                    if abs(dist_from_antinode) <= wavelength_g(iwave)
                        pres_add = pressure_anomaly_airgravitywave(-sign(dist_from_antinode)*amp_peak, wavelength_g(iwave), abs(dist_from_antinode));
                    end

                    pres_grav = pres_grav + pres_add;
                end
                pres(i,j,k) = pres(i,j,k) + pres_grav ;
                %pres(i,j,k+1) = pres(i,j,k) + pres_grav;
            end
        end
%         clf(fig); pcolor(lon,lat,pres(:,:,k)); shading flat; caxis([-1,1]); colorbar; drawnow;
    end
    fprintf('\n');

%% check time-series of the air pressure


fig = figure;
p = fig.Position;
fig.Position = [0.5*p(1), 0.5*p(2), 1.2*p(3), 0.75*p(4)];
ax = nexttile;
plot(t/3600,squeeze(pres(indchk_lat,indchk_lon,:)),'Color','b','LineWidth',2.0);
xlim([floor(t(1)/3600),t(end)/3600]);
ylim([-1.2,1.2]);
% xticks(0.0:1.0:10.0)
ylabel(ax,'Pressure anomaly (hPa)','FontName','Times','FontSize',18,HorizontalAlignment='center');
xlabel(ax,'Elapsed time (hour)','FontName','Times','FontSize',18,HorizontalAlignment='center');
set(ax,'FontName','Times','FontSize',18);
grid on
% exportgraphics(fig,'create_press_.png','ContentType','image','Resolution',300);

%% save
matname_pres = strrep(matname_pres_base,'XXX',sprintf('%03d',round(T_g(1)/60)));
matname_pres = strrep(matname_pres,'NN',sprintf('%02d',round(nrepeat)));
matname_pres = strrep(matname_pres,'VVV',sprintf('%03d',round(c_g(1))));
save(matname_pres,'-v7.3',...
     'lon0','lat0','lonrange','latrange','lon','lat',...
     'nlon','nlat','dl','pres',...
     'cs','wavelength_g','dt','t','nt','c_g')


snap = round(linspace(1,round(0.8*nt),9));

fig = figure;
p = fig.Position;
fig.Position = [p(1)-0.25*p(3),p(2)-0.25*p(4),1.5*p(3),1.2*p(4)];
tile = tiledlayout(3,3);
i = 0;
for k = snap
    i = i + 1;
    ax(i) = nexttile;
    pcolor(lon,lat,pres(:,:,k)); shading flat
    axis equal tight
    text(ax(i),lon(1),lat(end),sprintf('%d min',round(t(k)/60)),'FontSize',14,'VerticalAlignment','top','HorizontalAlignment','left');
    clim(ax(i),[-0.25,0.25]);
    if i<7
        ax(i).XAxis.TickLabels = '';
    end
    if ~(mod(i,3)==1)
        ax(i).YAxis.TickLabels = '';
    end
end
tile.TileSpacing = 'tight';
tile.Padding = 'compact';



%% formula - air gravity wave
function pres = pressure_anomaly_airgravitywave(amp_antinode, wavelength_g, distance_from_antinode)
    pres = amp_antinode*cos((pi/wavelength_g*distance_from_antinode+pi/2));
end
