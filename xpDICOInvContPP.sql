SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--EXEC xpDICOInvContPP 99,2023,5,1
IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpDICOInvContPP')
DROP PROCEDURE xpDICOInvContPP
GO
CREATE PROCEDURE xpDICOInvContPP
@Estacion	INT,
@Ejercicio	INT,
@Periodo	INT,
@Debug		BIT=0
AS
BEGIN
	DELETE FROM DICOContTbPP WHERE Estacion=@Estacion

	DELETE FROM DICOInvContPP WHERE Estacion=@Estacion
	
CREATE TABLE #PolizasPRODE(
	ID				INT				NULL,
	Poliza			VARCHAR(25)		NULL,
	PolizaID		VARCHAR(25)		NULL,
	FechaContable	DATETIME		NULL,
	Mov				VARCHAR(30)     NULL,
	MovID			VARCHAR(30)     NULL,
	Cuenta			VARCHAR(30)		NULL,
	Cargo			MONEY			NULL,
	Abono			MONEY			NULL
)

CREATE TABLE #MovsPRODE(
	IDPoliza		INT				NULL,
	ID				INT				NULL,
	ProdSerieLote	VARCHAR(30)     NULL,
	TotalProdE		FLOAT			NULL,	
	Mov				VARCHAR(30)     NULL,
	MovID			VARCHAR(25)     NULL,
	FechaEmision	DATETIME		NULL
)

CREATE TABLE #MovsINVCM(
	ID				INT				NULL,
	Mov				VARCHAR(25)     NULL,
	MovID			VARCHAR(25)     NULL,
	FechaEmision	DATETIME		NULL,
	Almacen			VARCHAR(10)     NULL,
	TotalInvCM		FLOAT			NULL,
	ProdSerieLote	VARCHAR(30)     NULL
)

--Se obtienen las polizas de cuardo a un rango de fechas contables que contengan en su origen una entrada de produccion
INSERT INTO #PolizasPRODE
	SELECT c.ID,c.Mov,c.MovID,c.FechaContable,c.Origen,c.OrigenID, cd.Cuenta, cd.Debe, cd.Haber
	FROM Cont AS c (NOLOCK)
	JOIN ContD AS cd (NOLOCK) ON cd.ID = c.ID AND cd.Cuenta='115-003-000'
	WHERE c.Ejercicio=@Ejercicio
	AND c.Periodo=@Periodo
	AND c.Origen='Entrada Produccion'
	AND c.Estatus='CONCLUIDO'
	
INSERT INTO #PolizasPRODE
	SELECT c.ID,c.Mov,c.MovID,c.FechaContable,c.Origen,c.OrigenID, cd.Cuenta, cd.Debe, cd.Haber
	FROM Cont AS c (NOLOCK)
	JOIN ContD AS cd (NOLOCK) ON cd.ID = c.ID AND cd.Cuenta='115-003-000'
	WHERE c.Ejercicio=@Ejercicio
	AND c.Periodo=@Periodo
	AND c.Origen<>'Entrada Produccion'
	AND c.Estatus='CONCLUIDO'


IF @Debug=1
	SELECT * FROM #PolizasPRODE

--Obtiene todas las entradas de produccion basado en las polizas seleccionadas
INSERT INTO #MovsPRODE
	SELECT PP.id, p.ID,pd.ProdSerieLote,SUM(pd.Cantidad*pd.Costo),p.Mov,p.MovID,p.FechaEmision
	FROM Prod AS p (NOLOCK)
	JOIN ProdD AS pd (NOLOCK) ON pd.ID = p.ID
	JOIN MovTipo AS mt ON mt.Mov = p.Mov AND mt.Clave IN ('PROD.E')
	LEFT JOIN #PolizasPRODE AS pp ON pp.Mov = p.Mov AND pp.MovID = p.MovID
	WHERE p.Estatus='CONCLUIDO'
	AND p.Ejercicio=@Ejercicio
	AND p.Periodo=@Periodo
	GROUP BY PP.id, p.ID,pd.ProdSerieLote,p.Mov,p.MovID,p.FechaEmision
	
IF @Debug=1
	SELECT * FROM #MovsPRODE WHERE ProdSerieLote='894'
	
--Obtiene los consumos 
INSERT INTO #MovsINVCM
	SELECT i.id, i.mov,i.MovID,i.FechaEmision,i.Almacen,SUM(id.Cantidad*id.Costo),id.ProdSerieLote
	FROM Inv AS i (NOLOCK)
	JOIN InvD AS id (NOLOCK) ON id.ID = i.ID
	JOIN MovTipo AS mt ON mt.Mov = i.Mov AND mt.Modulo='INV' AND mt.Clave='INV.CM'
	WHERE i.Estatus='CONCLUIDO'
	AND i.Ejercicio=@Ejercicio
	AND i.Periodo=@Periodo
	GROUP BY i.id, i.mov,i.MovID,i.FechaEmision,i.Almacen,id.ProdSerieLote

