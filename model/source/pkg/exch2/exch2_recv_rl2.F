C $Header: /u/gcmpack/MITgcm/pkg/exch2/exch2_recv_rx2.template,v 1.4 2005/07/24 01:21:36 jmc Exp $
C $Name:  $

#include "CPP_EEOPTIONS.h"
#include "W2_OPTIONS.h"

      SUBROUTINE EXCH2_RECV_RL2(
     I       tIlo, tIhi, tiStride,
     I       tJlo, tJhi, tjStride,
     I       tKlo, tKhi, tkStride,
     I       thisTile, thisI, nN,
     I       e2Bufr1_RL, e2Bufr2_RL, e2BufrRecSize,
     I       mnb, nt,
     U       array1,
     I       i1Lo, i1Hi, j1Lo, j1Hi, k1Lo, k1Hi,
     U       array2,
     I       i2Lo, i2Hi, j2Lo, j2Hi, k2Lo, k2Hi,
     U       e2_msgHandles, myTiles,
     I       commSetting,
     I       myThid )

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "W2_EXCH2_TOPOLOGY.h"

C     === Routine arguments ===
C     tIlo, tIhi, tIstride :: index range in I that will be filled in target "array"
C     tJlo, tJhi, tJstride :: index range in J that will be filled in target "array"
C     tKlo, tKhi, tKstride :: index range in K that will be filled in target "array"
C     thisTile             :: Rank of the receiveing tile
C     thisI                :: Index of the receiving tile within this process (used
C                          :: to select buffer slots that are allowed).
C     nN                   :: Neighbour entry that we are processing
C     e2Bufr1_RL           :: Data transport buffer array. This array is used in one of
C                          :: two ways. For PUT communication the entry in the buffer
C                          :: associated with the source for this receive (determined
C                          :: from the opposing_send index) is read. For MSG communication
C                          :: the entry in the buffer associated with this neighbor of this
C                          :: tile is used as a receive location for loading a linear
C                          :: stream of bytes.
C     e2BufrRecSize        :: Number of elements in each entry of e2Bufr1_RL
C     mnb                  :: Second dimension of e2Bufr1_RL
C     nt                   :: Third dimension of e2Bufr1_RL
C     array                :: Target array that this receive writes to.
C     i1Lo, i1Hi           :: I coordinate bounds of target array
C     j1Lo, j1Hi           :: J coordinate bounds of target array
C     k1Lo, k1Hi           :: K coordinate bounds of target array
C     e2_msgHandles        :: Synchronization and coordination data structure used to coordinate access
C                          :: to e2Bufr1_RL or to regulate message buffering. In PUT communication
C                          :: sender will increment handle entry once data is ready in buffer.
C                          :: Receiver will decrement handle once data is consumed from buffer. For
C                          :: MPI MSG communication MPI_Wait uses hanlde to check Isend has cleared.
C                          :: This is done in routine after receives.
C     myTiles              :: List of nt tiles that this process owns.
C     commSetting          :: Mode of communication used to exchnage with this neighbor
C     myThid               :: Thread number of this instance of EXCH2_RECV_RL1
C  
      INTEGER tILo, tIHi, tiStride
      INTEGER tJLo, tJHi, tjStride
      INTEGER tKLo, tKHi, tkStride
      INTEGER i1Lo, i1Hi, j1Lo, j1Hi, k1Lo, k1Hi
      INTEGER i2Lo, i2Hi, j2Lo, j2Hi, k2Lo, k2Hi
      INTEGER thisTile, nN, thisI
      INTEGER e2BufrRecSize 
      INTEGER mnb, nt
      _RL     e2Bufr1_RL( e2BufrRecSize, mnb, nt, 2 )
      _RL     e2Bufr2_RL( e2BufrRecSize, mnb, nt, 2 )
      _RL     array1(i1Lo:i1Hi,j1Lo:j1Hi,k1Lo:k1Hi)
      _RL     array2(i2Lo:i2Hi,j2Lo:j2Hi,k2Lo:k2Hi)
      INTEGER e2_msgHandles(2, mnb, nt)
      INTEGER myThid
      INTEGER myTiles(nt)
      CHARACTER commSetting

C     == Local variables ==
C     itl, jtl, ktl  :: Loop counters
C                    :: itl etc... target local
C                    :: itc etc... target canonical
C                    :: isl etc... source local
C                    :: isc etc... source canonical
      INTEGER itl, jtl, ktl
c     INTEGER itc, jtc, ktc
c     INTEGER isc, jsc, ksc
c     INTEGER isl, jsl, ksl
C     tt         :: Target tile
C     iBufr1     :: Buffer counter
C     iBufr2     ::
      INTEGER tt
      INTEGER iBufr1, iBufr2
C     mb, nb :: Selects e2Bufr, msgHandle record to use
C     ir     ::
      INTEGER mb, nb, ir
C     oN     :: Opposing send record number 
      INTEGER oN
C     Loop counters
      INTEGER I
      INTEGER itl1reduce, jtl1reduce
      INTEGER itl2reduce, jtl2reduce

C     MPI setup
#ifdef ALLOW_USE_MPI
      INTEGER    nri1, nrj1, nrk1
      INTEGER    nri2, nrj2, nrk2
      INTEGER theTag1, theTag2, theType
c     INTEGER theSize1, theSize2
      INTEGER sProc, tProc
      INTEGER mpiStatus(MPI_STATUS_SIZE), mpiRc
#ifdef W2_E2_DEBUG_ON
      CHARACTER*(MAX_LEN_MBUF) messageBuffer
