#!/bin/bash

if [ $# -lt 1 ]; then
   echo "Invalid number of argument."
   echo "usage: $0 [filename.grd]" 
   exit 0
fi

grdfile=$1
if [ ! -e "$grdfile" ]; then
   echo "Not found: $grdfile"
   exit 2
fi
if [ ! -d "_plots" ]; then mkdir "_plots"; fi

output=`basename $grdfile`
output=${output//.grd/}

## parameters
proj="X"$(gmt grdinfo $grdfile -Cn -o0,1,2,3  | awk '{print 10"/"10*($4-$3)/($2-$1)}')
lat0=$(gmt grdinfo $grdfile -Cn -o2)
maxdep=$(gmt grdinfo $grdfile -Cn -o4)

## plot
gmt begin $output png
    gmt makecpt -Cpolar -T-5/5/0.5 -D

    gmt grdimage $grdfile -J$proj -R$grdfile -C
    gmt coast -Wthinnest,gray50 -Dh -Glightgray -Baf
    gmt colorbar -C -Bxa2 -By+lcm -DjTR+w2.5/0.3+o0.8/0.7+e
gmt end

mv "$output.png" "_plots/"
