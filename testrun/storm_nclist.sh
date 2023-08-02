#!/bin/bash

fnameout='storm_list.data'

echo '# ========================================================= # ' > $fnameout
echo '# LIST OF STORM DATA FILES                                  # ' >> $fnameout
echo '# Atmospheric data in NetCDF format                         # ' >> $fnameout
echo '# ========================================================= # ' >> $fnameout
echo ' ' >> $fnameout
echo $(ls -1 ../jaguar/*.nc | wc -l) >> $fnameout
ls -1 ../jaguar/*.nc >> $fnameout
echo "$fnameout has been made"

