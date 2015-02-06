
c+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	MODULE mod_donnees

c	module contenant les quantit�s fix�es au cours de l'�volution
c	- du fichier de donn�es initialis�es dans lit_nl
c	- les contantes physiques initialis�es dans ini_ctes_phys
c	- les param�tres de pr�cision initialis�es dans  cesam
c	- les param�tres d'�volution initialis�es dans cesam
c	- les param�tres de composition chimique initialis�es dans les
c       routines de r�ac. nuc., etc...	

c       param�tres public:
c	dtmin : pas temporel minimum en Myrs
c	n_min : nombre minimum de couches
c	pnzc : nombre max de zones convectives
c	r_qs : ordre des eq. diff. pour l'�quilibre quasi-statique
c	version : num�ro de version

c       variables public:

c---------------------real dp--------------------------

c	ab_ini : abondances initiales, initialis� dans nuc 
c	ab_min : abondances minimales, initialis� dans nuc 
c	nucleo : masses atomiques des �l�ments, initialis� dans tabul_nuc  
c	zi : charges des �l�m�nts, initialis� dans tabul_nuc
	
c	abe7 : masse atomique en amu du b�ryllium 7, initialis� dans
c	ini_ctes 
c	abe9 : masse atomique en amu du b�ryllium 9, initialis� dans
c	ini_ctes 
c	ac12 : masse atomique en amu du carbone 12, initialis� dans
c	ini_ctes 
c	ac13 : masse atomique en amu du carbone 13, initialis� dans
c	ini_ctes
c	afe56 : masse atomique en amu du fer 56, initialis� dans ini_ctes
c	af18 : masse atomique en amu du fluor 18, initialis� dans ini_ctes
c	af19 : masse atomique en amu du fluor 19, initialis� dans ini_ctes
c	agemax : age maximum � atteindre, initialis� dans lit_nl
c	ah : masse atomique en amu de l'hydrog�ne, initialis� dans ini_ctes
c	ah2 : masse atomique en amu du deut�rium, initialis� dans ini_ctes
c	ahe3 : masse atomique en amu de l'h�lium 3, initialis� dans
c	ini_ctes
c	ahe4 : masse atomique en amu de l'h�lium 4, initialis� dans
c	ini_ctes
c	ali6 : masse atomique en amu du lithium 6 , initialis� dans
c	ini_ctes
c	ali7 :  masse atomique en amu du lithium 7, initialis� dans
c	ini_ctes
c	alpha : longueur de m�lange, initialis� dans lit_nl 
c	amg23 : masse atomique en amu du magn�sium 23, initialis�
c	dans ini_ctes
c	amg24 : masse atomique en amu du magn�sium 24, initialis�
c	dans ini_ctes
c	amg25 : masse atomique en amu du magn�sium 25, initialis�
c	dans ini_ctes
c	amg26 : masse atomique en amu du magn�sium 26, initialis�
c	dans ini_ctes
c	amu : masse atom. unite, Avogadro=1/amu, initialis� dans ini_ctes
c	an : masse atomique en amu du neutron, initialis� dans ini_ctes
c	ana23 : masse atomique en amu du sodium 23, initialis� dans
c	ini_ctes
c	ane20 : masse atomique en amu du n�on 20, initialis� dans ini_ctes
c	ane21 : masse atomique en amu du n�on 21, initialis� dans ini_ctes
c	ane22 : masse atomique en amu du n�on 22, initialis� dans ini_ctes
c	an13 : masse atomique en amu de l'azote 13, initialis� dans
c	ini_ctes
c	an14 : masse atomique en amu de l'azote 14, initialis� dans
c	ini_ctes
c	an15 : masse atomique en amu de l'azote 15, initialis� dans
c	ini_ctes
c	ap : masse atomique en amu du proton, initialis� dans ini_ctes
c	ao16 : masse atomique en amu de l'oxyg�ne 16, initialis� dans
c	ini_ctes
c	ao17 : masse atomique en amu de l'oxyg�ne 17, initialis� dans
c	ini_ctes
c	ao18 : masse atomique en amu de l'oxyg�ne 18, initialis� dans
c	ini_ctes
c	aradia : cte. de la radiation, initialis� dans ini_ctes
c	clight : c�l�rite de la lumi�re, initialis� dans ini_ctes
c	cpturb : param�tre de pression turbulente, initialis� dans lit_nl
c	ctem : facteur de r�partition en masse, initialis� dans cesam
c	ctep : facteur de r�partition en pression, initialis� dans cesam
c	cter : facteur de r�partition en rayon, initialis� dans cesam
c	dpsi : variation max pour modification de n_qs, initialis�
c	dans cesam
c	dn_fixe : taux pour modif de grille fixe en comp.chim, initialis�
c	dans cesam
c	dtlist : intervalle de temps entre deux listings complets,
c	initialis� dans lit_nl
c	dtmax : pas temporel maximum, initialis� dans cesam
c	dt0 : pas temporel initial, initialis� dans cesam
c	pmw : param�tre libre de perte de moment cin�tique
c	d_grav : variation maximale du TdS, initialis� dans cesam
c	d_turb : coefficient de diffusion turbulente, initialis� dans
c	lit_nl
c	echarg : charge de l'�lectron, initialis� dans ini_ctes
c	eve : �lectron volt, initialis� dans ini_ctes
c	g : gravit� d�duit de gmsol et de Msol, initialis� dans ini_ctes
c	gmsol : valeur observ�e de G Msol, initialis� dans ini_ctes
c	granr : constante des gaz parfaits, initialis� dans ini_ctes
c	hpl : cte. de Planck, initialis� dans ini_ctes
c	kbol : cte. de Boltzman, initialis� dans ini_ctes
c	lbol0 : point 0 des Mbol, initialis� dans ini_ctes
c	ln10 : ln(10), initialis� dans ini_ctes
c	loc_zc : pr�cision de la localisation des limites ZR/ZC,
c	initialis� dans cesam
c	log_teff : limite en Teff, initialis� dans lit_nl
c	lsol : luminosit� solaire, initialis� dans ini_ctes
c	mdot : taux de perte de masse, initialis� dans lit_nl
c	me : masse �lectron, initialis� dans ini_ctes
c	msol : masse solaire, initialis� dans ini_ctes
c	mtot : masse initiale, initialis� dans lit_nl
c	ovshti : taux d'overshooting inf�rieur, initialis� dans lit_nl
c	ovshts : taux d'overshooting sup�rieur, initialis� dans lit_nl
c	pi : pi, initialis� dans ini_ctes
c	precit : pr�cision pour l'int�gration temporelle de la composition
c	chimique, initialis� dans cesam
c	precix : pr�cision pour int�gration �quilibre quasi statique,
c	initialis� dans cesam
c	re_nu : param�tre de diffusivit� radiative, initialis� dans lit_nl
c	ro_test : test de variation du TdS si ro > ro_test, initialis�
c	dans cesam
c	rsol : rayon solaire, initialis� dans ini_ctes
c	secon6 : nb. de s. en 10**6 ans, initialis� dans ini_ctes
c	sigma : cte. de Stefan, initialis� dans ini_ctes
c	tau_max : �paisseur optique au fond de l'atmosph�re, initialis�
c	dans lit_nl
c	t_inf, t_sup : limtes de la tabulation des r�actions
c	thermonucl�aires, initialis� dans tabul_nuc
c	t_stop : limite sup�rieure de la temp�rature centrale, initialis�
c	dans lit_nl
c	w_rot : vitesse angulaire initiale, initialis� dans lit_nl
c	x0 : abondance initiale en hydrog�ne, initialis� dans lit_nl
c	x_stop : valeur limite de l'abondance centrale en  hydrog�ne,
c	initialis� dans lit_nl
c	y0 : abondance initiale en h�lium, initialis� dans lit_nl
c	zsx_sol : Z/X solaire, initialis� dans ini_ctes
c	zsx0 : valeur initiale de Z/X, initialis� dans lit_nl
c	z0 : abondance initiale en m�taux, initialis� dans lit_nl

