clear
close all

file_org   = '../bathtopo/gebco_2022_n60.0_s-60.0_w110.0_e240.0.nc';
file_patch = '../bathtopo/../bathtopo/gebco_2022_filtered.nc';

file_out   = '../bathtopo/gebco_2022_n60.0_s-60.0_w110.0_e240.0_filter.nc';

[lon0,lat0,topo0] = grdread2(file_org);
[lon1,lat1,topo1] = grdread2(file_patch);

[ny0,nx0] = size(topo0);
[ny1,nx1] = size(topo1);
[minx,ix] = min(abs(lon1(1)-lon0));
[miny,iy] = min(abs(lat1(1)-lat0));


topo_mod = topo0;

topo_mod(iy:iy+(ny1-1),ix:ix+(nx1-1)) = topo1;


grdwrite2(lon0,lat0,topo_mod,file_out);







