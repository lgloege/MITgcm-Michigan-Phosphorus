C $Header: /u/gcmpack/MITgcm/pkg/exch2/exch2_send_rx1.template,v 1.5 2005/07/24 01:21:36 jmc Exp $
C $Name:  $

#include "CPP_EEOPTIONS.h"
#include "W2_OPTIONS.h"

      SUBROUTINE EXCH2_SEND_R41 (
     I       tIlo, tIhi, tiStride,
     I       tJlo, tJhi, tjStride,
     I       tKlo, tKhi, tkStride,
     I       thisTile, nN,
     I       e2Bufr1_R4, e2BufrRecSize,
     I       array,
     I       i1Lo, i1Hi, j1Lo, j1Hi, k1Lo, k1Hi,
     O       e2_msgHandle,
     I       commSetting, myThid )

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "W2_EXCH2_TOPOLOGY.h"

C     === Routine arguments ===
      INTEGER tILo, tIHi, tiStride
      INTEGER tJLo, tJHi, tjStride
      INTEGER tKLo, tKHi, tkStride
      INTEGER i1Lo, i1Hi, j1Lo, j1Hi, k1Lo, k1Hi
      INTEGER thisTile, nN
      INTEGER e2BufrRecSize 
      _R4     e2Bufr1_R4( e2BufrRecSize )
      _R4     array(i1Lo:i1Hi,j1Lo:j1Hi,k1Lo:k1Hi)
      INTEGER e2_msgHandle(1)
      INTEGER myThid
      CHARACTER commSetting

C     == Local variables ==
C     itl, jtl, ktl  :: Loop counters
C                    :: itl etc... target local
C                    :: itc etc... target canonical
C                    :: isl etc... source local
C                    :: isc etc... source canonical
      INTEGER itl, jtl, ktl
      INTEGER itc, jtc
      INTEGER isc, jsc
      INTEGER isl, jsl
c     INTEGER ktc, ksc, ksl
C     tt         :: Target tile
C     itb, jtb   :: Target local to canonical offsets
C
      INTEGER  tt
      INTEGER itb, jtb
      INTEGER isb, jsb
      INTEGER pi(2), pj(2), oi, oj
      INTEGER iBufr

C     MPI setup
#ifdef ALLOW_USE_MPI
      INTEGER theTag, theType, theHandle
      INTEGER sProc, tProc, mpiRc
#endif
#ifdef W2_E2_DEBUG_ON
      CHARACTER*(MAX_LEN_MBUF) messageBuffer
#endif

      IF     ( commSetting .EQ. 'P' ) THEN
C      Need to check that buffer synchronisation token is decremented 
C      before filling buffer.
      ENDIF

      tt=exch2_neighbourId(nN, thisTile )
      itb=exch2_tbasex(tt)
      jtb=exch2_tbasey(tt)
      isb=exch2_tbasex(thisTile)
      jsb=exch2_tbasey(thisTile)
      pi(1)=exch2_pi(1,nN,thisTile)
      pi(2)=exch2_pi(2,nN,thisTile)
      pj(1)=exch2_pj(1,nN,thisTile)
      pj(2)=exch2_pj(2,nN,thisTile)
      oi=exch2_oi(nN,thisTile)
      oj=exch2_oj(nN,thisTile)
      iBufr=0
#ifdef W2_E2_DEBUG_ON
      WRITE(messageBuffer,'(A,I4,A,I4)') 'EXCH2_SEND_R41 sourceTile= ', 
     &                                    thisTile,
     &                                   'targetTile= ',tt
      CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_BOTH,
     I      myThid)
#endif /* W2_E2_DEBUG_ON */
      DO ktl=tKlo,tKhi,tKStride
       DO jtl=tJLo, tJHi, tjStride
        DO itl=tILo, tIHi, tiStride
         iBufr=iBufr+1
         itc=itl+itb
         jtc=jtl+jtb
         isc=pi(1)*itc+pi(2)*jtc+oi
         jsc=pj(1)*itc+pj(2)*jtc+oj
         isl=isc-isb
         jsl=jsc-jsb
         e2Bufr1_R4(iBufr)=array(isl,jsl,ktl)
