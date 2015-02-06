
c************************************************************************

      MODULE mod_variables

c     ce MODULE regroupe les param�tres et les variables de CESAM2k

c variables public:

c-------------real dp-------------------------------------

c	bp : vecteur des variables quasi-statiques au temps t+dt,
c	initialis� dans resout
c	bp_t : vecteur des variables quasi-statiques au temps t,
c	initialis� dans update
c	chim : vecteur de composition chimique generalis�, au temps t+dt,
c	initialis� dans evol
c	chim_t : vecteur de composition chimique generalis�, au temps t,
c	initialis� dans update
c	old_ptm : vecteur des masses au temps t, initialis� dans pertes
c	tds : vecteur de l'�nergie graviphique au temps t+dt, initialis�
c	dans resout
c	tds_t : vecteur de l'�nergie graviphique au temps t, initialis�
c	dans update
	
c	mc : abscisses d'interpolation de la comp. chim. au temps t+dt,
c	initialis� dans evol
c	mct : vecteur nodal pour inter. de la comp. chim. au temps t+dt,
c	initialis� dans evol
c	mc_fixe : abscisses d'interpolation de la comp. chim. cas de la
c	grille fixe, initialis� dans cesam
c	mc_t : abscisses d'interpolation de la comp. chim. au temps t,
c	initialis� dans update
c	mct_t : vecteur nodal pour inter. de la comp. chim. au temps t,
c	initialis� dans update
c	m23 : vecteur des m^2/3 ou m au temps t+dt, initialis� dans resout
c	m23_t : vecteur des m^2/3 ou m au temps t, initialis� dans update
c	q : abscisses pour les variables quasi-statiques au temps t+dt,
c	initialis� dans resout
c	qt : vecteur nodal des variables quasi-statiques au temps t+dt,
c	initialis� dans resout
c	q_t : abscisses des variables quasi-statiques au temps t,
c	initialis� dans update
c	qt_t : vecteur nodal des variables quasi-statiques au temps t,
c	initialis� dans update
c	r2 : vecteur des r2 ou r au temps t+dt, initialis� dans
c	r2_t : vecteur des r2 ou r au temps t, initialis� dans update
c	xl : abscisses des limites pour le probl�me quasi-statique,
c	initialis� dans coll_qs
c	xt_ptm : vecteur nodal pour inter. des masses du temps t+dt --> t,
c	initialis� dans pertes
c	xt_tds : vecteur nodal pour interpolation du TdS au temps t+dt,
c	initialis� dans resout
c	xt_tds_t : vecteur nodal pour interpolation du TdS au temps t,
c	initialis� dans update
c	x_ptm : abscisses pour inter. des masses du temps t+dt --> t,
c	initialis� dans pertes
c	x_tds : abscisses pour interpolation du TdS au temps t+dt,
c	initialis� dans resout
c	x_tds_t : abscisses pour interpolation du TdS au temps t,
c	initialis� dans update
	
c	r_zc_conv : rayons des limites des ZC au temps t+dt, initialis�
c	dans lim_zc
c	m_zc : masses aux limites des ZC au temps t+dt, initialis� dans
c	lim_zc
c	m_zc_t : masses aux limites des ZC au temps t, initialis� dans
c	update
c	r_zc : rayons aux limites des ZC au temps t+dt, initialis� dans
c	im_zc	
c	r_zc_t : rayons aux limites des ZC au temps t, initialis� dans
c	update
c	r_ov : rayons aux limites des overshoot au temps t+dt, initialis�
c	dans lim_zc
c	r_ov_t : rayons aux limites des overshoot au temps t, initialis�
c	dans update		

c	age : age du mod�le au temps t, initialis� dans cesam
c	c_iben : constante de contraction de Iben, initialis� dans cesam
c	mstar : masse � l'instant t+dt, initialis� dans cesam modifi� dans
c	perte
c	mstar_t : masse � l'instant t, initialis� dans update
c	mw_tot : moment angulaire total au temps t+dt, initialis� dans
c	resout
c	mw_tot_t : moment angulaire total au temps t, initialis� dans
c	update
c	psi0 : facteur d'espacement, initialis� dans cesam
c	rstar : rayon bolom�trique au temps t+dt, initialis� dans cesam
c	wrot : vitesse angulaire en cas de rotation solide, initialis� dans
c	lit_nl
c	wrot_t : vitesse angulaire au pas temporel precedent (rot. solide),
c	initialis� dans update

c------------------integer------------------------