IF @Debug=1
	SELECT * FROM #MovsINVCM --WHERE Mov='Consumo Material' AND MovID='TEP2446'
		
	--Esta seccion inserta las polizas de las entradas de produccion y consumos
	IF NOT EXISTS(SELECT 1 FROM DICOContTbPP WHERE Estacion=@Estacion)
	BEGIN
		--Se insertan los consumos realizados a las entradas de produccion
		INSERT INTO DICOContTbPP	
			SELECT @Estacion, p.IDPoliza,pd.Poliza,pd.PolizaID,pd.FechaContable,pd.Cargo,pd.Abono,'INV',i.Mov,i.MovID,ISNULL(pd.Cuenta,'115-003-000'),i.ID
			FROM #MovsPRODE p
			LEFT JOIN #MovsINVCM i ON p.ProdSerieLote=i.ProdSerieLote
			LEFT JOIN #PolizasPRODE pd ON pd.ID=p.IDPoliza 
	
		--Se insertan todas aquellas polizas que no tienen una entrada de produccion asociada	
		INSERT INTO DICOContTbPP
			SELECT @Estacion, p.ID,p.Poliza,p.PolizaID,p.FechaContable,p.Cargo,p.Abono
				  ,'INV',i.Mov,i.MovID,p.Cuenta,i.ID
			FROM Inv i
			JOIN MovTipo mt ON i.Mov=mt.Mov AND mt.Modulo='INV' AND mt.Clave='INV.T'
			LEFT JOIN #PolizasPRODE p ON p.Mov=i.Mov AND p.MovID=i.MovID
			WHERE i.Ejercicio=@Ejercicio
			AND i.Periodo=@Periodo
			AND i.Estatus='CONCLUIDO'
		
		INSERT INTO DICOContTbPP
		SELECT @Estacion, p.IDPoliza,pd.Poliza,pd.PolizaID,pd.FechaContable,pd.Cargo,pd.Abono,'PROD',p.Mov,p.MovID,pd.Cuenta,p.ID
		FROM #MovsPRODE p
		LEFT JOIN #PolizasPRODE pd ON pd.ID=p.IDPoliza 
		
		IF @Debug=1			
			SELECT * FROM DICOContTbPP WHERE Estacion=@Estacion --AND OrigenTipo='INV' AND Origen='Entrada Produccion' AND OrigenID='TEP2514'
	END
		
	--Esta sección inserta datos en la tabla principal de conciliacion de datos
	 IF NOT EXISTS(SELECT 1 FROM DICOInvContPP WHERE Estacion=@Estacion)
	 BEGIN
	 		--Inserta los datos 
            INSERT INTO DICOInvContPP(Estacion,ModuloID,Fecha,Modulo,MovAux,MovAuxID,Cargo,Abono,Almacen,Cuenta)     
                  SELECT @Estacion,a.ModuloID,a.Fecha, a.Modulo, a.Mov, a.MovID
                        ,'Cargo'=SUM(ISNULL(a.Cargo,0))
                        ,'Abono'=SUM(ISNULL(a.Abono,0))
                        ,a.Grupo AS 'Almacen'
                        ,a2.Cuenta
               FROM AuxiliarU a (NOLOCK)
               LEFT JOIN Alm AS a2 ON a2.Almacen=a.Grupo
               WHERE 1=1
               AND a.Rama='INV'
               AND a.Grupo = 'PP'
               AND a.Ejercicio=@Ejercicio
               AND a.Periodo=@Periodo
               GROUP BY a.FECHA, a.Modulo, a.Mov, a.MovID,a.Grupo,a2.Cuenta,a.ModuloID
               HAVING ROUND((SUM(ISNULL(a.Cargo,0)))-(SUM(ISNULL(a.Abono,0))),2)<> 0
               
			   UPDATE d SET ID=c.ID
                     ,MovCont=c.MovCont
                     ,MovContID=c.MovContID
                     ,FechaContable=ISNULL(c.FechaContable, d.fecha)
                     ,Debe=ISNULL(c.Debe,0)
                     ,Haber=ISNULL(c.haber,0)
                     ,OrigenTipo=C.OrigenTipo
                     ,Origen=C.Origen
                     ,OrigenID=C.OrigenID
			 FROM DICOInvContPP d
			 JOIN DICOContTbPP c ON d.MovAux=c.Origen AND d.MovAuxID=c.OrigenID AND d.Modulo=c.OrigenTipo 
			  WHERE d.Estacion=@Estacion

               --Se insertan las polizas que no tienen movimientos en el auxiliar
              INSERT INTO DICOInvContPP(Estacion,ID,MovCont,MovContID,FechaContable ,Debe,Haber,OrigenTipo,Origen,OrigenID,Cuenta, Fecha,Almacen)
				 SELECT @Estacion,c.ID,c.MovCont,c.MovContID,c.FechaContable ,c.Debe,c.Haber,c.OrigenTipo,c.Origen
						,c.OrigenID,ISNULL(c.Cuenta,'115-003-000'), c.FechaContable
						,'PP'
				 FROM DICOContTbPP c
				 LEFT JOIN DICOInvContPP d ON c.Origen=d.MovAux 
										  AND c.OrigenID=d.MovAuxID 
										  AND c.OrigenTipo=d.Modulo
				 WHERE NOT EXISTS(SELECT 1 FROM DICOContTbPP p WHERE d.MovAux=p.Origen AND p.OrigenID=d.MovAuxID AND d.Modulo=p.OrigenTipo)
				 AND c.Estacion=@Estacion
      END	
			
	       
          
          UPDATE DICOInvContPP SET FechaContable =  ISNULL(FechaContable, Fecha)

		IF @Debug=1
			SELECT * FROM DICOInvContPP WHERE Estacion=@Estacion
	
RETURN
END