#ifdef W2_E2_DEBUG_ON
      WRITE(messageBuffer,'(A,2I4)') 
     &     'EXCH2_SEND_R41 target t(itl,jtl) = ', itl, jtl
         CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_RIGHT,
     I      myThid)
         WRITE(messageBuffer,'(A,2I4)') 
     &           '               source  (isl,jsl) = ', isl, jsl
         CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_RIGHT,
     I      myThid)
         IF ( isl .LT. i1Lo .OR. isl .GT. i1Hi ) THEN
          WRITE(messageBuffer,'(A,2I4)') 
     &        '              *** isl is out of bounds'        
          CALL PRINT_MESSAGE(messageBuffer,
     I       standardMessageUnit,SQUEEZE_RIGHT,
     I       myThid)
         ENDIF
         IF ( jsl .LT. j1Lo .OR. jsl .GT. j1Hi ) THEN
          WRITE(messageBuffer,'(A,2I4)') 
     &        '              *** jsl is out of bounds'        
          CALL PRINT_MESSAGE(messageBuffer,
     I       standardMessageUnit,SQUEEZE_RIGHT,
     I       myThid)
         ENDIF
#endif /* W2_E2_DEBUG_ON */
#ifdef   W2_USE_E2_SAFEMODE
         IF ( iBufr .GT. e2BufrRecSize ) THEN
C         Ran off end of buffer. This should not happen
          STOP 'EXCH2_SEND_R41:: E2BUFR LIMIT EXCEEDED'
         ENDIF
         IF ( isl .LT. i1Lo .OR. isl .GT. i1Hi ) THEN
C         Forward mode send getting from points outside of the
C         tiles exclusive domain bounds in X. This should not happen
          STOP 'EXCH2_SEND_R41:: ISL OUTSIDE TILE EXCLUSIVE DOMAIN'
         ENDIF
         IF ( jsl .LT. j1Lo .OR. jsl .GT. j1Hi ) THEN
C         Forward mode send getting from points outside of the
C         tiles exclusive domain bounds in Y. This should not happen
          STOP 'EXCH2_SEND_R41:: JSL OUTSIDE TILE EXCLUSIVE DOMAIN'
         ENDIF
#endif /* W2_USE_E2_SAFEMODE */
        ENDDO
       ENDDO
      ENDDO

C     Do data transport depending on communication mechanism between source and target tile
      IF     ( commSetting .EQ. 'P' ) THEN
C      Need to set data ready assertion (increment buffer synchronisation token)
C      for multithreaded mode, for now do nothing i.e. assume only one thread per process.
      ELSEIF ( commSetting .EQ. 'M' ) THEN
#ifdef ALLOW_USE_MPI
C      Setup MPI stuff here
       theTag =  (thisTile-1)*MAX_NEIGHBOURS + nN
     &         + 10000*(
     &            (tt-1)*MAX_NEIGHBOURS + nN
     &           )
       tProc = exch2_tProc(tt)-1
       sProc = exch2_tProc(thisTile)-1
       theType = MPI_REAL8
#ifdef W2_E2_DEBUG_ON
       WRITE(messageBuffer,'(A,I4,A,I4,A)') ' SEND FROM TILE=', thisTile,
     &                                   ' (proc = ',sProc,')'
       CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_RIGHT,
     I      myThid)
       WRITE(messageBuffer,'(A,I4,A,I4,A)') '        TO TILE=', tt,
     &                                   ' (proc = ',tProc,')'
       CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_RIGHT,
     I      myThid)
       WRITE(messageBuffer,'(A,I10)') '            TAG=', theTag
       CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_RIGHT,
     I      myThid)
       WRITE(messageBuffer,'(A,I4)') '            NEL=', iBufr
       CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_RIGHT,
     I      myThid)
#endif /* W2_E2_DEBUG_ON */
       CALL MPI_Isend( e2Bufr1_R4, iBufr, theType,
     I                 tProc, theTag, MPI_COMM_MODEL, 
     O                 theHandle, mpiRc )
C      Store MPI_Wait token in messageHandle.
       e2_msgHandle(1) = theHandle
#endif
      ELSE
       STOP 'EXCH2_SEND_R41:: commSetting VALUE IS INVALID'
      ENDIF
 
      RETURN
      END

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

CEH3 ;;; Local Variables: ***
CEH3 ;;; mode:fortran ***
CEH3 ;;; End: ***
