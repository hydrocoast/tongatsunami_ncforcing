#!/bin/bash

g=zratio.grd

gmt begin zratio png
    gmt makecpt -Cpolar -T-80/80/8 -D
    gmt grdimage $g -C -JX7/5 -R126/140/20/30
    gmt grdimage zratio3.grd -C
    gmt coast -Baf -Wthinnest -Ggray -Df
    #gmt colorbar -C
gmt end
