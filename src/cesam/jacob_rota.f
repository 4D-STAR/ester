
c****************************************************************

	SUBROUTINE jacob_rota(fait,neq,nu)

c routine subordonn�e de resout_rota

c formation des coefficients du jacobien pour la
c r�solution par collocation du syst�me d'�qua. diff.
c non lin�aires de la diffusion du moment cin�tique
c par it�ration Newton-Raphson

c entr�es
c	fait=0 : point courant
c	fait=1 : centre convectif ou radiatif
c	fait=2 : limite externe toujours convectif
c	neq : nombre d'�quations
c	nu : abscisse

c sorties dans le routine maitre resout_rota
c	�l�ments du jacobien a
c	second membre b
c	ligne indice de ligne
c	indpc indice de premi�re colonne

c Auteur: P.Morel, D�partement Cassiop�e, O.C.A.

c----------------------------------------------------------------

	IMPLICIT NONE
	
	REAL (kind=dp), INTENT(in) :: nu
	INTEGER, INTENT(in) :: fait, neq
	
	REAL(kind=dp), DIMENSION(nrot,nrot,0:1) :: as	
	REAL(kind=dp), DIMENSION(nrot) :: bd, bs
		
	INTEGER, SAVE :: l=1
	INTEGER :: col, id, ie, ind, iv, j

c-----------------------------------------------------------------

2000	FORMAT(8es10.3)

c variables et d�riv�es
	CALL bsp1dn(nrot,rota,mrot,mrott,n_rot,ord_rot,knotr,.TRUE.,nu,l,bs,bd)
	IF(no_croiss)PRINT*,'jacob_rota, Pb. en 1'
	y(:,0)=bs ; y(:,1)=bd

c formation des coefficients des �quations
	SELECT CASE(Krot)
	CASE(3)
	 CALL eq_diff_rota3(dt,fait,nu,y,as,bs)
	CASE(4)
	 CALL eq_diff_rota4(dt,fait,nu,y,as,bs)
	END SELECT

c les B-splines xcoll_rot(k), d�riv�es 0 � 1
	CALL bvald(nu,mrott,ord_rot,l,1,d)

c contribution au syst�me lin�aire,
c la matrice compress�e est le jacobien 'diagonal' ie. sans les
c �l�ments 'non diagonaux' identiquement nuls
	ind=nrot*(l-ord_rot)+1	!ind. prem. col. for nrot next lignes	
	DO ie=1,neq		!pour chaque �quation
	 ligne=ligne+1 ; b(1,ligne)=bs(ie) ; indpc(ligne)=ind
	 DO j=1,ord_rot		!pour chaque spline j
	  DO iv=1,nrot		!pour chaque variable
	   col=nrot*(j-1)+iv
	   DO id=0,1
	    a(ligne,col)=a(ligne,col)+as(ie,iv,id)*d(id,j)
	   ENDDO	!id
	  ENDDO		!iv variable
	 ENDDO		!j
	ENDDO		!ie �quation

	RETURN
	  
	END SUBROUTINE jacob_rota
