
c***************************************************************

	LOGICAL FUNCTION lmix(nu)

c fonction PRIVATE du module mod_evol
c est-on dans une zone de m�lange pour la composition chimique?

c entr�e :
c	nu : masse^2/3

c sortie :
c	lmix=.TRUE. : on est dans une zone m�lang�e

c Auteur: P.Morel, D�partement J.D. Cassini, O.C.A., CESAM2k

c-------------------------------------------------------------------

	USE mod_kind
	USE mod_numerique, ONLY : linf, no_croiss
	
	IMPLICIT NONE
	
	REAL (kind=dp), INTENT(in) :: nu
		
	REAL (kind=dp) :: mr
	
	INTEGER, SAVE :: l=1
	
c------------------------------------------------------------------

c toujours convectif � l'ext�rieur
	lmix=nu >= x_mix(n_mix)
	IF(lmix)RETURN
	
c � l'int�rieur	
	mr=MAX(x_mix(1),MIN(nu,x_mix(n_mix)))
	CALL linf(mr,x_mix,n_mix,l)
	IF(no_croiss)PRINT*,'Probl�me dans lmix'
	lmix=mix(l)
	
	RETURN	
	
	END FUNCTION lmix
