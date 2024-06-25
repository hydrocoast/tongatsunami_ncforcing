using VisClaw
using Printf
using JLD2
using Plots

simdir = "../run_presA1min_regionA_fg"
#simdir = "../run_presA1min_regionB_fg"
#simdir = "../run_presA1min_regionC_fg"

outputdir = joinpath(simdir,"_output")
jld2dir = joinpath(simdir,"_jld2")

print("reading storm ...     ")
amr_storm = loadstorm(outputdir, 11:35; AMRlevel=1:4, xlims=(125,140), ylims=(15,30))
print("end\n")

print("saving storm ...     ")
isdir(jld2dir) || (mkdir(jld2dir))
@save joinpath(jld2dir, "amr_storm.jld2") amr_storm
print("end\n")


plts = plotsamr(amr_storm; AMRlevel=1:4, c=:bwr, clims=(1012, 1014),
                    xguide="Longitude", yguide="Latitude", 
                    guidefont=Plots.font("Helvetica",12),
                    tickfont=Plots.font("Helvetica",10),
                    xlims=(125,140), ylims=(15,30)
                )
plts = tilebound!.(plts, amr_storm.amr; AMRlevel=3, lc=:green)
plts = tilebound!.(plts, amr_storm.amr; AMRlevel=4, lc=:orange)


