C $Header: /u/gcmpack/MITgcm/pkg/ptracers/ptracers_advection.F,v 1.7 2005/10/10 05:53:48 mlosch Exp $
C $Name:  $

#include "PTRACERS_OPTIONS.h"

CBOP
C !ROUTINE: PTRACERS_ADVECTION

C !INTERFACE: ==========================================================
      SUBROUTINE PTRACERS_ADVECTION( bi,bj,myIter,myTime,myThid )

C !DESCRIPTION:
C     Calculates tendancy for passive tracers and integrates forward
C     in time.

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "DYNVARS.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS.h"
#include "GAD.h"

C !INPUT PARAMETERS: ===================================================
C  bi,bj                :: tile indices
C  myIter               :: time-step number
C  myTime               :: model time
C  myThid               :: thread number
      INTEGER bi,bj
      INTEGER myIter
      _RL myTime
      INTEGER myThid

C !OUTPUT PARAMETERS: ==================================================
C  none

#ifdef ALLOW_PTRACERS

C !LOCAL VARIABLES: ====================================================
C  i,j,k,bi,bj,iTracer  :: loop indices
C  iMin,iMax,jMin,jMax  :: loop ranges
C  kUp,kDown            :: toggle indices for even/odd level fluxes
C  km1                  :: =min(1,k-1)
C  rFlx			:: vertical flux
      INTEGER iTracer
CEOP

C Loop over tracers
      DO iTracer=1,PTRACERS_numInUse

       IF (
     &     multiDimAdvection .AND.
     &     PTRACERS_advScheme(iTracer).NE.ENUM_CENTERED_2ND .AND.
     &     PTRACERS_advScheme(iTracer).NE.ENUM_UPWIND_3RD .AND.
     &     PTRACERS_advScheme(iTracer).NE.ENUM_CENTERED_4TH ) THEN
            CALL GAD_ADVECTION(
     I                        PTRACERS_ImplVertAdv(iTracer),
     I                        PTRACERS_advScheme(iTracer),
     I                        PTRACERS_advScheme(iTracer),
     I                        GAD_TR1+iTracer-1,
     I                        uVel, vVel, wVel,
     I                        pTracer(1-Olx,1-Oly,1,1,1,iTracer),
     O                        gPtr(1-Olx,1-Oly,1,1,1,iTracer),
     I                        bi,bj,myTime,myIter,myThid)
       ENDIF


C end of tracer loop
      ENDDO

#endif /* ALLOW_PTRACERS */

      RETURN
      END
