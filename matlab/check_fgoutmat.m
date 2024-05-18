clear
close all

matname = '../run_presA1min_3/_mat/fgout03.mat';
load(matname);


bwr = createcolormap(20,[0,0,1;1,1,1;1,0,0]);

nt = length(t_elapsed);

fig = figure;
iflag=1;
while iflag==1
    k = input(sprintf('input step (max: %d) = ',nt));
    if isempty(k); break; end
    if ~isnumeric(k); break; end
    k = round(k);
    if k<1; break; end
    if k>nt; break; end

    clf(fig);
    pcolor(x,y,reshape(eta_sp(:,k),[nx,ny])'); shading flat
    axis equal tight

    colormap(bwr);
    clim([-0.1,0.1]);
    colorbar;

    title(sprintf('%03d min',round(t_elapsed(k)/60)),'FontName','Helvetica','FontSize',16);
end

