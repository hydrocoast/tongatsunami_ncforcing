clear
close all


fname = '../bathtopo/GEBCO_2022_128_138_20_30.nc';
outgrdname = 'phasevel_depth.grd';

[lon,lat,topo] = grdread2(fname);


bath = -topo;
bath(bath<0.0) = NaN;

vel = sqrt(9.8*bath);

cmap = jet(10);
cmap = vertcat(cmap,[0.8,0.8,0.8]);


figure
pcolor(lon,lat,vel); shading flat
axis equal tight
colormap(cmap);
clim([110,220])
colorbar


grdwrite2(lon,lat,vel,outgrdname);

