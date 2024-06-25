#!/bin/bash

hostname="h100"
simdir=`basename $(pwd)`
rsync -av "miyashita@$hostname:Research/AMR/tongatsunami_ncforcing/$simdir/_output/*.data" _output/
rsync -av "miyashita@$hostname:Research/AMR/tongatsunami_ncforcing/$simdir/_output/fort.t0*" _output/
rsync -av "miyashita@$hostname:Research/AMR/tongatsunami_ncforcing/$simdir/_output/fort.a0*" _output/
