#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "usage: $0 [filename]"
    exit 1
fi

#topofile="gebco_2022_n60.0_s-60.0_w110.0_e240.0_filter.nc"
topofile="$1"

gmt begin ${topofile//.nc/} png
    gmt makecpt -Cglobe
    gmt grdimage -JM10 -R$topofile -C -Baf $topofile -V
    gmt coast -Di -Wthinnest

    gmt grdimage -JX10d -R120/140/15/35 -C -Baf -BnEwS $topofile -X10.5 -V
    gmt coast -Di -Wthinnest

gmt end

