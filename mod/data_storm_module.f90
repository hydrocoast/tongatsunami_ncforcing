! ==============================================================================
! model_storm_module 
!
! Module contains routines for constructing a wind and pressure field based on a
! provided set of data files.
!
! ==============================================================================
!                   Copyright (C) Clawpack Developers 2017
!  Distributed under the terms of the Berkeley Software Distribution (BSD) 
!  license
!                     http://www.opensource.org/licenses/
! ------------------------------------------------------------------------------
! 2020/01/31, v1, NF added what are written in wrf_storm_module.f90
!                 --> storm_location, set_storm_fields etc.
! 2022/01/27, v2, NF added ncfile read
! 2022/08/05, v3, NF added ncfile read in sequence (need buffer layer)
! ==============================================================================
module data_storm_module

    implicit none
    save

    logical, private :: module_setup = .false.

    ! Internal tracking variables for storm
    logical, private :: DEBUG = .true. 
    !logical, private :: DEBUG = .false. 

    ! Tolerance for floating point inequalities
    real(kind=8), parameter :: eps = 1.0e-8 

    ! List of storm files (only netCDF input)
    character(len=1024), allocatable :: ncfilelist(:)

    ! Pointer for reading nc files (only netCDF input)
    integer :: ifile_nc 
    integer :: nfile_nc ! number of nc files

    ! Counter variable
    integer :: it
    integer :: yy, mm, dd, hh, nn

    ! WRF storm type definition
    ! Specified wind & pressure field 
    type data_storm_type
        ! Size of spatial grids,
        !  corresponds to lengths of lat/lon arrays
        integer :: num_lats
        integer :: num_lons

        ! Location of storm field values
        ! longitude and latitude arrays
        ! start from SW corner
        real(kind=8) :: ll_lon, ur_lon
        real(kind=8) :: ll_lat, ur_lat
        real(kind=8) :: dx, dy
        !real(kind=8), allocatable :: lat(:)
        !real(kind=8), allocatable :: lon(:)

        ! We keep two time snapshots in memory 
        !  for interpolation, with t_next > t > t_prev
        real(kind=8) :: t_next, t_prev
        real(kind=8), allocatable :: u_next(:,:)
        real(kind=8), allocatable :: v_next(:,:)
        real(kind=8), allocatable :: p_next(:,:)
        real(kind=8), allocatable :: u_prev(:,:)
        real(kind=8), allocatable :: v_prev(:,:)
        real(kind=8), allocatable :: p_prev(:,:)
        ! The values will be updated incrementally:
        !  when t>t_next, replace older states with newer states
        !  and read in next snapshot.
        
        ! These will be used during the interpolation step
        !  for times between t_prev and t_next
        real(kind=8) :: t
        real(kind=8), allocatable :: u(:,:)
        real(kind=8), allocatable :: v(:,:)
        real(kind=8), allocatable :: p(:,:)

        ! The estimate center of the storm 
        !  is also stored for interpolation
        integer :: eye_next(2)
        integer :: eye_prev(2)

        ! Keep track of how many snapshots have been read
        integer :: last_storm_index

        ! Store the storm data file for repeated reading
        character(len=4096) :: data_path

        ! Storm specification type
        integer :: storm_specification_type

    end type data_storm_type

