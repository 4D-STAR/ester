
c********************************************************************

	SUBROUTINE resout(un23,dt,dts)
	
c	routine public du module mod_static
	
c	gestion de la r�solution des �quations avec fonction de
c	r�partition

c	routine du module mod_resout

c	Auteur: P.Morel, Departement J.D. Cassini, O.C.A.
c	CESAM2k

c	on distingue par SELECT CASE(un23) les 3 cas:
c	un23=1 : poursuite d'une �volution
c	un23=2 : calcul d'un mod�le initial de ZAMS homog�ne
c	un23=3 : calcul d'un mod�le initial de PMS homog�ne

c	Pour le probl�me aux limites:
c	r�solution du systeme d'�quations diff�rentielles non lin�aires
c	de la structure interne par d�veloppement sur B-splines
c	par it�ration Newton avec d�riv�es analytiques
c	(ou num�riques pour tests)

c	les �quations de la SI sont �crites pour tout point dans
c	static_m/_r, le jacobien de la m�thode NR est form� et r�solu
c	dans coll_qs dans l'espace des splines

c	pour le mod�le quasi-statique, au temps �ge+dt
c	 param�tres ind�pendants du temps
c	  m_qs : ordre des splines pour l'int�gration par collocation 
c	  ord_qs=m_qs+r_qs=m_qs+1 : ordre de la repr�sentation spline
c	  ne : nombre d'inconnues (6 ou 7)
c	 param�tr�s d�pendants du temps
c	  nombre de couches au temps t : n_qs
c	  knot : nombre de points de table,
c	  dim_qs=knot-ord_qs : dimension de l'espace des splines
c	  bp(ne,dim_qs) : coefficients des splines
c	  q(n_qs), qt(knot) : abscisses, et vecteur nodal

c	pour la composition chimique, au temps t
c	 param�tr�s ind�pendants du temps
c	  m_ch : ordre de la repr�sentation spline
c	  nchim : nombre d'�l�ments chimiques
c	 param�tr�s d�pendants du temps
c	  nombre de couches au temps t : n_ch
c	  knotc : nombre de points de table (nodaux),
c	  dim_ch=knotc-m_ch : dimension de l'espace des splines 
c	  chim(nchim,dim_ch) : coefficients des splines
c	  q(n_ch), qt(knotc) : abscisses, et vecteur nodal

c	les quantit�s au temps t-dt ont l'extension _t
c	Exemple : knot_t est nombre de points de table de la
c	repr�sentation spline des variables du mod�le quasi-statique
c	au temps t-dt

c	Pour le probl�me de valeurs initiales appel � evol

c	en_masse = .TRUE. variables lagrangiennes m23=m**23, r2=r**2
c	en_masse = .FALSE. variables eul�riennes m23=m, r2=r

c	pour avoir un algorithme unique pour la diffusion, la composition
c	chimique est toujours tabul�e en fonction de mu=(m/Msol)^2/3
c	que ce soit en lagrangien ou en eul�rien

c	l'�nergie graviphique, TdS/dt=tds est tabul�e en fonction
c	de m23=m^2/3 en lagrangien et de m23=m en eul�rien,

c entr�es
c	un23 :  1 poursuite d'une �volution
c		2 calcul d'un mod�le initial de ZAMS
c		3 mod�le d'un mod�le initial de PMS
c	dt : pas temporel


c	variables globales de module utilis�es

c	�ge : �ge du mod�le
c	mc,mct,nc,knotc,chim: comp. chim. � t+dt
c	n_qs,bp,q,qt,knot,p,t,r,l,m :  var. pples. � t+dt
c	lim : nombre de limites ZR/ZC
c	jlim : abscisses des limites ZR/ZC
c	x_tds,xt_tds,m_tds,n_tds,knot_tds,tds: �l�ments pour interpoler
c	le TdS au temps t
c	m_zct : masses des limites des ZR/ZC au temps t
c	lconv_t =.TRUE. : debut de ZC au temps t
c	r_zc,r_ov : rayons de limites ZR/ZC et d'overshoot
c	m_zc : masses des limites des ZR/ZC au temps t+dt
c	lconv =.TRUE. : d�but de ZC au temps t+dt
c	mstar: masse avec perte de masse

c	dts : estimation du pas temporel suivant
c	reprise=.TRUE. : on poursuit une �volution

c	le r�seau de points de raccord q, poss�de n_qs points

c-------------------------------------------------------------------------
	
	USE mod_donnees, ONLY: agemax, ah,
	1 dpsi, dtmin, dx_tams, en_masse, he_ajuste, he_core, hhe_core,
	2 ini0, Krot, kipp, langue, lnt_stop, loc_zc, lsol, m_ch, m_qs,
	3 m_tds, mdot, nchim, ne, nucleo, n_max, n_min, ord_qs, ovshti, ovshts,
	4 pi, precision, precix, pturb, rsol, r_qs, secon6, sigma,
	5 t_ajuste, t_stop, w_rot, x_ajuste, x_stop, x_tams 
	USE mod_evol, ONLY: evol
	USE mod_etat, ONLY: etat
	USE mod_kind		 
	USE mod_nuc, ONLY: nuc
	USE mod_numerique, ONLY: bsp1dn, bvald, coll, gauss_band, noein, 
	1 no_croiss, pause, sum_n
        USE mod_variables, ONLY: age, bp, bp_t, chim, chim_gram,
	1 chim_t, inter, jlim, knot, knot_t,
	2 knot_tds, knotc, knotc_t, lconv, lhe_stop, lim, lt_stop,
	2 lx_stop, mc, mc_t, mct, mct_t, mstar, 
	4 mw_tot, m_zc, m23, m23_t, n_ch, n_ch_t,
	5 n_qs, n_qs_t, n_tds, n_tds_t, q, qt, q_t, qt_t, psi0, rstar,
	6 r_ov, r_zc, r2, r2_t, sortie, tds, x_tds, xt_tds_t, xt_tds, wrot
	
	IMPLICIT NONE

	INTEGER, INTENT(in) :: un23	
	REAL (kind=dp), INTENT(inout) :: dt, dts
	
	REAL (kind=dp), ALLOCATABLE, DIMENSION(:,:) :: vtr, jac	
	REAL (kind=dp), ALLOCATABLE, DIMENSION(:) :: l, m, p, pt, r, t, 
	1 vtm, vtmt	
	REAL (kind=dp), DIMENSION(nchim) :: dxchim, depsx, xchim, xchim_t
	REAL (kind=dp), DIMENSION(ne) :: f, dfdq	
	REAL (kind=dp), DIMENSION(5) :: epsilon

	REAL (kind=dp), PARAMETER :: err4=1.d0
	REAL (kind=dp), SAVE :: x_stopm, x_tamsm				
	REAL (kind=dp) :: alfa, beta, be7, b8, cp, corr, dcpp, dcpt,
	1 dcpx, delta, deltap, deltat, deltax, depst, depsro,
	2 drop, drot, drox, dup, dut, dux,
	3 err, errp, f17, gamma1, gradad, dgradadp, dgradadt, dgradadx, 
	4 dpt, dp_tm, dt_tm, dtt, hh, ma,  m23_mstar, n13, o15, pp, pp_t, 
	5 ro, ro_t, tp, tp_t, u, u_t
	
	INTEGER, PARAMETER :: iter_max0=40
	INTEGER, SAVE :: lq=1		
	INTEGER :: compt, i, iter_max, j, knotw, new_nqs, qmax, vare
		
	LOGICAL, SAVE :: init=.TRUE., ovsht
	LOGICAL :: reprend, logic, modif, no_rep
		
c-------------------------------------------------------------------------

2000	FORMAT(8es10.3)

c	IF(.TRUE.)CALL pause('entr�e resout')
	IF(.FALSE.)CALL pause('entr�e resout')

c D�but des initialisations-------------

	Iini: IF(init)THEN
	 init=.FALSE.

c �critures
	 SELECT CASE(langue)
	 CASE('english')	
	  WRITE(*,1001) ; WRITE(2,1001)
1001	  FORMAT(/,'------ Parameters for the quasi-static model ------',/)
	 CASE DEFAULT
	  WRITE(*,1) ; WRITE(2,1)
1	  FORMAT('----- Param�tres pour le mod�le quasi-statique ----',/)
	 END SELECT
	 
c initialisations diverses
 
c	 WRITE(*,2000)x_stopm,x_stop,ah !arret des que X(centre) <= x_stop
c	 CALL pause('ah')

c il y aura une nouvelle r�partition si la cte. de r�partition
c a vari� de plus de dpsi 

	 SELECT CASE(langue)
	 CASE('english')
	  WRITE(*,1214)psi0,NINT(dpsi*100.d0)
	  WRITE(2,1214)psi0,NINT(dpsi*100.d0)
1214	  FORMAT('Change of the repartition function per shell = ',es10.3,
	1 /,'The number of shells changes if the repartition constant',/,
	2 'varies by more than ',i2,'%')	 	
	 CASE DEFAULT
	  WRITE(*,214)psi0,NINT(dpsi*100.d0)
	  WRITE(2,214)psi0,NINT(dpsi*100.d0)
214	  FORMAT('saut de la fonction de r�partition par couche =',es10.3,
	1 /,'modification du nombre de couches si la constante de',/,
	2 'r�partition varie de plus de ',i2,'%')
	 END SELECT
	 	 
c	 v�rification	 
c	 DO i=1,n_qs
c	  CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(i),lq,f,dfdq)
c	  WRITE(*,2000)q(i),f(1:ne)
c	 ENDDO
c	 CALL pause('entr�e resout')

