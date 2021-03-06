#include "LAKEICE_OPTIONS.h"
C
      subroutine lakeice_set_gen(  ! just change the sub-routine name
C      subroutine exf_set_gen( 
     &     genfile, genstartdate, genperiod, 
     &     genstartdate1, genstartdate2,
     &     lakeice_inscal_gen, genremove_intercept, genremove_slope,
     &     genfld, gen0, gen1, genmask,
#ifdef USE_LAKEICE_INTERPOLATION
     &     gen_lon0, gen_lon_inc, gen_lat0, gen_lat_inc,
     &     gen_nlon, gen_nlat, gen_xout, gen_yout, interp_method,
#endif
     &     mytime, myiter, mythid )

c     ==================================================================
c     SUBROUTINE lakeice_set_gen
c     ==================================================================
c
c     o set external forcing gen
c
c     started: Ralf.Giering@FastOpt.de 25-Mai-2000
c     changed: heimbach@mit.edu 10-Jan-2002
c              20-Dec-2002: mods for pkg/seaice, menemenlis@jpl.nasa.gov
c              heimbach@mit.edu: totally re-organized lakeice_set_... 
c              replaced all routines by one generic routine
c              5-Aug-2003: added USE_LAKEICE_INTERPOLATION for arbitrary
c                          input grid capability

c     ==================================================================
c     SUBROUTINE lakeice_set_gen
c     ==================================================================

      implicit none

c     == global variables ==

#include "EEPARAMS.h"
#include "SIZE.h"
#include "PARAMS.h"
#include "GRID.h"
#include "lakeice_param.h"
#include "lakeice.h"
C#include "exf_param.h"
C#include "exf_constants.h"

c     == routine arguments ==

      integer genstartdate1, genstartdate2
      _RL genstartdate, genperiod
      _RL lakeice_inscal_gen
      _RL genremove_intercept, genremove_slope
      _RL genfld(1-olx:snx+olx,1-oly:sny+oly,nsx,nsy)
      _RL gen0  (1-olx:snx+olx,1-oly:sny+oly,nsx,nsy)
      _RL gen1  (1-olx:snx+olx,1-oly:sny+oly,nsx,nsy)
      character*1 genmask
      character*(128) genfile, genfile0, genfile1
      _RL     mytime
      integer myiter
      integer mythid
#ifdef USE_LAKEICE_INTERPOLATION
c     gen_lon_0 ,gen_lat_0 :: longitude and latitude of SouthWest
c                             corner of global input grid
c     gen_nlon, gen_nlat   :: input x-grid and y-grid size
c     gen_lon_inc          :: scalar x-grid increment
c     gen_lat_inc          :: vector y-grid increments
c     gen_xout, gen_yout   :: coordinates for output grid
      _RL gen_lon0, gen_lon_inc
      _RL gen_lat0, gen_lat_inc(MAX_LAT_INC)
      INTEGER gen_nlon, gen_nlat
      _RS gen_xout  (1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RS gen_yout  (1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      integer interp_method
#endif

c     == local variables ==

      logical first, changed
      integer count0, count1
      integer year0, year1
      _RL     fac

      integer bi, bj
      integer i, j, il

c     == external ==

      integer  ilnblnk
      external ilnblnk

c     == end of interface ==

      if ( genfile .NE. ' ' ) then

cph(
cph-exf-print         if (genfile .EQ. hfluxfile)  year0 = 3000
cph)
c     get record numbers and interpolation factor for gen
C         call exf_GetFFieldRec(
         call lakeice_GetFFieldRec(
     I        genstartdate, genperiod
     I        , genstartdate1, genstartdate2
     I        , useLakeiceYearlyFields
     O        , fac, first, changed
     O        , count0, count1, year0, year1
     I        , mytime, myiter, mythid
     &        )

         if ( first ) then
            if (useLakeiceYearlyFields) then
C     Complete filename with YR or _YEAR extension
               il = ilnblnk( genfile )
               if (lakeicetwoDigitYear) then
                  if (year0.ge.2000) then
                     write(genfile0(1:128),'(a,i2.2)')
     &                    genfile(1:il),year0-2000
                  else
                     write(genfile0(1:128),'(a,i2.2)')
     &                    genfile(1:il),year0-1900
                  endif
               else
                  write(genfile0(1:128),'(2a,i4.4)')
     &                 genfile(1:il),'_',year0
               endif
            else
               genfile0 = genfile
            endif
#ifdef USE_LAKEICE_INTERPOLATION
C            call exf_interp( genfile0, exf_iprec
            call lakeice_interp( genfile0, lakeice_iprec
     &           , gen1, count0, gen_xout, gen_yout
     &           , gen_lon0,gen_lon_inc
     &           , gen_lat0,gen_lat_inc
     &           , gen_nlon,gen_nlat,interp_method,mythid
     &           )
#else
            call mdsreadfield( genfile0, lakeice_iprec, lakeice_yftype,
     &            1, gen1, count0, mythid
     &           )
#endif

            if (lakeice_yftype .eq. 'RL') then
C            if (lakeice_yftype .eq. 'RL') then
C               call exf_filter_rl( gen1, genmask, mythid )
               call lakeice_filter_rl( gen1, genmask, mythid )
            else
C               call exf_filter_rs( gen1, genmask, mythid )
               call lakeice_filter_rs( gen1, genmask, mythid )
            end if
         endif

         if (( first ) .or. ( changed )) then
C            call exf_SwapFFields( gen0, gen1, mythid )
            call lakeice_SwapFFields( gen0, gen1, mythid )
            
            if (useLakeiceYearlyFields) then
C     Complete filename with YR or _YEAR extension
               il = ilnblnk( genfile )
               if (lakeicetwoDigitYear) then
                  if (year1.ge.2000) then
                     write(genfile1(1:128),'(a,i2.2)')
     &                    genfile(1:il),year1-2000
                  else
                     write(genfile1(1:128),'(a,i2.2)')
     &                    genfile(1:il),year1-1900
                  endif
               else
                  write(genfile1(1:128),'(2a,i4.4)')
     &                 genfile(1:il),'_',year1
               endif
            else
               genfile1 = genfile
            endif
#ifdef USE_LAKEICE_INTERPOLATION
C            call exf_interp( genfile1, exf_iprec
            call lakeice_interp( genfile1, lakeice_iprec
     &           , gen1, count1, gen_xout, gen_yout
     &           , gen_lon0,gen_lon_inc
     &           , gen_lat0,gen_lat_inc
     &           , gen_nlon,gen_nlat,interp_method,mythid
     &           )
#else
            call mdsreadfield( genfile1, lakeice_iprec, lakeice_yftype, 
     &           1, gen1, count1, mythid
     &           )
#endif

            if (lakeice_yftype .eq. 'RL') then
C               call exf_filter_rl( gen1, genmask, mythid )
               call lakeice_filter_rl( gen1, genmask, mythid )
            else
C               call exf_filter_rs( gen1, genmask, mythid )
               call lakeice_filter_rs( gen1, genmask, mythid )
            end if
         endif

c     Loop over tiles.
         do bj = mybylo(mythid),mybyhi(mythid)
          do bi = mybxlo(mythid),mybxhi(mythid)
           do j = 1,sny
            do i = 1,snx
c     Interpolate linearly onto the  time.
             genfld(i,j,bi,bj) = lakeice_inscal_gen * (
     &                          fac * gen0(i,j,bi,bj) +
     &              (lakeice_one - fac) * gen1(i,j,bi,bj) )
             genfld(i,j,bi,bj) = 
     &            genfld(i,j,bi,bj) -
     &            lakeice_inscal_gen * ( genremove_intercept +
     &            genremove_slope*(mytime-starttime) )
                  enddo
               enddo
            enddo
         enddo

      endif

      end
