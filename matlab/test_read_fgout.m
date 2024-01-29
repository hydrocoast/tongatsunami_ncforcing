clear
close all

%% directory and filenames
dname = '/home/miyashita/Research/AMR/tongatsunami2022_ncforcing/matlab';
fname = 'fgout0001.q0360';

%% read header
fid = fopen(fullfile(dname,fname),'r');
header = textscan(fid,'%f %s\n',8);
fclose(fid);

nx = header{1}(3);
ny = header{1}(4);
x = linspace(header{1}(5), header{1}(5) + (nx-1)*header{1}(7), nx);
y = linspace(header{1}(6), header{1}(6) + (ny-1)*header{1}(8), ny);

%% read data
dat = readmatrix(fullfile(dname,fname),"FileType","text","NumHeaderLines",9);

v1 = dat(:,1);
v4 = dat(:,4);
land = v1==0;
eta = v4;
eta(land) = NaN;

eta = reshape(eta,[nx,ny])';


%% plot
figure
pcolor(x,y,eta); shading flat
hold on
contour(x,y,reshape(v1,[nx,ny])',[1e-2,1e-2],'k-');
hold off
axis equal tight
box on

bwr = createcolormap(20,[0,0,1;1,1,1;1,0,0]);
colormap(bwr);

clim([-0.2,0.2]);
colorbar;



