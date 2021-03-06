module kessler_update

   use ccpp_kinds, only: kind_phys

   implicit none
   private

   public :: kessler_update_init
   public :: kessler_update_timestep_init
   public :: kessler_update_run
   public :: kessler_update_timestep_final

   ! Private module variables
   real(kind_phys)    :: gravit
   real(kind_phys)    :: cpair

CONTAINS

   !> \section arg_table_kessler_update_init  Argument Table
   !! \htmlinclude kessler_update_init.html
   subroutine kessler_update_init(gravit_in, cpair_in)
      real(kind_phys),    intent(in)    :: gravit_in
      real(kind_phys),    intent(in)    :: cpair_in

      gravit = gravit_in
      cpair = cpair_in

   end subroutine kessler_update_init

   !> \section arg_table_kessler_update_timestep_init  Argument Table
   !! \htmlinclude kessler_update_timestep_init.html
   subroutine kessler_update_timestep_init(temp, temp_prev, ttend_t,          &
        errmsg, errflg)

      real(kind_phys),    intent(in)  :: temp(:,:)
      real(kind_phys),    intent(out) :: temp_prev(:,:)
      real(kind_phys),    intent(out) :: ttend_t(:,:)
      character(len=512), intent(out) :: errmsg
      integer,            intent(out) :: errflg

      !   Initialize the previous temperature and its tendency to zero
      temp_prev(:,:)  = temp(:,:)
      ttend_t(:,:)    = 0._kind_phys

      errmsg = ''
      errflg = 0

   end subroutine kessler_update_timestep_init

   !> \section arg_table_kessler_update_run  Argument Table
   !! \htmlinclude kessler_update_run.html
   subroutine kessler_update_run(nz, ncol, phis, temp, theta, exner, dt,      &
        temp_prev, ttend_t, errmsg, errflg)

      integer,            intent(in)    :: nz
      integer,            intent(in)    :: ncol
      real(kind_phys),    intent(in)    :: phis(:)
      real(kind_phys),    intent(in)    :: temp(:,:) ! temperature
      real(kind_phys),    intent(in)    :: exner(:,:)
      real(kind_phys),    intent(in)    :: dt

      real(kind_phys),    intent(inout) :: theta(:,:)
      real(kind_phys),    intent(inout) :: temp_prev(:,:)
      real(kind_phys),    intent(inout) :: ttend_t(:,:)

      character(len=512), intent(out)   :: errmsg
      integer,            intent(out)   :: errflg

      integer                           :: klev
      real(kind_phys)                   :: ptend_s(ncol)

      errmsg = ''
      errflg = 0

      ! Back out tendencies from updated fields
      do klev = 1, nz
         ptend_s(:ncol) = ((theta(:ncol,klev) * exner(:ncol,klev)) -          &
              temp_prev(:ncol,klev)) * cpair / dt
         ttend_t(:ncol,klev) = ttend_t(:ncol,klev) + (ptend_s(:ncol) / cpair)
      end do

      ! Save the temperature for the next time step
      !!XXgoldyXX ==> @cacraigucar: Does this have any effect?
      temp_prev(:,:)     = temp(:,:)

!    surf_state%precl(:ncol) = surf_state%precl(:ncol) + precl(:ncol)  ! KEEPING THIS HERE AS A REMINDER

   end subroutine kessler_update_run

   !> \section arg_table_kessler_update_timestep_final  Argument Table
   !! \htmlinclude kessler_update_timestep_final.html
   subroutine kessler_update_timestep_final(nz, temp, zm, phis, st_energy,    &
        errflg, errmsg)

      ! Dummy arguments
      integer,            intent(in)    :: nz
      real(kind_phys),    intent(in)    :: temp(:,:) ! temperature
      real(kind_phys),    intent(in)    :: zm(:,:)
      real(kind_phys),    intent(in)    :: phis(:)
      real(kind_phys),    intent(out)   :: st_energy(:,:)

      character(len=512), intent(out)   :: errmsg
      integer,            intent(out)   :: errflg

      ! Local variable
      integer :: klev

      errmsg = ''
      errflg = 0

      do klev = 1, nz
         st_energy(:,klev) = (temp(:,klev) * cpair) + (gravit * zm(:,klev)) + &
              phis(:)
      end do

   end subroutine kessler_update_timestep_final


end module kessler_update
