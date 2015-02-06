
c******************************************************************

	MODULE mod_nuc

c	module regroupant les routines de CESAM2k
c	concernant les r�actions thermonucl�aires
c	et les routines propres d'exploitation
c	les param�tres propres, valeurs max. des dimensions de tableaux

c	le calcul des taux des r�actions est effectu� par la routine
c	g�n�rique nuc
c	les r�seaux de  r�actions sont diff�renci�s par leur nom: nom_nuc
c	lu par lit_nl, fonction publique du module mod_donnees

c param�tre private:
c	nelem_ini : nombre d'�l�ments chimiques initiaux

c variables privates:
c	ab : mixture, initialis� dans abon_ini
c	abon_rela : abondance relative des �l�ments dans Z, initialis�
c	dans abon_ini
c	m : masses atomiques des �l�ments, initialis� dans abon_ini 
c	c : charges des �l�ments, initialis� dans abon_ini

c	be7sbe9 : rapport isotopique Be7/Be9, initialis� dans abon_ini 
c	be7sz : rapport isotopique Be7/Z, initialis� dans abon_ini
c	c13sc12 : rapport isotopique C13/C12, initialis� dans abon_ini
c	h2sh1 : rapport isotopique H2/H1, initialis� dans abon_ini 
c	he3she4 : rapport isotopique He3/He4, initialis� dans abon_ini
c	he3she4z : rapport isotopique He3/He4Z, initialis� dans abon_ini
c	li6sli7 : rapport isotopique Li6/Li7, initialis� dans abon_ini
c	mg25smg24 : rapport isotopique Mg25/Mg24, initialis� dans abon_ini
c	mg26smg25 : rapport isotopique Mg26/Mg25, initialis� dans abon_ini
c	ne22sne20 : rapport isotopique Ne22/Ne20, initialis� dans abon_ini
c	nom_abon : type d'abondance initiale , initialis� dans lit_nl
c	n15sn14 : rapport isotopique N15/N14, initialis� dans abon_ini 
c	o17so16 : rapport isotopique O17/O16, initialis� dans abon_ini
c	izz : charges des noyaux utilis�s, initialis� dans tabul_nuc 
c	nreac : nombre de r�actions thermonucl�aires, initialis� dans
c	tabul_nuc 	
c	elem : noms des �l�ments, initialis� dans abon_ini

c variables public:
c	t_sup : temp�rature maximale des tabulations des r�actions
c	nucl�aires, initialis� dans tabul_nuc

c fonctions private:
c	abon_ini : d�termination des abondances initiales	
c	iben : routine de r�actions nucl�aires fictive, d�termination de
c	la constante de contraction PMS
c	pp1 : cycle PP1 simplifi�
c	ppcno10Fe : cycle PPCNO 10 �l�ments + Fe56
c	ppcno10K : cycle PPCNO 10 �l�ments + K
c	ppcno10 : cycle PPCNO 10 �l�ments
c	ppcno11 : cycle PPCNO 11 �l�ments
c	ppcno12Be : cycle PPCNO 12 �l�ments + Be9
c	ppcno12Li : cycle PPCNO 12 �l�ments + Li6
c	ppcno12 : cycle PPCNO 12 �l�ments
c	ppcno3a9 : cycle PPCNO + 3alpha 9 �l�ments
c	ppcno3ac10 : cycle PPCNO + 3alpha + carbone 10 �l�ments
c	ppcno9 : cycle PPCNO 9 �l�ments 
c	rq_reac : interpolation des taux de r�action et effet d'�cran
c	tabul_nuc : tabulation des r�actions thermonucl�aires 
c	taux_nuc : calcul des taux des r�actions thermonucl�aires 	

c fonction public:
c	nuc : routine g�n�rique de r�actions thermonucl�aires

c	Auteur: P.Morel, D�partement J.D. Cassini, O.C.A.
c	CESAM2k

c--------------------------------------------------------------------

	USE mod_kind
	
	IMPLICIT NONE
	
	INTEGER, PRIVATE, PARAMETER :: nelem_ini=28, niso_tot=28,
	1 nreac_tot=45
	REAL (kind=dp), SAVE, PRIVATE, DIMENSION(nelem_ini) :: ab,
	1 abon_rela, m, c
	REAL (kind=dp), SAVE, PRIVATE ::  be7sbe9, be7sz, c13sc12, h2sh1,
	1 he3she4, he3she4z, li6sli7, mg25smg24, mg26smg25, ne22sne20,
	2 nom_abon, n15sn14, o17so16
	REAL (kind=dp), SAVE, PUBLIC :: t_sup	
	INTEGER, SAVE, PRIVATE, ALLOCATABLE, DIMENSION(:,:) :: izz	
	INTEGER, SAVE, PRIVATE :: nreac
	CHARACTER (len=2), PRIVATE, DIMENSION(nelem_ini) :: elem
			
	PRIVATE
!	PUBLIC :: nuc, vent
	PUBLIC :: nuc, vent, rq_reac, tabul_nuc

	CONTAINS

c------------------------------------------------------------------------

	INCLUDE 'abon_ini.f'
	INCLUDE 'iben.f'
	INCLUDE 'nuc.f'
c	INCLUDE 'neutrinos.f'				!YLD
	INCLUDE 'pp1.f'
	INCLUDE 'pp3.f'	
	INCLUDE 'ppcno10BeBFe.f'	
	INCLUDE 'ppcno10Fe.f'
	INCLUDE 'ppcno10K.f'
	INCLUDE 'ppcno10.f'	
	INCLUDE 'ppcno11.f'
	INCLUDE 'ppcno12Be.f'
	INCLUDE 'ppcno12BeBFe.f'
	INCLUDE 'ppcno12Li.f'
	INCLUDE 'ppcno12.f'
	INCLUDE 'ppcno3a9.f'
	INCLUDE 'ppcno3ac10.f'
	INCLUDE 'ppcno9.f'
	INCLUDE 'ppcno9Fe.f'	
	INCLUDE 'rq_reac.f'
	INCLUDE 'tabul_nuc.f'
	INCLUDE 'taux_nuc.f'
	INCLUDE 'vent.f'	 	 	 	 	 	
	
	END MODULE mod_nuc
