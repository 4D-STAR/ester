
c******************************************************************

	SUBROUTINE resout_chim(dt,ok)

c routine public du module mod_evol
	
c r�solution par �l�ments finis Galerkin du syst�me d'�qua. diff.
c ord. non lin�aires de la rotation par it�ration Newton-Raphson

c fait=1:
c	on forme les produits scalaire pour toutes les splines de la base
c	(de dimension dim) par int�gration de Gauss (algorithme inspir� de
c	celui de Schumaker, 5.22 p. 203),
c fait=2:
c	on ajoute les quantit�s int�gr�es

c fait=3
c	on forme les conditions limites

c	 as : d�riv�es/ Xi, Xi' des coeff. de la spline du prod. scalaire
c	 ad : d�riv�es/ Xi, Xi' des coeff. de la der. du produit scalaire

c	 as(i,j,k)=coefficient de la k-i�me d�riv�e (k=0,1)
c	 de la j-i�me variable de la i-i�me �quation < . Ni >

c	 ad(i,j,k)=coefficient de la k-i�me d�riv�e (k=0,1)
c	 de la j-i�me variable de la i-i�me �quation < . dNi/dx > 

c	 a(<spline 1 . �quation 1: variable 1,2,..,ne>
c	   <spline 1 . �quation 2: variable 1,2,..,ne>
c		 :     :     :     :     :     
c	   <spline 1 . �quation ne: variable 1,2,..,ne>
c	   <spline 2 . �quation ne: variable 1,2,..,ne>
c	   <spline 2 . �quation ne: variable 1,2,..,ne>
c           :     :     :     :     :
c	   <spline 2 . �quation ne: variable 1,2,..,ne>
c	   <spline 3 . �quation ne: variable 1,2,..,ne>
c           :     :     :     :     :
c	   <spline dim . �quation ne: variable 1,2,..,ne>)

c	 bs(i)=second membre de la i-i�me �quation < . Ni > 
c	 bd(i)=second membre de la i-i�me �quation < . d/dx Ni >

c	 b(<spline 1 . �quation 1, 2,.., ne>
c	  <spline 2 . �quation 1, 2,.., ne>
c           :     :     :     :
c	  <spline dims . �quation 1, 2,.., nvar>)

c Auteur: P.Morel, D�partement Cassiop�e, O.C.A.

c----------------------------------------------------------------

	USE mod_donnees, ONLY : ab_min, ihe4, Krot, langue, lisse, m_ch, nchim,
	1 nom_elem, precix
	USE mod_kind
	USE mod_numerique, ONLY : bsp1dn, bvald, gauss_band, intgauss,
	1 linf, no_croiss
	USE mod_variables, ONLY : chim, dim_ch, knotc, mc, mct, n_ch, chim_t
	
	IMPLICIT NONE

	REAL (kind=dp), INTENT(in) :: dt
	LOGICAL, INTENT(out) :: ok
		
	REAL(kind=dp), DIMENSION(nchim,nchim,0:1) :: ad, as		
	REAL(kind=dp), ALLOCATABLE, DIMENSION(:,:) :: a, b, temp
	REAL(kind=dp), DIMENSION(nchim,0:1) :: y
	REAL(kind=dp), DIMENSION(0:1,m_ch) :: d	
	REAL(kind=dp), DIMENSION(nchim) :: bd, bs
	REAL(kind=dp), DIMENSION(m_ch) :: qg, wg
	
	REAL(kind=dp), SAVE :: dtp=-HUGE(dt), err_lim, err_max, preci	
	REAL(kind=dp) :: corr, er, err, errg
		
	INTEGER, PARAMETER :: compt_max=15
	INTEGER, ALLOCATABLE, DIMENSION(:) :: indpc, indpc0
	INTEGER, SAVE :: bloc
	INTEGER :: col, colonne, compt, i, id, ie,
	1 ig, ipe, iv, ive, j, k, l=1, ligne, nl, rang, spi, spl, sple

	LOGICAL, SAVE :: init=.TRUE.
	LOGICAL :: inversible
	
c----------------------------------------------------------------

2000	FORMAT(8es10.3)
2001	FORMAT(10es8.1)

