	
c***********************************************************************

	 SUBROUTINE etat(p,t,xchim,deriv,ro,drop,drot,drox,u,dup,dut,dux,
	1 delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	2 gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)

c	subroutine g�n�rique pour le calcul de l'�quation d'�tat

c	routine public du module mod_etat	

c entr�es:
c	  p : pression
c	  t : temperature
c	  xchim : composition chimique
c	  deriv=.FALSE. : �vite le calcul  de certaines d�riv�es

c sorties:
c	  ro : densit� et d�riv�es
c	  u : �nergie interne et d�riv�es

c	Auteur: P.Morel, D�partement J.D. Cassini, O.C.A.
c	CESAM2k

c----------------------------------------------------------------

	  USE mod_donnees, ONLY : nom_etat
	  USE mod_kind
	
	  IMPLICIT NONE
	  			
	  REAL (kind=dp), INTENT(in), DIMENSION(:) :: xchim	
	  REAL (kind=dp), INTENT(in) :: p, t
	  LOGICAL, INTENT(in) :: deriv	  		
	  REAL (kind=dp), INTENT(out) :: ro, drop, drot, drox, u, dup,
	1 dut, dux,delta, deltap, deltat, deltax, cp, dcpp, dcpt, dcpx,
	2 gradad, dgradadp, dgradadt, dgradadx, alfa, beta, gamma1
	
c---------------------------------------------------------------------
	
	  SELECT CASE(nom_etat)	  
	  CASE ('etat_ceff')
	   CALL etat_ceff(p,t,xchim,ro,drop,drot,drox,u,dup,dut,dux,
	1 delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	2 gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)
	  CASE ('etat_eff')
	   CALL etat_eff(p,t,xchim,ro,drop,drot,drox,u,dup,dut,dux,
	1 delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	2 gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)
	  CASE ('etat_gong1')
	   CALL etat_gong1(p,t,xchim,deriv,ro,drop,drot,drox,u,dup,dut,dux,
	1 delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	2 gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)
	  CASE ('etat_gong2')
	   CALL etat_gong2(p,t,xchim,ro,drop,drot,drox,u,dup,dut,dux,
	1 delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	2 gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)
	  CASE ('etat_mhd')
	   CALL etat_mhd(p,t,xchim,deriv,ro,drop,drot,drox,u,dup,dut,dux,
	1 delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	2 gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)
	  CASE ('etat_opal')
	   CALL etat_opal(p,t,xchim,deriv,ro,drop,drot,drox,u,dup,dut,dux,
	1 delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	2 gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)
	  CASE ('etat_opalX')
	   CALL etat_opalX(p,t,xchim,deriv,ro,drop,drot,drox,u,dup,dut,dux,
	1 delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	2 gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)
	  CASE ('etat_opalZ')
	   CALL etat_opalZ(p,t,xchim,deriv,ro,drop,drot,drox,u,dup,dut,dux,
	1 delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	2 gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)	
	  CASE ('etat_opal5Z')
	   CALL etat_opal5Z(p,t,xchim,deriv,ro,drop,drot,drox,u,dup,dut,dux,
	1 delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	2 gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)	
	  CASE DEFAULT
	   PRINT*,'routine d''�quation d''�tat inconnue: ',nom_etat
	   PRINT*,'routines connues: etat_ceff, etat_eff, etat_gong1'	   
	   PRINT*,'etat_gong2, etat_mhd, etat_opal, etat_opalX, etat_opalZ'
	   PRINT*,'arret' ; STOP
	  END SELECT
	  
	  RETURN

	 END SUBROUTINE etat
