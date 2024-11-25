#!/bin/bash

hostname="h100"
simdir=`basename $(pwd)`
rsync -av "miyashita@$hostname:Research/AMR/tongatsunami_ncforcing/$simdir/_jld2/amr_surf.jld2" _jld2/
