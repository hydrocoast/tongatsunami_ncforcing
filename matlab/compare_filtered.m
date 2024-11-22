clear
close all

topodir = '../bathtopo';
file1 = 'gebco_2022_cut.nc';
file2 = 'gebco_2022_filtered.nc';

[lon,lat,org] = grdread2(fullfile(topodir,file1));
[~,~,new] = grdread2(fullfile(topodir,file2));


figure
pcolor(lon,lat,new-org); shading flat
axis equal tight
demcmap([-7000,3000]);




