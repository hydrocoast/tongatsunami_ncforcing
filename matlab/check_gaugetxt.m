clear
close all

dirname = '../run_L5_Amami_presA/_output';
gaugefile = 'gauge00003.txt';

dat = readmatrix(fullfile(dirname,gaugefile),"FileType","text","CommentStyle",'#');

t = dat(:,2);
eta = dat(:,6);

eta(abs(eta)>5.0) = NaN;


plot(t./3600,eta,'-');
axis tight;
grid on
box on