c	 initialisations
c	 bloc: longueur du bloc des coeff. non idt. nuls

	IF(init)THEN 
	 bloc=nchim*(2*m_ch-1)
	 err_max=10.d0*precix
	 err_lim=10.d0*err_max	 
	 init=.FALSE.
	 SELECT CASE(Krot)
	 CASE(3,4)
	  preci=precix*10.d0
	 CASE DEFAULT
	  preci=precix	 
	 END SELECT
	ENDIF	 

c NOTATIONS (h�las incoh�rentes) pour les d�veloppements sur B-splines
c	n_ch : nombre VARIABLE de points �l�ment de mod_variables
c	nch : nombre FIXE de fonctions �l�ment de mod_donnees
c	m_ch : ordre FIXE des splines �l�ment de mod_donnees 
c	mc(n_ch) : abscisses VARIABLES �l�ment de mod_variables

c nl = rang : nombre de lignes du syst�me lin�aire	
	rang=nchim*dim_ch ; nl=rang
		
	ALLOCATE(a(nl,bloc),b(1,nl),indpc(nl),indpc0(nl),temp(nchim,dim_ch))

c indices de premi�re colonne pour les produits scalaires
c ils seront chang�s dans gauss_band
	indpc0=0 ; ligne=0
	DO i=1,dim_ch      !pour chaque spline de la base des mc
	 k=MAX(1,i-m_ch+1)      !indice s'il n'y avait qu'une variable
	 DO ie=1,nchim         !avec toutes les variables
	  ligne=ligne+1 ; indpc0(ligne)=nchim*(k-1)+1
	 ENDDO
	ENDDO
	 
c it�rations Newton Raphson: boucle infinie B1
	compt=0
	B1: DO compt=1,compt_max
	 indpc=indpc0

c initialisations

	 a=0.d0 ; b=0.d0 ; ligne=0
	 
c---------------d�but de la construction du syt�me lin�aire------------	
	    
c les produits scalaires, pour chaque intervalle de m_ch � dim_ch
	 B3: DO k=m_ch,dim_ch

c on �vite les points multiples
	  IF(mct(k) >= mct(k+1))CYCLE B3	 
	  	 
c spi : indice-1 de la premi�re spline non id.nulle  
c comme mct(l) <= qg(ig) < mct(l+1), l est le m�me pour toutes
c les abscisses de Gauss dans l'intervalle [mct(k),mct(k+1)]
	  CALL linf(mct(k),mct,knotc,l) ; spi=l-m_ch	  

c poids, wg et abscisses, qg pour int�gration Gauss d'ordre m_ch
	  CALL intgauss(mct(k),mct(k+1),qg,wg,m_ch)

c pour chaque abscisse de GAUSS
	  DO ig=1,m_ch

c variables et d�riv�es
	   CALL bsp1dn(nchim,chim,mc,mct,n_ch,m_ch,knotc,.TRUE.,qg(ig),l,bs,bd)

	   IF(no_croiss)PRINT*,'resout_chim, Pb. en 1'
	   y(:,0)=bs ; y(:,1)=bd
	   
c formation des coefficients des �quations
	   CALL eq_diff_chim(qg(ig),y,dt,ad,as,bd,bs)	    
	   		   
c les B-splines en qg(ig), d�riv�es 0 � 1
	   CALL bvald(qg(ig),mct,m_ch,l,1,d)   
	   	   
c contribution au syst�me lin�aire
	   DO ie=1,nchim		!pour chaque �quation
	    DO i=1,m_ch		!pour chaque spline d'indice i
	     ligne=nchim*(spi+i-1)+ie
	     b(1,ligne)=b(1,ligne)+wg(ig)*(d(0,i)*bs(ie)+d(1,i)*bd(ie))
c	     WRITE(*,2003)ligne,d(0,i),d(1,i),bs(ie),bd(ie),y(1,0),
c	1    y(1,1),qg(ig),b(1,ligne) ; PAUSE'b'
2003	     FORMAT(i3,9es8.1)
		
c la matrice compress�e est le jacobien 'diagonal' ie. sans les
c �l�ments 'non diagonaux' identiquement nuls
	     DO j=1,m_ch		!pour chaque spline j
	      DO iv=1,nchim	!pour chaque variable	       
	       colonne=nchim*(spi+j-1)+iv    
	       col=colonne-indpc(ligne)+1   !colonne matrice compress�e
