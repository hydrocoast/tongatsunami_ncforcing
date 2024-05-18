clear
close all

% matname = '../run_presA1min_3/_mat/fgout03.mat'; savename = 'waveform_regionA_fg03.mat';
% matname = '../run_presA1min_regionB/_mat/fgout03.mat'; savename = 'waveform_regionB_fg03.mat';
% matname = '../run_presA1min_regionC/_mat/fgout03.mat'; savename = 'waveform_regionC_fg03.mat';
% pickxy = [
%           129.5600, 28.3187; 
%           129.5482, 28.3213;
%           129.5460, 28.3228;
%           129.5370, 28.3229;
%           ];

% matname = '../run_presA1min_3/_mat/fgout02.mat'; savename = 'waveform_regionA_fg02.mat';
% matname = '../run_presA1min_regionB/_mat/fgout02.mat'; savename = 'waveform_regionB_fg02.mat';
matname = '../run_presA1min_regionC/_mat/fgout02.mat'; savename = 'waveform_regionC_fg02.mat';
pickxy = [
          135.6176, 22.0782; 
          133.8340, 23.1591;
          132.6403, 23.8715;
          131.3511, 24.4391;
          ];


load(matname);


np = size(pickxy,1);

indx = zeros(np,1);
indy = zeros(np,1);
for i = 1:np
    [~,indx(i)] = min(abs(x(:)-pickxy(i,1)));
    [~,indy(i)] = min(abs(y(:)-pickxy(i,2)));
end


ind = sub2ind([nx,ny],indx,indy);


eta = full(eta_sp(ind,:))';
etamax_pick = max(full(abs(eta)));


save(savename,'eta','etamax_pick','pickxy','t_elapsed','-v7.3');

plot(t_elapsed/60,eta,'-','LineWidth',1);
grid on
box on


