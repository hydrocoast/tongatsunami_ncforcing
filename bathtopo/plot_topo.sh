#!/bin/bash

topofile="gebco_2022_n60.0_s-60.0_w110.0_e240.0_filter.nc"

gmt begin ${topofile//.nc/} png
    gmt makecpt -Cglobe
    gmt grdimage -JM10 -R$topofile -C -Baf $topofile
    gmt coast -Di -Wthinnest

    gmt grdimage -JX10d -R120/140/15/35 -C -Baf -BnEwS $topofile -X10.5
    gmt coast -Di -Wthinnest

gmt end

