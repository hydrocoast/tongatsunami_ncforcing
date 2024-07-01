using VisClaw
using Printf
using JLD2
using Plots

#simdir = "../run_presA1min_regionA_fg"
#simdir = "../run_presA1min_regionB_fg"
simdir = "../run_presA1min_regionC_fg"

outputdir = joinpath(simdir,"_output")
jld2dir = joinpath(simdir,"_jld2")

ind_time = 11:35

flist = filter(x->occursin("fort.t0",x), readdir(outputdir))
timelap = VisClaw.loadfortt.(joinpath.(outputdir,flist[ind_time]))

print("reading storm ...     ")
amr_storm = loadstorm(outputdir, ind_time; AMRlevel=1:4, xlims=(125,140), ylims=(15,30))
print("end\n")

print("saving storm ...     ")
isdir(jld2dir) || (mkdir(jld2dir))
@save joinpath(jld2dir, "amr_storm.jld2") amr_storm timelap
print("end\n")

## plot
plts = plotsamr(amr_storm; AMRlevel=1:4, c=:bwr, clims=(1012, 1014))
plts = tilebound!.(plts, amr_storm.amr; AMRlevel=3, lc=:green)
plts = tilebound!.(plts, amr_storm.amr; AMRlevel=4, lc=:orange)
plts = plot!.(plts; xlims=(125,140), ylims=(15,30), 
                    xguide="Longitude", yguide="Latitude", 
                    guidefont=Plots.font("Helvetica",12), 
                    tickfont=Plots.font("Helvetica",10))
for i in eachindex(timelap)
    plts[i] = plot!(plts[i]; title=@sprintf("%d min", timelap[i]/60))
end


## savefig
figdir =  joinpath(simdir,"_plots")
isdir(figdir) || (mkdir(figdir))
for i in eachindex(timelap)
    savefig(plts[i],joinpath(figdir,@sprintf("airpressure_%03d.png",i)))
end

## save as jld2
jldopen(joinpath(jld2dir, "amr_storm.jld2"), "a+") do file
    file["plts"] = plts
end
