clear
close all

%% 作成した気圧データをGeoClawで計算するためのテキストファイルに出力

%% filename
% matfile = 'pres_synthetic.mat';
% matfile = 'pres_lamb.mat';
% matfile = 'pres_lg_A.mat';6
matfile = 'pres_lg_A_15arcmin.mat';
% matfile = 'pres_lg_A_30arcmin.mat';
% matfile = 'pres_lg_B.mat'; 
% matfile = 'pres_T010min_03waves.mat';
% matfile = 'pres_T012min_03waves.mat';
% matfile = 'pres_T015min_03waves.mat';
% matfile = 'pres_T020min_03waves.mat';
% matfile = 'pres_T012min_C170_03waves.mat';
% matfile = 'pres_T012min_C175_03waves.mat';
% matfile = 'pres_T012min_C180_03waves.mat';
% matfile = 'pres_T012min_C185_03waves.mat';
% matfile = 'pres_T012min_C190_03waves.mat';
% matfile = 'pres_T012min_C195_03waves.mat';
load(matfile)

%% output
ncdir = './slp_nc';
if exist(ncdir,'dir'); system(['rm -rf  ', ncdir]); end
mkdir(ncdir);

ncfile_base = 'slp_XXX.nc';

nt = length(t);

% for k = 1:3
for k = 1:nt
    ncfile = fullfile(ncdir,strrep(ncfile_base,'XXX',sprintf('%04d',k)));
    disp([ncfile, '   ...']);

    % % lonlat
    nccreate(ncfile,'lon',"Dimensions",{"lon",nlon},"FillValue","disable","Datatype", "single");
    nccreate(ncfile,'lat',"Dimensions",{"lat",nlat},"FillValue","disable","Datatype", "single");
    ncwrite(ncfile,'lon',lon);
    ncwrite(ncfile,'lat',lat);
    % % pressure
    nccreate(ncfile,'slp',"Dimensions",{"lon",nlon,"lat",nlat},"FillValue","disable","Datatype", "single");
    ncwrite(ncfile,'slp',permute(flipud(pres(:,:,k)),[2,1]));
    % % time
    nccreate(ncfile,'time',"Datatype", "single");
    ncwrite(ncfile,'time',t(k));
end

%% single file
% ncfile = 'slp_all.nc';
% 
% % % lonlat
% nccreate(ncfile,'lon',"Dimensions",{"lon",nlon},"FillValue","disable","Datatype", "single");
% nccreate(ncfile,'lat',"Dimensions",{"lat",nlat},"FillValue","disable","Datatype", "single");
% ncwrite(ncfile,'lon',lon);
% ncwrite(ncfile,'lat',lat);
% % % time
% nccreate(ncfile,'time',"Dimensions",{"time",nt},"FillValue","disable","Datatype", "single");
% ncwrite(ncfile,'time',t);
% % % pressure
% nccreate(ncfile,'slp',"Dimensions",{"lon",nlon,"lat",nlat,"time",nt},"FillValue","disable","Datatype", "single");
% ncwrite(ncfile,'slp',permute(flipud(pres(:,:,:)),[2,1,3]));
