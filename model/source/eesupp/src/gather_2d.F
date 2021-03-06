C $Header: /u/gcmpack/MITgcm/eesupp/src/gather_2d.F,v 1.6 2005/11/09 19:50:03 jmc Exp $
C $Name:  $

#include "CPP_EEOPTIONS.h"

      SUBROUTINE GATHER_2D( global, local, myThid )
C     Gather elements of a 2-D array from all mpi processes to process 0.
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
C     mythid - thread number for this instance of the routine.
C     global,local - working arrays used to transfer 2-D fields
      INTEGER mythid 
      Real*8  global(Nx,Ny)
      _RL     local(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)

      INTEGER iG,jG, i, j, bi, bj
#ifdef ALLOW_USE_MPI
      _RL     temp(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      INTEGER istatus(MPI_STATUS_SIZE), ierr
      INTEGER lbuff, idest, itag, npe, ready_to_receive
#endif /* ALLOW_USE_MPI */

C--   Make everyone wait except for master thread.
      _BARRIER
      _BEGIN_MASTER( myThid )

#ifndef ALLOW_USE_MPI

      DO bj=1,nSy
         DO bi=1,nSx
            DO j=1,sNy
               DO i=1,sNx
                  iG = myXGlobalLo-1+(bi-1)*sNx+i
                  jG = myYGlobalLo-1+(bj-1)*sNy+j
                  global(iG,jG) = local(i,j,bi,bj)
               ENDDO
            ENDDO
         ENDDO
      ENDDO

#else /* ALLOW_USE_MPI */

      lbuff = (sNx+2*OLx)*nSx*(sNy+2*OLy)*nSy
      idest = 0
      itag  = 0
      ready_to_receive = 0

      IF( mpiMyId .EQ. 0 ) THEN

C--   Process 0 fills-in its local data
         npe = 0
         DO bj=1,nSy
            DO bi=1,nSx
               DO j=1,sNy
                  DO i=1,sNx
                     iG = mpi_myXGlobalLo(npe+1)-1+(bi-1)*sNx+i
                     jG = mpi_myYGlobalLo(npe+1)-1+(bj-1)*sNy+j
                     global(iG,jG) = local(i,j,bi,bj)
                  ENDDO
               ENDDO
            ENDDO
         ENDDO

C--   Process 0 polls and receives data from each process in turn
         DO npe = 1, numberOfProcs-1
            CALL MPI_SEND (ready_to_receive, 1, MPI_INTEGER,
     &           npe, itag, MPI_COMM_MODEL, ierr)
            CALL MPI_RECV (temp, lbuff, MPI_DOUBLE_PRECISION,
     &           npe, itag, MPI_COMM_MODEL, istatus, ierr)

C--   Process 0 gathers the local arrays into a global array.
            DO bj=1,nSy
               DO bi=1,nSx
                  DO j=1,sNy
                     DO i=1,sNx
                        iG = mpi_myXGlobalLo(npe+1)-1+(bi-1)*sNx+i
                        jG = mpi_myYGlobalLo(npe+1)-1+(bj-1)*sNy+j
                        global(iG,jG) = temp(i,j,bi,bj)
                     ENDDO
                  ENDDO
               ENDDO
            ENDDO
         ENDDO

      ELSE

C--   All proceses except 0 wait to be polled then send local array
         CALL MPI_RECV (ready_to_receive, 1, MPI_INTEGER,
     &        idest, itag, MPI_COMM_MODEL, istatus, ierr)
         CALL MPI_SEND (local, lbuff, MPI_DOUBLE_PRECISION,
     &        idest, itag, MPI_COMM_MODEL, ierr)

      ENDIF

#endif /* ALLOW_USE_MPI */

      _END_MASTER( myThid )
      _BARRIER

      RETURN
      END
