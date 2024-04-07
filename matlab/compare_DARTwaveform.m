clear
close all

%% sim data
% --------------------------------------
simdir1 = '../run_presA1min_3/_output';
simdir2 = '../run_jaguar/_output';
simcase_label = {'Parametric','JAGUAR'};
simcase_prefix = 'waveforms_PJ';
t_offset1 = 0.0;
t_offset2 = 0.34;
% --------------------------------------
cmap = lines(7);
LC1 = cmap(7,:);
LC2 = cmap(1,:);

list_gauge1 = dir(fullfile(simdir1,'gauge*.txt'));
ngauge = size(list_gauge1,1);
list_gauge2 = dir(fullfile(simdir2,'gauge*.txt'));
if ngauge ~= size(list_gauge2,1)
    error(['Number of gauges ',simdir1,' and ',simdir2,' is inconsistent.'])
end

%% obs data
% load('DART_records.mat');
load('DART_records_rev.mat');

%% directory for export figs
option_printfig = 0; % 1: on, others: off
figdir = '.';

%% read and compare
fig = figure;
p = fig.Position;
fig.Position = [p(1)-0.25*p(3),p(2)-0.5*p(4),1.25*p(3),1.5*p(4)];

print(fig,'-dpng','tmp.png'); delete('tmp.png');
g = cell(ngauge,2);

tile = tiledlayout(3,2);

tn = 0;

for i = 1:ngauge

    if ~strcmp(list_gauge1(i).name,list_gauge2(i).name)
        error(['Gauge number is inconsistent.', list_gauge1(i).name, ' and ', list_gauge2(i).name]);
    end

    file1 = fullfile(simdir1,list_gauge1(i).name);
    file2 = fullfile(simdir2,list_gauge1(i).name);

    %% read header
    fid = fopen(file1,'r');
    header = textscan(fid,'# gauge_id= %d location=( %f %f)',1);
    fclose(fid);
    gid = header{1};
    lon = header{2};
    lat = header{3};
    if gid < 999; continue; end
    tn = tn + 1;

    %% find the closest DART buoy
    [dist,ind_row] = min(sqrt((table_DART.Lat-lat).^2+(table_DART.Lon-lon).^2));

    %% read

    % --- simulation A
    dat1 = readmatrix(file1,"FileType","text","CommentStyle",'#');
    g{i,1} = [dat1(:,2),dat1(:,6),dat1(:,1)]; % time, eta, AMRlevel

    % --- simulation B
    dat2 = readmatrix(file2,"FileType","text","CommentStyle",'#');
    g{i,2} = [dat2(:,2),dat2(:,6),dat2(:,1)]; % time, eta, AMRlevel

    %% 近い観測点がない場合はスキップ
    if isempty(ind_row); continue; end
    
    %% plot
    ax(tn) = nexttile;
    xrange = [1.5,11.5];

    hold on
    p1 = plot(g{i,1}(:,1)./3600 + t_offset1, g{i,1}(:,2)*100,'-','LineWidth',2,'Color',LC1);
    p2 = plot(g{i,2}(:,1)./3600 + t_offset2, g{i,2}(:,2)*100,'-','LineWidth',2,'Color',LC2);
    grid on; box on
    p1.Color(4) = 0.8;
    p2.Color(4) = 0.8;

    hold on
    p3 = plot(cell2mat(table_DART.Time(ind_row))./3600, cell2mat(table_DART.Eta_filtered(ind_row)),'k-','LineWidth',1);
    xlim(xrange);
    text(xrange(1)+0.65,5.0,...
         sprintf('%05d',table_DART.DART(ind_row)),...
         'FontName','Helvetica','FontSize',20,...
         'HorizontalAlignment','left','VerticalAlignment','middle');
    hold off

    % legend([p1,p2,p3],{simcase_label{1},simcase_label{2},'Obs.'},'FontName','Helvetica','FontSize',14,'Location','southwest');
    set(gca,'FontName','Helvetica','FontSize',16)
    set(gca,'XTick',0:2:20);
    set(gca,'YTick',-6:2:6);
end

ax(1).XAxis.TickLabels = '';
ax(2).XAxis.TickLabels = '';
ax(3).XAxis.TickLabels = '';
ax(4).XAxis.TickLabels = '';


xlabel(ax(5),"Relative time (hour)",'FontName','Helvetica','FontSize',20);
% xlabel(ax(5:6),"Relative time (hour)",'FontName','Helvetica','FontSize',20);
ylabel(ax(3),"Surface elevation (cm)",'FontName','Helvetica','FontSize',20);
ax(2).YAxis.TickLabels = '';
ax(4).YAxis.TickLabels = '';
ax(6).YAxis.TickLabels = '';

legend(ax(5),[p1,p2,p3],{simcase_label{1},simcase_label{2},'Obs.'},'FontName','Helvetica','FontSize',20,'Location','southwest','Orientation','horizontal');

linkaxes(ax,'y');
ylim([-7,7]);

tile.TileSpacing = 'tight';
tile.Padding = 'compact';



%% print
if option_printfig == 1
    figfile = [simcase_prefix,'_DART.png'];
    % exportgraphics(gcf,fullfile(figdir,figfile),'Resolution',300,'ContentType','image');
    exportgraphics(gcf,strrep(fullfile(figdir,figfile),'.png','.pdf'),'ContentType','vector');
end



