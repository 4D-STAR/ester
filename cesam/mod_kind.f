
c******************************************************************

	MODULE mod_kind
	
c	module de d�finition des types
c	sp: simple pr�cision, dp: double pr�cision

c	Auteur: P.Morel + B. Pichon
c	Laboratoire JD. Cassini, OCA

c-----------------------------------------------------------------
	
	INTEGER, PARAMETER, public :: dp=kind(1.d0), sp=kind(1.)
	
	END module mod_kind
