C $Header: /u/gcmpack/MITgcm/pkg/my82/my82_readparms.F,v 1.1 2004/09/02 09:11:54 mlosch Exp $
C $Name:  $

#include "MY82_OPTIONS.h"

CBOP
C !ROUTINE: MY82_READPARMS

C !INTERFACE: ==========================================================
      SUBROUTINE MY82_READPARMS( myThid )

C !DESCRIPTION:
C     Initialize MY82 parameters, read in data.pp

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "MY82.h"
#include "PARAMS.h"

C !INPUT PARAMETERS: ===================================================
C  myThid               :: thread number
      INTEGER myThid

C !OUTPUT PARAMETERS: ==================================================
C  none

#ifdef ALLOW_MY82

C !LOCAL VARIABLES: ====================================================
C  iUnit		:: unit number for I/O
C  msgBuf		:: message buffer
      INTEGER iUnit
      CHARACTER*(MAX_LEN_MBUF) msgBuf
CEOP

      NAMELIST /MY_PARM01/
     &     MYviscMax, 
     &     MYdiffMax, 
     &     MYhblScale,
     &     MYdumpFreq,
     &     MYMixingMaps,
     &     MYwriteState,
     &     MYtaveFreq

C This routine has been called by the main model so we set our
C internal flag to indicate we are in business
      MYisON=.TRUE.

C Set defaults values for parameters in MY82.h
      MYviscMax    = 1. _d 0
      MYdiffMax    = 1. _d 0
      MYhblScale   = 0.1
      RiMax        = 0.1950
      MYdumpFreq   = dumpFreq
      MYtaveFreq   = taveFreq
      MYMixingMaps = .FALSE.
      MYwriteState = .FALSE.

C Open and read the data.pp file
      _BEGIN_MASTER(myThid)
      WRITE(msgBuf,'(A)') ' MY82_READPARMS: opening data.my82'
      CALL PRINT_MESSAGE(msgBuf, standardMessageUnit,
     &                   SQUEEZE_RIGHT , 1)
      CALL OPEN_COPY_DATA_FILE(
     I                   'data.my82', 'MY82_READPARMS',
     O                   iUnit,
     I                   myThid )
      READ(UNIT=iUnit,NML=MY_PARM01)
      WRITE(msgBuf,'(A)')
     &  ' MY82_READPARMS: finished reading data.my82'
      CALL PRINT_MESSAGE(msgBuf, standardMessageUnit,
     &                   SQUEEZE_RIGHT , 1)

C Close the open data file
      CLOSE(iUnit)
      _END_MASTER(myThid)

C Everyone else must wait for the parameters to be loaded
      _BARRIER

C Now set-up any remaining parameters that result from the input parameters 
      IF ( MYviscMax .LE. 0. ) THEN
       WRITE(msgBuf,'(A)') 'MYviscMax must be greater than zero'
       CALL PRINT_ERROR( msgBuf , 1)
       STOP 'ABNORMAL END: S/R MY82_READPARMS'
      ENDIF
      IF ( MYdiffMax .LE. 0. ) THEN
       WRITE(msgBuf,'(A)') 'MYdiffMax must be greater than zero'
       CALL PRINT_ERROR( msgBuf , 1)
       STOP 'ABNORMAL END: S/R MY82_READPARMS'
      ENDIF
#endif /* ALLOW_MY82 */

      RETURN
      END
