using VisClaw
using Printf
using JLD2
using Plots

simdir1 = "../run_presA1min_regionA_fg"
simdir2 = "../run_presA1min_regionC_fg"

jld2dir1 = joinpath(simdir1,"_jld2")
jld2dir2 = joinpath(simdir2,"_jld2")

using GMT: GMT
## make cpt
cpt = GMT.makecpt(C=:polar, T="1012/1014", D=true, I=true)

## projection
proj = "X10d/10d"
region = "125/140/15/30"

jldopen(joinpath(jld2dir1, "amr_storm.jld2"), "r") do file
    global amr_storm1 = file["amr_storm"]
    global timelap = file["timelap"]
end


jldopen(joinpath(jld2dir2, "amr_storm.jld2"), "r") do file
    global amr_storm2 = file["amr_storm"]
end


outpng = "storm-"*@sprintf("%03d", k)*".png"


## make cpt
cpt = GMT.makecpt(C=:polar, T="1012/1014", D=true, I=true)

## projection
proj = "X10d/10d"
region = "125/140/15/30"

Gp = tilegrd(amr_storm1, k; length_unit="d")
GMT.psbasemap(J=proj, R=region, B="a5f5 neSW")
map(G -> GMT.grdimage!(G, J=proj, R=region, C=cpt), Gp)
GMT.coast!(D=:i, W="thinnest")
GMT.text!([@sprintf("%d min", timelap[k]/60)], x=125.5, y=29, font=(14,:Helvetica,:black), justify=:ML)

Gp = tilegrd(amr_storm2, k; length_unit="d")
GMT.psbasemap!(J=proj, R=region, B="a5f5 NEsw", X="10.3")
map(G -> GMT.grdimage!(G, J=proj, R=region, C=cpt), Gp)
GMT.colorbar!(B="xa1f0.5 y+lhPa", D="JMR+w8.0/0.3+o1.7/0.0+e")
GMT.coast!(D=:i, W="thinnest", savefig=outpng)
