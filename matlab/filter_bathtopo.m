clear
close all


bwr = createcolormap([0,0,1;1,1,1;1,0,0]);

%% file
topodir = '../bathtopo';
file1 = 'gebco_2022_cut.nc';
file2 = 'gebco_2022_medfilt2.nc';

[lon,lat,org] = grdread2(fullfile(topodir,file1));


filtered1 = medfilt2(org,[50,50]);
filtered2 = medfilt2(filtered1,[50,50]);
% filtered1 = medfilt2(org,[100,100]);


% grdwrite2(lon,lat,filtered1, fullfile(topodir,file2));
grdwrite2(lon,lat,filtered2, fullfile(topodir,file2));



fig = figure("Position",[200,500,1000,375]);
tile = tiledlayout(1,2);
ax1 = nexttile;
pcolor(lon,lat,filtered2); shading flat
axis equal tight
demcmap([-7000,3000]);
colorbar(ax1);

ax2 = nexttile;
pcolor(lon,lat,filtered2-org); shading flat
axis equal tight
clim(ax2,[-2000,2000])
colormap(ax2,bwr);
colorbar(ax2);
grid on
box on


tile.TileSpacing = 'tight';
tile.Padding = 'compact';





