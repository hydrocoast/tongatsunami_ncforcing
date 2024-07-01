using VisClaw
using Printf
using JLD2
using Plots

simdir = "../run_presA1min_regionA_fg"
#simdir = "../run_presA1min_regionB_fg"
#simdir = "../run_presA1min_regionC_fg"

outputdir = joinpath(simdir,"_output")
jld2dir = joinpath(simdir,"_jld2")


@load joinpath(jld2dir, "amr_storm.jld2") amr_storm timelap

k = 12

plt = VisClaw.plotsamr2d(amr_storm.amr[k]; AMRlevel=1:4, c=:bwr, clims=(1012, 1014), colorbar=true)
#plt = plot!(plt; xlims=(125,140), ylims=(15,30))
plt = plot!(plt; xlims=(125,140), ylims=(15,30), title=@sprintf("%d min", timelap[k]/60),
                 xguide="Longitude", yguide="Latitude", 
                 guidefont=Plots.font("Helvetica",12), 
                 tickfont=Plots.font("Helvetica",10),
                 )
plt = tilebound!(plt, amr_storm.amr[k]; AMRlevel=3, lc=:green)
plt = tilebound!(plt, amr_storm.amr[k]; AMRlevel=4, lc=:orange)
                


#=
outpng = "storm-"*@sprintf("%03d", k)*".png"

using GMT: GMT

## make cpt
cpt = GMT.makecpt(C=:polar, T="1012/1014", D=true, I=true)

## projection
proj = "X10d/10d"
region = "125/140/15/30"

Gp = tilegrd(amr_storm, k; length_unit="d")
GMT.psbasemap(J=proj, R=region, B="a5f5 neSW")
map(G -> GMT.grdimage!(G, J=proj, R=region, C=cpt), Gp)
GMT.colorbar!(B="xa1f0.5 y+lhPa", D="jMR+w8.0/0.3+o-1.5/0.0+e")
GMT.coast!(D=:i, W="thinnest")
GMT.text!([@sprintf("%d min", timelap[k]/60)], x=125.5, y=29, font=(14,:Helvetica,:black), justify=:ML,show=true)
=#