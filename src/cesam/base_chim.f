
c*******************************************************

	SUBROUTINE base_chim

c routine subordonn�e de diffus	
c Formation de la base pour la diffusion des �l�ments chimiques

c la fonction d'interpolation est d'ordre m
c le vecteur nodal a m point en x(1), x(n) et m-i aux singularit�s
c s'il n'y a pas de singularit� une base continue est cr�e
c s'il n'y a des ZR & ZC base continue non d�rivable aux limites
c avec diffusion du moment cin�tique, base continue non d�rivable en tout point

c entr�es
c	0 <= i < m : ordre de continuit� aux points de singularit�
c	i = 0 discontinue
c	i = 1 d�riv�e premi�re discontinue
c	i = 2 d�riv�e seconde discontinue
c	.................
c	i = m-1 fonction continue partout

c	is(0:ns+1) : indices des abscisses des singularit�s
c	ns : nombre de singularit�s

c Auteur: P. Morel, D�partement Cassiop�e, O.C.A.
c CESAM2k

c------------------------------------------------------------------

	USE mod_donnees, ONLY : Krot
	USE mod_variables, ONLY : tot_conv
		
	IMPLICIT NONE

	INTEGER, ALLOCATABLE, DIMENSION(:) :: mult
	
	LOGICAL, SAVE :: init=.TRUE.

c------------------------------------------------------------------

2000	FORMAT(8es10.3)

	IF(init)THEN
	 init=.FALSE.
	 SELECT CASE(langue)
	 CASE('english')
          WRITE(*,1001) ; WRITE(2,1001)
1001      FORMAT(/,'Use of a continuous basis')	 
	 CASE DEFAULT 
          WRITE(*,1) ; WRITE(2,1)
1         FORMAT(/,'Utilisation de la base continue')
	 END SELECT	
	ENDIF
		
c multiplicit�s
	ALLOCATE(mult(n_ch))

c continuit�
	IF(tot_conv)THEN
	 mult=1
	 	 
c discontinuit� de la d�riv�e 1-i�re 
	ELSE
	 SELECT CASE(Krot)
	 CASE(3,4)		!partout	
	  mult=MAX(1,m_ch-1)
	 CASE DEFAULT		!seulement aux limites ZR/ZC
	  mult=1 ; mult(idis(1:ndis))=MAX(1,m_ch-1)
	 END SELECT	 
	ENDIF	
		
c construction du vecteur nodal				
	mult(1)=m_ch ; mult(n_ch)=m_ch ; knotc=SUM(mult)
	DEALLOCATE(mct) ; ALLOCATE(mct(knotc))
	CALL noeud(mc,mct,mult,n_ch,knotc)
	DEALLOCATE(mult)
	
	RETURN
	
	END SUBROUTINE base_chim
