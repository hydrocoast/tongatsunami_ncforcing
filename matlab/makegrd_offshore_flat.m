clear
close all


bwr = createcolormap([0,0,1;1,1,1;1,0,0]);

%% file
topodir = '../bathtopo';
file1 = 'gebco_2022_cut.nc';

[lon,lat,org] = grdread2(fullfile(topodir,file1));

depth_thresh = -5700;
TFshallow = depth_thresh < org;

% file_out = fullfile(topodir,sprintf('gebco_2022_flat_above%04dm.nc',-depth_thresh));
% file_out = fullfile(topodir,'gebco_2022_flat_amamiplateau.nc');
file_out = fullfile(topodir,'gebco_2022_flat_daitoridges.nc');


fig = figure("Position",[200,500,1000,375]);
tile = tiledlayout(1,2);
ax1 = nexttile;
% pcolor(lon,lat,new); shading flat
% axis equal tight
% demcmap([-7000,3000]);
% colorbar(ax1);

pcolor(lon,lat,org); shading flat; hold on
[C,l] = contour(lon,lat,org,-8000:2000:-2000,'w-');
% [C,l] = contour(lon,lat,org,-5700:500:-4200,'w-');
% [C,l] = contour(lon,lat,org,[-5700,-5000],'w-'); % only daito ridges
axis equal tight
demcmap([-7000,3000]);
colorbar(ax1);


%% contourline
S = contourdata(C);
[~,ind] = maxk([S.numel]',3);
plot(S(ind(1)).xdata, S(ind(1)).ydata, 'm-', 'LineWidth',2);
plot(S(ind(2)).xdata, S(ind(2)).ydata, 'y-', 'LineWidth',2);
plot(S(ind(3)).xdata, S(ind(3)).ydata, 'g-', 'LineWidth',2);

[n1,n2,n3] = S(ind).numel;
[x1,x2,x3] = S(ind).xdata;
[y1,y2,y3] = S(ind).ydata;

plot(x1(1),y1(1),'mo');
plot(x2(1),y2(1),'yo');
plot(x3(1),y3(1),'go');

% --------------------------------
% %% mask offshore
% i1a = 1:5100;
% i3 = n3:-1:4400;
% i1b = 12400:14150;
% i1c = 29800:n1;
% 
% xcat = vertcat(max(lon),x1(i1a),x3(i3),x1(i1b),x1(i1c));
% ycat = vertcat(min(lat),y1(i1a),y3(i3),y1(i1b),y1(i1c));
% xcat = downsample(xcat,200);
% ycat = downsample(ycat,200);
% --------------------------------

% --------------------------------
%% mask amami plateau
i1a = 12400:15500;
i1b = 18200:23000;
i3 = 4400;

xcat = vertcat(x3(i3),x1(i1a),x1(i1b));
ycat = vertcat(y3(i3),y1(i1a),y1(i1b));
xcat = downsample(xcat,100);
ycat = downsample(ycat,100);
% --------------------------------

% --------------------------------
% %% mask daito ridges
% i1a = 21700:24400;
% i3 = 11300:14000;
% i2 = 14500:15000;
% i1b = 28000:33700;
% 
% xcat = vertcat(x1(i1a),x3(i3),x2(i2),x1(i1b));
% ycat = vertcat(y1(i1a),y3(i3),y2(i2),y1(i1b));
% xcat = downsample(xcat,100);
% ycat = downsample(ycat,100);
% --------------------------------


plot(xcat,ycat,'r-',LineWidth=2);

fid = fopen('maskline.dat','w');
fprintf(fid,'%15.10f %15.10f\n',[xcat,ycat]');
fclose(fid);


% S1 = S(ind(1));
% S2 = S(ind(2));
% S3 = S(ind(3));
% plot(S1.xdata(13000), S1.ydata(13000), 'ko', MarkerFaceColor='y', MarkerSize=10);


[LON,LAT] = meshgrid(lon,lat);
% lat_above = 16;
% lon_below = 138;
% TFlon = LON<lon_below;
% TFlat = LAT>lat_above;
in = inpolygon(LON(:),LAT(:),xcat,ycat);
TFin = reshape(in,[length(lat),length(lon)]);
TFapp = TFin & TFshallow;

%% apply
new = org;
new(TFapp) = depth_thresh;


ax2 = nexttile;
pcolor(lon,lat,new); shading flat; hold on
axis equal tight
demcmap([-7000,3000]);
% pcolor(lon,lat,new-org); shading flat
% axis equal tight
% clim(ax2,[-2000,2000])
% colormap(ax2,bwr);
% colorbar(ax2);
% grid on
% box on


tile.TileSpacing = 'tight';
tile.Padding = 'compact';


%% output
% grdwrite2(lon,lat,new, file_out);


