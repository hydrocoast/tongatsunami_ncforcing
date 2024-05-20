clear
close all

topogrd = 

matname1 = 'waveform_regionA_fg03.mat';
matname2 = 'waveform_regionB_fg03.mat';
matname3 = 'waveform_regionC_fg03.mat';

D1 = load(matname1);
D2 = load(matname2);
D3 = load(matname3);

cmap = lines(7);
LC1 = cmap(1,:);
LC2 = cmap(4,:);
LC3 = cmap(5,:);
simcase_label = ["A (high res.)","B (mid res.)","C (low res.)"];


fig = figure('Position',[300,300,900,600]);
tile = tiledlayout(2,2);

for k = 1:4
    ax(k) = nexttile;
    hold on
    LA = plot(D1.t_elapsed./3600, D1.eta(:,k),'-','LineWidth',1.5,'Color',LC1);
    LB = plot(D2.t_elapsed./3600, D2.eta(:,k),'-','LineWidth',1.5,'Color',LC2);
    LC = plot(D3.t_elapsed./3600, D3.eta(:,k),'-','LineWidth',1.5,'Color',LC3);
    box on
    grid on
    set(gca,'FontName','Helvetica','FontSize',16);
    ax(k).YAxis.TickLabelFormat = '%0.1f';
end
linkaxes(ax,'xy');
xlim(ax(1),[7,13]);
ylim(ax(1),[-1.1,1.1]);
% ylim(ax(1),[-0.1,0.1]);

legend(ax(1),[LA,LB,LC],simcase_label,'FontName','Helvetica','FontSize',16,'Location','northwest');

xlabel(ax(3),'Relative time (hour)','FontName','Helvetica','FontSize',18)
ylabel(ax(1),'Surface level (m)','FontName','Helvetica','FontSize',18)

ax(1).XTickLabel = '';
ax(2).XTickLabel = '';

xlim(ax(1),[8.5,12.5]);
tile.Padding = 'compact';
tile.TileSpacing = 'tight';


