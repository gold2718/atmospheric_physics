module geopotential_t

   !---------------------------------------------------------------------------
   ! Compute geopotential from temperature
   !
   ! The hydrostatic matrix elements must be consistent with the dynamics
   !      algorithm.
   ! The diagonal element is the itegration weight from interface kint minus
   !      lyr_step to midpoint kint.
   ! The offdiagonal element is the weight between interfaces.
   !
   ! Author: B.Boville, Feb 2001 from earlier code by Boville and S.J. Lin
   !---------------------------------------------------------------------------

   use ccpp_kinds, only: kind_phys

   implicit none
   private
   save

   public geopotential_t_run

CONTAINS
   !===========================================================================

   !> \section arg_table_geopotential_t_run  Argument Table
   !! \htmlinclude geopotential_t_run.html
   subroutine geopotential_t_run(pver, pverp, lagrang, layer_surf, layer_toa,          &
        interface_surf, interface_toa, piln, pmln, pint, pmid, pdel, rpdel,   &
        t, q, rair, gravit, zvir, zi, zm, ncol, errflg, errmsg)

      !-----------------------------------------------------------------------
      !
      ! Purpose:
      ! Compute the geopotential height (above the surface) at the midpoints and
      ! interfaces using the input temperatures and pressures.
      !
      !-----------------------------------------------------------------------

      !------------------------------Arguments--------------------------------
      !
      ! Input arguments
      !
      integer,         intent(in)  :: pver
      integer,         intent(in)  :: pverp
      logical,         intent(in)  :: lagrang     ! lagrangian vertical coordinate?
      integer,         intent(in)  :: layer_surf
      integer,         intent(in)  :: layer_toa
      integer,         intent(in)  :: interface_surf
      integer,         intent(in)  :: interface_toa
      integer,         intent(in)  :: ncol       ! Number of longitudes

      ! piln: Log interface pressures
      real(kind_phys), intent(in)  :: piln(:,:)  ! (ncol,pverp)
      ! pmln: Log midpoint pressures
      real(kind_phys), intent(in)  :: pmln(:,:)  ! (ncol,pver)
      ! pint: Interface pressures
      real(kind_phys), intent(in)  :: pint(:,:)  ! (ncol,pverp)
      ! pmid: Midpoint pressures
      real(kind_phys), intent(in)  :: pmid(:,:)  ! (ncol,pver)
      ! pdel: layer thickness
      real(kind_phys), intent(in)  :: pdel(:,:)  ! (ncol,pver)
      ! rpdel: inverse of layer thickness
      real(kind_phys), intent(in)  :: rpdel(:,:) ! (ncol,pver)
      ! t: temperature
      real(kind_phys), intent(in)  :: t(:,:)     ! (ncol,pver)
      ! q: specific humidity
      real(kind_phys), intent(in)  :: q(:,:)     ! (ncol,pver)
      ! rair: Gas constant for dry air
      real(kind_phys), intent(in)  :: rair(:,:)  ! (ncol,pver)
      ! gravit: Acceleration of gravity
      real(kind_phys), intent(in)  :: gravit
      ! zvir: rh2o/rair - 1
      real(kind_phys), intent(in)  :: zvir(:,:)  ! (ncol,pver)

      ! Output arguments

      ! zi: Height above surface at interfaces
      real(kind_phys), intent(out) :: zi(:,:)    ! (ncol,pverp)
      ! zm: Geopotential height at mid level
      real(kind_phys), intent(out) :: zm(:,:)    ! (ncol,pver)
      integer,            intent(out) :: errflg
      character(len=512), intent(out) :: errmsg
      !
      !---------------------------Local variables-----------------------------
      !
      integer                      :: icol     ! Horizontal index
      integer                      :: klyr      ! Vertical layer index
      integer                      :: kint      ! Vertical interface index
      integer                      :: lyr_step  ! increment to move up a level
      integer                      :: int_step  ! increment to move up a level
      real(kind_phys)              :: hkk(ncol) ! diagonal element of hydrostatic matrix
      real(kind_phys)              :: hkl(ncol) ! off-diagonal element
      real(kind_phys)              :: rog(ncol,pver) ! Rair / gravit
      real(kind_phys)              :: tv        ! virtual temperature
      real(kind_phys)              :: tvfac     ! Tv / T
      !
      !-----------------------------------------------------------------------
      !

      errmsg = ''
      errflg = 0

      rog(:ncol,:) = rair(:ncol,:) / gravit

      if (layer_surf > layer_toa) then
         lyr_step = -1
      else
         lyr_step = 1
      end if
      if (interface_surf > interface_toa) then
         int_step = -1
      else
         int_step = 1
      end if

      ! The surface height is zero by definition.
      zi(:ncol, interface_surf) = 0.0_kind_phys

      ! Compute zi, zm from bottom up.
      ! Note, zi(i,k) is the interface above zm(i,k) when ordered top to bot

      klyr = layer_surf
      do kint = interface_surf + int_step, interface_toa, int_step

         ! First set hydrostatic elements consistent with dynamics
         if (lagrang) then
            do icol = 1, ncol
               hkl(icol) = piln(icol, kint-int_step) - piln(icol,kint)
               hkk(icol) = 1._kind_phys -                                     &
                    (pint(icol,kint) * hkl(icol) * rpdel(icol,klyr))
            end do
         else
            do icol = 1,ncol
               hkl(icol) = pdel(icol,klyr) / pmid(icol,klyr)
               hkk(icol) = 0.5_kind_phys * hkl(icol)
            end do
         end if

         ! Now compute tv, zm, zi

         do icol = 1, ncol
            tvfac   = 1._kind_phys + zvir(icol,klyr) * q(icol,klyr)
            tv      = t(icol,klyr) * tvfac

            zm(icol,klyr) = zi(icol,kint-int_step) +                          &
                 (rog(icol,klyr) * tv * hkk(icol))
            zi(icol,kint) = zi(icol,kint-int_step) +                          &
                 (rog(icol,klyr) * tv * hkl(icol))
         end do
         klyr = klyr + lyr_step
      end do

   end subroutine geopotential_t_run

end module geopotential_t
