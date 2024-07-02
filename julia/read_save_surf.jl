using VisClaw
using Printf
using JLD2
using Plots

#simdir = "../run_presA1min_regionA_fg"
simdir = "../run_jaguar"

outputdir = joinpath(simdir,"_output")
jld2dir = joinpath(simdir,"_jld2")

ind_time = 11:35

flist = filter(x->occursin("fort.t0",x), readdir(outputdir))
timelap = VisClaw.loadfortt.(joinpath.(outputdir,flist[ind_time]))

print("reading sea surface level ...     ")
amr_surf = loadsurface(outputdir, ind_time; AMRlevel=1:4, xlims=(120,135), ylims=(10,35))
print("end\n")

print("saving sea surface level ...     ")
isdir(jld2dir) || (mkdir(jld2dir))
@save joinpath(jld2dir, "amr_surf.jld2") amr_surf timelap
print("end\n")