c-------------------real sp-----------------------------

c	dfesh_des : barres d'erreur pour le dessin de [Fe/H], initialis�
c	dans des
c	dl_des : barres d'erreur pour le dessin de LOG L, initialis� dans
c	dans des
c	dteff_des : barres d'erreur pour le dessin de LOG Teff, initialis�
c	dans des
c	zoom_l : extensions asym�triques en luminosit�, initialis� dans des
c	zoom_t : extensions asym�triques en Teff, initialis� dans des	

c	fesh_des : valeur de [Fe/H] en surface, initialis� dans des
c	l_des : cible en L/Lsol, initialis� dans des
c	teff_des : cible en Teff, initialis� dans des	

c--------------------integer------------------------

c	ihe4 : indice de l'h�lium 4, initialis� dans tabul_nuc
c	ini0 : nb. iter. N-R avec r�estim. de comp.chim. lim. ZR/ZC,
c	initialis� dans cesam
c	Krot : indice de la vitesse angulaire, initialis� dans lit_nl
c	m_ch : ordre des splines pour interpolation de la comp.chim.
c	initialis� dans cesam
c	m_ptm : ordre des spl. pour inter. de la masse (perte de masse),
c	initialis� dans cesam
c	m_qs : ordre des splines pour les variables quasi-static,
c	initialis� dans cesam
c	m_tds : ordre des splines pour interpolation de TdS, initialis�
c	dans cesam
c	nchim : nombre d'�l�ments strictement chimiques, initialis� dans
c	nuc
c	ne : nombre d'�quations pour l'�quilibre quasi-statique,
c	initialis� dans cesam
c	n_atm : nombre de couches de l'atmosph�re, initialis� dans cesam
c	n_max : nombre maximum de couches pour l'�quilibre quasi-statique,
c	initialis� dans cesam
c	ordre : ordre d'int�gration de l'�volution temporelle de la
c	composition chimique, sans diffusion, initialis� dans cesam
c	ord_qs : ordre d'int�gration  pour l'�quilibre quasi-statique,
c	initialis� dans cesam

