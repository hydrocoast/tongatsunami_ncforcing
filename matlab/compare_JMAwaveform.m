clear
close all

%% sim data
matdir = '.';
cmap = lines(7);
% --------------------------------------
mat1 = 'run_presA1min.mat';
mat2 = 'run_jaguar.mat';
simcase_label = {'Parametric pressure model','JAGUAR'};
simcase_prefix = 'waveforms_SJ';
LC1 = cmap(7,:);
LC2 = cmap(1,:);
% time_offset(1,1:5) = [-0.27,  0.0, -0.81,  0.0,  0.0];
time_offset(1,1:5) = [-0.27,  0.0,  0.0,  0.0,  0.0];
time_offset(2,1:5) = [ 0.10, 0.44, 0.27, 0.40, 0.32];
% --------------------------------------
time_offset = time_offset';

ind_pickup = 1:5;
YL = [20,40,110,60,70];
npick = length(ind_pickup);
xrange = [6,15];

%% load obs and sim data
load('JMA_records_limited.mat');
T1 = load(fullfile(matdir,mat1),'Tsim').Tsim;
T2 = load(fullfile(matdir,mat2),'Tsim').Tsim;

%% rename
JMA.Name(contains(JMA.Name,'Ishigakijima')) = {'Ishigakijima'};
JMA.Name(contains(JMA.Name,'Amami')) = {'Amami'};
JMA.Name(contains(JMA.Name,'Tanegashima')) = {'Tanegashima'};
JMA.Name(contains(JMA.Name,'aburatsu')) = {'Aburatsu'};
JMA.Name(contains(JMA.Name,'Muroto')) = {'Muroto'};
JMA.Name(contains(JMA.Name,'Shirahama')) = {'Shirahama'};
JMA.Name(contains(JMA.Name,'Katsuurashi')) = {'Okitsu'};
JMA.Name(contains(JMA.Name,'Chichijima')) = {'Chichijima'};
JMA.Name(contains(JMA.Name,'Kujiko')) = {'Kuji'};
JMA.Name(contains(JMA.Name,'Numazu')) = {'Uchiura'};
JMA.Name(contains(JMA.Name,'Iwaki')) = {'Onahama'};


%% plot
fig = figure;
p = fig.Position;
fig.Position = [p(1)-0.6*p(3),p(2)-p(4),1.6*p(3),2.5*p(4)];
print(fig,'-dpng','tmp.png'); delete('tmp.png');

tile = tiledlayout(3,2);
for i = 1:npick
    ax(i) = nexttile;
    hold on

    t1 = T1.("Elapsed time"){ind_pickup(i)}./3600+time_offset(i,1);
    t2 = T2.("Elapsed time"){ind_pickup(i)}./3600+time_offset(i,2);
    e1 = T1.Eta{ind_pickup(i)}.*100;
    e2 = T2.Eta{ind_pickup(i)}.*100;

    e1(abs(e1)>150) = 0.0;
    e2(abs(e2)>150) = 0.0;

    %% line
    p0 = plot(JMA.Time{ind_pickup(i)}./3600, JMA.Eta_filtered{ind_pickup(i)},'k-','LineWidth',1.0);
    p1 = plot(t1, e1, '-','LineWidth',2.0,'Color',LC1);
    p2 = plot(t2, e2, '-','LineWidth',2.0,'Color',LC2);
    p1.Color(4) = 0.8;
    p2.Color(4) = 0.8;
    
    grid on
    box on

    set(gca,'XTick',xrange(1):xrange(2));
    % if YL(i)<30
    %     set(gca,'YTick',-30:10:30);
    % elseif YL(i)>75
    %     set(gca,'YTick',-120:40:120);
    % else
        set(gca,'YTick',-120:20:120);
    % end
    set(gca,'YLim',[-YL(i),+YL(i)]);
    set(gca,'FontName','Helvetica','FontSize',16)

    text(6.2, 0.80*YL(i), [sprintf('%2d. ',ind_pickup(i)),JMA.Name{ind_pickup(i)}],...
         'FontName','Helvetica','FontSize',20,...
         'HorizontalAlignment','left','VerticalAlignment','middle');
    hold off


end

%% legend
ax(npick+1) = nexttile; set(ax(npick+1),'Visible','off');
% legend(ax(npick+1),[p1,p2,p0],{simcase_label{1},simcase_label{2},'Obs.'},'FontName','Helvetica','FontSize',20,'Location','northwest');
legend(ax(npick+1),[p1,p2,p0],{simcase_label{1},simcase_label{2},'Observation'},'FontName','Helvetica','FontSize',20,'Location','northwest');

% legend(ax(1),[p1,p2,p0],{simcase_label{1},simcase_label{2},'Obs.'},'FontName','Helvetica','FontSize',20,'Location','southwest');

%% Ticks
ax(1).XAxis.TickLabels = '';
ax(2).XAxis.TickLabels = '';
ax(3).XAxis.TickLabels = '';

%% labels
% xlabel(ax([4,5]),'Elapsed time (hour)','FontName','Helvetica','FontSize',20);
xlabel(ax(5),'Elapsed time (hour)','FontName','Helvetica','FontSize',20);
ylabel(ax(1),'Surface elevation (cm)','FontName','Helvetica','FontSize',20);
linkaxes(ax,'x');
xlim(ax,xrange);

tile.TileSpacing = 'tight';
tile.Padding = 'compact';

%% print
% exportgraphics(fig,[simcase_prefix,'.pdf'],"ContentType","vector");
