#!/bin/bash

fnameout='storm_list.data'
dir_current=`pwd`
dir_nc="nc_dNami"
dt_file=60.0


echo '# ========================================================= # ' > $fnameout
echo '# LIST OF STORM DATA FILES                                  # ' >> $fnameout
echo '# Atmospheric data in NetCDF format                         # ' >> $fnameout
echo '# ========================================================= # ' >> $fnameout
echo ' ' >> $fnameout
echo "$dt_file           =: dt_file" >> $fnameout
echo $(ls -1 ../${dir_nc}/*.nc | wc -l) >> $fnameout
ls -1 ../${dir_nc}/*.nc | awk -v cdir=`pwd` '{printf "%s/%s\n", cdir, $1}' >> $fnameout
echo "$fnameout has been made"

