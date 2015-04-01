
c*******************************************************************

	MODULE mod_conv
      
c Module regroupant les routines relatives � la convection
c le calcul du gradient est effectu� par appel � la routine g�n�rique conv

c La signification des variables est d�crite au paragraphe F7 de la notice
c de CESAM2k

c Auteur : P.Morel, D�partement J.D. Cassini, O.C.A., CESAM2k	
	
c-------------------------------------------------------------------

	PRIVATE     
	PUBLIC :: conv

	CONTAINS

c------------------------------------------------------------------

	INCLUDE 'conv.f'       
	INCLUDE 'conv_a0.f' 
	INCLUDE 'conv_cgm_reza.f'
	INCLUDE 'conv_cm.f'
	INCLUDE 'conv_cml.f'
	INCLUDE 'conv_cm_reza.f'
	INCLUDE 'conv_jmj.f'

	END MODULE mod_conv
