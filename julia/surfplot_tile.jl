using VisClaw
using Printf
using JLD2
using Plots
#pyplot()
gr()

simdir1 = "../run_presA1min_regionA_fg"
simdir2 = "../run_jaguar"

jld2dir1 = joinpath(simdir1,"_jld2")
jld2dir2 = joinpath(simdir2,"_jld2")


jldopen(joinpath(jld2dir1, "amr_surf.jld2"), "r") do file
    global amr_surf1 = file["amr_surf"]
    global timelap = file["timelap"]
end


jldopen(joinpath(jld2dir2, "amr_surf.jld2"), "r") do file
    global amr_surf2 = file["amr_surf"]
end


glon = [124.1390,127.6560,129.5370,130.9644,131.4060]
glat = [ 24.3229, 26.2229, 28.3229, 30.4636, 31.5757]

k = 12

#=
plt1 = VisClaw.plotsamr2d(amr_surf1.amr[k]; AMRlevel=1:4, c=:bwr, clims=(-0.05, 0.05), colorbar=true, xlims=(120,140), ylims=(15,35))
plt1 = plot!(plt1; guidefont=Plots.font("Helvetica",12), tickfont=Plots.font("Helvetica",10))
plt1 = plot!(plt1; annotations=(122,34,Plots.text("Synthetic","Helvetica",12,:left,:top)))
plt1 = plot!(plt1; annotations=(122,33,Plots.text(@sprintf("%d min", timelap[k]/60),"Helvetica",12,:left,:top)))
=#

#=
plt2 = VisClaw.plotsamr2d(amr_surf2.amr[k]; annotations=(122,33,Plots.text(@sprintf("%d min", timelap[k]/60),"Helvetica",12,:left,:top)), c=:bwr, clims=(-0.05, 0.05), colorbar=true, xlims=(120,140), ylims=(15,35))
plt2 = plot!(plt2; annotations=(122,34,Plots.text("JAGUAR","Helvetica",12,:left,:top)))
plt2 = plot!(plt2; guidefont=Plots.font("Helvetica",12), tickfont=Plots.font("Helvetica",10), colorbar=:false)
plt2 = scatter!(plt2, [132.1447], [20.6267], m=:square, markercolor=:yellow, ms=4, legend=false)
plt2 = scatter!(plt2, glon, glat, m=:circle, markercolor=:lightgreen, ms=4, legend=false)
=#

function add_gaugepos!(plt, txt)
    #plt = plot!(plt; guidefont=Plots.font("Helvetica",12), tickfont=Plots.font("Helvetica",10), colorbar=:false)
    #plt = plot!(plt; guide="", ticks=[], colorbar=:false)
    plt = plot!(plt; colorbar=:false)
    plt = plot!(plt; annotations=(122,34,Plots.text(txt,"Helvetica",12,:left,:top)))
    plt = scatter!(plt, [132.1447], [20.6267], m=:square, markercolor=:yellow, ms=4, legend=false)
    plt = scatter!(plt, glon, glat, m=:circle, markercolor=:lightgreen, ms=4, legend=false)
    return plt
end

plt11 = VisClaw.plotsamr2d(amr_surf1.amr[10]; annotations=(122,33,Plots.text(@sprintf("%d min", timelap[10]/60),"Helvetica",12,:left,:top)), c=:bwr, clims=(-0.05, 0.05), colorbar=true, xlims=(120,140), ylims=(15,35))
plt12 = VisClaw.plotsamr2d(amr_surf1.amr[12]; annotations=(122,33,Plots.text(@sprintf("%d min", timelap[12]/60),"Helvetica",12,:left,:top)), c=:bwr, clims=(-0.05, 0.05), colorbar=true, xlims=(120,140), ylims=(15,35))
plt13 = VisClaw.plotsamr2d(amr_surf1.amr[14]; annotations=(122,33,Plots.text(@sprintf("%d min", timelap[14]/60),"Helvetica",12,:left,:top)), c=:bwr, clims=(-0.05, 0.05), colorbar=true, xlims=(120,140), ylims=(15,35))
plt11 = add_gaugepos!(plt11,"Synthetic")
plt12 = add_gaugepos!(plt12,"Synthetic")
plt13 = add_gaugepos!(plt13,"Synthetic")

