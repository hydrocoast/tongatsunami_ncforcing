clear
close all

%% 気圧データの作成
% --- Lamb波＋大気重力波
%% gravity wave switch
active_g = 1; % 1: on, otherwise: off

%% filenames
if active_g==1
    matname_pres = 'pres_synthetic.mat';
else
    matname_pres = 'pres_l.mat';
end

%% origin
lat0 =  -20.544686;
lon0 = -175.393311 + 360.0;

%% lonlat
latrange = [-60,60];
lonrange = [110,200.2];
dl = 0.10;
% dl = 3.0;
nlon = round(abs(diff(lonrange))/dl)+1;
nlat = round(abs(diff(latrange))/dl)+1;
lon = linspace(lonrange(1),lonrange(2),nlon);
lat = linspace(latrange(1),latrange(2),nlat);
[LON,LAT] = meshgrid(lon,lat);

degmesh = sqrt((LON-lon0).^2 + (LAT-lat0).^2);
kmmesh = deg2km(degmesh);

% checkpoint = [135.0,32.5];
checkpoint = [129.5,28.3];
[~,indchk_lon] = min(abs(checkpoint(1)-lon));
[~,indchk_lat] = min(abs(checkpoint(2)-lat));


%% parameters
dt = 60;
t = dt:dt:3600*16;
nt = length(t);
%% parameters below are based on Gusman et al.(2022), PAGEOPH
% https://link.springer.com/article/10.1007/s00024-022-03154-1
% cs = 317.0; % m/s
cs = 310.0; % m/s
wavelength = 1500*cs*1e-3; % km
coef_lamb_peak = 169;
coef_lamb_trough = -107;
amp = @(r,a) sign(a)*min(abs(a),abs(a*r^(-0.5))); % km

coef_lamb_add = 25;
wavelength_add = 4.0*wavelength; % km


