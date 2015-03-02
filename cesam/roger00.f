
c*******************************************************************

	SUBROUTINE roger00(tau,teff,grav,t,dtsdtau,dtsdteff,dtsdg,
	1 ro_ext,dro_grav,dro_teff,f_tau,df_tau,d2f_tau)

c	routine private du module mod_tdetau
    
c	interface pour la loi T(tau) de R. cayrel avec [Fe/H]=0.0

c	Auteur: P. Morel, D�partement J.D. Cassini, O.C.A.
c	CESAM2k

c entr�es :
c	tau : profondeur optique Rosseland
c	teff : temp�rature effective
c	grav : gravit�

c sorties :
c	t : temp�rature
c	dtsd* : d�riv�es t/ tau, teff, grav
c	dtsd* : d�riv�es t/ tau, teff, grav
c	dro_** : d�riv�es ro_ext/ teff, grav
c	f_tau, df_tau, df_tau2 : f, d f / d tau, d2 f / d2 tau

c---------------------------------------------------------------------------

	USE mod_donnees, ONLY : langue
	USE mod_kind

	IMPLICIT NONE

	REAL (kind=dp), INTENT(in) :: tau, teff, grav
	REAL (kind=dp), INTENT(out) :: t, dtsdtau, dtsdteff, dtsdg,
	1 ro_ext, dro_grav, dro_teff, f_tau, df_tau, d2f_tau

	REAL (kind=dp) :: logg, tef

	CHARACTER (len=80) :: nom
	CHARACTER (len=80) :: nom_chemin = "/data1/sdeheuve/local/src/cesam2k_v1.1.8_ESTA/SUN_STAR_DATA/"

	LOGICAL, SAVE :: init=.TRUE.

c-----------------------------------------------------------------

	IF(init)THEN
	 init=.FALSE.
	 SELECT CASE(langue)	 
	 CASE('english')
	  WRITE(*,1001) ; WRITE(2,1001)
1001	  FORMAT(/,'T(tau,teff,grav) law, roger00, no purely radiative',/,
	1 '[Fe/H]=0. interpolations in Teff and Log g',/,
	2 'artificial extend of the data to Teff = 3500K',/,
	3 '3500K < Teff < 7000K, 1 < Log10(g) < 5, tau_min=1.d-4',/)	  
	 CASE DEFAULT	  
	  WRITE(*,1) ; WRITE(2,1)
1	  FORMAT(/,'loi T(tau,teff,grav), roger00, non purement radiative',/,
	1 '[Fe/H]=0. interpolations en Teff et gravit�',/,
	2 'table �tendue artificiellement a Teff = 3500K',/,
	3 '3500K < Teff < 7000K, 1 < Log10(g) < 5, tau_min=1.d-4',/)
	 END SELECT	 
	 nom=TRIM(nom_chemin)//'fesh00.data' ; rad=.FALSE.
	ENDIF

	logg=LOG10(grav) ; tef=teff     !peut �tre chang� dans trho
	CALL trho(nom,tau,tef,logg,t,dtsdtau,dtsdteff,
	1 dtsdg,ro_ext,dro_teff,dro_grav,f_tau,df_tau,d2f_tau)

	RETURN

	END SUBROUTINE roger00
