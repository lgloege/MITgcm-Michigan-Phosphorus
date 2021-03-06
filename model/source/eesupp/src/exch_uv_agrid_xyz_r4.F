C $Header: /u/gcmpack/MITgcm/eesupp/src/exch_uv_agrid_xyz_rx.template,v 1.6 2004/11/19 02:32:05 jmc Exp $
C $Name:  $

#include "PACKAGES_CONFIG.h"
#include "CPP_EEOPTIONS.h"

      SUBROUTINE EXCH_UV_AGRID_XYZ_R4( component1,component2, withSigns,
     .                                                          myThid )

      implicit none

C*=====================================================================*
C  Purpose: subroutine exch_uv_agrid_xyz_R4 will
C      handle exchanges for a 3D vector field on an A-grid.  
C
C  Input: component1(lon,lat,levs,bi,bj) - first component of vector
C         component2(lon,lat,levs,bi,bj) - second component of vector
C         withSigns (logical)            - true to use signs of components
C         myThid                         - Thread number
C
C  Output: component1 and component2 are updated (halo regions filled)
C
C  Calls: exch (either exch_rx_cube or exch_rx) - twice, once
C         for the first-component, once for second.
C
C  NOTES: 1) This code, as written, only works on ONE PROCESSOR!
C         2) This code assumes that the faces are square (sNx=sNy....)
C               (also - we do not worry about barriers)
C*=====================================================================*

#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "EXCH.h"

C     == Argument list variables ==
      _R4 component1(1-OLx:sNx+OLx,1-OLy:sNy+OLy,1:Nr,nSx,nSy)
      _R4 component2(1-OLx:sNx+OLx,1-OLy:sNy+OLy,1:Nr,nSx,nSy)
      LOGICAL withSigns
      INTEGER myThid

C     == Local variables ==
C     i,j,L,bi,bj  are do indices.
C     OL[wens] - Overlap extents in west, east, north, south.
C     exchWidth[XY] - Extent of regions that will be exchanged.
C     dummy[12] - copies of the vector components with haloes filled.
C     b[nsew] - indices of the [nswe] neighboring faces for each face.

      integer i,j,L,bi,bj
      integer OLw, OLe, OLn, OLs, exchWidthX, exchWidthY, myNz
      _R4 dummy1(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _R4 dummy2(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _R4 negOne

#ifdef ALLOW_EXCH2
      CALL EXCH2_UV_AGRID_XYZ_R4(
     U                           component1, component2,
     I                           withSigns, myThid )
      RETURN
#endif

      OLw        = OLx
      OLe        = OLx
      OLn        = OLy
      OLs        = OLy
      exchWidthX = OLx
      exchWidthY = OLy
      myNz       = Nr
      negOne = 1.
      IF (withSigns) negOne = -1.

C First call the exchanges for the two components

      if (useCubedSphereExchange) then
       call exch_R4_cube( component1,
     .            OLw, OLe, OLs, OLn, myNz,
     .            exchWidthX, exchWidthY,
     .            FORWARD_SIMULATION, EXCH_UPDATE_CORNERS, myThid )
       call exch_R4_cube( component2,
     .            OLw, OLe, OLs, OLn, myNz,
     .            exchWidthX, exchWidthY,
     .            FORWARD_SIMULATION, EXCH_UPDATE_CORNERS, myThid )
      else
       call exch_R4( component1,
     .            OLw, OLe, OLs, OLn, myNz,
     .            exchWidthX, exchWidthY,
     .            FORWARD_SIMULATION, EXCH_UPDATE_CORNERS, myThid )
       call exch_R4( component2,
     .            OLw, OLe, OLs, OLn, myNz,
     .            exchWidthX, exchWidthY,
     .            FORWARD_SIMULATION, EXCH_UPDATE_CORNERS, myThid )
      endif

C Then if we are on the sphere we may need to switch u and v components
C and/or the signs depending on which cube face we are located.

      if (useCubedSphereExchange) then

       do bj = myByLo(myThid), myByHi(myThid)
       do bi = myBxLo(myThid), myBxHi(myThid)
       do L = 1,Nr

C First we need to copy the component info into dummy arrays
       do j = 1-OLy,sNy+OLy
       do i = 1-OLx,sNx+OLx
        dummy1(i,j) = component1(i,j,L,bi,bj)
        dummy2(i,j) = component2(i,j,L,bi,bj)
       enddo
       enddo

C Now choose what to do at each edge of the halo based on which face
C    (we assume that bj is always=1)

C odd faces share disposition of all sections of the halo
       if ( mod(bi,2).eq.1 ) then
         do j = 1,sNy
         do i = 1,exchWidthX
C east
          component1(sNx+i,j,L,bi,bj) = dummy1(sNx+i,j)
          component2(sNx+i,j,L,bi,bj) = dummy2(sNx+i,j)
C west
          component1(i-OLx,j,L,bi,bj) = dummy2(i-OLx,j)
          component2(i-OLx,j,L,bi,bj) = negOne*dummy1(i-OLx,j)
C north
          component1(j,sNy+i,L,bi,bj) = negOne*dummy2(j,sNy+i)
          component2(j,sNy+i,L,bi,bj) = dummy1(j,sNy+i)
C south
          component1(j,i-OLx,L,bi,bj) = dummy1(j,i-OLx)
          component2(j,i-OLx,L,bi,bj) = dummy2(j,i-OLx)
         enddo
         enddo
C now the even faces (share disposition of all sections of the halo)
       elseif ( mod(bi,2).eq.0 ) then
         do j = 1,sNy
         do i = 1,exchWidthX
C east
          component1(sNx+i,j,L,bi,bj) = dummy2(sNx+i,j)
          component2(sNx+i,j,L,bi,bj) = negOne*dummy1(sNx+i,j)
C west
          component1(i-OLx,j,L,bi,bj) = dummy1(i-OLx,j)
          component2(i-OLx,j,L,bi,bj) = dummy2(i-OLx,j)
C north
          component1(j,sNy+i,L,bi,bj) = dummy1(j,sNy+i)
          component2(j,sNy+i,L,bi,bj) = dummy2(j,sNy+i)
C south
          component1(j,i-OLy,L,bi,bj) = negOne*dummy2(j,i-OLy)
          component2(j,i-OLy,L,bi,bj) = dummy1(j,i-OLy)
         enddo
         enddo
       endif

       enddo
       enddo
       enddo

      endif

      RETURN
      END

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

CEH3 ;;; Local Variables: ***
CEH3 ;;; mode:fortran ***
CEH3 ;;; End: ***
