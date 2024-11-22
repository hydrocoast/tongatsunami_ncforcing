#!/bin/bash

grdfile="gebco_2022_cut.nc"
grdout="gebco_2022_filtered.nc"

length_param=100

gmt grdcut -R115/140/15/35 -G$grdfile=nf -fog gebco_2022_n60.0_s-60.0_w110.0_e240.0.nc

gmt grdfilter $grdfile -D4 -Fg$length_param -G$grdout -V




