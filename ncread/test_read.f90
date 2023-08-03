program read_msmnc
  use netcdf
  implicit none

  ! dimension
  integer :: nx, ny, nt
  character(len=1024) :: f_in
  real(kind=4), allocatable :: lon(:), lat(:), timelap(:)
  real(kind=4), allocatable :: psea(:,:,:)
  real(kind=4), allocatable :: u10(:,:,:), v10(:,:,:)
  ! parameters for read
  integer :: ncid, varid, dimid
  integer :: start_nc(3), count_nc(3)
  real(kind=4) :: scale_factor, add_offset
  ! loop counter
  integer :: k

  ! netcdf filename
  if(iargc()>0)then
    call getarg(1,f_in)
  else    
    stop 'No filename specified.'
  end if
 
  ! open
  call check_ncstatus( nf90_open( trim( f_in ), nf90_nowrite, ncid) )

  ! number of array
  ! -- lon
  call check_ncstatus( nf90_inq_dimid(ncid, 'lon', dimid) )
  call check_ncstatus( nf90_inquire_dimension(ncid, dimid, len=nx) )
  allocate(lon(nx))
  call check_ncstatus( nf90_get_var(ncid, dimid, lon) )
  ! -- lat
  call check_ncstatus( nf90_inq_dimid(ncid, 'lat', dimid) )
  call check_ncstatus( nf90_inquire_dimension(ncid, dimid, len=ny) )
  allocate(lat(ny))
  call check_ncstatus( nf90_get_var(ncid, dimid, lat) )
  ! -- timelap
  call check_ncstatus( nf90_inq_dimid(ncid, 'time', dimid) )
  call check_ncstatus( nf90_inquire_dimension(ncid, dimid, len=nt) )
  allocate(timelap(nt))
  call check_ncstatus( nf90_get_var(ncid, dimid, timelap) )

  ! allocate
  allocate(psea(nx,ny,nt))
  allocate(u10(nx,ny,nt), v10(nx,ny,nt))

  ! indices
  start_nc = [1,1,1]
  count_nc = [nx,ny,nt]

  ! read variables
  ! -- psea
  call check_ncstatus( nf90_inq_varid(ncid, "psea", varid) )
  call check_ncstatus( nf90_get_var(ncid, varid, psea, start=start_nc, count=count_nc) )
  call check_ncstatus( nf90_get_att(ncid, varid, "scale_factor", scale_factor) )
  call check_ncstatus( nf90_get_att(ncid, varid, "add_offset", add_offset) )
  psea(:,:,:) = psea(:,:,:)*scale_factor + add_offset
  ! -- u10
  call check_ncstatus( nf90_inq_varid(ncid, "u", varid) )
  call check_ncstatus( nf90_get_var(ncid, varid, u10, start=start_nc, count=count_nc) )
  call check_ncstatus( nf90_get_att(ncid, varid, "scale_factor", scale_factor) )
  call check_ncstatus( nf90_get_att(ncid, varid, "add_offset", add_offset) )
  u10(:,:,:) = u10(:,:,:)*scale_factor + add_offset
  ! -- v10
  call check_ncstatus( nf90_inq_varid(ncid, "v", varid) )
  call check_ncstatus( nf90_get_var(ncid, varid, v10, start=start_nc, count=count_nc) )
  call check_ncstatus( nf90_get_att(ncid, varid, "scale_factor", scale_factor) )
  call check_ncstatus( nf90_get_att(ncid, varid, "add_offset", add_offset) )
  v10(:,:,:) = v10(:,:,:)*scale_factor + add_offset

  ! close nc file
  call check_ncstatus( nf90_close(ncid) )

  ! --- print for check
  write(*,*) nx, ny, nt
  write(*,*) timelap(lbound(timelap)), timelap(ubound(timelap))
  write(*,*) minval(lon), maxval(lon), minval(lat), maxval(lat)
  do k = 1, nt
    write(*,*) timelap(k), maxval(psea(:,:,k)), minval(psea(:,:,k)), &
  &               maxval(u10(:,:,k)), minval(u10(:,:,k)), maxval(v10(:,:,k)), minval(v10(:,:,k))
  end do

  contains
! ------------------------------------------------------------------------------
  subroutine check_ncstatus( status )
    integer, intent (in) :: status
    if(status /= nf90_noerr) then 
       print *, trim(nf90_strerror(status))
       stop "Something went wrong while reading ncfile."
    end if
  end subroutine check_ncstatus
! ------------------------------------------------------------------------------
end program read_msmnc