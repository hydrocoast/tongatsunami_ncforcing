clear
close all

% % ---------------------------------
% fname1 = '../run_presA1min_regionA_fg/_grd/fg0002_max.grd';
% fname2 = '../run_presA1min_regionC_fg/_grd/fg0002_max.grd';
% outgrdname = 'zratioAC_fg02.grd';
% % ---------------------------------
% fname1 = '../run_presA1min_regionA_fg/_grd/fg0003_max.grd';
% fname2 = '../run_presA1min_regionC_fg/_grd/fg0003_max.grd';
% outgrdname = 'zratioAC_fg03.grd';
% % ---------------------------------
% fname1 = '../run_presA1min_regionA_fg/_grd/fg0002_max.grd';
% fname2 = '../run_presA1min_regionB_fg/_grd/fg0002_max.grd';
% outgrdname = 'zratioAB_fg02.grd';
% % ---------------------------------
fname1 = '../run_presA1min_regionA_fg/_grd/fg0003_max.grd';
fname2 = '../run_presA1min_regionB_fg/_grd/fg0003_max.grd';
outgrdname = 'zratioAB_fg03.grd';
% % ---------------------------------


[x,y,zmax1] = grdread2(fname1); zmax1(abs(zmax1)<0.5) = NaN;
[~,~,zmax2] = grdread2(fname2); zmax2(abs(zmax2)<0.5) = NaN;


bwr = createcolormap(10,[0,0,1;1,1,1;1,0,0]);
% bwr = lines(10);

fig = figure("Position",[300,600,1500,450]);
tile = tiledlayout(1,3);
ax1 = nexttile;
pcolor(x,y,zmax1); shading flat
axis equal tight;


ax2 = nexttile;
pcolor(x,y,zmax1); shading flat
axis equal tight;

ax3 = nexttile;
pcolor(x,y,zmax1-zmax2); shading flat
axis equal tight;


colormap(ax1,turbo(10));
colormap(ax2,turbo(10));
clim(ax1,[0,50]);
clim(ax2,[0,50]);
colorbar(ax1,"west");

colormap(ax3,bwr);
clim(ax3,[-10,10]);
colorbar(ax3,"west");

tile.TileSpacing = "tight";


zratio = 100*(zmax1-zmax2)./zmax2;

grdwrite2(x,y,zratio,outgrdname);


bwr20 = createcolormap(20,[0,0,1;1,1,1;1,0,0]);

figure;
pcolor(x,y,zratio); shading flat
axis equal tight;
colorbar;

clim([-50,50]);
colormap(bwr20);