c	       PRINT*,'ligne,colonne,col,iv',ligne,colonne,col,iv;PAUSE'1'
	       DO id=0,1  !pour 0: NiNj, 1: NiN'j, 3: NiN"j etc...
	        a(ligne,col)=a(ligne,col)+wg(ig)*
	1	(as(ie,iv,id)*d(0,i)*d(id,j)+ad(ie,iv,id)*d(1,i)*d(id,j))
	       ENDDO      !id
	      ENDDO	!iv variable
	     ENDDO	!j
	    ENDDO	!i
	   ENDDO	!ie �quation	   
	  ENDDO 	!ig
	 ENDDO B3	!k
	 
c----------------fin de la construction du syst�me lin�aire-------------- 

c	 IF(chim_ou_rota == 'rota')THEN
c	 IF(chim_ou_rota == 'chim')THEN
c	  PRINT*,ligne,nl,bloc ; PAUSE'ligne,nl,bloc avant a'
c	  DO i=1,nl
c	   PRINT*,i,indpc(i)
c	   WRITE(*,2000)a(i,:),b(1,i) ; IF(mod(i,200) == 0)PAUSE'a200'
c	   IF(MAXVAL(ABS(a(i,:))) == 0.d0)PAUSE'a=0'
c	  ENDDO
c	  PAUSE'a'
c	 ENDIF	
	
c	 PRINT*,nl
c	 DO i=1,nl
c	  IF(MAXVAL(ABS(a(i,:))) == 0.d0)PRINT*,i
c	 ENDDO
	 	
c r�solution du syst�me lin�aire
	 CALL gauss_band(a,b,indpc,nl,rang,bloc,1,inversible)
	 IF(.NOT.inversible)THEN
	  PRINT*,'ARRRET, matrice singuli�re dans resout_chim' ; STOP
	 ENDIF
	 
c	 WRITE(*,2000)b(1,:) ; PAUSE'solution'
	
c vecteur des corrections
	 temp=RESHAPE(b,SHAPE(temp))
	 
c	 DO i=1,dim_ch!,100
c	  PRINT*,i
c	  WRITE(*,2000)temp(1,i),chim(1,i),temp(3,i),chim(3,i)
c	  WRITE(*,2000)chim(:,i)
c	  IF(mod(i,50) == 0)PAUSE'solution'
c	 ENDDO
c	 PAUSE'corrections au pas de 100'
	 	
c limitation des corrections
	 corr=1.d0
	 DO spl=1,dim_ch
	  B2: DO iv=1,nchim	  
	   IF(iv == 1 .OR. iv == ihe4)THEN	  
	    IF(ABS(chim(iv,spl)) < ab_min(iv))CYCLE B2
	    IF(corr*ABS(temp(iv,spl)) > 0.6d0*ABS(chim(iv,spl)))corr=corr/2.d0
	   ENDIF
	  ENDDO B2	!iv
	 ENDDO		!spl

c estimation de la pr�cision
	 err=0.d0 ; errg=0.d0
	 DO spl=1,dim_ch
	  B4: DO iv=1,nchim
	   IF(ABS(chim(iv,spl)) < ab_min(iv))CYCLE B4
	   er=ABS(temp(iv,spl)/chim(iv,spl))
	   IF(er > err)THEN
	    sple=spl ; ive=iv ; err=er
c	    PRINT*,iv,spl,nom_elem(iv)
c	    WRITE(*,2000)er,err,temp(iv,spl),chim(iv,spl),ab_min(iv)
	   ENDIF
	   IF((iv == 1 .OR. iv == ihe4) .AND. er > errg)errg=er 
	  ENDDO B4	!chim
	 ENDDO		!spl
	 
c	 PRINT*,sple,ive ; WRITE(*,2000)er,err ; PAUSE	