c-------------logical-----------------------

c	diffusion : il y a diffusion microscopique, initialis� dans lit_nl
c	en_masse : utilisation de la variable lgrangienne, initialis� dans
c	cesam
c	grille_fixe : utilisation d'une grille fixe pour la composition
c	chimique, initialis� dans lit_nl
c	jpz : overshoot suivant JpZh, initialis� dans lit_nl
c	kipp : utilisation de l'approximation de Kippenhahn, initialis�
c	dans cesam
c	ledoux : utilisation du crit�re de Ledoux , initialis� dans lit_nl
c	lim_ro : limite en densit� pour l'atmosph�re, initialis� dans
c	lit_nl
c	mitler : utilisation de l'�crantage suivant Mitler, initialis� dans
c	lit_nl
c	mvt_dis : ajustement de comp.chim. suivant mvt. des discontinut�s,
c	initialis� dans cesam
c	pturb : utilisation de la pression turbulente, initialis� dans
c	cesam
c	rep_atm : on reprend l'atmosph�re en binaire, initialis� dans cesam
c	rot_solid : il y a rotation solide, initialis� dans lit_nl
	
c---------character------------

c	precision : type de calcul, initialis� dans lit_nl
c	nom_elem : nom des �l�ments du vecteur de composition chimique
c	g�n�ralis�, initialis� dans tabul_nuc
c	arret : type d'arr�t, initialis� dans lit_nl
c	nom_atm : d�signation de la routine de restitution d'atmosph�re,
c	initialis� dans lit_nl
c	nom_abon : d�signation de la routine d'abondances initiales,
c	initialis� dans lit_nl
c	nom_conv : d�signation de la routine de convection, initialis�
c	dans lit_nl
c	nom_ctes : d�signation de la routine de constantes physiques,
c	initialis� dans lit_nl
c	nom_des : d�signation de la routine de dessin, initialis� dans
c	lit_nl
c	nom_diffm : d�signation de la routine de diffusion micoscopique,
c	initialis� dans lit_nl
c	nom_difft : d�signation de la routine de diffusion turbulente,
c	initialis� dans lit_nl
c	nom_etat : d�signation de la routine d'�quation d'�tat, initialis�
c	dans lit_nl
c	nom_nuc : d�signation de la routine de r�actions thermonucl�aires,
c	initialis� dans lit_nl
c	nom_nuc_cpl : d�signation de la compilation de r�actions
c	thermonucl�aires, initialis� dans lit_nl
c	nom_output : d�signation du type de fichier ASCII en sortie,
c	initialis� dans lit_nl
c	nom_pertm : d�signation de la routine de perte de masse, initialis�
c	dans lit_nl
c	nom_pertw : d�signation de la routine de perte de moment cin�tique,
c	initialis� dans lit_nl
c	nom_tdetau : d�signation de la routine de loi T(tau), initialis�
c	dans lit_nl
c	nom_fich2 : identificateur des fichiers du mod�le, initialis� dans
c	cesam
c	f_eos : noms des fichiers d'opacit�, initialis� dans lit_nl
c	f_opa : noms des fichiers d'�quation d'�tat, initialis� dans lit_nl
c	nom_chemin : chemin du directory SUN_STAR_DATA des donn�es,
c	initialis� dans lit_nl
c	nom_opa : d�signation de la routine d'opacit�, initialis� dans
c	lit_nl
c	source : nom de la source des constantes physiques, initialis�
c	dans ini_ctes
c	methode : description de la m�thode de calcul, initialis� dans
c	cesam

