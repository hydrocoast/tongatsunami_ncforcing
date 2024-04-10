clear
close all

bwr = createcolormap([0,0,1;1,1,1;1,0,0]);

grddir = '../run_presA1min_3/_grd';
grdname = 'fgout0002_0150.grd';


[lon,lat,z] = grdread2(fullfile(grddir,grdname));


pcolor(lon,lat,z); shading flat; axis equal tight;
colormap(bwr);
clim([-10,10]);


