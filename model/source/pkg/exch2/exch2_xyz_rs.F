C $Header: /u/gcmpack/MITgcm/pkg/exch2/exch2_xyz_rx.template,v 1.4 2005/07/27 01:11:19 jmc Exp $
C $Name:  $

#include "CPP_EEOPTIONS.h"
#include "W2_OPTIONS.h"

CBOP

C     !ROUTINE: EXCH_XYZ_RS

C     !INTERFACE:
      SUBROUTINE EXCH2_XYZ_RS(
     U                       phi,
     I                       myThid )
      IMPLICIT NONE

C     !DESCRIPTION:
C     *==========================================================*
C     | SUBROUTINE EXCH_XYZ_RS
C     | o Handle exchanges for _RS, three-dim scalar arrays.
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
      _RS phi(1-OLx:sNx+OLx,1-OLy:sNy+OLy,1:Nr,nSx,nSy)
      INTEGER myThid

C     !LOCAL VARIABLES:
C     == Local variables ==
C     OL[wens]       :: Overlap extents in west, east, north, south.
C     exchWidth[XY]  :: Extent of regions that will be exchanged.
      INTEGER OLw, OLe, OLn, OLs, exchWidthX, exchWidthY, myNz
#ifdef W2_FILL_NULL_REGIONS
      INTEGER bi, bj, myTile, i, j, k
#endif

CEOP

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

       CALL EXCH2_RS1_CUBE( phi, 'T ',
     I            OLw, OLe, OLs, OLn, myNz,
     I            exchWidthX, exchWidthY,
     I            FORWARD_SIMULATION, EXCH_UPDATE_CORNERS, myThid )

#ifdef W2_FILL_NULL_REGIONS
       DO bj=myByLo(myThid),myByHi(myThid)
        DO bi=myBxLo(myThid),myBxHi(myThid)
         myTile = W2_myTileList(bi)
C        South-east corner
         IF ( exch2_isEedge(myTile) .EQ. 1 .AND.
     &        exch2_isSedge(myTile) .EQ. 1 ) THEN
          DO j=1-OLy,0
           DO i=sNx+1,sNx+OLx
            DO k=1,Nr
             phi(i,j,k,bi,bj)=e2FillValue_RS
            ENDDO
           ENDDO
          ENDDO
         ENDIF
C        North-east corner
         IF ( exch2_isEedge(myTile) .EQ. 1 .AND.
     &        exch2_isNedge(myTile) .EQ. 1 ) THEN
          DO j=sNy+1,sNy+OLy
           DO i=sNx+1,sNx+OLx
            DO k=1,Nr
             phi(i,j,k,bi,bj)=e2FillValue_RS
            ENDDO
           ENDDO
          ENDDO
         ENDIF
C        South-west corner
         IF ( exch2_isWedge(myTile) .EQ. 1 .AND.
     &        exch2_isSedge(myTile) .EQ. 1 ) THEN
          DO j=1-OLy,0
           DO i=1-OLx,0
            DO k=1,Nr
             phi(i,j,k,bi,bj)=e2FillValue_RS
            ENDDO
           ENDDO
          ENDDO
         ENDIF
C        North-west corner
         IF ( exch2_isWedge(myTile) .EQ. 1 .AND.
     &        exch2_isNedge(myTile) .EQ. 1 ) THEN
          DO j=sNy+1,sNy+OLy
           DO i=1-OLx,0
            DO k=1,Nr
             phi(i,j,k,bi,bj)=e2FillValue_RS
            ENDDO
           ENDDO
          ENDDO
         ENDIF
        ENDDO
       ENDDO
#endif /* W2_FILL_NULL_REGIONS */

       CALL EXCH2_RS1_CUBE( phi, 'T ',
     I            OLw, OLe, OLs, OLn, myNz,
     I            exchWidthX, exchWidthY,
     I            FORWARD_SIMULATION, EXCH_UPDATE_CORNERS, myThid )

#ifdef W2_FILL_NULL_REGIONS
       DO bj=myByLo(myThid),myByHi(myThid)
        DO bi=myBxLo(myThid),myBxHi(myThid)
         myTile = W2_myTileList(bi)
C        South-east corner
         IF ( exch2_isEedge(myTile) .EQ. 1 .AND.
     &        exch2_isSedge(myTile) .EQ. 1 ) THEN
          DO j=1-OLy,0
           DO i=sNx+1,sNx+OLx
            DO k=1,Nr
             phi(i,j,k,bi,bj)=e2FillValue_RS
            ENDDO
           ENDDO
          ENDDO
         ENDIF
C        North-east corner
         IF ( exch2_isEedge(myTile) .EQ. 1 .AND.
     &        exch2_isNedge(myTile) .EQ. 1 ) THEN
          DO j=sNy+1,sNy+OLy
           DO i=sNx+1,sNx+OLx
            DO k=1,Nr
             phi(i,j,k,bi,bj)=e2FillValue_RS
            ENDDO
           ENDDO
          ENDDO
         ENDIF
C        South-west corner
         IF ( exch2_isWedge(myTile) .EQ. 1 .AND.
     &        exch2_isSedge(myTile) .EQ. 1 ) THEN
          DO j=1-OLy,0
           DO i=1-OLx,0
            DO k=1,Nr
             phi(i,j,k,bi,bj)=e2FillValue_RS
            ENDDO
           ENDDO
          ENDDO
         ENDIF
C        North-west corner
         IF ( exch2_isWedge(myTile) .EQ. 1 .AND.
     &        exch2_isNedge(myTile) .EQ. 1 ) THEN
          DO j=sNy+1,sNy+OLy
           DO i=1-OLx,0
            DO k=1,Nr
             phi(i,j,k,bi,bj)=e2FillValue_RS
            ENDDO
           ENDDO
          ENDDO
         ENDIF
        ENDDO
       ENDDO
#endif /* W2_FILL_NULL_REGIONS */

      ELSE

       CALL EXCH_RS( phi,
     I            OLw, OLe, OLs, OLn, myNz,
     I            exchWidthX, exchWidthY,
     I            FORWARD_SIMULATION, EXCH_UPDATE_CORNERS, myThid )

      ENDIF

      RETURN
      END

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

CEH3 ;;; Local Variables: ***
CEH3 ;;; mode:fortran ***
CEH3 ;;; End: ***
