clear
close all

bwr = createcolormap([0,0,1;1,1,1;1,0,0]);

grddir = '../run_presA1min_regionA_fg/_grd';
grdname = 'fg0003_max.grd';


[lon,lat,z] = grdread2(fullfile(grddir,grdname));


pcolor(lon,lat,z); shading flat; axis equal tight;
colormap(bwr);
clim([-30,30]);


