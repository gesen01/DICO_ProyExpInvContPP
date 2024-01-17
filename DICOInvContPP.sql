CREATE TABLE DICOInvContPP(
	  Estacion	    INT			NOT NULL
	 ,ID			    INT			NULL
	 ,MovCont		    VARCHAR(30)	NULL
	 ,MovContID	    VARCHAR(20)	NULL
	 ,FechaContable    DATETIME		NULL
	 ,Debe		    FLOAT			NULL
	 ,Haber		    FLOAT			NULL
	 ,OrigenTipo	    VARCHAR(10)	NULL
	 ,Origen		    VARCHAR(30)	NULL
	 ,OrigenID	    VARCHAR(20)	NULL
	 ,Cuenta		    VARCHAR(35)	NULL
    	 ,Fecha		    DATETIME		NULL    
	 ,Modulo		    VARCHAR(5)		NULL
	 ,MovAux		    VARCHAR(30)	NULL
	 ,MovAuxID	    VARCHAR(20)	NULL
	 ,Almacen		    VARCHAR(15)	NULL
	 ,Cargo		    FLOAT			NULL
	 ,Abono		    FLOAT			NULL
	 ,ModuloID	    VARCHAR(20)	NULL

)