#endif
#endif

      tt=exch2_neighbourId(nN, thisTile )
      oN=exch2_opposingSend_record(nN, thisTile )
      itl1reduce=0
      jtl1reduce=0
      itl2reduce=0
      jtl2reduce=0
      IF ( exch2_pi(1,oN,tt) .EQ. -1 ) itl1reduce=1
      IF ( exch2_pj(1,oN,tt) .EQ. -1 ) itl1reduce=1
      IF ( exch2_pi(2,oN,tt) .EQ. -1 ) jtl2reduce=1
      IF ( exch2_pj(2,oN,tt) .EQ. -1 ) jtl2reduce=1

C     Handle receive end data transport according to communication mechanism between 
C     source and target tile
      IF     ( commSetting .EQ. 'P' ) THEN
C      1 Need to check and spin on data ready assertion for multithreaded mode, for now do nothing i.e.
C        assume only one thread per process.

C      2 Need to set e2Bufr to use put buffer from opposing send.
       oN = exch2_opposingSend_record(nN, thisTile )
       mb = oN
       ir = 1
       DO I=1,nt
        IF ( myTiles(I) .EQ. tt ) THEN
         nb = I
        ENDIF
       ENDDO
C      Get data from e2Bufr(1,mb,nb)
      ELSEIF ( commSetting .EQ. 'M' ) THEN
#ifdef ALLOW_USE_MPI
C      Setup MPI stuff here
       nb = thisI
       mb = nN
       ir = 2
       theTag1 =  (tt-1)*MAX_NEIGHBOURS*2 + oN-1
     &         + 10000*(
     &            (thisTile-1)*MAX_NEIGHBOURS*2 + oN-1
     &           )
       theTag2 =  (tt-1)*MAX_NEIGHBOURS*2 + MAX_NEIGHBOURS + oN-1
     &         + 10000*(
     &            (thisTile-1)*MAX_NEIGHBOURS*2 + MAX_NEIGHBOURS + oN-1
     &           )
       tProc = exch2_tProc(thisTile)-1
       sProc = exch2_tProc(tt)-1
       theType = MPI_REAL8
       nri1 = (tIhi-tIlo+1-itl1reduce)/tiStride
       nrj1 = (tJhi-tJlo+1-jtl1reduce)/tjStride
       nrk1 = (tKhi-tKlo+1)/tkStride
       iBufr1 = nri1*nrj1*nrk1
       nri2 = (tIhi-tIlo+1-itl2reduce)/tiStride
       nrj2 = (tJhi-tJlo+1-jtl2reduce)/tjStride
       nrk2 = (tKhi-tKlo+1)/tkStride
       iBufr2 = nri2*nrj2*nrk2
       CALL MPI_Recv( e2Bufr1_RL(1,mb,nb,ir), iBufr1, theType, sProc,
     &               theTag1, MPI_COMM_MODEL, mpiStatus, mpiRc )
       CALL MPI_Recv( e2Bufr2_RL(1,mb,nb,ir), iBufr2, theType, sProc,
     &               theTag2, MPI_COMM_MODEL, mpiStatus, mpiRc )
#ifdef W2_E2_DEBUG_ON
       WRITE(messageBuffer,'(A,I4,A,I4,A)') ' RECV FROM TILE=', tt,
     &                                   ' (proc = ',sProc,')'
       CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_RIGHT,
     I      myThid)
       WRITE(messageBuffer,'(A,I4,A,I4,A)') '      INTO TILE=', thisTile,
     &                                   ' (proc = ',tProc,')'
       CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_RIGHT,
     I      myThid)
       WRITE(messageBuffer,'(A,I10)') '            TAG1=', theTag1
       CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_RIGHT,
     I      myThid)
       WRITE(messageBuffer,'(A,I4)') '            NEL1=', iBufr1
       CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_RIGHT,
     I      myThid)
       WRITE(messageBuffer,'(A,I10)') '            TAG2=', theTag2
       CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_RIGHT,
     I      myThid)
       WRITE(messageBuffer,'(A,I4)') '            NEL2=', iBufr2
       CALL PRINT_MESSAGE(messageBuffer,
     I      standardMessageUnit,SQUEEZE_RIGHT,
     I      myThid)
#endif /* W2_E2_DEBUG_ON */
C      Set mb to neighbour entry
C      Set nt to this tiles rank
       mb = nN
#endif
      ELSE
       STOP 'EXCH2_RECV_RL2:: commSetting VALUE IS INVALID'
      ENDIF

      iBufr1=0
      DO ktl=tKlo,tKhi,tKStride
       DO jtl=tJLo+jtl1reduce, tJHi, tjStride
        DO itl=tILo+itl1reduce, tIHi, tiStride
C        Read from e2Bufr1_RL(iBufr,mb,nb)
         iBufr1=iBufr1+1
         array1(itl,jtl,ktl)=e2Bufr1_RL(iBufr1,mb,nb,ir)
        ENDDO
       ENDDO
      ENDDO

      iBufr2=0
      DO ktl=tKlo,tKhi,tKStride
       DO jtl=tJLo+jtl2reduce, tJHi, tjStride
        DO itl=tILo+itl2reduce, tIHi, tiStride
C        Read from e2Bufr1_RL(iBufr,mb,nb)
         iBufr2=iBufr2+1
         array2(itl,jtl,ktl)=e2Bufr2_RL(iBufr2,mb,nb,ir)
        ENDDO
       ENDDO
      ENDDO
 
      RETURN
      END

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

CEH3 ;;; Local Variables: ***
CEH3 ;;; mode:fortran ***
CEH3 ;;; End: ***
