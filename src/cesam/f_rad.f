          	
c********************************************************************

	SUBROUTINE f_rad(lum,ray,t,kap,dkapx,nel,ychim,ioni,grav,
	1 g_rad,dg_rad)

c	subroutine private du module mod_evol
	
c	subroutine g�n�rique de calcul des acc�l�rations radiatives

c entr�es :
c	lum : luminosit�
c	ray : rayon
c	t : temp�rature
c	kap : opacit�
c	dkapx : d�riv�e/X (mole)
c entr�es / sorties :
c	g_rad : vecteur des acc�l�rations radiatives,
c		la gravit� est grav+g\_rad sur l'�l�ment d'indice i 

c	dg_rad(i,j) : matrice des d�riv�es des acc�l�rations radiatives
c	sur l'�l�ment i / abondance par mole de l'�l�ment j.

c	Auteur: P.Morel, D�partement J.D. Cassini, O.C.A.
c	CESAM2k

c---------------------------------------------------------------------

	USE mod_bp_for_alecian, ONLY : alecian2
	USE mod_donnees, ONLY : langue, nom_diffm, nom_frad
	USE mod_kind

	IMPLICIT NONE

	REAL (kind=dp), INTENT(in), DIMENSION(0:,:) :: ioni
	REAL (kind=dp), INTENT(in), DIMENSION(:) :: ychim
	REAL (kind=dp), INTENT(in) :: grav, dkapx, kap, lum, nel, ray, t
	REAL (kind=dp), INTENT(out), DIMENSION(:,:) :: dg_rad
	REAL (kind=dp), INTENT(out), DIMENSION(:) :: g_rad

	LOGICAL, SAVE :: init=.TRUE.

c---------------------------------------------------------------------

	SELECT CASE(nom_frad)
	CASE('alecian1')
	 IF(init)THEN
	  init=.FALSE.
	  IF(nom_diffm /= 'diffm_br')THEN
	   SELECT CASE(langue)
	   CASE('english')
	    WRITE(*,1002)nom_diffm ; WRITE(2,1001)nom_diffm
1002	    FORMAT('STOP, the radiative accelerations are not taken',/,
	1    'into account by the routine diffm=',a,/,'use diffm_br')
	   CASE DEFAULT	  
	    WRITE(*,2)nom_diffm ; WRITE(2,2)nom_diffm
2	    FORMAT('ARRET, les acc�l�rations radiatives ne peuvent �tre',/,
	1    'prises en compte avec la routine diffm=',a,/,
	2    'utiliser diffm_br')
 	   END SELECT
	   STOP
	  ENDIF  
	 ENDIF	 	
	 CALL alecian1(lum,ray,t,kap,dkapx,nel,ychim,ioni,grav,g_rad,dg_rad)

	CASE('alecian2')
	 IF(init)THEN
	  init=.FALSE.
	  IF(nom_diffm /= 'diffm_br')THEN
	   SELECT CASE(langue)
	   CASE('english')
	    WRITE(*,1002)nom_diffm ; WRITE(2,1001)nom_diffm
	   CASE DEFAULT	  
	    WRITE(*,2)nom_diffm ; WRITE(2,2)nom_diffm
	   END SELECT
	   STOP
	  ENDIF  
	 ENDIF	 	
	 CALL alecian2(lum,ray,t,nel,grav,ychim,ioni,g_rad,dg_rad)

	CASE('no_frad')
	 dg_rad=0.d0 ; g_rad=0.d0
	 IF(init)THEN
	  init=.FALSE.
	  SELECT CASE(langue)
	  CASE('english')
	   WRITE(*,1001) ; WRITE(2,1001) ; RETURN
1001	   FORMAT('The radiative accelarations are ignored')	  
	  CASE DEFAULT	  
	   WRITE(*,1) ; WRITE(2,1) ; RETURN
1	   FORMAT('On ne tient pas compte des acc�l�rations radiatives')
 	  END SELECT
	 ENDIF	 
	CASE DEFAULT
	 PRINT*,'routine de calcul des forces radiatives inconnue: ',
	1  nom_frad
	 PRINT*,'routines connues: alecian1, alecian2, no_frad' 
	 PRINT*,'arr�t' ; STOP
	END SELECT
 
	RETURN

	END SUBROUTINE f_rad
