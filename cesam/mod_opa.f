
c******************************************************************

	MODULE mod_opa

c	module regroupant les routines de CESAM2k
c	concernant les routines d'opacit� et leurs routines propres
c	d'exploitation

c	le calcul de l'opacit� est effectu� par la routine g�n�rique opa
c	les opacit�s sont diff�renci�es par leur nom: nom_opa
c	lu dans lit_nl mis dans mod_donnees

c fonctions private:
c	kappa_cond : opacit�s conductives
c	opa_gong : opacit�s simplifiees (Kramers ameliore)
c	opa_houdek9 : opacit�s de Houdek version 9, (OPAL+Alexander),
c	interpolation par rational B-spline
c	opa_int_zsx : opacit�s OPAL interpolation lin�aires
c	opa_yveline : opacit�s OPAL+Alexander interp. et raccord d'Yveline
c	extension arbitraire X=1
c	opa_yveline_lisse : opacit�s OPAL+Alexander raccord d'Yveline,
c	interpolation lin�aire et extension arbitraire X=1

c fonction public:
c	opa : routine g�n�rique d'opacit�

c	Auteurs: P.Morel, D�partement J.D. Cassini, O.C.A.
c	CESAM2k

c-------------------------------------------------------

	PRIVATE
	PUBLIC :: opa
	
	CONTAINS
	
c------------------------------------------------------------------	
	
	INCLUDE 'kappa_cond.f'
	INCLUDE 'opa.f'
	INCLUDE 'opa_gong.f'
	INCLUDE 'opa_houdek9.f'   !YLD
c	INCLUDE 'opa_houdek04.f'
	INCLUDE 'opa_int_zsx.f'
	INCLUDE 'opa_opalCO.f'
	INCLUDE 'opa_opal2.f'
	INCLUDE 'opa_yveline.f'
c	INCLUDE 'opa_yveline_lisse.f'			
	
	END MODULE mod_opa

	INCLUDE 'z14xcotrin21.f'
