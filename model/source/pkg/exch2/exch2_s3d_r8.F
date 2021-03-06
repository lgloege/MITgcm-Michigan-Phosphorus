C $Header: /u/gcmpack/MITgcm/pkg/exch2/exch2_s3d_rx.template,v 1.1 2005/11/07 02:15:55 jmc Exp $
C $Name:  $

#include "CPP_EEOPTIONS.h"
#include "W2_OPTIONS.h"

CBOP

C     !ROUTINE: EXCH2_S3D_R8

C     !INTERFACE:
      SUBROUTINE EXCH2_S3D_R8(
     U                       phi,
     I                       myThid )
      IMPLICIT NONE

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE EXCH2_S3D_R8
C     | o Handle Simple exchanges (= that ignore corners)
C     |   for _R8, 3-dim scalar arrays with overlap size = 1
C     *==========================================================*
C     | Invoke appropriate exchange routine depending on type
C     | of grid (cube or globally indexed) to be operated on.
C     *==========================================================*

C     !USES:
C     === Global data ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "W2_EXCH2_TOPOLOGY.h"
#include "W2_EXCH2_PARAMS.h"

C     !INPUT/OUTPUT PARAMETERS:
C     === Routine arguments ===
C     phi    :: Array with overlap regions are to be exchanged
C     myThid :: My thread id.
      _R8 phi(0:sNx+1,0:sNy+1,Nr,nSx,nSy)
      INTEGER myThid

C     !LOCAL VARIABLES:
C     == Local variables ==
C     OL[wens]       :: Overlap extents in west, east, north, south.
C     exchWidth[XY]  :: Extent of regions that will be exchanged.
      INTEGER OLw, OLe, OLn, OLs, exchWidthX, exchWidthY, myNz

CEOP

      OLw        = 1
      OLe        = 1
      OLn        = 1
      OLs        = 1
      exchWidthX = 1
      exchWidthY = 1
      myNz       = Nr
C     ** NOTE ** The exchange routine we use here does not
C                require the preceeding and following barriers.
C                However, the slow, simple exchange interface
C                that is calling it here is meant to ensure
C                that threads are synchronised before exchanges
C                begine.

      IF (useCubedSphereExchange) THEN

       CALL EXCH2_R81_CUBE( phi, 'T ',
     I            OLw, OLe, OLs, OLn, myNz,
     I            exchWidthX, exchWidthY,
     I            FORWARD_SIMULATION, EXCH_IGNORE_CORNERS, myThid )

      ELSE

       CALL EXCH_R8( phi,
     I            OLw, OLe, OLs, OLn, myNz,
     I            exchWidthX, exchWidthY,
     I            FORWARD_SIMULATION, EXCH_IGNORE_CORNERS, myThid )

      ENDIF

      RETURN
      END

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

CEH3 ;;; Local Variables: ***
CEH3 ;;; mode:fortran ***
CEH3 ;;; End: ***
