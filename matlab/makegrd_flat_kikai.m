clear
close all


bwr = createcolormap([0,0,1;1,1,1;1,0,0]);

%% file
topodir = '../bathtopo';
file1 = 'gebco_2022_cut.nc';

[lon,lat,org] = grdread2(fullfile(topodir,file1));

depth_thresh = -300;
TFshallow = depth_thresh < org;

file_out = fullfile(topodir,'gebco_2022_flat_kikai.nc');


fig = figure("Position",[200,500,1000,375]);
tile = tiledlayout(1,2);
ax1 = nexttile;

pcolor(lon,lat,org); shading flat; hold on
axis equal tight
demcmap([-7000,3000]);
colorbar(ax1);


[LON,LAT] = meshgrid(lon,lat);
TFlon = 129.8 < LON & LON < 130.2;
TFlat =  28.0 < LAT & LAT < 28.4;
TFapp = TFlon & TFlat & TFshallow;

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