cessai~~~~~~~~ non valable car on doit avoir X+Y+Z=1
c limitation des corrections
c	 corr=1.d0 ; errg=MIN(errg,1.d0)
c	 DO spl=1,dim_ch
c	  B5: DO iv=1,nchim	  
c	   IF(ABS(chim(iv,spl)-temp(iv,spl)) < ab_min(iv))CYCLE B5
c	   temp(iv,spl)=SIGN(MIN(ABS(temp(iv,spl)),0.6d0*ABS(chim(iv,spl))),
c	1  temp(iv,spl))
c	  ENDDO B5	!iv
c	 ENDDO		!spl
cessai~~~~~~~~~

c nouvelle solution
	 chim=chim-temp*corr
	 
c	 PRINT*,'apr�s correction'
c	 B5: DO i=1,n_ch
c	  CALL bsp1dn(nmix,fmix,x_mix,x_mixt,n_mix,m_mix,knot_mix,.TRUE.,
c	1 mc(i),l,bs,bd)
c	  IF(bs(1) > 0.d0)CYCLE B5	 
c	  CALL bsp1dn(nchim,chim,mc,mct,n_ch,m_ch,knotc,.TRUE.,mc(i),
c	1 l,bs,bd)
c	  WRITE(*,2000)mc(i),bs(1:7)
c	 ENDDO B5
c	 PAUSE'apr�s correction'
	 
c �critures
	 ipe=sple/m_ch+1	!indice de couche
	 WRITE(usl_evol,100)compt,errg,nom_elem(1),nom_elem(ihe4),corr,err,
	1 nom_elem(ive),sple,ipe,mc(ipe)**(2.d0/3.d0)
	
100	 FORMAT('resout_chim, it�ration:',i3,', erreur max:',es8.1,
	1 ', sur ',a,' ou ',a,', corr:',es8.1,/,'err. max. globale:',es8.1,
	2 ', sur ',a,', B-spline:',i4,', couche:',i4,', m=',es10.3)
	 
c on poursuit si l'erreur est < err_lim apr�s compt_max 
c il y a convergence forc�e si l'erreur est < err_max apr�s2*compt_max
c on accepte une mauvaise convergence pour un nouveau pas temporel
	 ok= errg <= preci
	 IF(compt <= 1)THEN
	  CYCLE B1
	 ELSEIF(ok)THEN
	  EXIT B1
	 ELSEIF(compt < compt_max)THEN
	  CYCLE B1	 
	 ELSEIF(errg < err_max)THEN
	  SELECT CASE(langue)
	  CASE('english')
	   PRINT*,'bad conv. in resout_chim, number of iterations :',compt
	  CASE DEFAULT
	   PRINT*,'conv. forc�e dans resout_chim, nb. it�rations :',compt
	  END SELECT
	  ok=.TRUE. ; EXIT B1
	 ELSEIF(errg < err_lim .AND. compt < 2*compt_max)THEN
	  CYCLE B1
	 ELSEIF(dt /= dtp)THEN
	  ok=.TRUE. ; EXIT B1 	  
	 ELSE  
	  SELECT CASE(langue)
	  CASE('english')
	   PRINT*,'no conv. in resout_chim, number of iterations :',compt
	  CASE DEFAULT
	   PRINT*,'pas de conv. dans resout_chim, nb. it�rations :',compt
	  END SELECT
	  EXIT B1
	 ENDIF
	ENDDO B1
	dtp=dt

c lissage
c	IF(lisse)THEN
	IF(.FALSE.)THEN
	
c on transpose la solution dans temp
	 temp=chim ; DEALLOCATE(chim) ; ALLOCATE(chim(nchim,n_ch))	

c interpolation et mise dans chim	
	 DO i=1,n_ch
	  CALL bsp1dn(nchim,temp,mc,mct,n_ch,m_ch,knotc,.TRUE.,mc(i),l,bs,bd)
	  chim(:,i)=bs
	 ENDDO

c interpolation avec lissage
	 DEALLOCATE(mct) ; ALLOCATE(mct(n_ch+m_ch))	 
	 CALL bsp1dn(nchim,chim,mc,mct,n_ch,m_ch,knotc,.FALSE.,mc(1),l,
	1 bs,bd,lisse)	
	 dim_ch=knotc-m_ch	!en fait dim_ch=n_ch
	ENDIF	  

c sortie	
	DEALLOCATE(a,b,indpc,indpc0,temp)

c	PAUSE'sortie'
	
	RETURN
	
	END SUBROUTINE resout_chim
