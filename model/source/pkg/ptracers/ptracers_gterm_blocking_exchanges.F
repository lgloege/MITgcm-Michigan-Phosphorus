C $Header: /u/gcmpack/MITgcm/pkg/ptracers/ptracers_gterm_blocking_exchanges.F,v 1.3 2004/11/02 19:09:55 edhill Exp $
C $Name:  $

#include "PTRACERS_OPTIONS.h"

CBOP
C !ROUTINE: PTRACERS_GTERM_BLOCKING_EXCHANGES

C !INTERFACE: ==========================================================
      SUBROUTINE PTRACERS_GTERM_BLOCKING_EXCH( myThid )

C !DESCRIPTION:
C     Exchange data to update overlaps for passive tracer tendancies

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS.h"

C !INPUT PARAMETERS: ===================================================
C  myThid               :: thread number
      INTEGER myThid

C !OUTPUT PARAMETERS: ==================================================
C  none

#ifdef ALLOW_PTRACERS

C !LOCAL VARIABLES: ====================================================
C  iTracer 		:: loop indices
      INTEGER iTracer
CEOP

      IF (PTRACERSisON) THEN

C Loop over passive tracers
      DO iTracer=1,PTRACERS_numInUse

C Exchange overlaps
      _EXCH_XYZ_R8(gPtr(1-Olx,1-Oly,1,1,1,iTracer),myThid)

C End of tracer loop
      ENDDO

      ENDIF
#endif /* ALLOW_PTRACERS */

      RETURN
      END
