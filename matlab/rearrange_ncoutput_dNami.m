clear
close all

%% file list
ncdir_org = '/media/miyashita/HDCZ-UT2/dataset/TongaEruption2022/FromStephen/ncfile';
flist = dir(fullfile(ncdir_org,'*.nc'));

%% read test
i = 5;
ncfilename = fullfile(ncdir_org,flist(i).name);
t = ncread(ncfilename,'time');
lon = ncread(ncfilename,'lon');
lat = ncread(ncfilename,'lat');
slp = ncread(ncfilename,'slp');


%% shift -180 - 0 -> 180 - 360
ind_lon_rearrange = find(lon<0);
lon_shift = lon(ind_lon_rearrange);
lon_shift = lon_shift + 360.0;
lon(ind_lon_rearrange) = [];
lon = vertcat(lon,lon_shift);

slp_shift = slp(ind_lon_rearrange,:);
slp(ind_lon_rearrange,:) = [];
slp = vertcat(slp,slp_shift);

%% plot
pcolor(lon,lat,slp'); shading flat;
axis equal tight;