c	 si ovsht, il y a des overshoot

	 ovsht=MAX(ovshts,ovshti) > 0.d0

c le pas temporel dt est estim� dans update, � partir de sa
c valeur pr�c�dente et d'une estimation dts issue de evol
c bas�e sur la variation des abondances au pas temporel pr�c�dent
c au premier appel, dans le cas d'une reprise d'�volution (un23=1)
c dts est inconnu, on l'initialise � dt
c dans les autres cas (un23=1,3) dt=0 et dts=0 sont inutilis�s

c x_stop par mole
	 x_stopm=x_stop/ah
	 
c x_tamsm x_tams par mole
	 x_tamsm=x_tams/ah 
	 	 	 
	ENDIF Iini	!init
	
c Fin des initialisation---------- calcul des mod�les	

c	on diff�rencie les cas suivant un23:
c	un23 = 1 : poursuite d'une �volution
c	un23 = 2 : mod�le quasi-statique de ZAMS
c	un23 = 3 : mod�le quasi-statique de PMS

c	PRINT*,un23 ; WRITE(*,2000)dt ; CALL pause('avant select')

	SELECT CASE(un23)

c �volution d'un mod�le	
	CASE(1)		
	 SELECT CASE(langue)
	 CASE('english')	
	  WRITE(*,1002)
1002	  FORMAT('-- Integration of the quasi-static model (begin)---',/)
	 CASE DEFAULT
	  WRITE(*,2)
2	  FORMAT('-- Int�gration du mod�le quasi-statique (d�but)----',/)
	 END SELECT	

c d�termination du nombre de couches suivant la pr�cision requise
c pour le dernier mod�le ie. agemax-age < dt des mod�les en "sa"
c (solar accuracy), "hp" (hyper pr�cision), "co' (COROT) 
c on augmente le nombre de couches au maximum (psi0 tr�s petit)
c on augmente aussi la pr�cision de l'int�gration globale et
c celle de la localisation des limites ZR/ZC

	 IF(agemax-age <= dt)THEN
	  SELECT CASE(precision)
	  CASE('sa', 'sr', 'hp')
	   precix=5.d-6	!pr�cision de l'int�gration globale
	   psi0=1.d-6	!constante de r�partition tr�s petite
	   loc_zc=precix !pr�cision de la localisation des limites ZR/ZC
	  CASE('co')
	   psi0=1.d-6	!constante de r�partition tr�s petite
	  END SELECT	  	  
	 ENDIF

c	 on poursuit une �volution mod�le �ge --> mod�le �ge_t
c	 initialisation du nouveau dt
	
	 CALL update(.TRUE.,dt,dts)
	 WRITE(*,20)dt ; WRITE(2,20)dt	 
20	 FORMAT('Mod�le suivant, pas temporel dt=',es10.3)

c Int�gration mod�le quasi-statique boucle Bnr1 infinie de NR
c si compt=0 : utilisation du TdS/dt du pas pr�c�dent
c no_rep=.TRUE. : il n'y a pas eu de reprise

c	 CALL pause('resout avant boucle')

	 compt=0 ; modif=.FALSE. ; err=1.d20 ; no_rep=.TRUE.
	 Bnr1: DO
	  
c boucle infinie Bnr10 (reprend: TdS varie trop ou non CV dans evol)	 
	  Bnr10: DO

c tant que compt <= ini0 il y a d�termination de la
c perte de masse, des limites ZR/ZC et �volution de la composition
c chimique

	   reprend=.FALSE.	   
	   IR1: IF(compt <= ini0 .OR. modif)THEN
	   	 
c d�termination la nouvelle masse mstar en tenant compte de
c	    la perte de masse,
c	    avec perte_tot d�termination des diminutions de masse
c	    dues � E=mc^2 d'o� les abscisses (en m23 ou m) old_ptm
c	    � l'�ge, qui correspondent aux abscisses x_ptm � l'�ge t+dt
	 
	    CALL pertm(dt)
c	    PRINT*,n_ptm,m_ptm,knot_ptm ; CALL pause('pertm')
	    
c on estime si une modification du nb. de couches est n�cessaire
c bp(6,*) est la valeur du saut de la fonction de r�partition
c qui doit �tre �gal � psi0 +/- dpsi, le saut total de la
c fonction de r�partition avec n_qs couches doit �tre
c new_nqs*psi0 : n_qs*bp(6,1)=new_nqs*psi0
c variation MAX du nb. de couches : 10%
	    IR2: IF(compt == 0)THEN	     
	     IR3: IF(ABS(bp(6,1)-psi0)/psi0 > dpsi)THEN
c il y a eut reprise: pas de modif du nb. de couches	      
	      IF(.NOT.no_rep)THEN
	       new_nqs=n_qs
	      ELSE
	       new_nqs=bp(6,1)/psi0*n_qs	      	      
	       new_nqs=MIN(n_qs*1.1d0,MAX(new_nqs*1.d0,n_qs*0.9d0))	      
	       new_nqs=MAX(n_min,MIN(new_nqs,n_max))
	       IF(ABS(n_qs-new_nqs) < 20)new_nqs=n_qs
	      ENDIF	      
