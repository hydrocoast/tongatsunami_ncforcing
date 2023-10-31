#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Invalid number of argument."
    echo "usage: $0 [ncfile]"
    exit 0
fi

#grd="ncfile/groundPressure_00055831.nc"
grd="$1"
grd_base=`basename $grd`

proj="A165/-5/12"
region="g"
#gmt begin ${grd_base//.nc/} pdf
gmt begin ${grd_base//.nc/} png
    ## set cpt
    gmt makecpt -Cpolar -T-1/1 -D

    ## plot
    gmt grdimage $grd -J$proj -R$region -C
    gmt coast -Wthinnest,gray30 -Dl -Bf
gmt end


