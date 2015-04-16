
c---------------------------------------------------------------

	SUBROUTINE difft_nu(melange,t,ro,drox,kap,dkapr,dkapx,deff,d,dd)

c routine private du module mod_evol

c formation du coefficient de diffusion turbulente, d_turb + nu_rad + Deff
c nu_rad, suivant Morel & Th�venin �vite la s�dimentation de l'h�lium
c sauf dans les ZC m�lang�es

c Dimensions et initialisations dans le programme appelant
c d(nchim,nchim), dd(nchim,nchim,nchim), v(nchim),dv(nchim,nchim)

c convention de notation :
c �quation de diffusion dXi/dt=dFi/dm + nuclear, i=1,nchim
c Fi=4 pi r**2 ro (4 pi r**2 ro D.dX/dm - Vi Xi)

c entr�es
c	melange=.TRUE.: on est dans une ZC
c	t : temp�rature
c	ro, drox : densit� et d�riv�e / X
c	kap, dkapx: opacit� et d�riv�e / X
c	deff : diffusivit� turbulente due � la rotation

c sorties
c	d, dd : coefficients d_ij de d x_j / d m et d�riv�es / x_k

c Auteur: P.Morel, OCA, CESAM2k

c-------------------------------------------------------------------------

	USE mod_donnees, ONLY : aradia, clight, d_conv, d_turb,
	1 langue, nchim, nucleo, re_nu
	USE mod_kind

	IMPLICIT NONE
      
	REAL (kind=dp), INTENT(in) :: deff, dkapr, dkapx, drox, kap, ro, t
	LOGICAL, INTENT(in) :: melange	
	REAL (kind=dp), INTENT(inout), DIMENSION(:,:,:) :: dd
	REAL (kind=dp), INTENT(inout), DIMENSION(:,:) :: d
	REAL (kind=dp), SAVE :: cte2
	REAL (kind=dp) :: dnu_radx, nu_rad

	INTEGER :: i

	LOGICAL, SAVE :: init=.TRUE.

c--------------------------------------------------------------------------

2000	FORMAT(8es10.3)

	IF(init)THEN
	 init=.FALSE.
	 WRITE(2,*)
	 cte2=re_nu*aradia/clight*4.d0/15.d0
	 SELECT CASE(langue)
	 CASE('english')
	  WRITE(*,1010)d_conv,d_turb,re_nu
	  WRITE(2,1010)d_conv,d_turb,re_nu
1010	  FORMAT('Turbulent diffusion : in CZ, Dconv=',es10.3,
	1 ', in RZ, Dturb=',es10.3,/,'Re_nu=',es10.3,' + Deff with rotation')	 
	 CASE DEFAULT	 
	  WRITE(*,10)d_conv,d_turb,re_nu ; WRITE(2,10)d_conv,d_turb,re_nu
10	  FORMAT('Diffusion turbulente dans ZC, Dconv=',es10.3,
	1 ', dans ZR, Dturb=',es10.3,/,'Re_nu=',es10.3,' + Deff avec rotation')
	 END SELECT
	ENDIF

c dans une zone de m�lange	
	IF(melange)THEN
	 DO i=1,nchim
	  d(i,i)=d_conv
	 ENDDO
	ELSE
	
c coefficient de diffusivit� radiative et d�riv�e / MOLE
	 nu_rad=cte2*t**4/kap/ro**2+ABS(deff)
	 dnu_radx=-nu_rad*((dkapx+dkapr*drox)/kap+2.d0*drox/ro)*nucleo(1)
	 
c contributions des diverses diffusivit�s turbulentes / mole
	 DO i=1,nchim
	  d(i,i)=d(i,i)+d_turb+nu_rad ; dd(i,i,1)=dd(i,i,1)+dnu_radx	  
	 ENDDO

	ENDIF
	
	RETURN

	END SUBROUTINE difft_nu
