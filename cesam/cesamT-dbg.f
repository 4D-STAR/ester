
c*********************************************************************

	PROGRAM cesamT_dbg
	
c	execution de cesamT_dbg
c	Programme du sous directory CESAM_T/SOURCE_T

c	la routine cesam constituant le programme principal a �t� plac�e
c	dans le module mod_cesam. Cette disposition permet de mettre
c	cesam dans la biblioth�que et �vite de recompiler le programme
c	principal lors de tests ou de mises au point

c	cesamT-dbg est destin� aux modifications importantantes,
c	typiquement aux restructuration
	
c	Auteur: P.Morel, D�partement J.D. Cassini, O.C.A.
c    	CESAMT

c+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	USE mod_cesam, ONLY : cesam
	
	IMPLICIT NONE		
	
	CALL cesam
	
	STOP
	
	END PROGRAM cesamT_dbg
