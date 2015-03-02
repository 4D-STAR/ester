
c***********************************************************************

	SUBROUTINE atm(list,l_rac,r_rac,xchim,pt_rac,dptsdl,dptsdr,
	1 t_rac,dtsdl,dtsdr,m_rac,dmsdl,dmsdr,p_rac,dpsdl,dpsdr,t_eff)

c	routine g�n�rique pour la restitution de l'atmosph�re
c	il y a des appels diff�rents suivant nom_atm

c	routine public du module mod_atm

c entr�es :
c	list=.true. : calcul r�duit pour une liste
c	r_rac : rayon au raccord
c	l_rac : luminosit� au raccord
c	xchim : composition chimique par gramme

c sorties :
c	  pt_rac : pression totale au raccord,
c	  dptsdl : d�riv�e / L de la pression totale au raccord,   
c	  dptsdr : d�riv�e / R de la pression totale au raccord,   
c	  t_rac : temp�rature au raccord,
c	  dtsdl : d�riv�e / L de la temp�rature au raccord,    
c	  dtsdr : d�riv�e / R de la temp�rature au raccord,    
c	  m_rac : masse au raccord,
c	  dmsdl : d�riv�e / L de la masse au raccord,   
c	  dmsdr : d�riv�e / R de la masse au raccord,       
c	  p_rac : pression gazeuse au raccord,
c	  dpsdl : d�riv�e / L de la pression gazeuse au raccord,   
c	  dpsdr : d�riv�e / R de la pression gazeuse au raccord,    
c	  t_eff  : temp�rature effective. 

c	Auteur: P. Morel, D�partement J.D. Cassini, O.C.A.
c	CESAM2k

c--------------------------------------------------------------------

	USE mod_donnees, only : nom_atm
	USE mod_kind

	IMPLICIT NONE

	REAL (kind=dp), INTENT(in), DIMENSION(:) :: xchim
	REAL (kind=dp), INTENT(in) :: l_rac, r_rac
	LOGICAL, INTENT(in) :: list    
	REAL (kind=dp), INTENT(out) :: pt_rac, dptsdl, dptsdr, t_rac,
	1 dtsdl, dtsdr, m_rac, dmsdl, dmsdr, p_rac, dpsdl, dpsdr, t_eff

c-------------------------------------------------------------

	SELECT CASE(nom_atm)
	CASE('lim_gong1')
	 CALL lim_gong1(l_rac,r_rac,xchim,pt_rac,dptsdl,dptsdr,
	1 t_rac,dtsdl,dtsdr,m_rac,dmsdl,dmsdr,p_rac,dpsdl,dpsdr,t_eff)  
	CASE('lim_tau1')
	 CALL lim_tau1(l_rac,r_rac,xchim,pt_rac,dptsdl,dptsdr,
	1  t_rac,dtsdl,dtsdr,m_rac,dmsdl,dmsdr,p_rac,dpsdl,dpsdr,t_eff)
	CASE('lim_atm')
	 CALL lim_atm(list,l_rac,r_rac,xchim,pt_rac,dptsdl,dptsdr,
	1 t_rac,dtsdl,dtsdr,m_rac,dmsdl,dmsdr,p_rac,dpsdl,dpsdr,t_eff)
	CASE DEFAULT
	 PRINT*,'routine de restitution d''atmosph�re inconnue: ',nom_atm
	 PRINT*,'routines connues: lim_gong1, lim_tau1, lim_atm'
	 PRINT*,'arr�t' ; STOP
	END SELECT
	
	RETURN

	END SUBROUTINE atm
