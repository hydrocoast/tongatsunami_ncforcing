clear
close all

matname1 = 'waveform_regionA_fg03.mat';
matname2 = 'waveform_regionB_fg03.mat';
matname3 = 'waveform_regionC_fg03.mat';

D1 = load(matname1);
D2 = load(matname2);
D3 = load(matname3);

fig = figure('Position',[300,300,900,600]);
tile = tiledlayout(2,2);

for k = 1:4
    ax(k) = nexttile;
    hold on
    LA = plot(D1.t_elapsed./3600, D1.eta(:,k),'-','LineWidth',1);
    LB = plot(D2.t_elapsed./3600, D2.eta(:,k),'-','LineWidth',1);
    LC = plot(D3.t_elapsed./3600, D3.eta(:,k),'-','LineWidth',1);
    box on
    grid on
end
linkaxes(ax,'xy');
xlim(ax(1),[7,13]);
ylim(ax(1),[-1.1,1.1]);
% ylim(ax(1),[-0.1,0.1]);

tile.Padding = 'compact';
tile.TileSpacing = 'tight';


