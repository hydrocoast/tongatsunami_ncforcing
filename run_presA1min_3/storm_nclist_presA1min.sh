#!/bin/bash

fnameout='storm_list.data'
dir_current=`pwd`

echo '# ========================================================= # ' > $fnameout
echo '# LIST OF STORM DATA FILES                                  # ' >> $fnameout
echo '# Atmospheric data in NetCDF format                         # ' >> $fnameout
echo '# ========================================================= # ' >> $fnameout
echo ' ' >> $fnameout
echo 60.0 >> $fnameout
echo $(ls -1 ../nc_presA/*.nc | wc -l) >> $fnameout
ls -1 ../nc_presA/*.nc | awk -v cdir=`pwd` '{printf "%s/%s\n", cdir, $1}' >> $fnameout
echo "$fnameout has been made"

