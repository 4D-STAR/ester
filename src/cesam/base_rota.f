
c*******************************************************

	SUBROUTINE base_rota

c routine subordonn�e de evol
c Formation de la base pour la rotation

c r_qs=1 ordre des �quations diff�rentielles, est un PARAMETER de mod_donnees
c ord_rot est d�fini dans initialise_rota et initialise rota4

c Auteur: P. Morel, D�partement Cassiop�e, O.C.A., CESAM2k

c------------------------------------------------------------------
	
	INTEGER, ALLOCATABLE, DIMENSION(:) :: mult

c------------------------------------------------------------------

2000	FORMAT(8es10.3)
		
c multiplicit�s
	ALLOCATE(mult(n_rot))
	
c discontinuit� de la d�riv�e 1-i�re et  discontinuit� � chaque limite ZR/ZC
	ord_rot=m_rot+r_qs ; mult=m_rot 			
	mult(1)=ord_rot ; mult(n_rot)=ord_rot
	 
c vecteur nodal	
	knotr=SUM(mult) ; DEALLOCATE(mrott) ; ALLOCATE(mrott(knotr))
	CALL noeud(mrot,mrott,mult,n_rot,knotr) ; dim_rot=knotr-ord_rot
	DEALLOCATE(mult)
	
	RETURN
	
	END SUBROUTINE base_rota