plt21 = VisClaw.plotsamr2d(amr_surf2.amr[3]; annotations=(122,33,Plots.text(@sprintf("%d min", timelap[3]/60),"Helvetica",12,:left,:top)), c=:bwr, clims=(-0.05, 0.05), colorbar=true, xlims=(120,140), ylims=(15,35))
plt22 = VisClaw.plotsamr2d(amr_surf2.amr[5]; annotations=(122,33,Plots.text(@sprintf("%d min", timelap[5]/60),"Helvetica",12,:left,:top)), c=:bwr, clims=(-0.05, 0.05), colorbar=true, xlims=(120,140), ylims=(15,35))
plt23 = VisClaw.plotsamr2d(amr_surf2.amr[7]; annotations=(122,33,Plots.text(@sprintf("%d min", timelap[7]/60),"Helvetica",12,:left,:top)), c=:bwr, clims=(-0.05, 0.05), colorbar=true, xlims=(120,140), ylims=(15,35))
plt21 = add_gaugepos!(plt21,"JAGUAR")
plt22 = add_gaugepos!(plt22,"JAGUAR")
plt23 = add_gaugepos!(plt23,"JAGUAR")


blank = plot(foreground_color_subplot=:white)

l = @layout [grid(2, 3) a{0.1w}]
p = plot(plt11, plt12, plt13, plt21, plt22, plt23, blank, layout=l, link=:all, size=(1200,1200))
p = scatter!(p, [NaN], [NaN], zcolor=[NaN], clims=clims=(-5,5), label="", m=:none, c=:bwr, colorbar_title=Plots.text("cm","Helvetica",10, rotation=90), background_color_subplot=:transparent, markerstrokecolor=:transparent, framestyle=:none, inset=bbox(0.1, 0.0, 0.05, 0.8, :center, :right), subplot=8)

#=
l = @layout [grid(1, 3) a{0.1w}]
p2 = plot(plt21, plt22, plt23, blank, layout=l, link=:all)
p_all = scatter!(p2, [NaN], [NaN], zcolor=[NaN], clims=clims=(-5,5), label="", m=:none, c=:bwr, colorbar_title=Plots.text("cm","Helvetica",10, rotation=90), background_color_subplot=:transparent, markerstrokecolor=:transparent, framestyle=:none, inset=bbox(0.1, 0.0, 0.05, 0.8, :center, :right), subplot=5)
=#



#=
k = 6

outpng = "surf_"*@sprintf("%03d", k)*".png"

using GMT: GMT
## make cpt
cpt = GMT.makecpt(C=:polar, T="-0.05/0.05", D=true)

## projection
proj = "X9d/12d"
region = "120/135/12/32"


Gp = tilegrd(amr_surf1, k; length_unit="d")
GMT.psbasemap(J=proj, R=region, B="a5f5 neSW")
for i in eachindex(Gp)
    @printf("%d\n",i)
    GMT.grdimage!(Gp[i], J=proj, R=region, C=cpt)
end
#map(G -> GMT.grdimage!(G, J=proj, R=region, C=cpt), Gp)
GMT.coast!(D=:i, W="thinnest")
GMT.text!([@sprintf("%d min", timelap[k]/60)], x=125.5, y=29, font=(14,:Helvetica,:black), justify=:ML)

Gp = tilegrd(amr_surf2, k; length_unit="d")
GMT.psbasemap!(J=proj, R=region, B="a5f5 NEsw", X="9.3")
map(G -> GMT.grdimage!(G, J=proj, R=region, C=cpt), Gp)
GMT.colorbar!(B="xa1f0.5 y+lhPa", D="JMR+w8.0/0.3+o1.7/0.0+e")
GMT.coast!(D=:i, W="thinnest", savefig=outpng)
=#