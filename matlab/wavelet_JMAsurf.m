clear
close all


%% filenames
matfile_obs = 'JMA_records_limited.mat';
load(matfile_obs);
nstation = size(JMA,1);
JMA.Name(contains(JMA.Name,'Amami')) = {'Amami'};
JMA.Name(contains(JMA.Name,'Tanegashima')) = {'Tanegashima'};
JMA.Name(contains(JMA.Name,'Muroto')) = {'Muroto'};
JMA.Name(contains(JMA.Name,'Shirahama')) = {'Shirahama'};
JMA.Name(contains(JMA.Name,'Katsuurashi')) = {'Okitsu'};
JMA.Name(contains(JMA.Name,'Chichijima')) = {'Chichijima'};
JMA.Name(contains(JMA.Name,'Kujiko')) = {'Kuji'};
JMA.Name(contains(JMA.Name,'Numazu')) = {'Uchiura'};
JMA.Name(contains(JMA.Name,'Iwaki')) = {'Onahama'};


%% parameters
fs = 1/15; % Hz
dt = 1/fs; % s

%% wavelet analysis for each station
fig = figure; print(fig,'-dpng','tmp.png'); delete('tmp.png');

% for i = 1:nstation
for i = [3,8,9,30]
% for i = 3

    label_station = JMA.Name{i};

    %% 時系列データを等間隔に内挿
    t_obs = JMA.Time{i};
    if isempty(t_obs); disp(['skip: ',label_station]); continue; end

    t_uniform = t_obs(1):dt:t_obs(end);
    surf_obs = JMA.Eta_filtered{i};
    surf_interp = interp1(t_obs,surf_obs,t_uniform(:),"spline");
        
    %% wavelet analysis
    [wt,f] = cwt(surf_interp,'morse',fs);
    perT = 1./f;

    %% plot
    range_t = [6,16];

    figure(fig); clf(fig);
    tile = tiledlayout(3,1);

    %% time-series
    axt = nexttile;
    plot(t_uniform./3600, surf_interp, 'k-','LineWidth',2); hold on
    grid on
    set(axt,'FontName','Helvetica','FontSize',14);
    ylabel(axt,'Elevation (cm)','FontName','Helvetica','FontSize',16);
    axt.XAxis.TickLabels = [];
    set(axt,'XTick',range_t(1):range_t(end));
    
    %% scalogram
    axw = nexttile([2,1]);
    pcolor(t_uniform./3600,perT./60,20*log10(abs(wt))); shading flat
    ylim(axw,[5,100]);
    ylabel(axw,'Period (min)','FontName','Helvetica','FontSize',16);
    axw.YAxis.TickValues = [5,10,20,50,100];
    yline([10,100],'-','Color',[.8,.8,.8],'LineWidth',2);
    yline([2:1:9,20:10:90,200],'--','Color',[.8,.8,.8],'Alpha',0.5,'LineWidth',2);

    clim(axw,[0,30]);
    set(axw,'YScale','log','YDir','reverse','FontName','Helvetica','FontSize',16);

    cb = colorbar(axw,'west','FontName','Helvetica','FontSize',16);
    cb.Label.String = 'Power (dB)';
    cb.Label.Color = 'w';
    cb.Color = 'w';
    set(axw,'XTick',range_t(1):range_t(end));

    xlabel(axw,'Elapsed time (hour)','FontName','Helvetica','FontSize',18);
    linkaxes([axt,axw],'x');
    xlim(axt,range_t);

    tile.TileSpacing = 'tight';
    tile.Padding = 'tight';

    text(axt, 6.5, axt.YLim(1)+0.80*(diff(axt.YLim)), [sprintf('%2d. ',i),JMA.Name{i}],...
         'FontName','Helvetica','FontSize',20,...
         'HorizontalAlignment','left','VerticalAlignment','middle');
    

    %% print
    filename_png = ['wavelet_JMAsurf_',label_station,'.png'];
    filename_pdf = strrep(filename_png,'.png','.pdf');
    % exportgraphics(gcf,fullfile(figdir,filename_png),'ContentType','image','Resolution',300);
    exportgraphics(gcf,filename_pdf,'ContentType','vector');

end

