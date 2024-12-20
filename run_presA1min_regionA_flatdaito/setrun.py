# encoding: utf-8
"""
Module to set up run time parameters for Clawpack.

The values set in the function setrun are then written out to data files
that will be read in by the Fortran code.

"""

from __future__ import absolute_import
from __future__ import print_function

import os
import glob
import datetime
import shutil
import gzip

import numpy as np
import clawpack
from clawpack.geoclaw.surge.storm import Storm
import clawpack.clawutil as clawutil
from clawpack.geoclaw import fgmax_tools
from clawpack.geoclaw.data import ForceDry
from clawpack.geoclaw import topotools
from clawpack.geoclaw import fgout_tools

# Time Conversions
def days2seconds(days):
    return days * 60.0**2 * 24.0

# Scratch directory for storing topo and dtopo files:
topodir = os.path.join(os.getcwd(), '..', 'bathtopo')

# topolist
topoflist = {
             "GEBCO2022"      :"gebco_2022_n60.0_s-60.0_w110.0_e240.0.nc",
             "GEBCO2022f"     :"gebco_2022_flat_daitoridges_all.nc",
             "Amami"          :"zone01_depth_0090-03_lonlat.asc",
             "Tanegashima"    :"zone02_depth_0090-06_lonlat.asc",
             "Aburatsu"       :"zone02_depth_0090-07_lonlat.asc",
             "BungoChannel"   :"zone02_depth_0090-10_lonlat.asc",
             "Tosashimizu"    :"zone04_depth_0090-02_lonlat.asc",
             "Muroto"         :"zone04_depth_0090-04_lonlat.asc",
             "KiiChannel"     :"zone04_depth_0090-05_lonlat.asc",
             "OsakaBay"       :"zone06_depth_0090-01_mask_lonlat.asc",
             "KiiPeninsula"   :"zone06_depth_0090-03_lonlat.asc",
             "KumanoOwase"    :"zone06_depth_0090-04_lonlat.asc",
             "IseBay"         :"zone06_depth_0090-06_mask_lonlat.asc",
             "MaisakaOmaezaki":"zone08_depth_0090-01_lonlat.asc",
             "ShimizuUchiura" :"zone08_depth_0090-02_lonlat.asc",
             "TokyoBay"       :"zone09_depth_0090-06_mask_lonlat.asc",
             "Mera"           :"zone09_depth_0090-07_lonlat.asc",
             "Oarai"          :"zone09_depth_0090-10_lonlat.asc",
             "Onahama"        :"zone09_depth_0090-11_lonlat.asc",
             "Chichijima"     :"M7023.asc",
             "Ishigaki"       :"M7021.asc",
             "Naha"           :"M7020.asc",
             "Ofunato"        :"M7005a.asc",
             "Kuji"           :"M7005b.asc",
             "Hakodate"       :"M7006.asc",
             "Kushiro"        :"M7007a.asc",
             "Nemuro"         :"M7007b.asc",
            }

