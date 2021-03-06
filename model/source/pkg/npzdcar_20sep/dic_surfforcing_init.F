#include "PTRACERS_OPTIONS.h"
#include "GCHEM_OPTIONS.h"

CBOP
C !ROUTINE: DIC_SURFFORCING_INIT

C !INTERFACE: ==========================================================
      SUBROUTINE DIC_SURFFORCING_INIT(
     I          myThid)

C !DESCRIPTION:
C  Calculate first guess of pH                            

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "DYNVARS.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "FFIELDS.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS.h"
#include "NPZDCAR.h"
#include "NPZDCAR_LOAD.h"

C !INPUT PARAMETERS: ===================================================
C  myThid               :: thread number
      INTEGER  myThid

#ifdef ALLOW_PTRACERS

C !LOCAL VARIABLES: ====================================================
       INTEGER I,J, kLev, it
       INTEGER intime0,intime1
       _RL otime
       _RL aWght,bWght,rdt
       INTEGER nForcingPeriods,Imytm,Ifprd,Ifcyc,Iftm
C Number of iterations for pCO2 solvers...
C Solubility relation coefficients
C local variables for carbon chem
      INTEGER iMin,iMax,jMin,jMax, bi, bj
      _RL surfalk(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL surfphos(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL surfsi(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL surfdic(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
CEOP

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      kLev=1

ccccccccccccccccccccccccccccccccccccccccc
C =================================================================
      DO bj=myByLo(myThid),myByHi(myThid)
        DO bi=myBxLo(myThid),myBxHi(myThid)

        jMin=1-OLy
        jMax=sNy+OLy
        iMin=1-OLx
        iMax=sNx+OLx

C determine inorganic carbon chem coefficients
        DO j=1-OLy,sNy+OLy
         DO i=1-OLx,sNx+OLx

cQQQQ check ptracer numbers
             surfalk(i,j) = PTRACER(i,j,klev,bi,bj,19)*1e-3
     &                          * maskC(i,j,kLev,bi,bj)
             surfphos(i,j)  = PTRACER(i,j,klev,bi,bj,1)*1e-3
     &                          * maskC(i,j,kLev,bi,bj)
             surfdic(i,j) = PTRACER(i,j,klev,bi,bj,13)*1e-3
     &                          * maskC(i,j,kLev,bi,bj)
             surfsi(i,j) = PTRACER(i,j,klev,bi,bj,7)*1e-3
     &                          * maskC(i,j,kLev,bi,bj)
          ENDDO
         ENDDO

         CALL CARBON_COEFFS(
     I                       theta,salt,
     I                       bi,bj,iMin,iMax,jMin,jMax)
C====================================================================

c set number of iterations for [H+] solvers
C set guess of pH for first step here

        DO j=1-OLy,sNy+OLy
         DO i=1-OLx,sNx+OLx
                  pH(i,j,bi,bj) = 8.0
          ENDDO
         ENDDO
         print*,'QQ: pCO2 approximation method'
c first approxmation
C$TAF LOOP = parallel
        DO j=1-OLy,sNy+OLy
C$TAF LOOP = parallel
        DO i=1-OLx,sNx+OLx
         IF(maskC(i,j,kLev,bi,bj) .NE. 0.)THEN
C$TAF init dic_surf = static, 10
          do it=1,10
C$TAF STORE pH(i,j,bi,bj), PTR_CO2(i,j,kLev)           = dic_surf
C$TAF STORE surfalk(i,j), surfphos(i,j), surfsi(i,j)   = dic_surf
           CALL CALC_PCO2_APPROX(
     I        theta(i,j,kLev,bi,bj),salt(i,j,kLev,bi,bj),
     I        surfdic(i,j), surfphos(i,j),
     I        surfsi(i,j),surfalk(i,j),
     I        ak1(i,j,bi,bj),ak2(i,j,bi,bj),
     I        ak1p(i,j,bi,bj),ak2p(i,j,bi,bj),ak3p(i,j,bi,bj),
     I        aks(i,j,bi,bj),akb(i,j,bi,bj),akw(i,j,bi,bj),
     I        aksi(i,j,bi,bj),akf(i,j,bi,bj),ff(i,j,bi,bj),
     I        bt(i,j,bi,bj),st(i,j,bi,bj),ft(i,j,bi,bj),
     U        pH(i,j,bi,bj),pCO2(i,j,bi,bj) )
          enddo
         ENDIF
        ENDDO
        ENDDO

        ENDDO
        ENDDO
        print*,'QQ first guess pH', pH(20,20,1,1), theta(20,20,1,1,1),
     &         salt(20,20,1,1,1),
     &        surfdic(20,20), surfphos(20,20),
     &        surfsi(20,20),surfalk(20,20)
#endif
        RETURN
        END
