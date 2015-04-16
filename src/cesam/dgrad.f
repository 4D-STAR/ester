
c****************************************************************************

	REAL (kind=dp) FUNCTION dgrad(pt,p,t,dlpp,xchim,m,l,r,dxchim,w)

c routine public du module mod_static
c calcul de la diff�rence des gradients pour le crit�re de convection

c Auteur: P.Morel + N. Audard, D�partement J.D. Cassini, O.C.A., CESAM2k

c	Modifs
c	09 10 96 : introduction de w
c	09 11 99 : correction crit�re de Ledoux
c	19 11 99 : suppression de nh1, nhe1, nhe2, lamb
c	30 07 00 : introduction F95

c entr�es :
c	pt : pression totale
c	p : pression gazeuse cgs
c	t : temp�rature K
c	xchim : composition chimique ATTENTION en 1/mole : *ah pour avoir X
c	dxchim : d xchim/d m^2/3
c	m : masse/msol
c	l : luminosite/lsol
c	r : rayon / rsol
c	mstar: masse au temps du calcul, avec perte de masse
c	w : rotation
c	dlpp : d ln Pgaz / d ln Ptot

c sortie:
c	dgrad=grad_rad-grad_ad > 0 dans ZR

c----------------------------------------------------------------

	USE mod_donnees, ONLY : aradia, clight, cpturb, g, ihe4,
	1 ledoux, lsol, msol, nchim, pi, rsol, t_inf
	USE mod_etat, ONLY : etat, mu_mol
	USE mod_kind
	USE mod_opa, ONLY : opa
	USE mod_nuc, ONLY : nuc
	USE mod_variables, ONLY : chim_gram
	
	IMPLICIT NONE

	REAL (kind=dp), INTENT(in), DIMENSION(nchim) :: dxchim, xchim
	REAL (kind=dp), INTENT(in) :: dlpp, l, m, p, pt, t, r, w

	REAL (kind=dp), DIMENSION(0,0) :: jac	
	REAL (kind=dp), DIMENSION(nchim) :: depsx, dlnmu_x, dgrad_mux, dmu_x,
	1 dxchimm, xchi, xchimm
	REAL (kind=dp), DIMENSION(0) :: dcomp 
	REAL (kind=dp), SAVE, DIMENSION(5) :: epsilon
	REAL (kind=dp), SAVE :: cte1, cte2, cte8, cte9, cte13
	REAL (kind=dp) :: alfa, beta, be7, b8, cp, dcpp, dcpt, dcpx, delta,
	1 deltap, deltat, deltax, depst, depsro, dlnmu, drop, drot, drox, dup,
	2 dut, dux, f17, gamma1, gradad, dgradadp, dgradadt, dgradadx,
	3 gradrad, gravite, hh, hp, kap, dkapro, dkapt, dkapx, grad_mu,
	4 krad, ldx, mu, m23, nel, n13, o15, ro, u, Zbar

	LOGICAL, SAVE :: init=.TRUE.

c--------------------------------------------------------------------

2000	FORMAT(8es10.3)

	IF(init)THEN	!initialisations
	 init=.FALSE.
	 cte1=4.d0/3.d0*aradia*clight ; cte13=g*msol/rsol/rsol	 	 
	 cte2=2.d0/3.d0*rsol
	 cte8=lsol/4.d0/pi/rsol/rsol	!de 5.9
	 cte9=3.d0/16.d0/pi/aradia/clight/g	 
	ENDIF		!initialisation
	
c composition chimique /gr
	xchimm=ABS(xchim) ; dxchimm=dxchim ; xchi=xchim		 
	
	CALL chim_gram(xchimm,dxchimm)

	CALL etat(p,t,xchimm,.FALSE.,
	1 ro,drop,drot,drox,u,dup,dut,dux,
	2 delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	3 gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)
	IF(cpturb < 0.d0)gradad=gradad*dlpp

c opacit�
	CALL opa(xchimm,t,ro,kap,dkapt,dkapro,dkapx)	
	krad=cte1/kap/ro*t**3		!5.1 conductivite radiative
	
	IF(m*l*r /= 0.d0)THEN		!gradient radiatif
	 gravite=cte13*m/r**2-cte2*w**2*r !gravit� effective avec rotation
	 gradrad=cte8*l*p/gravite/ro/r**2/krad/t	!5.9
	 hp=pt/gravite/ro		!�chelle de hauteur de pression
	ELSE		!au centre
	 IF(t > t_inf)THEN
	  CALL nuc(t,ro,xchi,dcomp,jac,.FALSE.,3,
	1 epsilon,depst,depsro,depsx,hh,be7,b8,n13,o15,f17)
	 ELSE
	  epsilon(1)=0.d0	!total
	 ENDIF
	 gradrad=cte9*kap*epsilon(1)*p/t**4	!au centre l/m ~ epsilon
	 hp=1.d38
	ENDIF
	dgrad=gradrad-gradad	!critere de Schwarzschild

c crit�re de Ledoux pour la convection
	IF(ledoux)THEN
	 m23=m**(2.d0/3.d0)	 
	 CALL mu_mol(dxchim,hp,m23,r,ro,t,xchim,dlnmu,dlnmu_x,grad_mu,
	1 dgrad_mux,mu,dmu_x,nel,Zbar)

c correction de Ledoux
	 ldx=beta/(4.d0-3.d0*beta)*grad_mu
	 
c diff�rence des gradients	 
	 dgrad=dgrad-ldx
	ENDIF
	
	RETURN

	END FUNCTION dgrad