c       NOTATIONS (h�las incoh�rentes) pour les d�veloppements sur B-splines
c	n_ch : nombre VARIABLE de points �l�ment de mod_variables
c	nch : nombre FIXE de fonctions �l�ment de mod_donnees
c	m_ch : ordre FIXE des splines �l�ment de mod_donnees 
c	mch(n_ch) : abscisses VARIABLES �l�ment de mod_variables

c       Auteur: P.Morel, D�partement J.D. Cassini, O.C.A.
c       CESAM2k

c+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	USE mod_kind
	
	IMPLICIT NONE

c       param�tres public:

	REAL (kind=dp), PARAMETER, PUBLIC :: dtmin=5.d-7, dx_tams=1.d-4,
	1    x_tams=0.01d0
	INTEGER, PARAMETER, PUBLIC :: n_min=150, pnzc=8, r_qs=1
	
c	CHARACTER (len=7), PARAMETER, PUBLIC :: version='V1.1.4'
	INCLUDE 'journal'
	
c       variables public

	REAL (kind=dp), SAVE, PUBLIC, ALLOCATABLE, DIMENSION(:) :: ab_ini,
	1    ab_min, nucleo, rot_min, xvent, zi	
	REAL (kind=dp), SAVE, PUBLIC, DIMENSION(28) :: abon_m
	REAL (kind=dp), SAVE, PUBLIC, DIMENSION(5) :: pmw
	REAL (kind=dp), SAVE, PUBLIC :: abe7, abe9, ab11, ac12, ac13,
	1    afe56, af18, af19, agemax, ah, ah2, ahe3, ahe4, ali6, ali7,
	2    alpha, amg23, amg24, amg25, amg26, amu, an, ana23, ane20, ane21,
	3    ane22, an13, an14, an15, ap, ao16, ao17, ao18, aradia, beta_cgm, clight,
	4    cpturb, ctel, ctem, ctep, cter, ctet, dpsi, dn_fixe, dtlist,
	5    dtmax, dt0, d_conv=1.d13, d_grav, d_turb, echarg, eve, f_cgm, fesh_sol,
	6    g, gmsol, granr, he_core, hhe_core, hpl, kbol, lbol0, li_ini,
	7    lnt_stop, ln_Tli, ln10, loc_zc, log_teff, lsol, mdot, me, msol, mtot,
	8    ovshti, ovshts, pi, precit, precix, p_pertw, p_vent, pw_extend,
	9    re_nu, ro_test, rsol, secon6, sigma, tau_max, t_inf, t_sup,
	1    t_stop, w_form, w_rot, x0, x_stop, y0, zeta_cgm, zsx_sol, zsx0, z0,
	2    beta_v, zeta_v, frac_vp
	
	REAL (kind=sp), SAVE, PUBLIC, DIMENSION(2) :: dfesh_des, dl_des,
	1    dteff_des, zoom_l=0., zoom_t=0.

