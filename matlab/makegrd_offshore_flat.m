clear
close all


bwr = createcolormap([0,0,1;1,1,1;1,0,0]);

%% file
topodir = '../bathtopo';
file1 = 'gebco_2022_cut.nc';

[lon,lat,org] = grdread2(fullfile(topodir,file1));

depth_thresh = -5500;
TFshallow = depth_thresh < org;

file_out = fullfile(topodir,sprintf('gebco_2022_flat_above%04dm.nc',-depth_thresh));


fig = figure("Position",[200,500,1000,375]);
tile = tiledlayout(1,2);
ax1 = nexttile;
% pcolor(lon,lat,new); shading flat
% axis equal tight
% demcmap([-7000,3000]);
% colorbar(ax1);

pcolor(lon,lat,org); shading flat; hold on
[C,l] = contour(lon,lat,org,-8000:2000:-2000,'w-');
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

i1a = 1:5100;
i1b = 12400:14150;
i3 = n3:-1:4400;
i1c = 29800:n1;

xcat = vertcat(max(lon),x1(i1a),x3(i3),x1(i1b),x1(i1c));
ycat = vertcat(min(lat),y1(i1a),y3(i3),y1(i1b),y1(i1c));
xcat = downsample(xcat,200);
ycat = downsample(ycat,200);

plot(xcat,ycat,'r-',LineWidth=2);



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
grdwrite2(lon,lat,new, file_out);