# ------------------------------
def setrun(claw_pkg='geoclaw'):
#------------------------------

    """
    Define the parameters used for running Clawpack.

    INPUT:
        claw_pkg expected to be "geoclaw" for this setrun.

    OUTPUT:
        rundata - object of class ClawRunData

    """

    from clawpack.clawutil import data

    assert claw_pkg.lower() == 'geoclaw',  "Expected claw_pkg = 'geoclaw'"

    num_dim = 2
    rundata = data.ClawRunData(claw_pkg, num_dim)

    #------------------------------------------------------------------
    # Problem-specific parameters to be written to setprob.data:
    #------------------------------------------------------------------
    
    #probdata = rundata.new_UserData(name='probdata',fname='setprob.data')

    #------------------------------------------------------------------
    # Standard Clawpack parameters to be written to claw.data:
    #   (or to amr2ez.data for AMR)
    #------------------------------------------------------------------
    clawdata = rundata.clawdata  # initialized when rundata instantiated


    # Set single grid parameters first.
    # See below for AMR parameters.


    # ---------------
    # Spatial domain:
    # ---------------

    # Number of space dimensions:
    clawdata.num_dim = num_dim

    # Lower and upper edge of computational domain:
    clawdata.lower[0] = 115.0    # west longitude
    clawdata.upper[0] = 200.0   # east longitude
    clawdata.lower[1] = -50.0    # south latitude
    clawdata.upper[1] = 50.0   # north latitude

    # Number of grid cells
    degree_factor = 5
    clawdata.num_cells[0] = int(clawdata.upper[0] - clawdata.lower[0]) \
        * degree_factor
    clawdata.num_cells[1] = int(clawdata.upper[1] - clawdata.lower[1]) \
        * degree_factor

    # ---------------
    # Size of system:
    # ---------------

    # Number of equations in the system:
    clawdata.num_eqn = 3

    # Number of auxiliary variables in the aux array (initialized in setaux)
    # First three are from shallow GeoClaw, fourth is friction and last 3 are
    # storm fields
    clawdata.num_aux = 3 + 1 + 3

    # Index of aux array corresponding to capacity function, if there is one:
    clawdata.capa_index = 2 # 0 for cartesian x-y, 2 for spherical lat-lon
    
    
    # -------------
    # Initial time:
    # -------------
    clawdata.t0 = 0.0

    # Restart from checkpoint file of a previous run?
    # If restarting, t0 above should be from original run, and the
    # restart_file 'fort.chkNNNNN' specified below should be in 
    # the OUTDIR indicated in Makefile.

    clawdata.restart = False               # True to restart from prior results
    clawdata.restart_file = 'fort.chk00006'  # File to use for restart data

    # -------------
    # Output times:
    #--------------

    # Specify at what times the results should be written to fort.q files.
    # Note that the time integration stops after the final output time.
    # The solution at initial time t0 is always written in addition.

    clawdata.output_style = 2
    clawdata.tfinal = 3600.0*16.0

    if clawdata.output_style==1:
        # Output nout frames at equally spaced times up to tfinal:
        clawdata.num_output_times = 121
        clawdata.output_t0 = True  # output at initial (or restart) time?

    elif clawdata.output_style == 2:
        # Specify a list of output times.
        #clawdata.output_times = [i*1800.0 for i in range(0,33)] # every 30 min, 0 to 16 h
        clawdata.output_times = [0.0]
        clawdata.output_times.extend([i*600.0+6.0*3600.0 for i in range(0,43)]) # every 5 min, 6 to 13 h
        clawdata.output_times.append(clawdata.tfinal)

    elif clawdata.output_style == 3:
        # Output every iout timesteps with a total of ntot time steps:
        clawdata.output_step_interval = 1
        clawdata.total_steps = 100
        clawdata.output_t0 = True
        

    clawdata.output_format = 'ascii'      # 'ascii' or 'netcdf' 
    clawdata.output_q_components = 'all'   # could be list such as [True,True]
    clawdata.output_aux_components = 'all'
    clawdata.output_aux_onlyonce = False    # output aux arrays only at t0

    # ---------------------------------------------------
    # Verbosity of messages to screen during integration:
    # ---------------------------------------------------

    # The current t, dt, and cfl will be printed every time step
    # at AMR levels <= verbosity.  Set verbosity = 0 for no printing.
    #   (E.g. verbosity == 2 means print only on levels 1 and 2.)
    clawdata.verbosity = 1

    # --------------
    # Time stepping:
    # --------------

    # if dt_variable==1: variable time steps used based on cfl_desired,
    # if dt_variable==0: fixed time steps dt = dt_initial will always be used.
    clawdata.dt_variable = True

    # Initial time step for variable dt.
    # If dt_variable==0 then dt=dt_initial for all steps:
    clawdata.dt_initial = 1.0

    # Max time step to be allowed if variable dt used:
    clawdata.dt_max = 1e+99

    # Desired Courant number if variable dt used, and max to allow without
    # retaking step with a smaller dt:
    clawdata.cfl_desired = 0.50
    clawdata.cfl_max = 0.80

    # Maximum number of time steps to allow between output times:
    clawdata.steps_max = 500000

    # ------------------
    # Method to be used:
    # ------------------

    # Order of accuracy:  1 => Godunov,  2 => Lax-Wendroff plus limiters
    clawdata.order = 1
    
    # Use dimensional splitting? (not yet available for AMR)
    clawdata.dimensional_split = 'unsplit'
    
    # For unsplit method, transverse_waves can be 
    #  0 or 'none'      ==> donor cell (only normal solver used)
    #  1 or 'increment' ==> corner transport of waves
    #  2 or 'all'       ==> corner transport of 2nd order corrections too
    clawdata.transverse_waves = 1

    # Number of waves in the Riemann solution:
    clawdata.num_waves = 3
    
    # List of limiters to use for each wave family:  
    # Required:  len(limiter) == num_waves
    # Some options:
    #   0 or 'none'     ==> no limiter (Lax-Wendroff)
    #   1 or 'minmod'   ==> minmod
    #   2 or 'superbee' ==> superbee
    #   3 or 'mc'       ==> MC limiter
    #   4 or 'vanleer'  ==> van Leer
    clawdata.limiter = ['mc', 'mc', 'mc']

    clawdata.use_fwaves = True    # True ==> use f-wave version of algorithms
    
    # Source terms splitting:
    #   src_split == 0 or 'none'    ==> no source term (src routine never called)
    #   src_split == 1 or 'godunov' ==> Godunov (1st order) splitting used, 
    #   src_split == 2 or 'strang'  ==> Strang (2nd order) splitting used,  not recommended.
    clawdata.source_split = 'godunov'

    # --------------------
    # Boundary conditions:
    # --------------------

    # Number of ghost cells (usually 2)
    clawdata.num_ghost = 2

    # Choice of BCs at xlower and xupper:
    #   0 => user specified (must modify bcN.f to use this option)
    #   1 => extrapolation (non-reflecting outflow)
    #   2 => periodic (must specify this at both boundaries)
    #   3 => solid wall for systems where q(2) is normal velocity

    clawdata.bc_lower[0] = 'extrap' # west
    clawdata.bc_upper[0] = 'extrap' # east 

    clawdata.bc_lower[1] = 'extrap' # south
    clawdata.bc_upper[1] = 'extrap' # north

    # Specify when checkpoint files should be created that can be
    # used to restart a computation.

    clawdata.checkpt_style = 0

    if clawdata.checkpt_style == 0:
        # Do not checkpoint at all
        pass

    elif np.abs(clawdata.checkpt_style) == 1:
        # Checkpoint only at tfinal.
        pass

    elif np.abs(clawdata.checkpt_style) == 2:
        # Specify a list of checkpoint times.
        clawdata.checkpt_times = [0.1, 0.15]

    elif np.abs(clawdata.checkpt_style) == 3:
        # Checkpoint every checkpt_interval timesteps (on Level 1)
        # and at the final time.
        clawdata.checkpt_interval = 5


    # ---------------
    # AMR parameters:
    # ---------------
    amrdata = rundata.amrdata

    # max number of refinement levels:
    amrdata.amr_levels_max = 5

    # List of refinement ratios at each level (length at least mxnest-1)
    amrdata.refinement_ratios_x = [3,4,4,3]
    amrdata.refinement_ratios_y = [3,4,4,3]
    amrdata.refinement_ratios_t = [3,4,4,3]

    # Specify type of each aux variable in amrdata.auxtype.
    # This must be a list of length maux, each element of which is one of:
    #   'center',  'capacity', 'xleft', or 'yleft'  (see documentation).

    amrdata.aux_type = ['center','capacity','yleft','center','center','center','center', 'center', 'center'] # For lon-lat
    # amrdata.aux_type = ['center','center','yleft','center','center','center','center', 'center', 'center']  # For X-Y


    # Flag using refinement routine flag2refine rather than richardson error
    amrdata.flag_richardson = False    # use Richardson?
    amrdata.flag2refine = True

    # steps to take on each level L between regriddings of level L+1:
    amrdata.regrid_interval = 3

    # width of buffer zone around flagged points:
    # (typically the same as regrid_interval so waves don't escape):
    amrdata.regrid_buffer_width  = 3

    # clustering alg. cutoff for (# flagged pts) / (total # of cells refined)
    # (closer to 1.0 => more small grids may be needed to cover flagged cells)
    amrdata.clustering_cutoff = 0.700000

    # print info about each regridding up to this level:
    amrdata.verbosity_regrid = 0  


    #  ----- For developers ----- 
    # Toggle debugging print statements:
    amrdata.dprint = False      # print domain flags
    amrdata.eprint = False      # print err est flags
    amrdata.edebug = False      # even more err est flags
    amrdata.gprint = False      # grid bisection/clustering
    amrdata.nprint = False       # proper nesting output
    amrdata.pprint = False      # proj. of tagged points
    amrdata.rprint = False      # print regridding summary
    amrdata.sprint = False      # space/memory output
    amrdata.tprint = True       # time step reporting each level
    amrdata.uprint = False      # update/upbnd reporting
    
    # More AMR parameters can be set -- see the defaults in pyclaw/data.py

    # == setregions.data values ==
    #rundata.regiondata.regions = []
    regions = rundata.regiondata.regions
    # to specify regions of refinement append lines of the form
    #  [minlevel,maxlevel,t1,t2,x1,x2,y1,y2]
    regions.append([1, 1, clawdata.t0, clawdata.tfinal, clawdata.lower[0], clawdata.upper[0], clawdata.lower[1], clawdata.upper[1]])
    regions.append([1, 2, 2.0*3600.0, clawdata.tfinal, 110.0, 160.0,  0.0, 40.0])
    regions.append([1, 3, 4.0*3600.0, clawdata.tfinal, 115.0, 150.0, 10.0, 35.0])
    regions.append([1, 4, 4.5*3600.0, clawdata.tfinal, 120.0, 140.0, 15.0, 33.0])

    ## Level 5
    #topo_file = topotools.Topography(os.path.join(topodir, topoflist['Ishigaki']), topo_type=3)
    #regions.append([1, 5, 4.0*3600.0, clawdata.tfinal, topo_file.x[0], topo_file.x[-1], topo_file.y[0], topo_file.y[-1]])
    #topo_file = topotools.Topography(os.path.join(topodir, topoflist['Naha']), topo_type=3)
    #regions.append([1, 5, 4.0*3600.0, clawdata.tfinal, topo_file.x[0], topo_file.x[-1], topo_file.y[0], topo_file.y[-1]])
    topo_file = topotools.Topography(os.path.join(topodir, topoflist['Amami']), topo_type=3)
    regions.append([1, 5, 5.0*3600.0, clawdata.tfinal, topo_file.x[0], topo_file.x[-1], topo_file.y[0], topo_file.y[-1]])
    #topo_file = topotools.Topography(os.path.join(topodir, topoflist['Tanegashima']), topo_type=3)
    #regions.append([1, 5, 4.0*3600.0, clawdata.tfinal, topo_file.x[0], topo_file.x[-1], topo_file.y[0], topo_file.y[-1]])
    topo_file = topotools.Topography(os.path.join(topodir, topoflist['Aburatsu']), topo_type=3)
    regions.append([1, 5, 4.0*3600.0, clawdata.tfinal, topo_file.x[0], topo_file.x[-1], topo_file.y[0], topo_file.y[-1]])

    # Target simulation domain
    gauges = rundata.gaugedata.gauges
    gauges.append([1, 124.1390, 24.3229, 0., 1.e10]) # Ishigaki
    gauges.append([2, 127.6560, 26.2229, 0., 1.e10]) # Naha
    gauges.append([3, 129.5370, 28.3229, 0., 1.e10]) # Amami
    gauges.append([4, 130.9730, 30.4604, 0., 1.e10]) # Tanegashima
    gauges.append([5, 131.4060, 31.5688, 0., 1.e10]) # Aburatsu

    ## regions -- gauge の周辺だけ解像度レベルを高い状態に保つ
    #for g in gauges:
    #     regions.append([4, 4, 5.0*3600.0, clawdata.tfinal, g[1]-0.15, g[1]+0.15, g[2]-0.15, g[2]+0.15])
    #for g in gauges:
    #     regions.append([5, 5, 5.0*3600.0, clawdata.tfinal, g[1]-0.10, g[1]+0.10, g[2]-0.10, g[2]+0.10])

    # DART buoy 地点を gauge に追加
    gauges.append([52401, 155.7293, 19.2395, 0., 1.e10]) #
    gauges.append([52402, 153.9228, 11.9303, 0., 1.e10]) #
    gauges.append([52403, 145.6083,  4.0358, 0., 1.e10]) #
    gauges.append([52404, 132.1447, 20.6267, 0., 1.e10]) #
    gauges.append([52405, 132.2395, 12.9890, 0., 1.e10]) #
    gauges.append([52406, 164.9910, -5.3737, 0., 1.e10]) #

    ## 海嶺通過前後の地点
    gauges.append([51,  141.631, 17.821, 5.0*3600.0, 1.e10]) #
    gauges.append([101, 135.912, 21.555, 5.0*3600.0, 1.e10]) #
    gauges.append([102, 132.947, 23.628, 5.0*3600.0, 1.e10]) #
    gauges.append([103, 130.099, 25.571, 5.0*3600.0, 1.e10]) #
    gauges.append([201, 133.890, 24.481, 5.0*3600.0, 1.e10]) #
    gauges.append([202, 132.243, 25.641, 5.0*3600.0, 1.e10]) #
    gauges.append([203, 130.643, 26.726, 5.0*3600.0, 1.e10]) #

    # Fixed grid output
    fgout_grids = rundata.fgout_data.fgout_grids  # empty list initially
    ### fgout 1
    fgout = fgout_tools.FGoutGrid()
    fgout.fgno = 1
    fgout.output_format = 'ascii'
    fgout.nx = clawdata.num_cells[0]
    fgout.ny = clawdata.num_cells[1]
    fgout.x1 = clawdata.lower[0]
    fgout.x2 = clawdata.upper[0]
    fgout.y1 = clawdata.lower[1]
    fgout.y2 = clawdata.upper[1]
    fgout.tstart = clawdata.t0
    fgout.tend = clawdata.tfinal
    fgout.nout = int((fgout.tend - fgout.tstart)/3600.0) * 30 + 1
    fgout_grids.append(fgout)

    ## Ryukyu islands
    fgout = fgout_tools.FGoutGrid()
    fgout.fgno = 2
    fgout.output_format = 'ascii'
    fgout.x1 = 125.0
    fgout.x2 = 140.0
    fgout.y1 = 15.0
    fgout.y2 = 30.0
    fgout.nx = int( (fgout.x2 - fgout.x1) * 30 )
    fgout.ny = int( (fgout.y2 - fgout.y1) * 30 )
    fgout.tstart = 60.0*470.0
    fgout.tend = 60.0*750.0
    fgout.nout = int((fgout.tend - fgout.tstart)/3600.0) * 120 + 1
    fgout_grids.append(fgout)

    ## Amami
    topo_file = topotools.Topography(os.path.join(topodir, topoflist['Amami']), topo_type=3)
    fgout = fgout_tools.FGoutGrid()
    fgout.fgno = 3
    fgout.output_format = 'ascii'
    fgout.x1 = topo_file.x[0]
    fgout.x2 = topo_file.x[-1]
    fgout.y1 = topo_file.y[0]
    fgout.y2 = topo_file.y[-1]
    fgout.nx = topo_file.Z.shape[1]
    fgout.ny = topo_file.Z.shape[0]
    fgout.tstart = 60.0*590.0
    fgout.tend = 60.0*720.0
    fgout.nout = int((fgout.tend - fgout.tstart)/3600.0) * 60 + 1
    fgout_grids.append(fgout)

    # ============================
    # == fgmax.data values =======
    # ============================
    fgmax_files = rundata.fgmax_data.fgmax_files
    ## num_fgmax_val
    #rundata.fgmax_data.num_fgmax_val = 1  # 1 to save depth, 2 to save depth and speed, and 5 to Save depth, speed, momentum, momentum flux and hmin

    #------------------------------------------------------------------
    # GeoClaw specific parameters:
    #------------------------------------------------------------------
    rundata = setgeo(rundata)

    return rundata
    # end of function setrun
    # ----------------------


