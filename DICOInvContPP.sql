CREATE TABLE DICOInvContPP(
	  Estacion	    INT			NOT NULL
	 ,ID			    INT			NULL
	 ,Empresa			VARCHAR(5)	NULL
	 ,MovCont		    VARCHAR(30)	NULL
	 ,MovContID	    VARCHAR(20)	NULL
	 ,FechaContable    DATETIME		NULL
	 ,EstatusCont	VARCHAR(10)		NULL
	 ,Cuenta		    VARCHAR(35)	NULL
	 ,Debe		    FLOAT			NULL
	 ,Haber		    FLOAT			NULL
	 ,Origen		    VARCHAR(30)	NULL
	 ,OrigenID	    VARCHAR(20)	NULL
	 ,OrigenTipo	    VARCHAR(10)	NULL
	 ,EstatusProd	VARCHAR(10)		NULL
	 ,ModuloID	    VARCHAR(20)	NULL
	 ,ModuloInv		VARCHAR(5)	NULL
	 ,ModuloIDInv	INT			NULL
	 ,DebeInv		FLOAT	NULL
	 ,HaberInv		FLOAT	NULL
	 ,ModuloIDAux	INT		NULL
	 ,ModuloAux		VARCHAR(5)	NULL
     ,FechaAux		    DATETIME		NULL    
	 ,Cargo		    FLOAT			NULL
	 ,Abono		    FLOAT			NULL
	 
)