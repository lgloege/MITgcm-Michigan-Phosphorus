C $Header: /u/gcmpack/MITgcm/eesupp/src/exch_uv_xyz_rx.template,v 1.5 2004/11/16 17:21:40 jmc Exp $
C $Name:  $

#include "PACKAGES_CONFIG.h"
#include "CPP_EEOPTIONS.h"

CBOP

C     !ROUTINE: EXCH_UV_XYZ_RS

C     !INTERFACE:
      SUBROUTINE EXCH_UV_XYZ_RS(
     U                       Uphi, Vphi,
     I                       withSigns, myThid )
      IMPLICIT NONE
C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE EXCH_UV_XYZ_RS                                 
C     | o Handle exchanges for _RS, 3-dimensional vector arrays.    
C     *==========================================================*
C     | Vector arrays need to be rotated and interchaged for 
C     | exchange operations on some grids. This driver routine
C     | branches to support this.
C     *==========================================================*

C     !USES:
C     === Global data ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "EXCH.h"

C     !INPUT/OUTPUT PARAMETERS:
C     === Routine arguments ===
C     phi    :: Array with overlap regions are to be exchanged
C               Note - The interface to EXCH_RS assumes that
C               the standard Fortran 77 sequence association rules
C               apply.
C     myThid :: My thread id.
      _RS Uphi(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RS Vphi(1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      LOGICAL withSigns
      INTEGER myThid

C     !LOCAL VARIABLES:
C     == Local variables ==
C     OL[wens]       :: Overlap extents in west, east, north, south.
C     exchWidth[XY]  :: Extent of regions that will be exchanged.
      INTEGER OLw, OLe, OLn, OLs, exchWidthX, exchWidthY, myNz

CEOP
#ifdef ALLOW_EXCH2
      CALL EXCH2_UV_XYZ_RS(
     U                       Uphi, Vphi,
     I                       withSigns, myThid )
      RETURN
#endif

      OLw        = OLx
      OLe        = OLx
      OLn        = OLy
      OLs        = OLy
      exchWidthX = OLx
      exchWidthY = OLy
      myNz       = Nr
C     ** NOTE ** The exchange routine we use here does not
C                require the preceeding and following barriers.
C                However, the slow, simple exchange interface
C                that is calling it here is meant to ensure
C                that threads are synchronised before exchanges
C                begine.
      IF (useCubedSphereExchange) THEN
       CALL EXCH_UV_RS_CUBE( Uphi, Vphi, withSigns,
     I            OLw, OLe, OLs, OLn, myNz,
     I            exchWidthX, exchWidthY,
     I            FORWARD_SIMULATION, EXCH_UPDATE_CORNERS, myThid )
      ELSE
c      CALL EXCH_RS( Uphi,
c    I            OLw, OLe, OLs, OLn, myNz,
c    I            exchWidthX, exchWidthY,
c    I            FORWARD_SIMULATION, EXCH_UPDATE_CORNERS, myThid )
c      CALL EXCH_RS( Vphi,
c    I            OLw, OLe, OLs, OLn, myNz,
c    I            exchWidthX, exchWidthY,
c    I            FORWARD_SIMULATION, EXCH_UPDATE_CORNERS, myThid )
c_jmc: for JAM compatibility, replace the 2 CALLs above by the 2 CPP_MACROs:
       _EXCH_XYZ_RS( Uphi, myThid )
       _EXCH_XYZ_RS( Vphi, myThid )
      ENDIF

      RETURN
      END

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

CEH3 ;;; Local Variables: ***
CEH3 ;;; mode:fortran ***
CEH3 ;;; End: ***