%% parameters for air gravity waves
if active_g == 1
    g = 9.8; % m/s^2
    % N = 1.16e-2; % /s
    N = 1.62e-2; % /s
    mu = 0.5*(N^2/g + g/cs^2); % /m
    sigma0 = mu*cs;
    % wavelength_g = wavelength*[0.37; 0.34; 0.29;   0.27; 0.255; 0.23; 0.22; 0.215; 0.21;   0.20; 0.187; 0.18; 0.179; 0.175; 0.17;   0.168; 0.165; 0.160;  0.155; 0.154; 0.153; 0.148; 0.143; 0.14; 0.135; 0.1375; 0.13;0.1275;0.125]; % km 0.25-0.27
    % nwave_g = length(wavelength_g);
    % coef_g_p = [-10; -25; -30; 10; 25; 20; 20; 20; -25;      -25; -20; -30; 20; 10; 10; -10; -10; 20; 10; 20; 20; 20; 20; -10; -10; -10;-10;-10;-10; -10];
    % coef_g_t = [ -5; -10;  20;-40; 25; 20; 10; 10; -20;      -20; -25; -20; 8;  10; 10; -10; -20;-20; 20; 20; 20; 20; 20; -10; -10; -10;-10;-10;-10;-10];
    wavelength_g = wavelength*[0.37; 0.34; 0.29; 0.27; 0.255; 0.23; 0.22; 0.215; 0.21; 0.20; 0.187; 0.18; 0.179; 0.175; 0.17; 0.168; 0.165; 0.160;  0.155; 0.154; 0.153; 0.148; 0.143; 0.14; 0.135; 0.1375; 0.13;0.1275;0.125; (0.124:-0.002:0.100)'; (0.098:-0.001:0.070)'];
    nwave_g = length(wavelength_g);
    coef_g_p = [ 10;  5;  5; 5; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 20; 10; 10; 25; 25; 25; 10; 10; 10; 10; 10; 10; 10; 15*ones(13,1); linspace(15,0.1,29)'];
    coef_g_t = [  5;  5;  5; 5; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 10; 15*ones(13,1); linspace(15,0.1,29)'];
    % wavelength_g = [200:-10:100, 95:-5:60, 57.5:-2.5:45, 44:-1:30]';
    % nwave_g = length(wavelength_g);
    % coef_g_p = [2.5*ones(11,1); 10*ones(8,1); 10*ones(6,1); 15*ones(15,1)];
    % coef_g_t = coef_g_p;


    k_g = 2*pi./(2*wavelength_g.*1e3); % wavelength_g represents a half wavelength!!!


    sigma_g = zeros(nwave_g,1);
    for iwave = 1:nwave_g
        sigma_g(iwave) = dispersion_relation_airgravitywave(k_g(iwave),mu,N,cs,0.0);
    end
    c_g = sigma_g./k_g;
    perT_g_min = 2*pi./sigma_g/60;
end


% fig = figure;
%% create pressure data
pres = zeros(nlat, nlon, nt);
for k = 1:nt
    if mod(k,20)==0; fprintf('%03d,',k); end

    %% Lamb wave
    dist_peak = cs*t(k)*1e-3; % km
    amp_peak = amp(dist_peak,coef_lamb_peak);
%     dist_trough = max(1,dist_peak-wavelength); % km
    dist_trough = max(1,dist_peak-0.4*wavelength); % km
    amp_trough = amp(dist_trough,coef_lamb_trough);

    dist_peak_add = max(1,dist_peak-0.7*wavelength_add); % km howahowa
    amp_peak_add = amp(dist_peak_add,coef_lamb_add);

    for i = 1:nlat
    for j = 1:nlon
        %% Lamb wave peak side
        dist_from_antinode = abs(kmmesh(i,j)-dist_peak); % km
        if dist_from_antinode > 0.5*wavelength
            pres_lamb = 0.0;
        else
            pres_lamb = pressure_anomaly_Lamb(amp_peak, wavelength, dist_from_antinode);
        end
        %% Lamb wave trough side
        dist_from_antinode = abs(kmmesh(i,j)-dist_trough); % km
        if dist_from_antinode <= 0.5*wavelength
            pres_lamb = pres_lamb + pressure_anomaly_Lamb(amp_trough, wavelength, dist_from_antinode);
        end

        %% Additional peak
        dist_from_antinode = abs(kmmesh(i,j)-dist_peak_add); % km
        if dist_from_antinode <= 0.5*wavelength_add
            pres_lamb = pres_lamb + pressure_anomaly_Lamb(amp_peak_add, wavelength_add, dist_from_antinode) -0.1;
           % pres_lamb_short = pres_lamb +0.1*sin(t)+0.1*sin(t+1);
     
        end
        
        %% Composite pressure data
        pres(i,j,k) = pres(i,j,k) + pres_lamb;
    end
    end
%     clf(fig); pcolor(lon,lat,pres(:,:,k)); shading flat; caxis([-1,1]); colorbar; drawnow; 
end
fprintf('\n');

if active_g == 1

    %% Gravity wave(s)
    for k = 1:nt
        if mod(k,20)==0; fprintf('%03d,',k); end
        dist_peak = c_g.*t(k)*1e-3; % km
        for i = 1:nlat
            for j = 1:nlon
                pres_grav = 0.0;
                for iwave = 1:nwave_g
                    pres_add = 0.0;
                    amp_peak = amp(dist_peak(iwave),coef_g_p(iwave));
                    %% peak side
                    dist_from_antinode = kmmesh(i,j)-dist_peak(iwave); % km
                    if abs(dist_from_antinode) <= 0.5*wavelength_g(iwave)
                        pres_add = pressure_anomaly_airgravitywave(amp_peak, wavelength_g(iwave), abs(dist_from_antinode));
                    end

                    %% trough side
                    dist_trough = max(1,dist_peak(iwave)-wavelength_g(iwave)); % km
                    amp_trough = -amp(dist_trough,coef_g_t(iwave));
                    dist_from_antinode = kmmesh(i,j)-dist_trough; % km
                    if abs(dist_from_antinode) <= 0.5*wavelength_g(iwave)
                        pres_add = pressure_anomaly_airgravitywave(amp_trough, wavelength_g(iwave), abs(dist_from_antinode));
                    end

                    pres_grav = pres_grav + pres_add;
                end
                pres(i,j,k) = pres(i,j,k) + pres_grav;
            end
        end
%         clf(fig); pcolor(lon,lat,pres(:,:,k)); shading flat; caxis([-1,1]); colorbar; drawnow;
    end
    fprintf('\n');

end

%% check time-series of the air pressure
figure
ax = axes;
plot(t/3600,squeeze(pres(indchk_lat,indchk_lon,:)));
xlim([6.0,16.0]);
grid on
ax.XAxis.TickValues = 0:1:20;

print('気圧波形_l','-djpeg')
%% save
save(matname_pres,'-v7.3',...
     'lon0','lat0','lonrange','latrange','lon','lat',...
     'nlon','nlat','dl','pres','perT_g_min',...
     'cs','wavelength','dt','t','nt','active_g')


% %% output
% ncdir = './pres_nc';
% if exist(ncdir,'dir'); system(['rm -rf  ', ncdir]); end
% mkdir(ncdir);




%% formula - Lamb wave
function pres = pressure_anomaly_Lamb(amp_antinode, wavelength, distance_from_antinode)
    pres = amp_antinode*cos(pi/wavelength*distance_from_antinode);
%     pres = amp_antinode*(1-min(distance_from_antinode/wavelength,1));
end


%% formula - dispersion relation of gravity waves
function sigma_g = dispersion_relation_airgravitywave(k,mu,N,cs,n)
    sigma_g = sqrt( ...
                    0.5*cs^2*(k^2+n^2+mu^2)* ...
                    (1-sqrt(1-(4*k^2*N^2/(cs^2*(k^2+n^2+mu^2)^2)))) ...
                   );
end

%% formula - air gravity wave
function pres = pressure_anomaly_airgravitywave(amp_antinode, wavelength, distance_from_antinode)
   pres = amp_antinode*cos(pi/wavelength*distance_from_antinode);
%     pres = amp_antinode*(1-min(distance_from_antinode/wavelength,1));
end


