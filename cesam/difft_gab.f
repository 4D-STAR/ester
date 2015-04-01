
c---------------------------------------------------------------

	SUBROUTINE difft_gab(melange,t,deff,d)

c routine private du module mod_evol

c formation du coefficient de diffusion turbulente, d_turb + Deff
c suivant une id�e de M.Gabriel, on �vite la s�dimentation de l'h�lium en
c m�langeant si T < Tlim=1.d6 
c sauf dans les ZC m�lang�es

c Dimensions et initialisations dans le programme appelant
c d(nchim,nchim), dd(nchim,nchim,nchim), v(nchim),dv(nchim,nchim)

c convention de notation :
c �quation de diffusion dXi/dt=dFi/dm + nuclear, i=1,nchim
c Fi=4 pi r**2 ro (4 pi r**2 ro D.dX/dm - Vi Xi)

c d=D=(di1, di2,... din) avec Dij coefficient de d Xj / dm
c dans le produit scalaire D.dX/dm=sum d_ij d Xj / dm

c pour ligne d'indice i
c v(i) coefficient de x_i,
c dv(i,k)=dv(nchim*(k-1)+i)=d�riv�e v_i / x_k
c seule la premi�re colonne de dv
c est non nulle (pas de d�riv�es / Xi, i .ne. 1)
c d(i,j)=coefficient d_ij de d x_j / dm
c dd(i,j,k)= d�riv�e de d_ij / x_k
c deff : diffusion turbulente due � la rotation

c entr�es
c	melange=.TRUE.: on est dans une ZC
c	p, t, r, l, m, ro: donn�es au point de calcul
c	xi: composition chimique, par mole
c	kap: opacit� 
c	gradad, gradrad: gradients
c	terminaisons x : d�riv�es/ X1 (ie H) par gramme
c	mstar: masse avec perte de masse
c	m_zc, r_zc, lim : masses, rayons, nombre de limites ZR/ZC
c	age, gamma1, cp, delta: notations evidentes

c sorties
c	d0, dd : coefficients d_ij de d x_j / d m et d�riv�es / x_k
c	v0, dv : coefficients v_i de x_i et d�riv�es / x_k

c-------------------------------------------------------------------------

	USE mod_donnees, ONLY : d_conv, d_turb, langue, nchim
	USE mod_kind

	IMPLICIT NONE
      
	REAL (kind=dp), INTENT(in) :: deff, t
	LOGICAL, INTENT(in) :: melange
	REAL (kind=dp), INTENT(inout), DIMENSION(:,:) :: d

	INTEGER :: i

	LOGICAL, SAVE :: init=.TRUE.

c--------------------------------------------------------------------------

2000	FORMAT(8es10.3)

	IF(init)THEN
	 init=.FALSE.
	 WRITE(2,*)
	 SELECT CASE(langue)
	 CASE('english')
	  WRITE(*,1010)d_conv,d_turb,t_gab
	  WRITE(2,1010)d_conv,d_turb,t_gab
1010	  FORMAT('Turbulent diffusion : in CZ, Dconv=',es10.3,
	1 ', in RZ, Dturb=',es10.3,' + Deff with rotation',/,
	2 'mixing according to M.Gabriel if  T < ',es10.3)	 
	 CASE DEFAULT	 
	  WRITE(*,10)d_conv,d_turb,t_gab
	  WRITE(2,10)d_conv,d_turb,t_gab
10	  FORMAT('Diffusion turbulente dans ZC, Dconv=',es10.3,
	1 ', dans ZR, Dturb=',es10.3,' + Deff avec rotation',/,
	3 'm�lange selon M.Gabriel si T < ',es10.3)
	 END SELECT
	ENDIF

c dans une zone de m�lange	
	IF(melange .OR. t < t_gab)THEN
	 DO i=1,nchim
	  d(i,i)=d_conv
	 ENDDO
	ELSE
		 
c contributions des diverses diffusivit�s turbulentes
	 DO i=1,nchim
	  d(i,i)=d(i,i)+d_turb+deff
	 ENDDO
	ENDIF
	
	RETURN

	END SUBROUTINE difft_gab