#-------------------
def setgeo(rundata):
#-------------------
    """
    Set GeoClaw specific runtime parameters.
    For documentation see ....
    """

    try:
        geo_data = rundata.geo_data
    except:
        print("*** Error, this rundata has no geo_data attribute")
        raise AttributeError("Missing geo_data attribute")
       
    # == Physics ==
    geo_data.gravity = 9.8
    geo_data.coordinate_system = 2 # lonlat
    # geo_data.coordinate_system = 1 # XY
    geo_data.earth_radius = 6367.5e3
    geo_data.rho = 1025.0
    geo_data.rho_air = 1.15
    geo_data.ambient_pressure = 101.3e3 # Nominal atmos pressure

    # == Forcing Options
    geo_data.coriolis_forcing = True
    geo_data.friction_forcing = True
    geo_data.manning_coefficient = 0.025 # Overridden below
    geo_data.friction_depth = 1e10

    # == Algorithm and Initial Conditions ==
    geo_data.sea_level = 0.0
    geo_data.dry_tolerance = 1.0e-2

    # Refinement Criteria
    refine_data = rundata.refinement_data
    refine_data.wave_tolerance = 0.02
    refine_data.speed_tolerance = [0.25, 0.50, 0.75, 1.00]
    refine_data.variable_dt_refinement_ratios = True

    # == settopo.data values ==
    topo_data = rundata.topo_data
    topo_data.topofiles = []
    # for topography, append lines of the form
    #   [topotype, fname]
    # See regions for control over these regions, need better bathy data for the
    # smaller domains
    topo_data.topofiles.append( [4, os.path.join(topodir, topoflist['GEBCO2022f'])] )
    topo_data.topofiles.append( [3, os.path.join(topodir, topoflist['Amami'])] )

    # == setdtopo.data values ==
    dtopo_data = rundata.dtopo_data
    dtopo_data.dtopofiles = []
    # for moving topography, append lines of the form :   (<= 1 allowed for now!)
    #   [topotype, minlevel,maxlevel,fname]

    # == setqinit.data values ==
    rundata.qinit_data.qinit_type = 0
    rundata.qinit_data.qinitfiles = []
    # for qinit perturbations, append lines of the form: (<= 1 allowed for now!)
    #   [minlev, maxlev, fname]

    # NEW feature to force dry land some locations below sea level:
    # force_dry = ForceDry()
    # force_dry.tend = 1e10
    # force_dry.fname = os.path.join(topodir, 'force_dry_init_05.dat')
    # rundata.qinit_data.force_dry_list.append(force_dry)

    # ================
    #  Set Surge Data
    # ================
    data = rundata.surge_data

    # Source term controls - These are currently not respected
    data.wind_forcing = False
    data.drag_law = 1
    data.pressure_forcing = True

    # AMR parameters
    #data.wind_refine = [20.0,30.0,40.0] # m/s
    #data.R_refine = False  # m
    
    # Storm parameters
    data.storm_type = -2 # Type of storm
    data.storm_specification_type = 'WRF'
    #data.landfall = 3600.0
    data.display_landfall_time = False

    # storm data file
    #data.storm_file = os.path.join(os.getcwd())
    data.storm_file = os.getcwd()
    #data.storm_file = glob.glob(os.path.join(os.getcwd(),'../slp_nc_presA','*.nc'))


    # =======================
    #  Set Variable Friction
    # =======================
    data = rundata.friction_data

    # Variable friction
    data.variable_friction = False

    # Region based friction
    # Entire domain
    data.friction_regions.append([rundata.clawdata.lower, 
                                  rundata.clawdata.upper,
                                  [np.infty,0.0,-np.infty],
                                  [0.030, 0.022]])

    return rundata
    # end of function setgeo
    # ----------------------


if __name__ == '__main__':
    # Set up run-time parameters and write all data files.
    import sys
    if len(sys.argv) == 2:
        rundata = setrun(sys.argv[1])
    else:
        rundata = setrun()

    rundata.write()
