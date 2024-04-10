#!/bin/bash

hostname="h100"
simdir=`basename $(pwd)`
rsync -av "miyashita@$hostname:Research/AMR/tongatsunami_ncforcing/$simdir/_output/gauge*.txt" _output/
rsync -av "miyashita@$hostname:Research/AMR/tongatsunami_ncforcing/$simdir/_plots" .
rsync -av "miyashita@$hostname:Research/AMR/tongatsunami_ncforcing/$simdir/_mat" .
rsync -av "miyashita@$hostname:Research/AMR/tongatsunami_ncforcing/$simdir/_grd/fg*_max.grd" _grd/
#rsync -av "miyashita@$hostname:Research/AMR/tongatsunami_ncforcing/$simdir/_grd/fgout0002_0*.grd" _grd/