c	jlim : indices des limites ZR/ZC au temps t+dt, initialis� dans
c	lim_zc
c	jlim_t : indices des limites ZR/ZC au temps t, initialis� dans
c	update
c	dim_qs : dimension de l'espace des plines du mod�le quasi-static,
c	initialis� dans coll_qs
c	id_conv : indice de la premi�re zone convective, initialis� dans
c	lim_zc
c	if_conv : indice de la derni�re zone convective, initialis� dans
c	lim_zc
c       knot : dimension du vecteur nodal pour l'�qui. quasi-statique
c       au temps t+dt, la dimension de l'espace est knot-ord_qs, initialis�
c	dans cesam
c	knotc : nb. de noeuds du vecteur nodal pour la comp.chim. au temps
c	t+dt, initialis� dans evol
c	knotc_t : nb. de noeuds du vecteur nodal pour la comp.chim. au
c	temps t , initialis� dans update
c	knot_ptm : nb. de noeuds du vecteur nodal pour inter. des masses du
c       temps t+dt --> t, initialis� dans pertes
c	knot_t : dimension du vecteur nodal pour l'�qui. quasi-statique
c       au temps t, initialis� dans update
c	knot_tds : longueur du vecteur nodal pour inter. du TdS au temps
c	t+dt, initialis� dans resout
c	knot_tds_t : longueur du vecteur nodal pour inter. du TdS au temps
c	t, initialis� dans update
c	lim : nombre de limites ZR/ZC au temps t+dt, initialis� dans lim_zc
c	lim_t : nombre de limites ZR/ZC au temps t, initialis� dans update
c	nc_fixe : nombre de points de la grille fixe put interpolation de
c	la composition chiique, initialis� dans cesam
c	n_ch : nb. de couches pour la composition chimique au temps t+dt,
c	initialis� dans evol
c	n_ch_t : nb. de couches pour la composition chimique au temps t,
c	initialis� dans update
c	n_ptm : nb. de points pour inter. des masses du temps t+dt --> t,
c	initialis� dans perte
c	n_qs : nombre de points du mod�le quasi-statique au temps t+dt,
c	initialis� dans resout
c	n_qs_t : nombre de points du mod�le quasi-statique au temps t,
c	initialis� dans update
c	n_tds : nombre de points pour inter. du TdS au temps t+dt,
c	initialis� dans resout
c	n_tds_t : nb. de points pour inter. du TdS aux temps t, initialis�
c	dans update

c--------------------logical--------------------------

c	lconv : nature de la limite de la ZC au temps t+dt, initialis�
c	dans lim_zc
c	lconv_t :nature de la limite de la ZC au temps t, initialis�
c	dans update  
c	tot_conv : modele totalement convectif, initialis� dans lim_zc 
c	tot_rad : modele totalement radiatif, initialis� dans lim_zc
	
c fonctions public:

c	chim_gram : tranformation des abondances /mole ==> /gramme 
c	inter : recherche des variables � m^23 ou r^2 (m ou r) cte

c NOTATIONS (h�las incoh�rentes)
c	n_ch : nombre VARIABLE de points �l�ment de mod_variables
c	nch : nombre FIXE de fonctions �l�ment de mod_donnees
c	m_ch : ordre FIXE des splines �l�ment de mod_donnees 
c	mch(n_ch) : abscisses VARIABLES �l�ment de mod_variables

c 	Auteur: P.Morel D�partement J.D. Cassini O.C.A.
c	CESAM2k

c-------------------------------------------------------------------------

	USE mod_donnees, ONLY: nrot, pnzc
	USE mod_kind
	
	IMPLICIT NONE
		
c variables public:
	
	REAL (kind=dp), SAVE, PUBLIC, ALLOCATABLE, DIMENSION(:,:) :: bp,
	1 bp_t, chim, chim_t, old_ptm, rota, rota_t, tds, tds_t
	REAL (kind=dp), SAVE, PUBLIC, ALLOCATABLE, DIMENSION(:) :: mc,
	1 mct, mc_fixe, mc_t, mct_t, mrot, mrott, mrott_t, mrot_t, m23,
	2 m23_t, q, qt, q_t, qt_t, r2, r2_t, xl, xt_ptm, xt_tds, xt_tds_t,
	3 x_ptm, x_tds, x_tds_t
     	REAL (kind=dp), SAVE, PUBLIC, DIMENSION(0:2*pnzc+1) :: r_zc_conv, 
 	1 hp_zc_conv, pr_zc_conv, u_zc_conv
	REAL (kind=dp), SAVE, PUBLIC, DIMENSION(2*pnzc) :: hp_zc, m_zc, m_zc_t,
	1 pr_zc, r_zc, r_zc_t, r_ov, r_ov_t
			
	REAL (kind=dp), SAVE, PUBLIC :: age, c_iben, mstar,
	1 mstar_t, mw_tot=0.d0, mw_tot_t, psi0, rstar, wrot, wrot_t

	INTEGER, SAVE, PUBLIC, DIMENSION(2*pnzc) :: jlim, jlim_t
	INTEGER, SAVE, PUBLIC :: dim_ch, dim_qs, dim_rot, id_conv, if_conv,
	1 knot, knotc, knotc_t, knot_ptm, knotr=0, knotr_t, knot_t,
	2 knot_tds, knot_tds_t, lim, lim_t, nc_fixe, n_ch, n_ch_t=-100,
	3 n_ptm=-100, n_qs, n_qs_t=-100, n_rot=0, n_rot_t, n_tds, n_tds_t

	LOGICAL, SAVE, PUBLIC, DIMENSION(0:2*pnzc) :: lconv=.FALSE.,
	1 lconv_t=.FALSE.
	LOGICAL, SAVE, PUBLIC :: lhe_stop=.FALSE., lt_stop=.FALSE.,
	1 lx_stop=.FALSE., tot_conv, tot_rad
	
c fonctions PUBLIC: 

c	chim_gram : tranformation des abondances /mole ==> /gramme 
c	inter : recherche des variables � m^23 ou r^2 (m ou r) cte
								
	PRIVATE
	PUBLIC :: chim_gram, inter, sortie

	CONTAINS
	
c----------------------------------------------------------------------	
	
	INCLUDE 'chim_gram.f'
	INCLUDE 'inter.f'
	INCLUDE 'sortie.f'	
	
	END MODULE mod_variables
