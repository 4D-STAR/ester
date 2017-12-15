
c******************************************************************

	MODULE mod_opa

c module regroupant les routines de CESAM2k
c concernant les routines d'opacit� et leurs routines propres
c d'exploitation

c le calcul de l'opacit� est effectu� par la routine g�n�rique opa
c les opacit�s sont diff�renci�es par leur nom: nom_opa
c lu dans lit_nl mis dans mod_donnees

c La signification des variables est d�crite au paragraphe F6 de la notice
c de CESAM2k

c	Auteur: P.Morel, D�partement J.D. Cassini, O.C.A.
c	CESAM2k

c-------------------------------------------------------

	PRIVATE
	PUBLIC :: opa

	CONTAINS

c------------------------------------------------------------------

	INCLUDE 'opa/kappa_cond.f'
	INCLUDE 'opa/opa.f'
	INCLUDE 'opa/opa_compton.f'
	INCLUDE 'opa/opa_gong.f'
c	INCLUDE 'opa/opa_houdek9.f'
	INCLUDE 'opa/opa_int_zsx.f'
	INCLUDE 'opa/opa_opalCO.f'
	INCLUDE 'opa/opa_opal2.f'
	INCLUDE 'opa/opa_yveline.f'
	INCLUDE 'opa/opa_yveline_lisse.f'

	END MODULE mod_opa

	INCLUDE 'z14xcotrin21.f'
