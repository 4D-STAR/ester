
c******************************************************************

	MODULE mod_numerique

c	module regroupant les outils num�riques et utilitaires pour CESAM2k

c	Auteur: P.Morel, B.Pichon D�partement J.D. Cassini, O.C.A.
c	CESAM2k

c variable public:
c	no_croiss=.TRUE. : une suite des abscisses n'est pas
c	strictement croisaante

c fonctions private:
c	bval0 : calcul des B-splines non id. nulle en un point
c	de leur support
c	colpnt : calcul de l'abscisses du i-ieme point de collocation
c	difdiv : algorithme des diff�rences divis�es (pour interpolation
c	polynomiale formule de Newton)
c	horner : algorithme de Horner: calcul de la valeur d'un polyn�me et
c	de ses d�riv�es en un point
c	noeu_dis : formation du vecteur nodal avec discontinuit�s
c	schu58_n : interpolation pour n fonctions par B-splines (algorithme
c	5-8 p.194 de Schumaker)

c fonctions public:
c	arb_rom : transformation num�rotation arabe ==> romaine
c	boite : dessin d'une boite centr�e
c	box : dessin d'une boite assym�trique
c	bsp1ddn : interpolation 1D de n fonctions par B-spline avec d�riv�es 
c	bsp1dn : interpolation 1D de n fonctions par B-spline
c	bsp_dis : calcul des coefficients des B-splines pour interpolation
c	avec discontinuit�s, contient noeu_dis
c	bvald : calcul des B-splines non id. nulle en un point
c	de leur support avec d�riv�es
c	bval1 : calcul des B-splines non id. nulle en un point
c	de leur support avec d�riv�es premi�res	 
c	coll : d�termimation des points de collocation pour
c	int�gration d'�q. diff. avec B-splines
c	fermi_dirac: calcul des int�grales de Fermi Dirac
c	gauss_band : r�solution syst�me lin�aire, pivot partiel,
c	adapt� au cas des matrices bande
c	genere_bases : formation d'une base avec discontinuit�s
c	et de la base continue associ�e
c	intgauss : initialisation des poids et abscisses pour int�gration
c	de Gauss
c	linf : recherche de l'encadrement d'un nombre dans un tableau
c	ordonn� de fa�on croissante
c	matinv : inversion de matrice
c	neville : interpolation de Lagrange par algorithme de Neville
c	newspl : changement de base de B-spline pour n fonctions
c	newton : intepolation polynomiale, formule de Newton
c	noedif : formation du vecteur nodal pour int�gration
c	d'�q. diff. avec B-splines
c	noein : formation du vecteur nodal pour interpolation B-splines
c	noeud : formation du vecteur nodal a partir du vecteur de multiplicit�
c	pause : pause avec commentaire
c	polyder : valeurs et d�rivees d'un polyn�me, algorithme de Horner  
c	shell : routine de tri
c	sum_n : int�gration de n fonctions par B-spline
c	zoning : d�termination des abcisses assurant des incr�ments constants
c	pour une fonction monotone tabul�e

c--------------------------------------------------------------------

	USE mod_kind
	
	LOGICAL, SAVE, PUBLIC :: no_croiss=.FALSE.

	PUBLIC :: arb_rom, boite, box, bsp1ddn, bsp1dn, bsp_dis, bvald,
	1 bval1, coll, fermi_dirac, gauss_band, genere_bases, intgauss,
	2 linf, matinv, neville, newton, noedif, noein, noeud, newspl,
	3 pause, polyder, shell, sum_n, zoning

	CONTAINS

c--------------------------------------------------------------------

	INCLUDE 'arb_rom.f'
	INCLUDE 'boite.f'
	INCLUDE 'box.f'
	INCLUDE 'bsp1dn.f'
	INCLUDE 'bsp1ddn.f'
	INCLUDE 'bsp_dis.f'
	INCLUDE 'bval0.f'
	INCLUDE 'bval1.f'
	INCLUDE 'bvald.f'
	INCLUDE 'coll.f'
	INCLUDE 'colpnt.f'
	INCLUDE 'difdiv.f'    
	INCLUDE 'fermi_dirac.f'     
	INCLUDE 'gauss_band.f'
	INCLUDE 'genere_bases.f'
	INCLUDE 'horner.f'
	INCLUDE 'intgauss.f'
	INCLUDE 'linf.f'
	INCLUDE 'matinv.f'
	INCLUDE 'neville.f'  
	INCLUDE 'newspl.f'
	INCLUDE 'newton.f'
	INCLUDE 'noedif.f'
	INCLUDE 'noein.f'
	INCLUDE 'noeud.f'
	INCLUDE 'noeu_dis.f'
	INCLUDE 'pause.f'       
	INCLUDE 'polyder.f'
	INCLUDE 'schu58_n.f' 
	INCLUDE 'shell.f'
	INCLUDE 'sum_n.f'
	INCLUDE 'zoning.f'

	END MODULE mod_numerique