c	      PRINT*,'1,n_qs,new_nqs',n_qs,new_nqs ; PAUSE'new_qs'
	      IR4: IF(new_nqs /= n_qs)THEN
	       SELECT CASE(langue)
	       CASE('english')
	        WRITE(*,1218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi
	        WRITE(2,1218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi
1218	        FORMAT('Change of the number of shells for the',/,
	1       'quasi-static model from ',i5,' to ',i5,/,
	2       '(fct.rep.-psi0)/psi0=',es10.3,' <> dpsi=',es10.3)	     
	       CASE DEFAULT	     	     
	        WRITE(*,218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi
	        WRITE(2,218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi
218	        FORMAT('modif du nb. couches pour mod. quasi-stat. de ',
	1       i5,' � ',i5,/,'(fct.rep.-psi0)/psi0=',es10.3,' <> dpsi=',
	2       es10.3)
	       END SELECT	
	      ELSE IR4
	       SELECT CASE(langue)
	       CASE('english')
	        WRITE(*,1219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	        WRITE(2,1219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
1219	        FORMAT('The number of shells of the quasi-static model',/,
	1       'does not change n= ',i5,/,
	2       '(fct.rep.-psi0)/psi0=',es10.3,' < dpsi=',es10.3,/,
	3	'or because nmax is reached')	     
	       CASE DEFAULT     
	        WRITE(*,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	        WRITE(2,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
219	        FORMAT('no modif. nb. couches pour var. quasi-stat. n= ',
	1       i5,/,'(fct.rep.-psi0)/psi0=',es10.3,' < dpsi=',es10.3,/,
	2	'ou encore nmax est atteint')
	       END SELECT	 	
	      ENDIF IR4
	     ELSE IR3
	      new_nqs=n_qs
	      SELECT CASE(langue)
	      CASE('english')
	       WRITE(*,1219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	       WRITE(2,1219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
	      CASE DEFAULT 
	       WRITE(*,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	       WRITE(2,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
	      END SELECT
	     ENDIF IR3
	    ENDIF IR2
	    	    	    		 	
c d�termination des limites ZR/ZC et des facteurs de r�partition
c �ventuellement pr�c�d�e de l'optimisation de la r�partition
c	    PRINT*,no_rep ; CALL pause('no_rep')
	    CALL lim_zc(no_rep,new_nqs)	        
	    CALL evol(compt,dt,dts,reprend)
	   ENDIF IR1	   
   
	   IF(.NOT.reprend)THEN
c il n'y a pas eu de probl�me dans evol (CV dans rk_imps, diff_rota, diff_chim) 
c r�solution des �quations de la structure interne, le nombre d'it�rations
c maximal est d'autant plus grand que corr est voisin de 1
	    errp=err
	    CALL coll_qs(dt,compt,reprend,err,vare,qmax,corr)
	   ENDIF	    

c il y a eu probl�me dans evol ou coll_qs (cv ou TdS varie trop)
c no_rep=.FALSE : il y a eu reprise	   
	   IF(reprend)THEN
	    dt=dt*.6d0
	    IF(dt<1.d-7 .AND. precision=='ps') dt=7.5d-4
	    IF(dt < dtmin)THEN
	     WRITE(*,5)dt,dtmin ; WRITE(2,5)dt,dtmin ; CALL sortie !STOP
5	     FORMAT('dt =',es10.3,' < dt min.=',es10.3,', abandon')	     
	    ELSE			!reprise avec pas moiti�
	     WRITE(*,6)dt,dtmin ; WRITE(2,6)dt,dtmin
6	     FORMAT('r�duction du pas temporel dt =',es10.3,', dtmin =',
	1      es10.3)
	     CALL update(.FALSE.,dt,dts)  ; CALL pertm(dt) 
	     compt=0 ; err=1.d20 ; no_rep=.FALSE. ; CYCLE Bnr10
	    ENDIF
	   ELSE
	    EXIT Bnr10
	   ENDIF
	  ENDDO Bnr10
	  

	  IF(mdot > 1.d-6) THEN
	   IF(corr == 1.d0)THEN
	    iter_max=200
	   ELSEIF(corr == 2.d0)THEN
	    iter_max=150
	   ELSE
	    iter_max=100
	   ENDIF
	  ELSE
	   IF(corr == 1.d0)THEN
	    iter_max=20
	   ELSEIF(corr == 2.d0)THEN
	    iter_max=15
	   ELSE
	    iter_max=10
	   ENDIF
	  ENDIF

c d�compte du nombre d'it�rations	  
	  compt=compt+1
	 		
c �criture des variables quasi-statiques au max d'erreur
c couche d'indice qmax
	  PRINT* ; WRITE(*,100)compt,err,nom_qs(vare),qmax,1.d0/corr
100	  FORMAT('iter. globale:',i3,', err. max:',es8.1,
	1 ', var:',a,', couche: ',i5,', corr:',es8.1)		
	  CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(qmax),lq,f,dfdq)
	  IF(no_croiss)PRINT*,'Pb. en 4 dans resout'
	  IF(en_masse)THEN
	   IF(pturb)THEN
	    WRITE(*,101)(exp(f(i)),i=1,2),SQRT(ABS(f(3))),
	1   (SQRT(ABS(f(i)))**3,i=4,5),exp(f(7))
101	    FORMAT('variables Ptot, T, R, L, M, Pgaz :',6es10.3)	
	   ELSE
	    WRITE(*,103)(exp(f(i)),i=1,2),SQRT(ABS(f(3))),
	1   (SQRT(ABS(f(i)))**3,i=4,5)
103	    FORMAT('variables Pgaz, T, R, L, M :',5es10.3)		
	   ENDIF	
	  ELSE		!en rayon
	   IF(pturb)THEN	 
	    WRITE(*,101)(exp(f(i)),i=1,2),(f(i),i=3,5),exp(f(7))
	   ELSE
	    WRITE(*,103)(exp(f(i)),i=1,2),(f(i),i=3,5)	 
	   ENDIF
	   f(5)=f(5)**(2.d0/3.d0)	!en rayon f(5)=m
	  ENDIF
c	  WRITE(*,2000)bp(6,1) ; CALL pause('cv')

c	  IF(.TRUE.)CALL pause('apr�s �critures (EVOLUTION)')
        	 
c �criture de la comp. chim au max d'erreur
	  CALL bsp1dn(nchim,chim,mc,mct,n_ch,m_ch,
	1   knotc,.TRUE.,MAX(mc(1),MIN(f(5),mc(n_ch))),lq,xchim,dxchim)
	  IF(no_croiss)PRINT*,'Pb. en 5 dans resout'
	  CALL chim_gram(xchim,dxchim)
	  WRITE(*,102)(xchim(i),i=1,MIN(nchim,6))
102	  FORMAT('abon. -iers elem. :',6es10.3)

c pour �crire (debug) la solution interm�diaire 
	  IF(.FALSE.)THEN
c	  IF(.TRUE.)THEN
	   CALL pause('�criture')	 
	   ALLOCATE(l(n_qs),m(n_qs),p(n_qs),pt(n_qs),r(n_qs),t(n_qs)) 
	   DO i=1,n_qs
	    CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(i),lq,f,dfdq)
	    IF(no_croiss)PRINT*,'Pb. en 6 dans resout'	    
	    pt(i)=exp(f(1))	!variable ln Ptot
	    t(i)=exp(f(2))	!variable ln T
	    IF(pturb)THEN	!avec pression turbulente 8 inconnues	  
	     p(i)=exp(f(7))	!variable ln Pgaz
	    ELSE		!sans pression turbulente 7 inconnues
	     p(i)=pt(i)
	    ENDIF
	    IF(en_masse)THEN
	     r(i)=SQRT(ABS(f(3)))	!rayon/Rsol
	     l(i)=SQRT(ABS(f(4)))**3	!l/Lsol
	     m(i)=SQRT(ABS(f(5)))**3	!m/Mtot
	    ELSE
	     r(i)=ABS(f(3))	!rayon/Rsol
	     l(i)=f(4)		!l/Lsol
	     m(i)=ABS(f(5))	!m/Mtot
	     f(5)=m(i)**(2.d0/3.d0)
	    ENDIF
	    PRINT*,i ; WRITE(*,2000)pt(i),p(i),t(i),r(i),l(i),m(i),f(6)
	    CALL bsp1dn(nchim,chim,mc,mct,n_ch,m_ch,
	1     knotc,.TRUE.,MIN(f(5),mc(n_ch)),lq,xchim,dxchim)
	    IF(no_croiss)PRINT*,'Pb. en 7 dans resout'
	    WRITE(*,2000)xchim(1:8) ; WRITE(*,2000)xchim(9:nchim)	    
	   ENDDO
	   DEALLOCATE(l,m,p,pt,r,t)
	   CALL pause('solution interm�diaire')
	  ENDIF		!�criture de la solution interm�diaire
	   
c r�actualisation de m23 et r2 qui acc�l�rent la recherche dans le ssp.
c inter valable pour variables lagrangiennes alors m23=m^2/3, r2=r^2
c ou eul�riennes alors m23=m, r2=r
c	  PRINT*,ALLOCATED(r2),ALLOCATED(m23),n_qs,n_qs_t ; CALL pause('r2,m23')
          IF(n_qs /= n_qs_t)THEN          
	   IF(ALLOCATED(r2))THEN
	    DEALLOCATE(r2,m23) ; ALLOCATE(r2(n_qs),m23(n_qs))
	   ENDIF
	  ENDIF
	     	   
	  DO i=1,n_qs	   
c(test)	   CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(i),lq,f,dfdq)
	   r2(i)=bp(3,m_qs*(i-1)+1) ; m23(i)=bp(5,m_qs*(i-1)+1)
	  ENDDO
c	  CALL pause('r�actualisation de m23 et r2')

c gestion des it�rations	
c	  logic=compt >= 10 .AND. err < 5.d-2 .AND. dt < 0.1d0
c	1 .AND. ABS(err-errp) < precix !stagnation
	  logic=compt >= 10 .AND. err < precix .AND. dt < 0.1d0
	  IR7: IF((compt >= 2 .AND. err < precix) .OR. logic)THEN
	  
c arr�t sur x_stop � 10^-4 pr�s
	   IR12: IF(x_ajuste)THEN
c si on a travers� x_stop
	    IF(chim_t(1,1) > x_stopm .AND. chim(1,1) <= x_stopm)THEN
	     lx_stop=ABS(chim(1,1)-x_stopm) < dx_tams
c n'adjuste pas le pas temporel !!!!!!!!!!!!!!
c ================================================================
	     lx_stop=.TRUE.
c================================================================
	     IF(.NOT.lx_stop)THEN
	      dt=dt*(x_stopm-chim_t(1,1))/(chim(1,1)-chim_t(1,1))
	      SELECT CASE(langue)
	      CASE('english')
	       WRITE(*,1124)dt,x_stop,chim_t(1,1)*nucleo(1),chim(1,1)*nucleo(1)
	       WRITE(2,1124)dt,x_stop,chim_t(1,1)*nucleo(1),chim(1,1)*nucleo(1)
1124	       FORMAT(/,'adjustement of the time step to get x_stop at center',
	1      /,'dt=',es10.3,', X stop=',es10.3,', X(t)=',es10.3,', X(t+dt)=',
	2      es10.3)
	      CASE DEFAULT
	       WRITE(*,124)dt,x_stop,chim_t(1,1)*nucleo(1),chim(1,1)*nucleo(1)
	       WRITE(2,124)dt,x_stop,chim_t(1,1)*nucleo(1),chim(1,1)*nucleo(1)
124	       FORMAT(/,'ajustement du pas temp. pour avoir x_stop au centre',
	1      /,'dt=',es10.3,', X arret=',es10.3,', X(t)=',es10.3,', X(t+dt)=',
	2      es10.3)
	      END SELECT
	      CALL update(.FALSE.,dt,dts)
	      compt=0 ; err=1.d20 ; no_rep=.FALSE. ; modif=.TRUE.; CYCLE Bnr1
	     ENDIF
	    ENDIF
	   ENDIF IR12
	    
c arr�t sur T_stop
	   IR14: IF(t_ajuste)THEN	   
c si on a travers� t_stop
	    IF(bp_t(2,1) < lnt_stop .AND. bp(2,1) >= lnt_stop)THEN
	     lt_stop=ABS(bp(2,1)-lnt_stop) <= 1.d-5
c n'adjuste pas le pas temporel !!!!!!!!!!!!!!
c ================================================================
	     lt_stop=.TRUE.
c================================================================
	     IF(.NOT. lt_stop)THEN
	      dt=dt*(lnt_stop-bp_t(2,1))/(bp(2,1)-bp_t(2,1))
	      SELECT CASE(langue)
	      CASE('english')
	       WRITE(*,1125)dt,t_stop,EXP(bp_t(2,1)),EXP(bp(2,1))
	       WRITE(2,1125)dt,t_stop,EXP(bp_t(2,1)),EXP(bp(2,1))
1125	       FORMAT(/,'adjustement of the time step to get t_stop at center',
	1      /,'dt=',es10.3,', t stop=',es10.3,', T(t)=',es10.3,', T(t+dt)=',
	2      es10.3)
	      CASE DEFAULT
	       WRITE(*,125)dt,t_stop,EXP(bp_t(2,1)),EXP(bp(2,1))
	       WRITE(2,125)dt,t_stop,EXP(bp_t(2,1)),EXP(bp(2,1))
125	       FORMAT(/,'ajustement du pas temp. pour avoir t_stop au centre',
	1      /,'dt=',es10.3,', T arret=',es10.3,', T(t)=',es10.3,', T(t+dt)=',
	2      es10.3)
	      END SELECT
	      CALL update(.FALSE.,dt,dts)
	      compt=0 ; err=1.d20 ; no_rep=.FALSE. ; modif=.TRUE.; CYCLE Bnr1
	     ENDIF
	    ENDIF
	   ENDIF IR14
  
c arr�t sur He_core
	   IR15: IF(he_ajuste)THEN	   
c si on a travers� x_tams au niveau du He_core	   	   
	    CALL bsp1dn(nchim,chim,mc,mct,n_ch,m_ch,
	1   knotc,.TRUE.,hhe_core,lq,xchim,dxchim)
	    CALL bsp1dn(nchim,chim_t,mc_t,mct_t,n_ch_t,m_ch,
	1   knotc_t,.TRUE.,hhe_core,lq,xchim_t,dxchim)
	    IF(xchim_t(1) > x_tams .AND. xchim(1) <= x_tams)THEN
c le He core est n�cessairement plus grand qu'un core convectif avec X < X TAMS 	    
	     IF(m_zc(1) > he_core .AND. .NOT.lconv(1))THEN
	      SELECT CASE(langue)
	      CASE('english')     
	       WRITE(*,1127)he_core,m_zc(1) ; WRITE(2,1127)he_core,m_zc(1)
1127	       FORMAT(/,'STOP, X in the convective core have reached X TAMS',/,
	1      'unconsistency : He core =',es10.3,' < M_zc =',es10.3)	     
	      CASE DEFAULT	     
	       WRITE(*,127)he_core,m_zc(1) ; WRITE(2,127)he_core,m_zc(1)
127	       FORMAT(/,'ARRET, X dans le coeur convectif a atteint X TAMS,',/,
	1      'incompatibilit� : He core =',es10.3,' < M_zc =',es10.3)
	      END SELECT
	      CALL sortie
	     ENDIF
	     lhe_stop=ABS(xchim(1)-x_tams) < dx_tams
	     IF(.NOT.lhe_stop)THEN
	      dt=dt*(x_tamsm-xchim_t(1))/(xchim(1)-xchim_t(1))	     	 
	      SELECT CASE(langue)
	      CASE('english')
	       WRITE(*,1126)dt,xchim_t(1),he_core,xchim(1)
	       WRITE(2,1126)dt,xchim_t(1),he_core,xchim(1)
1126	       FORMAT(/,'adjustement of the time step to fit the He core',/,
	1      'dt=',es10.3,', X(t)=',es10.3,', he core=',es10.3,', X(t+dt)=',
	2      es10.3)
	      CASE DEFAULT
	       WRITE(*,126)dt,xchim_t(1),he_core,xchim(1)
	       WRITE(2,126)dt,xchim_t(1),he_core,xchim(1)
126	       FORMAT(/,'ajustement du pas temporel pour le He core', /,
	1      'dt=',es10.3,', X(t)=',es10.3,', he core=',es10.3,
	2      ', X(t+dt)=',es10.3)
	      END SELECT
              CALL update(.FALSE.,dt,dts)
	      compt=0 ; err=1.d20 ; no_rep=.FALSE. ; modif=.TRUE.; CYCLE Bnr1
	     ENDIF
	    ENDIF	
 	   ENDIF IR15

c convergence forc�e	    	   	  	  	  
	   IR13: IF(err > precix)THEN
	    SELECT CASE(langue)
	    CASE('english')
	     WRITE(*,1004) ; WRITE(2,1004)
1004	     FORMAT(/,'----------WARNING-----------',/,
	1    'Forced (5.d-2) convergency for this model',/,
	2    '-----------WARNING------------')	    
	    CASE DEFAULT	    
	     WRITE(*,4) ; WRITE(2,4)
4	     FORMAT(/,'----------ATTENTION-----------',/,
	1    'Convergence forc�e (5.d-2) pour ce mod�le',/,
	2    '----------ATTENTION-----------')
	    END SELECT  
	   ELSE IR13
	    SELECT CASE(langue)
	    CASE('english')
	     PRINT*,'The model is converged'	    
	    CASE DEFAULT
	     PRINT*,'Le mod�le a converg�'	    
	    END SELECT 	    
	   ENDIF IR13  

c on se satisfait de la convergence atteinte, on sort de Bnr1	   
	   EXIT Bnr1	   	  
	  ELSE IR7

c la convergence n'est pas atteinte plus d'it�rations sont n�cessaires,
c il y a au plus ini0 r�actualisations des limites ZR/ZC
c la r�partition est r�actualis�e au premier pas

	   IF(mdot > 1.d-6) THEN 
 	    IR5: IF(err > 1.d3 .AND. compt > 1)THEN
	     WRITE(*,10) ; WRITE(2,10) ; modif=.TRUE.	 
10	     FORMAT(/,'********',/,
	1    'pas de convergence dans resout mod�le trop �loign�',/,
	2    'diminution du pas temporel, r�initialisation',/,'********',/) 
	    ELSEIF(compt >= 20 .AND. err > err4)THEN IR5
	     WRITE(*,11) ; WRITE(2,11) ; modif=.TRUE.	 
11	     FORMAT(/,'********',/,'mauvaise convergence dans resout',/,
	1    'diminution du pas temporel',/,'********',/) 
	    ELSEIF(compt >= iter_max)THEN IR5
	     WRITE(*,12) ; WRITE(2,12) ; modif=.TRUE.	 
12	     FORMAT(/,'********',/,'pas de convergence dans resout',/,
	1    'diminution du pas temporel, r�initialisation',/,'********',/)
	    
c poursuite des it�rations sans r�actualisation de lim_zc, evol   
	    ELSE IR5	
	     modif=.FALSE.
	    ENDIF IR5

	   ELSE

	    IR66: IF(err > 1.d3 .AND. compt > 1)THEN
	     WRITE(*,10) ; WRITE(2,10) ; modif=.TRUE.	 
	    ELSEIF(compt >= 8 .AND. err > err4)THEN IR66
	     WRITE(*,11) ; WRITE(2,11) ; modif=.TRUE.	 
	    ELSEIF(compt >= iter_max)THEN IR66
	     WRITE(*,12) ; WRITE(2,12) ; modif=.TRUE.	 
	    
c poursuite des it�rations sans r�actualisation de lim_zc, evol   
	    ELSE IR66	
	     modif=.FALSE.
	    ENDIF IR66

	   ENDIF
	   
	   IR6: IF(modif)THEN
	    dt=dt*.6d0
	    IF(dt<1.d-7 .AND. precision=='ps') dt=1.d-3
	    IF(dt < dtmin)THEN
	     WRITE(*,5)dt,dtmin ; WRITE(2,5)dt,dtmin ; CALL sortie !STOP
	    ELSE
	     CALL update(.FALSE.,dt,dts)
	     compt=0 ; err=1.d20 ; no_rep=.FALSE. ; CYCLE Bnr1
	    ENDIF
	   ENDIF IR6
	  ENDIF	IR7	!compt >= 2			
	 ENDDO Bnr1	 
c	 CALL pause('sortie de Bnr1')
	 
c le mod�le quasi-static a converg�, d�termination de Teff, 
c de la situation convective, du TdS/dt,
c du moment angulaire, puis retour vers cesam 

	 WRITE(2,58)n_qs,n_ch
58	 FORMAT(/,'Nb. couches mod�le q.static : ',i5,
	1 ', Nb. couches comp.chim : ',i5)

c mod�le totalement convectif: lim=1,jlim(1)=n,lconv(1)=.FALSE.
c mod�le totalement radiatif: lim=0,jlim(i)=-100,lconv(i)=.FALSE.

	 IR8: IF(lim > 0)THEN
	  IR9: IF(lim == 1 .AND. jlim(1) == 1 .AND. .NOT.lconv(1))THEN
	   WRITE(2,7)
7	   FORMAT('mod�le compl�tement convectif',/)
	  ELSE IR9	  
	   WRITE(2,*) ; WRITE(2,9)
9	   FORMAT('limites Zones radiatives/convectives en Mstar ou Rstar')
	   DO j=1,lim
	    IR10: IF(ovsht)THEN
	     IR11: IF(lconv(j))THEN	!debut de ZC
	      IF(ovshts > 0.d0)THEN  !overshoot sup�rieur pas d'extension
	       WRITE(2,1221)jlim(j),m_zc(j)/mstar,r_zc(j)/rstar
1221	       FORMAT('couche:',i5,', masse:',es10.3,
	1      ', rayon du d�but de la ZC=',es10.3)	       	       
	      ELSE 			!overshoot inf�rieur extension
	       WRITE(2,122)jlim(j),m_zc(j)/mstar,r_ov(j)/rstar
122	       FORMAT('couche:',i5,', masse:',es10.3,
	1      ', rayon du d�but de l''overshoot inf�rieur=',es10.3)
	      ENDIF
	     ELSE IR11		!fin de ZC
	      IF(ovshts > 0.d0)THEN	!overshoot sup�rieur extension
	       WRITE(2,222)jlim(j),m_zc(j)/mstar,r_ov(j)/rstar
222	       FORMAT('couche:',i5,', masse:',es10.3,
	1      ', rayon de la fin de l''overshoot sup�rieur=',es10.3)
	      ELSE 	!overshoot inf�rieur pas d'extension
	       WRITE(2,2221)jlim(j),m_zc(j)/mstar,r_zc(j)/rstar
2221	       FORMAT('couche:',i5,', masse:',es10.3,
	1      ', rayon de la fin de la ZC=',es10.3)
	      ENDIF
	     ENDIF IR11
	    ELSE IR10	!sans overshoot
	     IF(lconv(j))THEN	
	      WRITE(2,1221)jlim(j),m_zc(j)/mstar,r_zc(j)/rstar
	     ELSE
	      WRITE(2,2221)jlim(j),m_zc(j)/mstar,r_zc(j)/rstar
	     ENDIF
	    ENDIF IR10
	   ENDDO
	   WRITE(2,*)
	  ENDIF IR9
	 ELSE IR8
	  WRITE(2,8)
8	  FORMAT('mod�le compl�tement radiatif',/)
	 ENDIF IR8
	  	
c 	 calcul du moment angulaire total et de la nouvelle valeur de la
c 	 vitesse angulaire cas de la conservation globale, et locale

	 IF(Krot == 2)THEN
	  ALLOCATE(vtr(1,n_qs),vtm(n_qs),vtmt(n_qs+m_ch))
	  DO i=1,n_qs
	   CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(i),lq,f,dfdq)
	   IF(no_croiss)PRINT*,'Pb. en 8 dans resout'
	   vtr(1,i)=f(3) ; vtm(i)=f(5)
	   IF(en_masse)THEN
	    vtm(i)=SQRT(vtm(i))**3		!m
	   ELSE
	    vtr(1,i)=vtr(1,i)**2		!r^2
	   ENDIF
	  ENDDO
	  vtm(1)=0.d0 ; vtr(1,1)=0.d0
	  CALL bsp1dn(1,vtr,vtm,vtmt,n_qs,m_ch,
	1   knotw,.FALSE.,vtm(1),lq,f,dfdq)
          IF(no_croiss)THEN
           PRINT*,'Arr�t 1 dans resout' ; CALL sortie !STOP
          ENDIF	
	  CALL sum_n(1,vtr,vtmt,m_ch,knotw,.FALSE.,vtm(1),vtm(n_qs),f)
	  mw_tot=f(1)*wrot
	  SELECT CASE(langue)
	  CASE('english')
	   WRITE(*,1382)wrot,mw_tot*2.d0/3.d0
1382	   FORMAT('angular velocity=',es10.3,
	1 ' rad/sec, total angular momentum=',es10.3,' sol. unit',/)	   
	  CASE DEFAULT	  
	   WRITE(*,382)wrot,mw_tot*2.d0/3.d0
382	   FORMAT('Vitesse angulaire=',es10.3,
	1 ' rad/sec, Moment angulaire total=',es10.3,' unite sol.',/)
	  END SELECT
	  DEALLOCATE(vtr,vtm,vtmt)
	 ENDIF

c initialisation de l'interpolation de TdS/dt en fonction de m23
c on ne tient pas compte de la diff�rence Pgaz, Ptot pour   
c l'�nergie graviphique, TdS/dt=tds qui est tabul� en fonction
c de m23=m^2/3 en lagrangien et de m23=m en eul�rien
c	 PRINT*,ALLOCATED(tds),ALLOCATED(x_tds),n_tds,n_tds_t

	 n_tds=n_qs
	 IF(n_tds /= n_tds_t)THEN
	  DEALLOCATE(tds,x_tds,xt_tds)
	  ALLOCATE(tds(1,n_tds),x_tds(n_qs),xt_tds(n_qs+m_tds))
	 ENDIF
	 Btds: DO i=1,n_tds
	  
c  variables au temps �ge+dt	  
	  CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(i),lq,f,dfdq)
	  IF(no_croiss)PRINT*,'Pb. en 9 dans resout'
	  IF(pturb)THEN	!avec pression turbulente 8 inconnues	  
	   pp=exp(f(7))	!variable ln Pgaz
	  ELSE		!sans pression turbulente 7 inconnues
	   pp=exp(f(1))
	  ENDIF
	  tp=exp(f(2))	!variable ln T
	  x_tds(i)=f(5)	!variable m^2/3 ou m
	  IF(en_masse)THEN
	   ma=SQRT(ABS(f(5)))**3
	  ELSE	  
	   ma=ABS(f(5)) ; f(5)= ma**(2.d0/3.d0)
	  ENDIF

	  CALL bsp1dn(nchim,chim,mc,mct,n_ch,m_ch,
	1   knotc,.TRUE.,MAX(mct(1),MIN(f(5),mc(n_ch))),lq,xchim,dxchim)
	  IF(no_croiss)PRINT*,'Pb. en 10 dans resout'
	  CALL chim_gram(xchim,dxchim)	  	   
	  CALL etat(pp,tp,xchim,.FALSE.,ro,drop,drot,drox,u,dup,dut,dux,
	1 delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	2 gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)
	  
c  variables au temps �ge
c------------------------------------------------------------------------------
	  m23_mstar=m23(i)*(1.d0-1.d6*mdot/mstar*dt)**(2.d0/3.d0) ! effects of accr!!
	  CALL inter('m23',bp_t,q_t,qt_t,n_qs_t,knot_t,m23_mstar,f,dfdq,
	1   r2_t,m23_t)	
c------------------------------------------------------------------------------
	  IF(pturb)THEN	!avec pression turbulente 7 inconnues
	   pp_t=EXP(f(7)) ; dp_tm=dfdq(7)*pp_t
	  ELSE			!sans pression turbulente 6 inconnues
	   pp_t=EXP(f(1)) ; dp_tm=dfdq(1)*pp_t
	  ENDIF
	  tp_t=EXP(f(2)) ; dt_tm=dfdq(2)*tp_t

	  IF(kipp)THEN	!approximation de Kippenhahan
	   tds(1,i)=(cp*(tp-tp_t)-delta/ro*(pp-pp_t))/dt	   
	  ELSE		!TdS=dU+PdV
	   ma=ABS(m23(i))	!interpolation en m**2/3 pour xchim	   
	   IF(.NOT.en_masse)ma=ma**(2.d0/3.d0)
	   CALL bsp1dn(nchim,chim_t,mc_t,mct_t,n_ch_t,m_ch,
	1  knotc_t,.TRUE.,MAX(mc_t(1),MIN(ma,mc_t(n_ch_t))),lq,xchim,
	2  dxchim)
	   IF(no_croiss)PRINT*,'Pb. en 11 dans resout'
	   CALL chim_gram(xchim,dxchim)		!X, Y, Z
c	   WRITE(*,2000)bid,pp_t,tp_t	   
	   CALL etat(pp_t,tp_t,xchim,.FALSE.,
	1  ro_t,drop,drot,drox,u_t,dup,dut,dux,
	2  delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	3  gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)
	   tds(1,i)=(u-u_t-pp/ro**2*(ro-ro_t))/dt
	  ENDIF	!kipp
c	  WRITE(*,2000)tds(1,i),u,u_t,pp,pp_t,tp_t,ro,ro_t ; Pause'TdS'     
	 ENDDO Btds
	 	 
c tabulation du TdS au temps �ge+dt
c	 PRINT*,ALLOCATED(tds),ALLOCATED(x_tds),ALLOCATED(xt_tds),n_qs,n_qs_t	 

c	v�rification de la stricte croissance des abscisses

c	 j=2
c	 Btds: DO
c	  IF(j >= n_tds)EXIT Btds
c	  IF(x_tds(j) <= x_tds(j-1))THEN
c	   n_tds=n_tds-1 ; x_tds(j:n_tds)=x_tds(j+1:n_tds+1)
c	   tds(1,j:n_tds)=tds(1,j+1:n_tds+1)
c	  ELSE
c	   j=j+1
c	  ENDIF	  
c	 ENDDO Btds
	 	 
	 CALL bsp1dn(1,tds,x_tds,xt_tds,n_tds,m_tds,knot_tds,.FALSE.,x_tds(1),
	1 lq,f,dfdq)
         IF(no_croiss)THEN
          PRINT*,'Arr�t 2 dans resout' ; CALL sortie !STOP
         ENDIF	
c	 PRINT*,n_tds,m_tds,knot_tds ; CALL pause('apr�s tabulation TdS')
		
c	 l'�volution entre �ge et �ge+dt est termin�e, retour vers cesam	

	 SELECT CASE(langue)
	 CASE('english')	
	  WRITE(*,1003)
1003	  FORMAT(/,'--- Integration of the quasi-static model (end)----')
	 CASE DEFAULT
	  WRITE(*,3)
3	  FORMAT(/,'---- Int�gration du mod�le quasi-statique (fin)----')
	 END SELECT

	 RETURN	
	
c mod�le quasi-statique de ZAMS
	
	CASE(2)	
	 SELECT CASE(langue)
	 CASE('english')	
	  WRITE(*,1041)
1041	  FORMAT(/,'Integration of the ZAMS quasi-static model (begin)',/)
	 CASE DEFAULT
	  WRITE(*,41)
41	  FORMAT(/,'Int�gration du mod�le quasi-statique de ZAMS(d�but)',/)
	 END SELECT	

c	 d�termination du nombre de couches suivant la pr�cision requise

c	 WRITE(*,2000)bp(6,1),psi0, bp(6,1)-psi0, dpsi
c	 CALL pause('psi0')
	 IS5: IF(ABS(bp(6,1)-psi0)/psi0 > dpsi)THEN
	  new_nqs=bp(6,1)/psi0*n_qs
c	  PRINT*,'new_qs=',new_nqs ; WRITE(*,2000)bp(6,1) ; PAUSE'psi0_2'
	  new_nqs=MAX(n_min,MIN(new_nqs,n_max))
	  IF(ABS(n_qs-new_nqs) < 20)new_nqs=n_qs	  	  
	  IF(new_nqs /= n_qs)THEN
	   SELECT CASE(langue)
	   CASE('english')
	    WRITE(*,1218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi
	    WRITE(2,1218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi	   
	   CASE DEFAULT  
	    WRITE(*,218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi
	    WRITE(2,218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi
	   END SELECT
c	   CALL pause('new_qs=')
	  ELSE
	   SELECT CASE(langue)
	   CASE('english')
	    WRITE(*,1219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	    WRITE(2,1219)n_qs,(bp(6,1)-psi0)/psi0,dpsi 
	   CASE DEFAULT  
	    WRITE(*,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	    WRITE(2,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
	   END SELECT	   
	  ENDIF
	 ELSE	 
	  new_nqs=n_qs
	  SELECT CASE(langue)
	  CASE('english')
	   WRITE(*,1219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	   WRITE(2,1219)n_qs,(bp(6,1)-psi0)/psi0,dpsi 
	  CASE DEFAULT  
	   WRITE(*,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	   WRITE(2,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
	  END SELECT
	 ENDIF IS5
	
c d�termination des limites ZR/ZC et des facteurs de r�partition
c pr�c�d�e, �ventuellement, de l'optimisation de la r�partition
	
	 no_rep=.TRUE.		 !PRINT*,no_rep
	 CALL lim_zc(no_rep,new_nqs)
	
c Int�gration mod�le quasi-statique boucle Bnr2 infinie de NR

	 compt=0 ; err=1.d20
	 Bnr2: DO
	  errp=err
	  CALL coll_qs(dt,compt,reprend,err,vare,qmax,corr)
	  compt=compt+1
	 		
c �criture des variables quasi-statiques au max d'erreur
	  PRINT*
	  WRITE(*,100)compt,err,nom_qs(vare),qmax,1.d0/corr	
	  CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(qmax),lq,f,dfdq)
	  IF(no_croiss)PRINT*,'Pb. en 12 dans resout'
	  IF(en_masse)THEN
	   IF(pturb)THEN
	    WRITE(*,101)(exp(f(i)),i=1,2),SQRT(ABS(f(3))),
	1   (SQRT(ABS(f(i)))**3,i=4,5),exp(f(7))
	   ELSE
	    WRITE(*,103)(exp(f(i)),i=1,2),SQRT(ABS(f(3))),
	1   (SQRT(ABS(f(i)))**3,i=4,5)	
	   ENDIF	
	  ELSE		!en rayon
	   IF(pturb)THEN	 
	    WRITE(*,101)(exp(f(i)),i=1,2),(f(i),i=3,5),exp(f(7))
	   ELSE
	    WRITE(*,103)(exp(f(i)),i=1,2),(f(i),i=3,5)	 
	   ENDIF
	   f(5)=f(5)**(2.d0/3.d0)	!en rayon f(5)=m
	  ENDIF
	  
c	  WRITE(*,2000)bp(6,1) ; CALL pause('bp(6,1)')

c	  IF(.TRUE.)CALL pause('apr�s �critures (ZAMS)')
         
c r�actualisation de m23 et r2 qui acc�l�rent la
c recherche dans le ssp. inter
c valable pour variables lagrangiennes alors m23=m^2/3, r2=r^2
c ou eul�riennes alors m23=m, r2=r
	   
	  DO i=1,n_qs	   
c(test)   CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(i),lq,f,dfdq)
	   r2(i)=bp(3,m_qs*(i-1)+1) ; m23(i)=bp(5,m_qs*(i-1)+1)
	  ENDDO

c pour �crire (debug) la solution interm�diaire
	  IF(.FALSE.)THEN
c	  IF(.TRUE.)THEN
	   PAUSE'�criture'	 
	   ALLOCATE(l(n_qs),m(n_qs),p(n_qs),pt(n_qs),r(n_qs),t(n_qs)) 

	   DO i=1,n_qs			!convergence totale si dt>0
	    CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(i),lq,f,dfdq)
	    IF(no_croiss)PRINT*,'Pb. en 13 dans resout'
	    pt(i)=exp(f(1))	!variable ln Ptot
	    t(i)=exp(f(2))	!variable ln T
	    IF(pturb)THEN	!avec pression turbulente 8 inconnues	  
	     p(i)=exp(f(7))	!variable ln Pgaz
	    ELSE		!sans pression turbulente 7 inconnues
	     p(i)=pt(i)
	    ENDIF
	    IF(en_masse)THEN
	     r(i)=SQRT(ABS(f(3)))	!rayon/Rsol
	     l(i)=SQRT(ABS(f(4)))**3	!l/Lsol
	     m(i)=SQRT(ABS(f(5)))**3	!m/Mtot
	    ELSE
	     r(i)=ABS(f(3))	!rayon/Rsol
	     l(i)=f(4)	!l/Lsol
	     m(i)=ABS(f(5))	!m/Mtot
	     f(5)=m(i)**(2.d0/3.d0)
	    ENDIF
	    PRINT*,i ; WRITE(*,2000)pt(i),p(i),t(i),r(i),l(i),m(i),f(6)
	   ENDDO
	   DEALLOCATE(l,m,p,pt,r,t) ; CALL pause('solution interm�diaire')
	  ENDIF		!�criture de la solution interm�diaire
	
	  logic=compt >= 10 .AND. err < 5.d-2 .AND. dt < 0.1d0
	1 .AND. ABS(err-errp) < precix !stagnation
	  IS0: IF((compt >= 2 .AND. err < precix) .OR. logic)THEN
	   IF(err > precix)THEN
	    WRITE(*,4) ; WRITE(2,4)
	   ELSE
	    SELECT CASE(langue)
	    CASE('english')
	     WRITE(*,1215)
1215	     FORMAT('the model of ZAMS is obtained')
	    CASE DEFAULT
	     WRITE(*,215)
215	     FORMAT('le mod�le de ZAMS a converg�')	     
	    END SELECT	   
	   ENDIF
	   WRITE(2,58)n_qs,n_ch

c mod�le totalement convectif: lim=1,jlim(1)=n,lconv(1)=.FALSE.
c mod�le totalement radiatif: lim=0,jlim(i)=-100,lconv(i)=.FALSE.
	   IF(lim > 0)THEN
	    IF(lim == 1 .AND. jlim(1) == 1 .AND. .NOT. lconv(1))THEN
	     WRITE(2,7)
	    ELSE
	     WRITE(2,*) ; WRITE(2,9)
	     DO j=1,lim
	      IF(ovsht)THEN
	       IF(lconv(j))THEN
	        IF(ovshts > 0.d0)THEN  !overshoot sup�rieur pas d'extension
	         WRITE(2,1221)jlim(j),m_zc(j)/mstar,r_zc(j)/rstar
	        ELSE 			!overshoot inf�rieur extension
	         WRITE(2,122)jlim(j),m_zc(j)/mstar,r_ov(j)/rstar  
	        ENDIF
	       ELSE		!fin de ZC
	        IF(ovshts > 0.d0)THEN	!overshoot sup�rieur extension	     
	         WRITE(2,222)jlim(j),m_zc(j)/mstar,r_ov(j)/rstar
	        ELSE 	!overshoot inf�rieur pas d'extension
	         WRITE(2,2221)jlim(j),m_zc(j)/mstar,r_zc(j)/rstar
	        ENDIF
	       ENDIF
	      ELSE	!sans overshoot
	       IF(lconv(j))THEN	
	        WRITE(2,1221)jlim(j),m_zc(j)/mstar,r_zc(j)/rstar
	       ELSE
	        WRITE(2,2221)jlim(j),m_zc(j)/mstar,r_zc(j)/rstar
	       ENDIF
	      ENDIF
	     ENDDO
	    ENDIF
	   ELSE
	    WRITE(2,8)
	   ENDIF
	   PRINT*
	  	
c	   calcul du moment angulaire total et de la nouvelle valeur de la
c	   vitesse angulaire cas de la conservation globale

	   IF(Krot == 2 )THEN
	    ALLOCATE(vtr(1,n_qs),vtm(n_qs),vtmt(n_qs+m_ch))
	    DO i=1,n_qs
	     CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(i),lq,f,dfdq)
	     IF(no_croiss)PRINT*,'Pb. en 14 dans resout'
	     vtr(1,i)=f(3) ; vtm(i)=f(5)
	     IF(en_masse)THEN
	      vtm(i)=SQRT(vtm(i))**3		!m
	     ELSE
	      vtr(1,i)=vtr(1,i)**2		!r^2
	     ENDIF
	    ENDDO
	    vtm(1)=0.d0 ; vtr(1,1)=0.d0
	    CALL bsp1dn(1,vtr,vtm,vtmt,n_qs,m_ch,knotw,.FALSE.,
	1     vtm(1),lq,f,dfdq)
            IF(no_croiss)THEN
             PRINT*,'Arr�t 3 dans resout' ; CALL sortie !STOP
            ENDIF	
	    CALL sum_n(1,vtr,vtmt,m_ch,knotw,.FALSE.,vtm(1),vtm(n_qs),f)
	    mw_tot=f(1)*wrot
	    SELECT CASE(langue)
	    CASE('english')
	     WRITE(*,1038)wrot,mw_tot*2.d0/3.d0
1038	     FORMAT('For the homogeneous ZAMS model:',/,
	1    'angular velocity=',es10.3,
	2    ' rad/sec, total angular momentum =',es10.3,' sol. unit',/)    
	    CASE DEFAULT
	     WRITE(*,38)wrot,mw_tot*2.d0/3.d0	    	    
38	     FORMAT('Pour le mod�le de ZAMS homog�ne:',/,
	1    'Vitesse angulaire=',es10.3,
	2    ' rad/sec, Moment angulaire total=',es10.3,' unit� sol.',/)
	    END SELECT	
	    DEALLOCATE(vtr,vtm,vtmt)	  
	   ENDIF
	   
c initialisation de l'interpolation de TdS/dt en fonction de m23
c on ne tient pas compte de la diff�rence Pgaz, Ptot pour
c l'�nergie graviphique, TdS/dt=tds qui est tabul�e en fonction
c de m23=m^2/3 en lagrangien et de m23=m en eul�rien
c TdS/dt =0 sur la ZAMS
	   n_tds=n_qs
	   IF(ALLOCATED(tds))DEALLOCATE(tds,x_tds,xt_tds)
	   ALLOCATE(tds(1,n_tds),x_tds(n_tds),xt_tds(n_tds+m_tds))
	   x_tds=m23 ; tds=0.d0
	   CALL noein(x_tds,xt_tds,n_tds,m_tds,knot_tds)
           IF(no_croiss)THEN
            PRINT*,'Arr�t 6 dans resout' ; CALL sortie !STOP
           ENDIF
	   		   
c mod�le converg�, sortie de brn2, puis retour vers cesam	   
	   EXIT Bnr2
	   
	  ELSEIF(compt >= iter_max0)THEN IS0
	   WRITE(*,220) ; WRITE(2,220) ; CALL sortie !STOP	
220        FORMAT('no conv. du mod�le quasi-statique de ZAMS, ARRET')

	  ELSE IS0
	  
c	   plus d'it�rations sont n�cessaires, il y a 
c	   au plus ini0 r�actualisations des limites ZR/ZC
c	   et de la r�partition

	   IS1: IF(compt < ini0)THEN
	    IS2: IF(compt < 1)THEN
	     IS3: IF(ABS(bp(6,1)-psi0)/psi0 > dpsi)THEN
	      new_nqs=bp(6,1)/psi0*n_qs
c	      PRINT*,'new_qs=',new_nqs
	      new_nqs=MAX(n_min,MIN(new_nqs,n_max))
	      IF(ABS(n_qs-new_nqs) < 20)new_nqs=n_qs
	      IS4: IF(new_nqs /= n_qs)THEN
	       SELECT CASE(langue)
	       CASE('english')
	        WRITE(*,1218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi
	        WRITE(2,1218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi	      
	       CASE DEFAULT	     	     
	        WRITE(*,218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi
	        WRITE(2,218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi
	       END SELECT	      
c	       CALL pause('new_qs2')
	      ELSE IS4
	       SELECT CASE(langue)
	       CASE('english')
	        WRITE(*,1219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	        WRITE(2,1219)n_qs,(bp(6,1)-psi0)/psi0,dpsi 
	       CASE DEFAULT	     	     
	        WRITE(*,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	        WRITE(2,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
	       END SELECT
	      ENDIF IS4
	     ELSE IS3
	      new_nqs=n_qs
	      SELECT CASE(langue)
	      CASE('english')
	       WRITE(*,1219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	       WRITE(2,1219)n_qs,(bp(6,1)-psi0)/psi0,dpsi 
	      CASE DEFAULT
	       WRITE(*,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	       WRITE(2,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
	      END SELECT
	     ENDIF IS3
	    ENDIF IS2	     
	    CALL lim_zc(no_rep,new_nqs)
c	    CALL pause('apr�s lim_zc')
	   ENDIF IS1	!compt < ini0	  
	  ENDIF	IS0	!compt >= 2			
	 ENDDO Bnr2
	 
c le mod�le quasi-static de ZAMS a converg�, retour vers cesam

	 SELECT CASE(langue)
	 CASE('english')	
	  WRITE(*,1051)
1051	  FORMAT('---Integration of the ZAMS quasi-static model (end)---',/)
	 CASE DEFAULT
	  WRITE(*,51)
51	  FORMAT('---Int�gration du mod�le quasi-statique de ZAMS(fin)---',
	1   /)
	 END SELECT
	
c>>	 mod�le quasi-statique de PMS
c	 un23=3 pour le premier mod�le de PMS calcul� avec c_iben
c	 un23=-3 pour le second mod�le de PMS calcul� avec c_iben*1.1
	
	CASE(-3, 3)
	
	 SELECT CASE(langue)
	 CASE('english')	
	  WRITE(*,1061)
1061	  FORMAT(/,'Integration of the PMS quasi-static model (begin)',/)
	 CASE DEFAULT
	  WRITE(*,61)
61	  FORMAT(/,'Int�gration du mod�le quasi-statique de PMS(d�but)',/)
	 END SELECT	
	
	 no_rep=.TRUE.

	 IF(un23 == 3)THEN
	 
c d�termination du nombre de couches suivant la pr�cision requise

c	  WRITE(*,2000)bp(6,1),psi0, bp(6,1)-psi0, dpsi
c	  CALL pause('psi0')
	  IF(ABS(bp(6,1)-psi0)/psi0 > dpsi)THEN
	   new_nqs=bp(6,1)/psi0*n_qs
c	   PRINT*,'new_qs=',new_nqs
	   new_nqs=MAX(n_min,MIN(new_nqs,n_max))
	   IF(ABS(n_qs-new_nqs) < 20)new_nqs=n_qs	  
	   IF(new_nqs /= n_qs)THEN
	    WRITE(*,218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi
	    WRITE(2,218)n_qs,new_nqs,(bp(6,1)-psi0)/psi0,dpsi
c	    CALL pause('new_qs3')
	   ELSE
	    WRITE(*,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	    WRITE(2,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi	
	   ENDIF
	  ELSE
	   new_nqs=n_qs
	   WRITE(*,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
c	   WRITE(2,219)n_qs,(bp(6,1)-psi0)/psi0,dpsi
	  ENDIF
	
c	  d�termination des limites ZR/ZC et des facteurs de r�partition
c	  pr�c�d�e, �ventuellement, de l'optimisation de la r�partition
	
c	  PRINT*,no_rep
	  CALL lim_zc(no_rep,new_nqs)
	 ENDIF
	
c	 Int�gration du mod�le quasi-statique boucle bnr3 infinie de NR

	 compt=0 ; err=1.d20
	 bnr3: DO
	  errp=err
	  CALL coll_qs(dt,compt,reprend,err,vare,qmax,corr)
	  compt=compt+1
	 		
c	  �criture des variables quasi-statiques au max d'erreur

	  PRINT* ; WRITE(*,100)compt,err,nom_qs(vare),qmax,1.d0/corr	
	  CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(qmax),lq,f,dfdq)
	  IF(no_croiss)PRINT*,'Pb. en 15 dans resout'
	  IF(en_masse)THEN
	   IF(pturb)THEN
	    WRITE(*,101)(exp(f(i)),i=1,2),SQRT(ABS(f(3))),
	1   (SQRT(ABS(f(i)))**3,i=4,5),exp(f(7))
	   ELSE
	    WRITE(*,103)(exp(f(i)),i=1,2),SQRT(ABS(f(3))),
	1   (SQRT(ABS(f(i)))**3,i=4,5)	
	   ENDIF	
	  ELSE		!en rayon
	   IF(pturb)THEN	 
	    WRITE(*,101)(exp(f(i)),i=1,2),(f(i),i=3,5),exp(f(7))
	   ELSE
	    WRITE(*,103)(exp(f(i)),i=1,2),(f(i),i=3,5)	 
	   ENDIF
	   f(5)=f(5)**(2.d0/3.d0)	!en rayon f(5)=m
	  ENDIF

c	  IF(.TRUE.)CALL pause('apr�s �critures (PMS)')
	   
c	  r�actualisation de m23 et r2 qui acc�l�rent la
c	  recherche dans le ssp. inter
c	  valable pour variables lagrangiennes alors m23=m^2/3, r2=r^2
c	  ou eul�riennes alors m23=m, r2=r
	   
	  DO i=1,n_qs	   
c(test)	   CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(i),lq,f,dfdq)
	   r2(i)=bp(3,m_qs*(i-1)+1) ; m23(i)=bp(5,m_qs*(i-1)+1)
	  ENDDO

c	  pour �crire (debug) la solution interm�diaire
 
	  IF(.FALSE.)THEN
c	  IF(.TRUE.)THEN
	   CALL pause('�criture')	 
	   ALLOCATE(l(n_qs),m(n_qs),p(n_qs),pt(n_qs),r(n_qs),t(n_qs)) 
	   DO i=1,n_qs			!convergence totale si dt>0
	    CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(i),lq,f,dfdq)
	    IF(no_croiss)PRINT*,'Pb. en 1 dans resout'
	    pt(i)=exp(f(1))	!variable ln Ptot
	    t(i)=exp(f(2))	!variable ln T
	    IF(pturb)THEN	!avec pression turbulente 8 inconnues	  
	     p(i)=exp(f(7))	!variable ln Pgaz
	    ELSE		!sans pression turbulente 7 inconnues
	     p(i)=pt(i)
	    ENDIF
	    IF(en_masse)THEN
	     r(i)=SQRT(ABS(f(3)))	    !rayon/Rsol
	     l(i)=SQRT(ABS(f(4)))**3	!l/Lsol
	     m(i)=SQRT(ABS(f(5)))**3	!m/Mtot
	    ELSE
	     r(i)=ABS(f(3))	!rayon/Rsol
	     l(i)=f(4)	!l/Lsol
	     m(i)=ABS(f(5))	!m/Mtot
	     f(5)=m(i)**(2.d0/3.d0)
	    ENDIF
	    PRINT*,i ; WRITE(*,2000)pt(i),p(i),t(i),r(i),l(i),m(i),f(6)
	   ENDDO
	   DEALLOCATE(l,m,p,pt,r,t)
	   CALL pause('solution interm�diaire')
	  ENDIF		!�criture de la solution interm�diaire	  
	  
c	  gestion des it�rations
	
	  logic=compt >= 10 .AND. err < 5.d-2 .AND. dt < 0.1d0
	1 .AND. ABS(err-errp) < precix !stagnation

	  IF((compt >= 2 .AND. err < precix) .OR. logic)THEN
	   IF(err > precix)THEN
	    WRITE(*,4) ; WRITE(2,4)
	   ELSE 
	    PRINT* ; PRINT*,'mod�le de PMS converg�'
	   ENDIF	  

	   WRITE(2,58)n_qs,n_ch
	   
c	   mod�le totalement convectif: lim=1,jlim(1)=n,lconv(1)=.FALSE.
c	   mod�le totalement radiatif: lim=0,jlim(i)=-100,lconv(i)=.FALSE.

	   IF(lim > 0)THEN
	    IF(lim == 1 .AND. jlim(1) == 1 .AND. .NOT. lconv(1))THEN
	     WRITE(2,7)
	    ELSE
	     WRITE(2,*) ; WRITE(2,9)
	     DO j=1,lim
	      IF(ovsht)THEN
	       IF(lconv(j))THEN	
	        IF(ovshts > 0.d0)THEN  !overshoot sup. pas d'extension
	         WRITE(2,1221)jlim(j),m_zc(j)/mstar,r_zc(j)/rstar
	        ELSE 			!overshoot inf�rieur extension
	         WRITE(2,122)jlim(j),m_zc(j)/mstar,r_ov(j)/rstar	      
	        ENDIF
	       ELSE		!fin de ZC
	        IF(ovshts > 0.d0)THEN	!overshoot sup�rieur extension	     
	         WRITE(2,222)jlim(j),m_zc(j)/mstar,r_ov(j)/rstar
	        ELSE 	!overshoot inf�rieur pas d'extension
	         WRITE(2,2221)jlim(j),m_zc(j)/mstar,r_zc(j)/rstar
	        ENDIF
	       ENDIF
	      ELSE	!sans overshoot
	       IF(lconv(j))THEN	
	        WRITE(2,1221)jlim(j),m_zc(j)/mstar,r_zc(j)/rstar
	       ELSE
	        WRITE(2,2221)jlim(j),m_zc(j)/mstar,r_zc(j)/rstar
	       ENDIF
	      ENDIF
	     ENDDO
	    ENDIF
	   ELSE
	    WRITE(2,8)
	   ENDIF
	   PRINT*
	  	
c	   calcul du moment angulaire total et de la nouvelle valeur de la
c	   vitesse angulaire cas de la conservation globale

	   IF(Krot == 2)THEN
	    ALLOCATE(vtr(1,n_qs),vtm(n_qs),vtmt(n_qs+m_ch))
	    DO i=1,n_qs
	     CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(i),lq,f,dfdq)
	     IF(no_croiss)PRINT*,'Pb. en 2 dans resout'
	     vtr(1,i)=f(3)
	     vtm(i)=f(5)
	     IF(en_masse)THEN
	      vtm(i)=SQRT(vtm(i))**3		!m
	     ELSE
	      vtr(1,i)=vtr(1,i)**2		!r^2
	     ENDIF
	    ENDDO
	    vtm(1)=0.d0 ; vtr(1,1)=0.d0
	    CALL bsp1dn(1,vtr,vtm,vtmt,n_qs,m_ch,knotw,.FALSE.,vtm(1),
	1     lq,f,dfdq)
            IF(no_croiss)THEN
             PRINT*,'Arr�t 4 dans resout' ; CALL sortie !STOP
            ENDIF
	    CALL sum_n(1,vtr,vtmt,m_ch,knotw,.FALSE.,vtm(1),vtm(n_qs),f)
	    mw_tot=f(1)*wrot
	    SELECT CASE(langue)
	    CASE('english')
	     WRITE(*,1381)wrot,mw_tot*2.d0/3.d0	    
1381	     FORMAT('For the homogeneous PMS model:',/,
	1    'angular velocity=',es10.3,
	2    ' rad/sec, total angular momentum =',es10.3,' sol. unit',/)
	    CASE DEFAULT
	     WRITE(*,381)wrot,mw_tot*2.d0/3.d0
381	     FORMAT('Pour le mod�le de PMS homog�ne:',/,
	1    'Vitesse angulaire=',es10.3,
	2    ' rad/sec, Moment angulaire total=',es10.3,' unite sol.'/)
	    END SELECT
	    DEALLOCATE(vtr,vtm,vtmt)	  
	   ENDIF
	   
c	   initialisation de l'interpolation de TdS/dt en fonction de m23
c	   l'�nergie graviphique, TdS/dt=tds est tabul�e en fonction
c	   de m23=m^2/3 en lagrangien et de m23=m en eul�rien,
c	   pour le premier mod�le de PMS avec c_iben, TdS/dt = 0
c	   on a pose un23=3 
c	   pour le second mod�le de PMS avec c_iben*1.1, TdS/dt \= 0
c	   on a pose un23=-3
c	   le tableau tds peut avoir �t� allou� lors du premier passage

	   n_tds=n_qs
	   IF(un23 < 0)THEN
	    IF(ALLOCATED(tds))DEALLOCATE(tds,x_tds,xt_tds)	   
	    ALLOCATE(tds(1,n_tds),x_tds(n_tds),xt_tds(n_tds+m_tds),
	1   jac(nchim,nchim))

c	    la composition chimique �tant uniforme xchim(1)=chim(1,1), etc.

	    xchim(:)=chim(:,1) ; dxchim=0.d0	    	    
	    CALL chim_gram(xchim,dxchim)
	    DO i=1,n_tds
	     CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(i),lq,f,dfdq)
	     IF(no_croiss)PRINT*,'Pb. 3 en dans resout'
	     IF(pturb)THEN	!avec pression turbulente 8 inconnues	  
	      pp=exp(f(7))	!variable ln Pgaz
	     ELSE		!sans pression turbulente 7 inconnues
	      pp=exp(f(1))
	     ENDIF
	     tp=exp(f(2))	!variable ln T
	     x_tds(i)=f(5)	       
	     CALL etat(pp,tp,xchim,.FALSE.,ro,drop,drot,drox,u,dup,dut,dux,
	1    delta,deltap,deltat,deltax,cp,dcpp,dcpt,dcpx,
	2    gradad,dgradadp,dgradadt,dgradadx,alfa,beta,gamma1)
	     CALL nuc(tp,ro,xchim,dxchim,jac,.FALSE.,3,
	1    epsilon,depst,depsro,depsx,hh,be7,b8,n13,o15,f17)
	     tds(1,i)=-epsilon(1)*secon6	!cT sort dans epsilon(1)
	    ENDDO
	    CALL bsp1dn(1,tds,x_tds,xt_tds,n_tds,m_tds,knot_tds,.FALSE.,
	1   x_tds(1),lq,f,dfdq)	   
            IF(no_croiss)THEN
             PRINT*,'Arr�t 5 dans resout' ; CALL sortie !STOP
            ENDIF
	    DEALLOCATE(jac)
	   
c	    on garde dans ***_t le mod�le de PMS obtenu	
c   	    CALL update(.TRUE.,dt,dts)
	   
	   ENDIF
	   		   
c 	   mod�le converg�, sortie de brn3, puis retour vers cesam5
	   
	   EXIT bnr3
	   
	  ELSEIF(compt >= iter_max0)THEN
	   PRINT* ; PRINT*	 	
	   PRINT*,'no conv. du mod�le quasi-statique de PMS, ARRET'
	   WRITE(2,*) ; WRITE(2,*) ; CALL sortie !STOP	 	
	   WRITE(2,*)'no conv. du mod�le quasi-statique de PMS, ARRET'
	  ENDIF		!compt >= 2			
	 ENDDO bnr3	 
	 
c	 PRINT*,un23
c	 CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(1),lq,f,dfdq)
c	 WRITE(*,2000)f(1:5)
c	 CALL bsp1dn(ne,bp,q,qt,n_qs,ord_qs,knot,.TRUE.,q(n_qs),lq,f,dfdq)
c	 WRITE(*,2000)f(1:5)
c	 CALL pause('sortie pms')
	 
c	 le mod�le quasi-statique de PMS a converg�, retour vers cesam

	 SELECT CASE(langue)
	 CASE('english')	
	  WRITE(*,1071)
1071	  FORMAT(/,'Integration of the PMS quasi-static model (end)',/)
	 CASE DEFAULT
	  WRITE(*,71)
71	  FORMAT(/,'Int�gration du mod�le quasi-statique de PMS(fin)',/)
	 END SELECT


	 	 
	CASE DEFAULT
	 PRINT*,'erreur |un23| est diff�rent de 1, 2ou 3, un23=',un23	
	 PRINT*,'ARRET dans resout' ; CALL sortie !STOP
	END SELECT
	
	RETURN
	
	END SUBROUTINE resout
