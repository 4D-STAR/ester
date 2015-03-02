
c******************************************************************

	MODULE mod_static

c	Module regroupant les routines permettant la r�solution 
c	des �quations de l'�quilibre quasi-statique etla gestion de
c	l'�volution

c variables private:
c	fac : facteur de r�partition, initialis� dans resout
c	xcoll : table des points de collocation pour l'�quilibre
c	quasi-statique, initialis� dans coll

c fonctions private:
c	coll_qs : r�solution des �quations de l'�quilibre quasi-statique
c	dgrad : calcul du gradient de temp�rature
c	lim_zc : r�partition des couches pour l'�quilibre quasi-statique,
c	d�termination des limites ZR/ZC
c	pertm_ext : d�termination de la perte de masse
c	pertm_msol : d�termination de la perte de masse cas M >= Msol
c	pertm_tot : d�termination de la perte de masse tenant compte de
c	E=mc^2  
c	static_m : d�termination des coefficients des �quations de
c	l'�quilibre quasi-static, cas lagrangien
c	static_r : d�termination des coefficients des �quations de
c	l'�quilibre quasi-static, cas eul�rien
c	update : on passe les variables du temps t+dt � t
	
c fonctions public:
c	resout : gestion de mod�les initiaux, �volution temporelle de la
c	composition chimique ==> �quilibre quasi-statique ==> �volution
c	temporelle de la composition chimique...
c	thermo : calcul des principales fonctions thermodynamiques, du
c	gradient convectif

c 	Auteur: P.Morel, D�partement J.D. Cassini, O.C.A.
c	CESAM2k

c--------------------------------------------------------------------

	USE mod_kind
	
	IMPLICIT NONE
	
	REAL (kind=dp), SAVE, PRIVATE, ALLOCATABLE, DIMENSION(:) :: fac,
	1 xcoll
	
	CHARACTER (len=3), PARAMETER, PRIVATE, DIMENSION(8) :: nom_qs=
	1(/ ' Pt', ' T ', ' R ', ' L ', ' M ', 'psi', ' ro', ' Pg' /)
	
	PRIVATE
	PUBLIC :: pertm, resout, thermo
	
	CONTAINS
	
c--------------------------------------------------------------

	INCLUDE 'coll_qs.f'
	INCLUDE 'dgrad.f'
	INCLUDE 'lim_zc.f'
	INCLUDE 'pertm.f'
	INCLUDE 'pertm_ext.f'
	INCLUDE 'pertm_msol.f'
	INCLUDE 'pertm_tot.f'
	INCLUDE 'pertm_waldron.f'		
	INCLUDE 'resout.f' 
	INCLUDE 'static.f'
	INCLUDE 'static_m.f'
	INCLUDE 'static_r.f'
	INCLUDE 'thermo.f'
	INCLUDE 'update.f'

	END MODULE mod_static