c       pour un �cran 1280 X 1024	
	REAL (kind=sp), SAVE, PUBLIC :: dh=1.5, dl=2., h=7., ld=10.
	
c       pour un �cran 1280 X 1600	
c	REAL (kind=sp), SAVE, PUBLIC ::  dh=2.5, dl=2.5, h=7., ld=11.3,
	
	REAL (kind=sp), SAVE, PUBLIC :: fesh_des=1000.,
	1    l_des=-100., teff_des=-100., logteff_max=-100.,
	2    logteff_min=-100., logl_max=-100., logl_min=-100.,
	3    xleft=1.8, ybot=1.4, y_age=1.3
	
	INTEGER, SAVE, PUBLIC :: Krot, ife56=0, ihe4, ini0, Ipg, i_ex,
	1    m_ch, m_ptm, m_qs, m_rl, m_rot, m_tds, nb_max_modeles, nchim,
	2    ne, nrot, n_atm, n_max, ordre, ord_qs

	LOGICAL, SAVE, PUBLIC :: diffusion, en_masse,
	1    garde_xish, grille_fixe, He_ajuste, jpz, kipp, ledoux, lim_ro,
	2    lov_ad=.TRUE., lvent=.TRUE., mitler, modif_chim, mvt_dis, pturb,
	3    rep_atm=.FALSE., rot_solid, t_ajuste, x_ajuste

	CHARACTER (len=2), SAVE, PUBLIC :: precision	
	CHARACTER (len=4), SAVE, PUBLIC, ALLOCATABLE, DIMENSION(:) ::
	1    nom_elem, nom_rot
	CHARACTER (len=4), SAVE, PUBLIC :: arret, nom_xheavy
	CHARACTER (len=5), SAVE, PUBLIC :: unit		
	CHARACTER (len=10), SAVE, PUBLIC :: langue	
	CHARACTER (len=20), SAVE, PUBLIC :: nom_atm, nom_abon,
	1    nom_conv, nom_ctes, nom_des, nom_diffm, nom_diffw, nom_difft,
	2    nom_etat, nom_frad, nom_nuc, nom_nuc_cpl, nom_output, nom_pertm,
	3    nom_pertw, nom_tdetau
	CHARACTER (len=31), SAVE, PUBLIC :: nom_fich2
	CHARACTER (len=50), SAVE, PUBLIC, DIMENSION(8) :: f_eos, f_opa
	CHARACTER (len=50), SAVE, PUBLIC :: nom_opa, source
	CHARACTER (len=80), SAVE, PUBLIC :: methode
	CHARACTER (len=100), SAVE, PUBLIC :: device='/xw'
	CHARACTER (len=255), SAVE, PUBLIC :: nom_chemin		

	PRIVATE
	PUBLIC :: lit_nl, ini_ctes, print_ctes

	CONTAINS

c-------------------------------------------------------------------
	
	INCLUDE 'ctes_85.f'
	INCLUDE 'ctes_94.f'
	INCLUDE 'ini_ctes.f'
	INCLUDE 'lit_nl.f'
	INCLUDE 'print_ctes.f'

	END MODULE mod_donnees
