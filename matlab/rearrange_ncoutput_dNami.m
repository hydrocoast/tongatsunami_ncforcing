clear
close all

%% file list
ncdir_org = '/media/miyashita/HDCZ-UT2/dataset/TongaEruption2022/FromStephen/ncfile';
flist = dir(fullfile(ncdir_org,'*.nc'));
nfile = size(flist,1);

ncfile_base = 'slp_XXX.nc';
ncdir_out = 'dNami_slp';

%% read test
% k = 5;
% ncfile_read = fullfile(ncdir_org,flist(k).name);
% ncfile_write = strrep(ncfile_base,'XXX',sprintf('%03d',k));
% t = ncread(ncfile_read,'time');
% lon = ncread(ncfile_read,'lon');
% lat = ncread(ncfile_read,'lat');
% slp = ncread(ncfile_read,'slp');
% nlon = length(lon);
% nlat = length(lat);
%% shift -180 - 0 -> 180 - 360
% [lon,slp] = shift_lon(lon,slp);
% %% plot
% pcolor(lon,lat,slp'); shading flat;
% axis equal tight;

f0 = fullfile(ncdir_org,flist(1).name);
t0 = ncread(f0,'time');

if ~isfolder(ncdir_out); mkdir(ncdir_out); end
for k = 1:nfile
    ncfile_read = fullfile(ncdir_org,flist(k).name);
    ncfile_write = fullfile(ncdir_out,strrep(ncfile_base,'XXX',sprintf('%03d',k)));

    lon = ncread(ncfile_read,'lon');
    lat = ncread(ncfile_read,'lat');
    slp = ncread(ncfile_read,'slp');
    nlon = length(lon);
    nlat = length(lat);
    [lon,slp] = shift_lon(lon,slp);
    slp = slp.*1e-2; % Pa -> hPa

    t = ncread(ncfile_read,'time') - t0;
    t = t*3600; % hour -> second
    disp(['File: ',flist(k).name, sprintf(' , time: %0.1f min', t/60)]);

    %% output to nc
    if isfile(ncfile_write); delete(ncfile_write); end
    % % lonlat
    nccreate(ncfile_write,'lon',"Dimensions",{"lon",nlon},"FillValue","disable","Datatype", "double");
    nccreate(ncfile_write,'lat',"Dimensions",{"lat",nlat},"FillValue","disable","Datatype", "double");
    ncwrite(ncfile_write,'lon',lon);
    ncwrite(ncfile_write,'lat',lat);
    % % pressure
    % nccreate(ncfile_write,'slp',"Dimensions",{"lon",nlon,"lat",nlat},"FillValue","disable","Datatype", "double");
    nccreate(ncfile_write,'slp',"Dimensions",{"lon",nlon,"lat",nlat},"FillValue","disable","Datatype", "single");
    ncwrite(ncfile_write,'slp',slp);
    % % time
    nccreate(ncfile_write,'time',"Datatype", "double");
    ncwrite(ncfile_write,'time',t);

    % ncid = netcdf.open(ncfile_write,'WRITE');
    % netcdf.close(ncid);
    clear lon lat slp nlon nlat t

end

%% shift -180 - 0 -> 180 - 360
function [lon,slp] = shift_lon(lon,slp)
    ind_lon_rearrange = find(lon<0);
    lon_shift = lon(ind_lon_rearrange);
    lon_shift = lon_shift + 360.0;
    lon(ind_lon_rearrange) = [];
    lon = vertcat(lon,lon_shift);

    slp_shift = slp(ind_lon_rearrange,:);
    slp(ind_lon_rearrange,:) = [];
    slp = vertcat(slp,slp_shift);
end