contains

    ! Setup routine for the WRF storm model
    ! Open data files, get parameters, allocate memory,
    !  and read in first two time snapshots of storm data
    subroutine set_storm(storm_data_path, storm, storm_spec_type, log_unit)

    use geoclaw_module, only: coordinate_system, ambient_pressure
    use amr_module, only: t0

        implicit none

        ! Subroutine I/O
        character(len=*), optional :: storm_data_path
        type(data_storm_type), intent(inout) :: storm
        integer, intent(in) :: storm_spec_type, log_unit

        ! Local storage
        integer, parameter :: l_file = 701
        integer :: i, j, iostatus

        ! Pointer for reading nc files (only netCDF input)
        ! integer :: ifile_nc 
        ! integer :: nfile_nc ! number of nc files

        real(kind=8) :: ll_lon, ll_lat, ur_lon, ur_lat, dx, dy

        ! Reading buffer variables
        character(len=100) :: dummy_read
        integer :: readsize

        ! Counter variable
        ! integer :: it
        ! integer :: yy, mm, dd, hh, nn


        

        ! Storm type only works on lat-long coordinate systems
        !if (coordinate_system /= 2) then
        !    stop "explicit storm type does only works on lat-long coordinates."
        !endif

        ! We need to count two things:
        !   number of latitude coords (ny)
        !   number of longitude coords (nx)
        ! We don't need number of time snapshots (nt)
        !   since we will load snapshots only as needed
        ! The datafiles for lat & lon contain nx*ny values
        ! The datafiles for u, v, p contain nx*ny*nt values

        !!!!
        if (present(storm_data_path)) then
            storm%data_path = storm_data_path
        else
            storm%data_path = '.'
        endif

        storm%storm_specification_type = storm_spec_type

        if (storm%storm_specification_type == -2) then

            ! Monitor output
            print *, "storm data format =====> *.nc"

            ! Read data list of storm files in netCDF
            storm_data_path = trim(storm%data_path) // "/storm_list.data"

            print *,'Reading storm list data file ',trim(storm_data_path)
            open(unit=l_file, file=storm_data_path, status='old', action='read', iostat=iostatus)
            if (iostatus /= 0) then
                print *, "Error opening storm list data file. status = ", iostatus
                stop 
            endif            

            ! Skip headers
            read(l_file,*)
            read(l_file,*)
            read(l_file,*)
            read(l_file,*)
            read(l_file,*)

            ! Read number of files
            read(l_file,*) nfile_nc
            if (DEBUG) print *, "Number of storm files: ",nfile_nc
            
            ! Allocate array of file list
            allocate(ncfilelist(nfile_nc))

            ! Read file lists
            do ifile_nc = 1,nfile_nc
                read(l_file,'(100a)') ncfilelist(ifile_nc)
                !if (DEBUG) print *, trim( ncfilelist(ifile_nc) )
            enddo


            ! Initialize loop counter
            it = 1
            ifile_nc = 1
            ! Initialize date (start from 0000/00/01 00:01)
            yy = 0
            mm = 0
            dd = 1
            hh = 0
            nn = 1

            ! Read in the first storm data snapshot as 'next'
            ! and increment storm%lalst_storm_index to 1
            call read_storm_nc( storm, t0 )

            ! Check if starting time of simulation
            !  is before the first storm data snapshot
            if (t0 < storm%t_next - eps) then
                print *, "Simulation start time precedes storm data. Using clear skies."
                if (DEBUG) print *, "t0=", t0, "first storm t:",storm%t_next
                storm%t_prev = t0
                storm%u_prev = 0
                storm%v_prev = 0
                storm%p_prev = ambient_pressure
                storm%eye_prev = storm%eye_next
            else
                ! Read in the second storm data snapshot as 'next',
                !  update 'prev' with old 'next' data,
                !  and increment storm%last_storm_index to 2
                call read_storm_nc( storm, t0  )
            endif

        endif

        ! Initialize current storm module data
        storm%t = t0
        ! Interpolate wind & pressure fields using prev and next snapshots
        call storm_interpolate(storm)

        !stop "Data-derived storm are not yet implemented!"

        if (.not. module_setup) then

            module_setup = .true.

        end if

    end subroutine set_storm

    ! ==========================================================================
    !  real(kind=8) pure date_to_seconds(year,months,days,hours,minutes,seconds)
    !    Convert time from year, month, day, hour, min, sec to seconds since the
    !    beginning of the year.
    ! ==========================================================================
    !pure real(kind=8) function date_to_seconds(year,months,days,hours,minutes, &
                                               !seconds) result(time)
    pure integer function date_to_seconds(year,months,days,hours,minutes) result(time)
      
        implicit none

        ! Input
        integer, intent(in) :: year, months, days, hours, minutes

        ! Local storage
        integer :: total_days

        ! Count number of days
        total_days = days

        ! Add days for months that have already passed
        if (months > 1) total_days = total_days + 31
        if (months > 2) then
            if (int(year / 4) * 4 == year) then
                total_days = total_days + 29
            else
                total_days = total_days + 28
            endif
        endif
        if (months > 3)  total_days = total_days + 30
        if (months > 4)  total_days = total_days + 31
        if (months > 5)  total_days = total_days + 30
        if (months > 6)  total_days = total_days + 31
        if (months > 7)  total_days = total_days + 30
        if (months > 8)  total_days = total_days + 31
        if (months > 9)  total_days = total_days + 30
        if (months > 10) total_days = total_days + 31
        if (months > 11) total_days = total_days + 30

        ! Convert everything to seconds since the beginning of the year
        time = (total_days - 1) * 86400 + hours * 3600 + minutes * 60

    end function date_to_seconds

    ! ==========================================================================
    !  read_storm_data_file()
    !    Opens storm data file and reads next storm entry
    !    Currently only for ASCII file
    !  This file will probably need to be modified
    !   to suit the input dataset format.
    ! ==========================================================================
    subroutine read_storm_file(data_path,storm_array,num_lats,last_storm_index,timestamp)

        implicit none

        ! Subroutine I/O
        real(kind=8), intent(inout) :: storm_array(:,:)
        character(len=*), intent(in) :: data_path
        integer, intent(in) :: num_lats, last_storm_index
        integer, intent(inout) :: timestamp

        ! Local storage
        integer :: j, k, iostatus
        integer :: yy, mm, dd, hh, nn
        integer, parameter :: data_file = 701

        ! Open the input file
        !
        open(unit=data_file,file=data_path,status='old', &
                action='read',iostat=iostatus)
        if (iostatus /= 0) then
            print *, "Error opening data file: ",trim(data_path)
            print *, "Status = ", iostatus
            stop 
        endif            
        ! Advance to the next time step to be read in
        ! Skip entries based on total number previously read
        do k = 1, last_storm_index
            do j = 1, num_lats + 1
                read(data_file, *, iostat=iostatus)
                ! Exit loop if we ran into an error or we reached the end of the file
                if (iostatus /= 0) then
                    print *, "Unexpected end-of-file reading ",trim(data_path)
                    print *, "Status = ", iostatus
                    if (DEBUG) print *, "k, laststormindex = ", k, last_storm_index
                    if (DEBUG) print *, "j, num_lats = ", j, num_lats
                    timestamp = -1
                    close(data_file) 
                    return
                endif
            enddo
        enddo
        ! Read in next time snapshot 
        ! example:
        ! ____108000 7908251800 (EDIT from here)
        read(data_file, 600, iostat=iostatus) & 
            yy, mm, dd, hh, nn
    600 FORMAT(11x,i2,i2,i2,i2,i2)
        !read(data_file, (11x,i2,i2,i2,i2,i2), iostat=iostatus) & 
            !yy, mm, dd, hh, nn
        do j = 1, num_lats
            read(data_file, *, iostat=iostatus) storm_array(:,j) 
            ! Exit loop if we ran into an error or we reached the end of the file
            if (iostatus /= 0) then
                print *, "Unexpected end-of-file reading ",trim(data_path)
                print *, "Status = ", iostatus
                if (DEBUG) print *, "j, num_lats = ", j, num_lats
                timestamp = -1
                close(data_file) 
                return
            endif
        enddo

        ! Convert datetime to seconds
        timestamp = date_to_seconds(yy,mm,dd,hh,nn)
        close(data_file) 

    end subroutine read_storm_file

    ! ==========================================================================
    ! read_storm_nc()
    ! Reads storm fields for next time snapshot
    ! NetCDF format only
    ! ==========================================================================

    subroutine read_storm_nc( storm, t )

        use geoclaw_module, only: ambient_pressure, earth_radius, deg2rad
        use netcdf

        implicit none

        ! Subroutine I/O
        type(data_storm_type), intent(inout) :: storm
        real(kind=8) :: lowest_p
        real(kind=8), intent(in) :: t
        ! integer, intent(inout) :: yy, mm, dd, hh, nn
        ! integer, intent(inout) :: it          ! time step
        ! integer, intent(inout) :: ifile_nc    ! file ID to be read
        ! character(len=1024), intent(in) :: ncfilelist(:)

        ! Reading buffer variables
        integer :: timestamp

        ! dimension
        integer :: nx, ny, nt
        character(len=1024) :: f_in
        real(kind=4), allocatable :: lon(:), lat(:), timelap(:)
        real(kind=4), allocatable :: psea(:,:,:)
        !real(kind=4), allocatable :: u10(:,:,:), v10(:,:,:)
        ! parameters for read
        integer :: ncid, varid, dimid
        integer :: start_nc(3), count_nc(3)
        real(kind=4) :: scale_factor, add_offset
        ! parameters for detecting storm eyes
        real(kind=8), parameter :: storm_dist_threshold = 1000.0e3 ! [m]
        real(kind=8) :: a1, a2, storm_dist
        

        ! check if ifile_nc exists
        if(ifile_nc>nfile_nc)then
            
            print *, "storm netCDF file does not exist ..."
            print *, "Using clear skies."
            storm%t_next = storm%t_next + 365*24*60
            storm%u_next = 0
            storm%v_next = 0
            storm%p_next = ambient_pressure
            storm%eye_next = [0,0]

            ! Update number of storm snapshots read in
            storm%last_storm_index = storm%last_storm_index + 1
            if (DEBUG) print *, "last_storm_index=", storm%last_storm_index

            return

        endif

        ! netcdf filename  
        f_in = ncfilelist(ifile_nc)
        print *, 'reading start: ' // trim(f_in)
        call check_ncstatus( nf90_open( f_in, nf90_nowrite, ncid) )

        ! number of array
        ! -- lon
        call check_ncstatus( nf90_inq_dimid(ncid, 'lon', dimid) )
        call check_ncstatus( nf90_inquire_dimension(ncid, dimid, len=nx) ) ! nx is determined
        allocate(lon(nx))
        call check_ncstatus( nf90_get_var(ncid, dimid, lon) )
        ! -- lat
        call check_ncstatus( nf90_inq_dimid(ncid, 'lat', dimid) )
        call check_ncstatus( nf90_inquire_dimension(ncid, dimid, len=ny) )
        allocate(lat(ny))
        call check_ncstatus( nf90_get_var(ncid, dimid, lat) )
        ! -- timelap
        !call check_ncstatus( nf90_inq_dimid(ncid, 'time', dimid) )
        !call check_ncstatus( nf90_inquire_dimension(ncid, dimid, len=nt) )
        !allocate(timelap(nt))
        !call check_ncstatus( nf90_get_var(ncid, dimid, timelap) )
        nt = 1

        ! allocate
        allocate(psea(nx,ny,nt))
        !allocate(u10(nx,ny,nt), v10(nx,ny,nt))
        
        ! process done in first step
        if(it==1 .and. ifile_nc==1)then
            ! allocate storm%xxx
            storm%num_lons = nx ! assign number of longitude to nx
            storm%num_lats = ny

            ! allocate storm parameters (only first time)
            allocate(storm%u_prev(storm%num_lons,storm%num_lats))
            allocate(storm%v_prev(storm%num_lons,storm%num_lats))
            allocate(storm%p_prev(storm%num_lons,storm%num_lats))
            allocate(storm%u_next(storm%num_lons,storm%num_lats))
            allocate(storm%v_next(storm%num_lons,storm%num_lats))
            allocate(storm%p_next(storm%num_lons,storm%num_lats))
            allocate(storm%u(storm%num_lons,storm%num_lats))
            allocate(storm%v(storm%num_lons,storm%num_lats))
            allocate(storm%p(storm%num_lons,storm%num_lats))

            ! lower left corner and dy
            storm%ll_lon = minval(lon)
            storm%ll_lat = minval(lat)
            ! upper right corner and dx
            storm%ur_lon = maxval(lon)
            storm%ur_lat = maxval(lat)
            lat = lat(ny:1:-1)

            ! grid size dx and dy
            storm%dx = abs( lon(2) - lon(1) )
            storm%dy = abs( lat(ny) - lat(ny-1) )

            ! This is used to speed up searching for correct storm data
            !  (using ASCII datafiles)
            storm%last_storm_index = 0

        endif

        ! ----- contents of subroutine read_storm()----------------------------------------------
        ! Overwrite older storm states with newer storm states
        storm%t_prev = storm%t_next
        storm%u_prev = storm%u_next 
        storm%v_prev = storm%v_next 
        storm%p_prev = storm%p_next 
        storm%eye_prev = storm%eye_next

        ! Current time t currently unused in favor of storm%last_storm_index.
        ! This should probably be changed in the future.
        
        ! read variables
        ! indices
        start_nc = [1,1,1]
        count_nc = [nx,ny,nt]

        ! -- psl
        call check_ncstatus( nf90_inq_varid(ncid, "psl", varid) )
        call check_ncstatus( nf90_get_var(ncid, varid, psea, start=start_nc, count=count_nc) )
        psea(:,:,:) = psea(:,:,:)*1e2 + ambient_pressure
        write(*,'("ambient pressure:  ",f10.2)') ambient_pressure
        write(*,'("min: ",f10.2,",  max: ",f10.2)') minval(psea(:,:,1)), maxval(psea(:,:,1))
        ! -- psea
        !call check_ncstatus( nf90_inq_varid(ncid, "psea", varid) )
        !call check_ncstatus( nf90_get_var(ncid, varid, psea, start=start_nc, count=count_nc) )
        !call check_ncstatus( nf90_get_att(ncid, varid, "scale_factor", scale_factor) )
        !call check_ncstatus( nf90_get_att(ncid, varid, "add_offset", add_offset) )
        !psea(:,:,:) = psea(:,:,:)*scale_factor + add_offset
        ! -- u10
        !call check_ncstatus( nf90_inq_varid(ncid, "u", varid) )
        !call check_ncstatus( nf90_get_var(ncid, varid, u10, start=start_nc, count=count_nc) )
        !call check_ncstatus( nf90_get_att(ncid, varid, "scale_factor", scale_factor) )
        !call check_ncstatus( nf90_get_att(ncid, varid, "add_offset", add_offset) )
        !u10(:,:,:) = u10(:,:,:)*scale_factor + add_offset
        ! -- v10
        !call check_ncstatus( nf90_inq_varid(ncid, "v", varid) )
        !call check_ncstatus( nf90_get_var(ncid, varid, v10, start=start_nc, count=count_nc) )
        !call check_ncstatus( nf90_get_att(ncid, varid, "scale_factor", scale_factor) )
        !call check_ncstatus( nf90_get_att(ncid, varid, "add_offset", add_offset) )
        !v10(:,:,:) = v10(:,:,:)*scale_factor + add_offset
        ! close nc file
        call check_ncstatus( nf90_close(ncid) )

        ! ----- contents of subroutine read_storm_data
        !
       

        ! if NOT using the buffer layers
        storm%p_next = psea(:,:,it)
        ! 
        ! make u10 v10 P filled with U10, V10 = 0 and P = 1013
        !call make_storm_buffer_layer(storm,psea(:,:,it),nx,ny,1,lon,lat)
        !call make_storm_buffer_layer(storm,u10(:,:,it),nx,ny,2,lon,lat)
        !call make_storm_buffer_layer(storm,v10(:,:,it),nx,ny,3,lon,lat)

        ! Convert pressure units: mbar (hPa) to Pa
        ! storm%p_next = storm%p_next * 1.0e2 ! NC file uses Pa
        ! Estimate storm center location based on lowest pressure
        ! (only the array index is saved)
        !storm%eye_next = minloc(storm%p_next)
        ! If no obvious low pressure area, set storm center to 0 instead
        !lowest_p = storm%p_next(storm%eye_next(1),storm%eye_next(2))
        !if (lowest_p > ambient_pressure*0.99) then
            storm%eye_next = [0,0]
        !endif 

        ! (temporary)
        ! Calculate distance b/w two typhoons
        ! dist=rcos-(sin(y1)sin(y2)+cos(y1)cos(y2)cos(x2-x1))
        !if(storm%eye_prev(1)/=0 .or. storm%eye_prev(2)/=0)then
        !    ! print *, storm%eye_prev
        !    ! print *, storm%eye_next
        !    a1 = sin(deg2rad*lat(storm%eye_prev(2)))&
        !    &    *sin(deg2rad*lat(storm%eye_next(2)))

        !    a2 = cos(deg2rad*lat(storm%eye_prev(2)))&
        !    &    *cos(deg2rad*lat(storm%eye_next(2)))&
        !    &    *cos(deg2rad*lon(storm%eye_next(1))&
        !    &        -deg2rad*lon(storm%eye_prev(1)))
        !    storm_dist = earth_radius * acos( a1 + a2 )
        !    print *, "storm distance = ",storm_dist
        !    if (storm_dist > storm_dist_threshold)then
        !        print *, "another storm appeared ..."
        !        storm%eye_next = [0,0]
        !    endif
        !endif

        ! Update number of storm snapshots read in
        storm%last_storm_index = storm%last_storm_index + 1
        if (DEBUG) print *, "last_storm_index=", storm%last_storm_index

        ! timestamp
        timestamp = date_to_seconds(yy,mm,dd,hh,nn)
        storm%t_next = timestamp
        
        ! --- print for check
        write(*,*) "------------------------------------------------------------------"
        write(*,*) "Storm information"
        write(*,*) "Time: ", dd, " [day]", hh, " [hour]", nn, " [min]"
        write(*,*) "nx: ",nx, "ny: ",ny, "nt: ", nt
        write(*,*) "dx and dy :",storm%dx, storm%dy
        !write(*,*) "tmin: ",timelap(lbound(timelap)), "tmax: ",timelap(ubound(timelap))
        write(*,*) "xll: ",minval(lon), "xur: " ,maxval(lon)
        write(*,*) "yll: ",minval(lat), "yur: ",maxval(lat)
        write(*,*) "iteration: ",it, "storm%t_next: ",storm%t_next
        if(storm%eye_next(1)/=0 .and. storm%eye_next(2)/=0)then
            write(*,*) "storm eye: ",lon(storm%eye_next(1)),lat(storm%eye_next(2))
        else
            write(*,*) "storm eye: N/A"
        endif
        write(*,*) "max P: ", maxval(storm%p_next), "min P: ", minval(storm%p_next)
        !write(*,*) "max U10: ",maxval(storm%u_next), "min U10: ",minval(storm%u_next)
        !write(*,*) "max V10: ", maxval(storm%v_next), "min V10: ",minval(storm%v_next)
        write(*,*) "------------------------------------------------------------------"

        ! renew loop counter
        it = it + 1
        ! renew time stamp
        nn = nn + 1
        if(nn>=60)then
            nn = nn - 60
            hh = hh + 1
        endif
        if(hh>=24)then
            hh = hh - 24
            dd = dd + 1
        endif

        ! reset loop counter
        if(it==nt+1)then
            if (DEBUG) print *, "EOF of netCDF file and proceed to next file ..."
            it = 1
            ifile_nc = ifile_nc + 1
        endif

    end subroutine read_storm_nc

    subroutine check_ncstatus( status )
        use netcdf
        integer, intent (in) :: status
        if(status /= nf90_noerr) then 
        print *, trim(nf90_strerror(status))
        stop "Something went wrong while reading ncfile."
        end if
    end subroutine check_ncstatus

    subroutine make_storm_buffer_layer(storm,storm_field,nx,ny,flag,x,y)

        use geoclaw_module, only: ambient_pressure

        implicit none

        ! storm field (pressure or wind)
        type(data_storm_type), intent(inout) :: storm
        integer, intent(inout) :: nx, ny
        real(kind=4), intent(inout) :: storm_field(nx,ny)
        real(kind=4) :: storm_field_wrk(nx,ny)

        ! coordinate
        real(kind=4), intent(inout) :: x(nx),y(ny)

        ! flag determining pressure (1) or wind (2)
        integer :: flag
        real(kind=4) :: val

        ! settings about margin
        integer :: nn, ninner, nbuffer, nghost, i, j

        ! --- monitor output
        ! print *, "Make buffer layer for storm"

        ! 
        nn = nint( max(nx,ny) * 0.1d0 ) ! 10% of number of meshes
        nbuffer = nint( nn * 0.33d0 ) ! quotient of 3
        ninner  = nn-nbuffer
        nghost =  nint( max(nx,ny) * 0.1d-1 ) ! 1%

        ! --- for debug only
        ! print *, "nn :",nn
        ! print *, "ninner :",ninner, " nbuffer: ",nbuffer
        ! print *, "nghost :", nghost

        ! print *, " SLP(100,100) =",storm_field(100,100)
        ! print *, "x = ",x(100),"y = ",y(100)

        if(flag==1)then
            val = ambient_pressure ! pressure
        else
            val = 0.0d0            ! wind speed
        endif

        ! fill with clear sky condition
        storm_field_wrk(:,:) = val
                
        ! pickup core region
        storm_field_wrk(nn+1:nx-nn, nn+1:ny-nn) &
        = storm_field(nn+1:nx-nn, nn+1:ny-nn)
        ! storm_field_wrk=storm_field

        ! subroutine of linear interpolation (for buffer layer)
        call interp2(storm_field_wrk,x,y, nn, ninner, nbuffer,nx,ny)

        ! fill margin with the same value as the edge of buffer
        ! --- WEST
        do i = 1,nghost
            do j = 1,ny
                storm_field_wrk(i,j) = storm_field_wrk(nghost+1,j)
            enddo
        enddo
        ! --- EAST
        do i = nx-nghost+1,nx
            do j = 1,ny
            storm_field_wrk(i,j) & 
                       = storm_field_wrk(nx-nghost,j)
            enddo
        enddo
        ! --- SOUTH
        do i = 1,nx
            do j = 1,nghost
            storm_field_wrk(i,j) = storm_field_wrk(i,nghost+1)
            enddo
        enddo
        ! --- NORTH
        do i = 1,nx
            do j = nx-nghost+1,nx
            storm_field_wrk(i,j) = storm_field_wrk(i,ny-nghost)
            enddo
        enddo

        if(flag==1)then
            storm%p_next = storm_field_wrk
        elseif(flag==2)then
            storm%u_next = storm_field_wrk
        elseif(flag==3)then
            storm%v_next = storm_field_wrk
        endif

    end subroutine make_storm_buffer_layer

    subroutine interp2(array, x, y, nn, ninner, nbuffer,nx,ny)

        implicit none

        integer, intent(in) :: nn, ninner, nbuffer, nx, ny
        integer :: is,ie,js,je,flag_dir
        real(kind=4), intent(inout) :: array(nx,ny)    
        real(kind=4), intent(inout) :: x(nx),y(ny)

        ! linear interpolation in buffer layer
        !----------------------------------------------------------
        ! --- WEST
        is = ninner+1; ie = nn+1
        js = nn+1;     je = ny-nn
        flag_dir = 1
        call interp2_data(array,x,y,is,js,ie,je,nx,ny,flag_dir)
        ! --- EAST
        is = nx-nn;  ie = nx-ninner
        js = nn+1;     je = ny-nn
        flag_dir = 1
        call interp2_data(array,x,y,is,js,ie,je,nx,ny,flag_dir)
        ! --- SOUTH
        is = nn+1;     ie = nx-nn
        js = ninner+1; je = nn+1
        flag_dir = 2
        call interp2_data(array,x,y,is,js,ie,je,nx,ny,flag_dir)
        ! --- NORTH
        is = nn+1;     ie = nx-nn
        js = ny-nn;  je = ny-ninner
        flag_dir = 2
        call interp2_data(array,x,y,is,js,ie,je,nx,ny,flag_dir)
        ! --- upper left
        is = ninner+1; ie = nn+1
        js = ninner+1; je = nn+1
        flag_dir = 3
        call interp2_data(array,x,y,is,js,ie,je,nx,ny,flag_dir)
        ! --- upper right
        is = nx-nn+1;  ie = nx-ninner
        js = ninner+1; je = nn+1
        flag_dir = 4
        call interp2_data(array,x,y,is,js,ie,je,nx,ny,flag_dir)
        ! --- lower left
        is = ninner+1; ie = nn+1
        js = ny-nn+1; je = ny-ninner
        flag_dir = 5
        call interp2_data(array,x,y,is,js,ie,je,nx,ny,flag_dir)
        ! --- lower right
        is = nx-nn+1;  ie = nx-ninner
        js = ny-nn; je = ny-ninner
        flag_dir = 6
        call interp2_data(array,x,y,is,js,ie,je,nx,ny,flag_dir)
        !------------------------------------------------------------

    end subroutine interp2

    subroutine interp2_data(array,x,y,is,js,ie,je,nx,ny,flag_dir)

        implicit none
        integer, intent(in) :: is,js,ie,je,nx,ny,flag_dir
        integer :: i, j
        real(kind=4), intent(inout) :: array(nx,ny)    
        real(kind=4), intent(inout) :: x(nx),y(ny)
        real(kind=4) :: S,v11,v12,v21,v22,x1,x2,y1,y2
        real(kind=4) :: b11,b12,b21,b22
        real(kind=4) :: v1,v2,b1,b2

        x1 = x(is);y1 = y(js)
        x2 = x(ie);y2 = y(je)
        
        if(flag_dir==1)then

            do j = js,je
                v1 = array(is,j); v2 = array(ie,j)
                do i = is,ie
                    b1 = (x2-x(i))/(x2-x1); b2 = (x(i)-x1)/(x2-x1)
                    array(i,j) = v1*b1+v2*b2
                enddo
            enddo

        elseif(flag_dir==2)then

            do i = is,ie
                v1 = array(i,js); v2 = array(i,je)
                do j = js,je
                    b1 = (y2-y(j))/(y2-y1); b2 = (y(j)-y1)/(y2-y1)
                    array(i,j) = v1*b1+v2*b2
                enddo
            enddo

        elseif(flag_dir>=3)then

            if(flag_dir==3)then
            v11 = array(is,js);v12 = array(is,je)
            v21 = array(ie,js);v22 = array(ie,je)
            elseif(flag_dir==4)then
            v11 = array(ie,js);v12 = array(ie,je)
            v21 = array(is,je);v22 = array(is,js)
            elseif(flag_dir==5)then
            v11 = array(ie,je);v12 = array(ie,js)
            v21 = array(is,je);v22 = array(is,js)
            elseif(flag_dir==6)then
            v11 = array(is,js);v12 = array(is,je)
            v21 = array(ie,je);v22 = array(ie,js)
            endif


            x1 = x(is);y1 = y(js)
            x2 = x(ie);y2 = y(je)
            S  = (x2-x1)*(y2-y1)


        do i = is,ie
            do j = js,je
                b11 = (x2-x(i))*(y2-y(j))/S
                b12 = (x(i)-x1)*(y2-y(j))/S
                b21 = (x2-x(i))*(y(j)-y1)/S
                b22 = (x(i)-x1)*(y(j)-y1)/S
                array(i,j) = v11 * b11 + v12 * b12 &
                           + v21 * b21 + v22 * b22 
            enddo
        enddo

    endif

    end subroutine interp2_data

    ! ==========================================================================
    !  storm_location(t,storm)
    !    Interpolate location of hurricane in the current time interval
    ! ==========================================================================
    function storm_location(t,storm) result(location)

        use amr_module, only: rinfinity

        implicit none

        ! Input
        real(kind=8), intent(in) :: t
        type(data_storm_type), intent(inout) :: storm

        ! Output
        real(kind=8) :: location(2)

        ! Local storage
        real(kind=8) :: alpha
        integer :: eye(2)

        ! Estimate location based on two nearest snapshots 

        ! If no data at this time, return infinity
        if ((t < storm%t_prev - eps) .OR. (t > storm%t_next + eps)) then
            location = [rinfinity,rinfinity]
        else if ((storm%eye_prev(1) == 0) .AND. (storm%eye_next(1) == 0)) then
            location = [rinfinity,rinfinity]
        else
            ! Otherwise check if there is a low pressure system
            !  and if so interpolate eye location from snapshots
            if (storm%eye_prev(1) == 0) then
                eye = storm%eye_next
            else if (storm%eye_next(1) == 0) then
                eye = storm%eye_prev
            else
                ! Determine the linear interpolation parameter (in time)
                if (storm%t_next-storm%t_prev < eps) then
                    print *, "t_next = ", storm%t_next,"t_prev = ", storm%t_prev
                    print *, "t = ", t, "storm%t = ", storm%t
                    alpha = 0
                else
                    alpha = (t-storm%t_prev) / (storm%t_next-storm%t_prev)
                endif
                ! Estimate location index of storm center at time t
                eye = storm%eye_prev + NINT((storm%eye_next - storm%eye_prev) * alpha)
            endif
            ! Convert to lat-lon
            location(1) = storm%ll_lon + (eye(1)-1)*storm%dx
            !location(2) = storm%ll_lat + (eye(2)-1)*storm%dy
            location(2) = storm%ur_lat - (eye(2)-1)*storm%dy
        endif

        !stop "Data-derived storm are not yet implemented!"

    end function storm_location

    ! ==========================================================================
    !  storm_direction
    !   Angle off of due north that the storm is traveling
    ! ==========================================================================
    real(kind=8) function storm_direction(t, storm) result(theta)

        implicit none

        ! Input
        real(kind=8), intent(in) :: t
        type(data_storm_type), intent(in) :: storm

        stop "Data-derived storm are not yet implemented!"

    end function storm_direction

    ! ==========================================================================
    !  Use the 1980 Holland model to set the storm fields
    ! ==========================================================================
    subroutine set_HWRF_fields(maux, mbc, mx, my, xlower, ylower,    &
                          dx, dy, t, aux, wind_index,           &
                          pressure_index, storm)

  
        implicit none

        ! Time of the wind field requested
        integer, intent(in) :: maux,mbc,mx,my
        real(kind=8), intent(in) :: xlower,ylower,dx,dy,t

        ! Storm description, need inout here since we may update the storm
        ! if at next time point
        type(data_storm_type), intent(inout) :: storm

        ! Array storing wind and presure field
        integer, intent(in) :: wind_index, pressure_index
        real(kind=8), intent(inout) :: aux(maux,1-mbc:mx+mbc,1-mbc:my+mbc)

        stop "HWRF data input is not yet implemented!"

    end subroutine set_HWRF_fields

    ! ==========================================================================
    !  set_storm_fields() added
    ! ==========================================================================
    subroutine set_storm_fields(maux, mbc, mx, my, xlower, ylower,    &
        dx, dy, t, aux, wind_index,           &
        pressure_index, storm)

        !use geoclaw_module, only: ambient_pressure
        use geoclaw_module, only: g => grav, rho_air, ambient_pressure
        use geoclaw_module, only: coriolis, deg2rad
        use geoclaw_module, only: spherical_distance

        use geoclaw_module, only: rad2deg  

        implicit none

        ! Time of the wind field requested
        integer, intent(in) :: maux,mbc,mx,my
        real(kind=8), intent(in) :: xlower,ylower,dx,dy,t

        ! Storm description, need inout here since we may update the storm
        ! if at next time point
        type(data_storm_type), intent(inout) :: storm

        ! Array storing wind and presure field
        integer, intent(in) :: wind_index, pressure_index
        real(kind=8), intent(inout) :: aux(maux,1-mbc:mx+mbc,1-mbc:my+mbc)

        ! Local storage
        real(kind=8) :: x, y
        integer :: i,j,k,l

        

        if (t < storm%t_prev - eps) then
        print *, "Simulation time precedes storm data in memory. &
            Race condition?"
        print *, "t=",t,"< t_prev=",storm%t_prev,"t_next=",storm%t_next
        endif

        if (t > storm%t_next + eps) then
        ! Load two snapshots into memory, at times t_next and t_prev
        !$OMP CRITICAL (READ_STORM)
        do while (t > storm%t_next + eps)
        ! update all storm data, including value of t_next
        if (DEBUG) print *,"loading new storm snapshot ",&
                        "t=",t,"old t_next=",storm%t_next

        call read_storm_nc( storm, t )

        if (DEBUG) print *,"new t_next=",storm%t_next
        ! If storm data ends, the final storm state is used.
        enddo
        !$OMP END CRITICAL (READ_STORM)
        endif

        ! Interpolate storm data in time
        ! t_prev <= t <= t_next
        if (t > storm%t + eps) then
        !$OMP CRITICAL (INTERP_STORM)
        if (t > storm%t + eps) then
        ! Update storm data by interpolation
        call storm_interpolate(storm)
        ! Update current time in storm module (race condition?)
        storm%t = t
        endif
        !$OMP END CRITICAL (INTERP_STORM)
        endif

        ! Set fields
        ! Determine lat/long of each cell in layer,
        !  determine corresponding storm cell indices
        !  (or nearest cell index if out-of-bound)
        !  then get value of corresponding storm data cell.
        do j=1-mbc,my+mbc
        y = ylower + (j-0.5d0) * dy     ! Degrees latitude
        k = get_lat_index(y,storm) ! storm index of latitude
        ! Check for out-of-bounds condition
        if (k == 0) then
        ! Out of bounds
        do i=1-mbc,mx+mbc
        ! Set storm components to ambient condition
        aux(pressure_index,i,j) = ambient_pressure
        aux(wind_index,i,j)   = 0.0
        aux(wind_index+1,i,j) = 0.0
        enddo
        else
        ! Within latitude range
        do i=1-mbc,mx+mbc
        x = xlower + (i-0.5d0) * dx   ! Degrees longitude
        l = get_lon_index(x,storm) ! storm index of longitude
        ! Check for out-of-bounds condition
        if (l == 0) then
        ! Out of bounds
            ! Set storm components to ambient condition
            aux(pressure_index,i,j) = ambient_pressure
            aux(wind_index,i,j)   = 0.0
            aux(wind_index+1,i,j) = 0.0
        else
        ! Within longitude range
            ! Set pressure field
            aux(pressure_index,i,j) = storm%p(l,k)
            ! Set velocity components of storm 
            aux(wind_index,i,j)   = storm%u(l,k)
            aux(wind_index+1,i,j) = storm%v(l,k)
        endif
        enddo
        endif
        enddo

    end subroutine set_storm_fields

    ! ==========================================================================
    !  integer pure get_lat_index(lat)
    !    Returns index of latitude array of the storm data
    !    corresponding to input lat.
    ! ==========================================================================
    pure integer function get_lat_index(lat,storm) result(i)
      
        implicit none

        ! Input
        real(kind=8), intent(in) :: lat
        type(data_storm_type), intent(in) :: storm

        ! Out-of-bound conditions:
        ! EDIT changed to 0.
        ! Will apply ambient conditions in calling function
        if (lat < storm%ll_lat) then
            !i = 1
            i = 0
        else if (lat > storm%ur_lat) then
            !i = storm%num_lats
            i = 0
        else
        ! Determine index based on spacing
            i = 1 + NINT((lat - storm%ll_lat) / storm%dy)
        ! REVERSE top to bottom, based on file format
            i = storm%num_lats + 1 - i                   !!!!!!!!!!!!!!!!!!!!!!
        endif

    end function get_lat_index

    ! ==========================================================================
    !  integer pure get_lon_index(lon)
    !    Returns index of longitude array of the storm data
    !    corresponding to input lon.
    ! ==========================================================================
    pure integer function get_lon_index(lon,storm) result(i)
      
        implicit none

        ! Input
        real(kind=8), intent(in) :: lon
        type(data_storm_type), intent(in) :: storm

        ! Out-of-bound conditions:
        ! EDIT changed to 0.
        ! Will apply ambient conditions in calling function
        if (lon < storm%ll_lon) then
            !i = 1
            i = 0
        else if (lon > storm%ur_lon) then
            !i = storm%num_lons
            i = 0
        else
        ! Determine index based on spacing
            !i = 1 + NINT((lon - storm%ll_lon) / storm%dx)
            i = 1 + INT((lon - storm%ll_lon) / storm%dx)
        endif

    end function get_lon_index

    ! ==========================================================================
    !  storm_interpolate()
    !  Determines intermediate storm values
    !   for time t between t_prev and t_next.
    !  If distinct storms are present at both times,
    !   the storm centers are shifted to an intermediate point
    !   and a weighted average is taken.
    !  Otherwise, no shift occurs and the
    !   weighted average is performed in place.
    ! ==========================================================================
    subroutine storm_interpolate(storm)

        implicit none

        ! Storm description, need "inout" here since will update the storm
        ! values at time t
        type(data_storm_type), intent(inout) :: storm

        ! Check if there are distinct storm "eyes"
        ! If not, interpolate wind & pressure fields in place.
        ! If so, spatially shift storm snapshots then interpolate. 
        if (storm%eye_prev(1) == 0 .or. storm%eye_next(1) == 0) then
            call storm_inplace_interpolate(storm)
        else
            call storm_shift_interpolate(storm)
            ! Optional: no weighted average, only shift prev snapshot in space
            !call storm_shift_only(storm)
        endif

    end subroutine storm_interpolate

    ! ==========================================================================
    !  storm_inplace_interpolate()
    !  Determines intermediate storm values
    !   for time t between t_prev and t_next
    !   based on simple weighted average.
    ! ==========================================================================
    subroutine storm_inplace_interpolate(storm)

        implicit none

        ! Storm description, need "inout" here since will update the storm
        ! values at time t
        type(data_storm_type), intent(inout) :: storm

        ! Local storage
        real(kind=8) :: alpha

        ! This is just a simple weighted average.
        ! Note that this a poor approach for a tropical cyclone:
        !  intensity is smoothed out between intervals
        !  so intermediate values may appear less intense
        ! For a more realistic storm field, use storm_shift_interpolate()

        ! Determine the linear interpolation parameter (in time)
        alpha = (storm%t-storm%t_prev) / (storm%t_next-storm%t_prev)

        ! Take weighted average of two storm fields
        storm%u = storm%u_prev + &
                (storm%u_next - storm%u_prev) * alpha
        storm%v = storm%v_prev + &
                (storm%v_next - storm%v_prev) * alpha
        storm%p = storm%p_prev + &
                (storm%p_next - storm%p_prev) * alpha


    end subroutine storm_inplace_interpolate

    ! ==========================================================================
    !  storm_shift_interpolate()
    !  Determines intermediate storm values
    !   for time t between t_prev and t_next
    !   both in time (linearly) and in space (approximate) 
    ! ==========================================================================
    subroutine storm_shift_interpolate(storm)

        implicit none

        ! Storm description, need "inout" here since will update the storm
        ! values at time t
        type(data_storm_type), intent(inout) :: storm

        ! Local storage
        real(kind=8) :: alpha
        integer :: i,j
        integer :: pi,pj,ni,nj
        integer :: prev_shift(2), next_shift(2)

        ! Determine the linear interpolation parameter (in time)
        alpha = (storm%t-storm%t_prev) / (storm%t_next-storm%t_prev)

        ! Estimate relative location of storm center at time t
        ! Note: The spatial grid is constant in time
        !  so we don't translate to lat-long
        prev_shift = NINT((storm%eye_next - storm%eye_prev) * alpha)
        next_shift = NINT((storm%eye_next - storm%eye_prev) * (alpha - 1))

        ! Now shift the two storm fields onto the intermediate
        !  storm center and use time-weighted average of their values.
        do j = 1,storm%num_lats
            ! If index would be out of bounds, use edge value
            pj = MIN(MAX(1,j-prev_shift(2)),storm%num_lats)
            nj = MIN(MAX(1,j-next_shift(2)),storm%num_lats)
            do i = 1,storm%num_lons
                ! If index would be out of bounds, use edge value
                pi = MIN(MAX(1,i-prev_shift(1)),storm%num_lons)
                ni = MIN(MAX(1,i-next_shift(1)),storm%num_lons)
                ! Perform shift & interpolate
                storm%u(i,j) = storm%u_prev(pi,pj) + &
                    (storm%u_next(ni,nj)-storm%u_prev(pi,pj)) * alpha
                storm%v(i,j) = storm%v_prev(pi,pj) + &
                    (storm%v_next(ni,nj)-storm%v_prev(pi,pj)) * alpha
                storm%p(i,j) = storm%p_prev(pi,pj) + &
                    (storm%p_next(ni,nj)-storm%p_prev(pi,pj)) * alpha
            enddo
        enddo
               

    end subroutine storm_shift_interpolate

    ! ==========================================================================
    !  storm_shift_only()
    !  Determines intermediate storm values
    !   for time t between t_prev and t_next
    !   by shifting storm data towards next position
    !  By not taking averages, this preserves large values
    ! ==========================================================================
    subroutine storm_shift_only(storm)

        implicit none

        ! Storm description, need "inout" here since will update the storm
        ! values at time t
        type(data_storm_type), intent(inout) :: storm

        ! Local storage
        real(kind=8) :: alpha
        integer :: i,j
        integer :: pi,pj
        integer :: prev_shift(2)

        ! Determine the linear interpolation parameter (in time)
        alpha = (storm%t-storm%t_prev) / (storm%t_next-storm%t_prev)

        ! Estimate relative location of storm center at time t
        ! Note: The spatial grid is constant in time
        !  so we don't translate to lat-long
        prev_shift = NINT((storm%eye_next - storm%eye_prev) * alpha)

        ! Now shift the earlier storm field
        !  onto the intermediate storm center
        do j = 1,storm%num_lats
            ! If index would be out of bounds, use edge value
            pj = MIN(MAX(1,j-prev_shift(2)),storm%num_lats)
            do i = 1,storm%num_lons
                ! If index would be out of bounds, use edge value
                pi = MIN(MAX(1,i-prev_shift(1)),storm%num_lons)
                ! Perform shift
                storm%u(i,j) = storm%u_prev(pi,pj)
                storm%v(i,j) = storm%v_prev(pi,pj)
                storm%p(i,j) = storm%p_prev(pi,pj)
            enddo
        enddo
                
    end subroutine storm_shift_only

end module data_storm_module






