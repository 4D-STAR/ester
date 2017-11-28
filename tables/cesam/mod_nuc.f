
c******************************************************************

	MODULE mod_nuc

c module regroupant les routines concernant les r�actions thermonucl�aires

c le calcul des taux des r�actions est effectu� par la routine	g�n�rique nuc
c les r�seaux de  r�actions sont diff�renci�s par leur nom: nom_nuc
c lu par lit_nl, fonction publique du module mod_donnees

c La signification des variables est d�crite au paragraphe F9 de la notice
c	 de CESAM2k

c Auteur: P.Morel, D�partement J.D. Cassini, O.C.A., CESAM2k

c--------------------------------------------------------------------

	USE mod_kind
	
	IMPLICIT NONE
	
	INTEGER, PUBLIC, PARAMETER :: m_temp=4, niso_tot=32, nreac_tot=64
	INTEGER, PRIVATE, PARAMETER :: nelem_ini=28	
	
	REAL (kind=dp), SAVE, PUBLIC, ALLOCATABLE, DIMENSION(:,:) :: taux_reac
	REAL (kind=dp),SAVE, PUBLIC , ALLOCATABLE, DIMENSION(:) :: ar, q0, temp,
	1 ttemp	
	REAL (kind=dp), SAVE, PRIVATE, DIMENSION(nelem_ini) :: ab, abon_rela,
	1 m, c
	REAL (kind=dp), SAVE, PRIVATE :: be7sbe9, be7sz, c13sc12, h2sh1,
	1 he3she4, he3she4z, li6sli7, mg25smg24, mg26smg25, ne22sne20,
	2 n15sn14, o17so16, o18so16
	REAL (kind=dp), SAVE, PUBLIC :: age_deb, age_fin, dt_planet, t_sup
	REAL (kind=dp), PUBLIC :: mzc_ext, nuzc_ext
		
	INTEGER, SAVE, PRIVATE, ALLOCATABLE, DIMENSION(:,:) :: izz
	
c i3al : indice de la r�action 3alpha			
	INTEGER, SAVE, PRIVATE :: i3al=0
	INTEGER, SAVE, PUBLIC ::  knot_temp, nreac, n_temp	
	
	
	LOGICAL, SAVE, PUBLIC :: l_planet, l_vent
	
	CHARACTER (len=2), SAVE, PRIVATE, DIMENSION(nelem_ini) :: elem
					
	PRIVATE
!	PUBLIC :: abon_ini, nuc, planetoides, taux_nuc, vent
	PUBLIC :: abon_ini, nuc, taux_nuc

	CONTAINS

c------------------------------------------------------------------------

	INCLUDE 'nuc/abon_ini.f'
	INCLUDE 'nuc/iben.f'
	INCLUDE 'nuc/nuc.f'
!	INCLUDE 'planetoides.f'	
	INCLUDE 'nuc/pp1.f'
 	INCLUDE 'nuc/pp3.f'
 	INCLUDE 'nuc/ppcno10BeBFe.f'
 	INCLUDE 'nuc/ppcno10Fe.f'
 	INCLUDE 'nuc/ppcno10K.f'
 	INCLUDE 'nuc/ppcno10.f'
 	INCLUDE 'nuc/ppcno11.f'
 	INCLUDE 'nuc/ppcno12Be.f'
 	INCLUDE 'nuc/ppcno12BeBFe.f'
 	INCLUDE 'nuc/ppcno12Li.f'
 	INCLUDE 'nuc/ppcno12.f'
 	INCLUDE 'nuc/ppcno3a12Ne.f'
 	INCLUDE 'nuc/ppcno3a9.f'
 	INCLUDE 'nuc/ppcno3aco.f'
 	INCLUDE 'nuc/ppcno9.f'
 	INCLUDE 'nuc/ppcno9Fe.f'
	INCLUDE 'nuc/rq_reac.f'
	INCLUDE 'nuc/tabul_nuc.f'
	INCLUDE 'nuc/taux_nuc.f'
!	INCLUDE 'vent.f' 	
	
	END MODULE mod_nuc
