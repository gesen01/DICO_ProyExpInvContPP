SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpDICOExpPP')
DROP PROCEDURE xpDICOExpPP
GO
--EXEC xpDICOExpPP 999,'XONA','115-003-000','PP',2023,01,1
CREATE PROCEDURE xpDICOExpPP
@Estacion	INT,
@Empresa	VARCHAR(5),
@Cuenta		VARCHAR(15)=NULL,
@Almacen	VARCHAR(5)=NULL,
@Ejercicio	INT,
@Periodo	INT,
@Debug		BIT=0
AS
BEGIN

CREATE TABLE #ProdTbl(
	ID		INT				NULL,
	Mov		VARCHAR(30)		NULL,
	MovID	VARCHAR(35)		NULL,
	FechaEmision	DATETIME	NULL,
	Estatus	VARCHAR(15)		NULL,
	Empresa	VARCHAR(10)		NULL,
	Clave	VARCHAR(10)		NULL,
	Cantidad	FLOAT		NULL,
	Costo		FLOAT		NULL,
	Articulo	VARCHAR(25)	NULL,
	ProdSerieLote	VARCHAR(45)	NULL,
	Total		FLOAT		NULL	
)

CREATE TABLE #ContTbl(
	ID			INT				NULL,
	Mov			VARCHAR(20)		NULL,
	MovID		VARCHAR(25)		NULL,
	FechaContable	DATETIME	NULL,
	Origen		VARCHAR(20)		NULL,
	OrigenID	VARCHAR(25)		NULL,
	OrigenTipo	VARCHAR(10)		NULL,
	Empresa		VARCHAR(10)		NULL,
	Estatus		VARCHAR(15)		NULL,
	Cuenta		VARCHAR(25)		NULL,
	Clave		VARCHAR(10)		NULL,
	Debe		FLOAT			NULL,
	Haber		FLOAT			NULL
)

CREATE TABLE #ProdETbl(
	ID			INT				NULL,
	Mov			VARCHAR(20)		NULL,
	MovID		VARCHAR(20)		NULL,
	FechaContable	DATETIME	NULL,
	Origen		VARCHAR(20)		NULL,
	OrigenID	VARCHAR(20)		NULL,
	OrigenTipo	VARCHAR(10)		NULL,
	EstatusProd	VARCHAR(10)		NULL,
	Empresa		VARCHAR(10)		NULL,
	EstatusCont	VARCHAR(10)		NULL,
	Cuenta		VARCHAR(20)		NULL,
	ModuloID	INT				NULL,
	Clave		VARCHAR(10)		NULL,
	Cantidad	FLOAT			NULL,
	Costo		FLOAT			NULL,
	Articulo	VARCHAR(20)		NULL,
	ProdSerieLote	VARCHAR(20)	NULL,
	TotalProd	FLOAT			NULL,
	Debe		FLOAT			NULL,
	Haber		FLOAT			NULL
)

CREATE TABLE #TransferenciasTbl(
	ID			INT				NULL,
	Mov			VARCHAR(20)		NULL,
	MovID		VARCHAR(20)		NULL,
	FechaContable	DATETIME	NULL,
	Origen		VARCHAR(20)		NULL,
	OrigenID	VARCHAR(20)		NULL,
	OrigenTipo	VARCHAR(10)		NULL,
	Empresa		VARCHAR(10)		NULL,
	EstatusCont	VARCHAR(10)		NULL,
	Cuenta		VARCHAR(20)		NULL,
	ModuloID	INT				NULL,
	Clave		VARCHAR(10)		NULL,
	Debe		FLOAT			NULL,
	Haber		FLOAT			NULL
)

CREATE TABLE #ProdSerieLoteTBL(
	ID			INT				NULL,
	Mov			VARCHAR(20)		NULL,
	MovID		VARCHAR(20)		NULL,
	Empresa		VARCHAR(10)		NULL,
	FechaContable	DATETIME	NULL,
	EstatusCont	VARCHAR(10)		NULL,
	Cuenta		VARCHAR(20)		NULL,
	Debe		FLOAT			NULL,
	Haber		FLOAT			NULL,
	Origen		VARCHAR(20)		NULL,
	OrigenID	VARCHAR(20)		NULL,
	OrigenTipo	VARCHAR(10)		NULL,
	EstatusProd	VARCHAR(10)		NULL,
	ModuloID	INT				NULL,
	Articulo	VARCHAR(20)		NULL,
	ProdSerieLote	VARCHAR(20)	NULL,
	Cantidad	FLOAT			NULL,
	TotalProd	FLOAT			NULL,
	ModuloInv	VARCHAR(10)		NULL,
	ModuloIDInv	INT				NULL,
	DebeInv		FLOAT			NULL,
	HaberInv	FLOAT			NULL
)

CREATE TABLE #ProdCont(
	ID			INT			NULL,
	Empresa		VARCHAR(10)	NULL,
	Mov			VARCHAR(20)	NULL,
	MovID		VARCHAR(20)	NULL,
	FechaContable	DATETIME	NULL,
	EstatusCont	VARCHAR(10)	NULL,
	Cuenta		VARCHAR(20)	NULL,
	Debe		FLOAT		NULL,
	Haber		FLOAT		NULL,
	OrigenTipo	VARCHAR(10)	NULL,
	ModuloID	INT			NULL,
	Origen		VARCHAR(20)	NULL,
	OrigenID	VARCHAR(20)	NULL,
	EstatusProd	VARCHAR(10)	NULL,
	ModuloINV	VARCHAR(10)	NULL,
	ModuloIDInv	INT			NULL,
	DebeInv		FLOAT		NULL,
	HaberInv	FLOAT		NULL
)

CREATE TABLE #AuxU(
	ModuloID	INT			NULL,
	Empresa		VARCHAR(10)	NULL,
	Modulo		VARCHAR(10)	NULL,
	Fecha		DATETIME	NULL,
	Cargo		FLOAT		NULL,
	Abono		FLOAT		NULL	
)

DELETE FROM DICOInvContPP WHERE Estacion=@Estacion
DELETE FROM DICOConsumosPP WHERE Estacion=@Estacion

IF @Cuenta IS NULL
	SELECT @Cuenta=a.Cuenta
	FROM Alm AS a
	WHERE a.Almacen=@Almacen

IF @Almacen IS NULL
	SELECT @Almacen=a.Almacen
	FROM Alm AS a
	WHERE a.Cuenta=@Cuenta

--Obtiene todos los datos del auxiliar en el perido y ejercicio
INSERT INTO #AuxU
SELECT a.ModuloID,a.Empresa,a.Modulo,a.Fecha,SUM(ISNULL(a.Cargo,0)) AS 'Cargo', SUM(ISNULL(a.Abono,0)) AS 'Abono'
FROM AuxiliarU a WITH(NOLOCK)
WHERE Ejercicio=@Ejercicio
AND Periodo=@Periodo
AND Grupo=@Almacen
GROUP BY a.ModuloID,a.Empresa,a.Modulo,a.Fecha

IF @Debug=1
	SELECT '#AuxU',* FROM #AuxU

--Se obtienen todas las entradas de produccion del ejercicio y periodo
INSERT INTO #ProdTbl
SELECT p.ID,p.Mov,p.MovID,p.FechaEmision,p.Estatus AS 'EstatusProd',p.Empresa,mt.Clave
		   ,pd.Cantidad,pd.costo,pd.Articulo
		   ,pd.ProdSerieLote,pd.Cantidad*pd.Costo AS 'Total'
	FROM Prod p WITH(NOLOCK) 
	JOIN ProdD pd  WITH(NOLOCK) ON pd.ID=p.ID
	JOIN MovTipo mt ON mt.Mov=p.Mov AND mt.Modulo='PROD' AND mt.Clave='PROD.E'
	WHERE YEAR(p.FechaEmision)=@Ejercicio
	AND MONTH(p.FechaEmision)=@Periodo
	AND p.Empresa=@Empresa
	AND ISNULL(pd.Costo,0) <> 0


IF @Debug=1
	SELECT '#ProdTbl',* FROM #ProdTbl

--Obtiene todas as polizas del ejercicio y periodo
INSERT INTO #ContTbl
SELECT c.ID,c.Mov,c.MovID,c.FechaContable,c.Origen,c.OrigenID,c.OrigenTipo,c.Empresa,c.Estatus, cd.Cuenta,mt.Clave
		  ,ISNULL(CASE WHEN c.Estatus='CANCELADO' THEN 0 ELSE cd.Debe END,0) AS 'Debe'
		  ,ISNULL(CASE WHEN c.Estatus='CANCELADO' THEN 0 ELSE cd.Haber END,0) AS 'Haber'
	FROM Cont AS c WITH(NOLOCK) 
	JOIN ContD AS cd WITH(NOLOCK) ON cd.ID = c.ID AND cd.Cuenta=@Cuenta
	JOIN MovTipo mt ON mt.Mov=c.Origen AND mt.Modulo=c.OrigenTipo AND mt.Clave='PROD.E'
	JOIN Mov m ON c.OrigenTipo=m.Modulo AND c.Empresa=m.Empresa AND c.Origen=m.Mov AND c.OrigenID=m.MovID
	WHERE YEAR(c.FechaContable)=@Ejercicio
	AND MONTH(c.FechaContable)=@Periodo
	AND c.Empresa=@Empresa

IF @Debug=1
	SELECT '#ContTbl',* FROM #ContTbl

--Se insertan todos los movimientos que existen en produccion con su respectiva poliza
INSERT INTO #ProdETbl(ID,Mov,MovID,FechaContable,Origen,OrigenID,OrigenTipo,EstatusProd,Empresa,EstatusCont,Cuenta,ModuloID,clave,Cantidad,Costo,Articulo,ProdSerieLote,TotalProd,Debe,Haber)
SELECT c.ID,c.Mov,c.MovID,c.FechaContable,c.Origen,c.OrigenID,c.OrigenTipo,p.Estatus,c.Empresa,c.Estatus,c.Cuenta,p.ID,c.Clave,p.Cantidad,p.Costo,p.Articulo,p.ProdSerieLote,p.Total,c.Debe,c.Haber
FROM #ContTbl c
JOIN #ProdTbl p ON c.Origen=p.Mov AND c.OrigenID=p.MovID	

--Se insertan las entradas de produccion que no tienen poliza
INSERT INTO #ProdETbl(FechaContable,Origen,OrigenID,OrigenTipo,EstatusProd,Empresa,ModuloID,Cantidad,Costo,Articulo,ProdSerieLote,TotalProd)
SELECT p.FechaEmision,p.Mov,p.MovID,'PROD',p.Estatus,p.Empresa,p.ID,p.Cantidad,p.Costo,p.Articulo,p.ProdSerieLote,p.Total
FROM #ProdTbl p
LEFT JOIN #ContTbl c ON c.Origen=p.Mov AND c.OrigenID=p.MovID	
WHERE c.ID IS NULL

--Se insertan las polizas que no tienen como origen una entrada de produccion
INSERT INTO #ProdETbl(ID,Mov,MovID,FechaContable,Origen,OrigenID,OrigenTipo,Empresa,EstatusCont,Cuenta,Debe,Haber)
	SELECT c.ID,c.Mov,c.MovID,c.FechaContable,c.Origen,c.OrigenID,c.OrigenTipo,c.Empresa,c.Estatus, cd.Cuenta
		  ,ISNULL(CASE WHEN c.Estatus='CANCELADO' THEN 0 ELSE cd.Debe END,0) AS 'Debe'
		  ,ISNULL(CASE WHEN c.Estatus='CANCELADO' THEN 0 ELSE cd.Haber END,0) AS 'Haber'
	FROM Cont AS c WITH(NOLOCK)
	JOIN ContD AS cd WITH(NOLOCK) ON cd.ID = c.ID AND cd.Cuenta=@Cuenta
	WHERE YEAR(c.FechaContable)=@Ejercicio
	AND MONTH(c.FechaContable)=@Periodo
	AND c.Empresa=@Empresa
	AND c.Origen IS NULL
	AND c.OrigenID IS NULL
	
IF @Debug=1
	SELECT '#ProdETbl',* FROM #ProdETbl ORDER BY MovID--WHERE id=74367

INSERT INTO #TransferenciasTbl(ID,Mov,MovID,FechaContable,Origen,OrigenID,OrigenTipo,Empresa,EstatusCont,Cuenta,ModuloID,clave,Debe,Haber)
	SELECT c.ID,c.Mov,c.MovID,c.FechaContable,c.Origen,c.OrigenID,c.OrigenTipo,c.Empresa,c.Estatus, cd.Cuenta,m.ID AS 'ModuloID',mt.Clave
		  ,ISNULL(CASE WHEN c.Estatus='CANCELADO' THEN 0 ELSE cd.Debe END,0) AS 'Debe'
		  ,ISNULL(CASE WHEN c.Estatus='CANCELADO' THEN 0 ELSE cd.Haber END,0) AS 'Haber'
	FROM Cont AS c WITH(NOLOCK)
	JOIN ContD AS cd WITH(NOLOCK) ON cd.ID = c.ID AND cd.Cuenta=@Cuenta
	JOIN MovTipo mt ON mt.Mov=c.Origen AND mt.Modulo=c.OrigenTipo AND mt.Clave='INV.T'
	LEFT JOIN Mov m ON c.OrigenTipo=m.Modulo AND c.Empresa=m.Empresa AND c.Origen=m.Mov AND c.OrigenID=m.MovID
	WHERE YEAR(c.FechaContable)=@Ejercicio
	AND MONTH(c.FechaContable)=@Periodo
	AND c.Empresa=@Empresa
	--AND c.ID=73269

IF @Debug=1
	SELECT '#TransferenciasTbl', * FROM #TransferenciasTbl	

INSERT INTO #ProdSerieLoteTBL
SELECT p.ID,p.Mov,p.MovID,p.Empresa,p.FechaContable,p.EstatusCont,p.Cuenta,ISNULL(p.Debe,SUM(ISNULL(s.Cargo,0))),ISNULL(p.Haber,SUM(ISNULL(s.Abono,0)))
	  ,p.Origen,p.OrigenID,p.OrigenTipo,p.EstatusProd,p.ModuloID,p.Articulo,p.ProdSerieLote,p.Cantidad,p.TotalProd
	  ,s.Modulo AS 'ModuloInv'
	  ,s.ModuloID AS 'ModuloIDInv'
	  ,SUM(ISNULL(s.Cargo,0)) AS 'DebeInv'
	  ,SUM(ISNULL(s.Abono,0)) AS 'HaberInv'
FROM #ProdETbl p
LEFT JOIN ProdSerieLoteCosto s WITH(NOLOCK) ON p.ModuloID=s.ModuloID AND p.ProdSerieLote=s.ProdSerieLote AND p.Articulo=s.Articulo AND s.Modulo='PROD'
GROUP BY p.ID,p.Mov,p.MovID,p.Empresa,p.FechaContable,p.EstatusCont,p.Cuenta,p.Debe,p.Haber,p.Origen,p.OrigenID
		,p.OrigenTipo,p.EstatusProd,p.ModuloID,p.Articulo,p.ProdSerieLote,p.Cantidad,p.TotalProd
		,s.Modulo,s.ModuloID


INSERT INTO #ProdSerieLoteTBL
SELECT p.ID,p.Mov,p.MovID,p.Empresa,p.FechaContable,p.EstatusCont,p.Cuenta
	  ,ISNULL(p.Debe,SUM(ISNULL(s.Cargo,0)))
	  ,ISNULL(p.Haber,SUM(ISNULL(s.Abono,0)))
	  ,p.Origen,p.OrigenID,p.OrigenTipo,p.EstatusProd,p.ModuloID,NULL,NULL,NULL,NULL
	  ,'INV',NULL
	  ,SUM(ISNULL(s.Cargo,0)) AS 'DebeInv'
	  ,SUM(ISNULL(s.Abono,0)) AS 'HaberInv'
FROM #ProdETbl p
JOIN ProdSerieLoteCosto s WITH(NOLOCK) ON p.ProdSerieLote=s.ProdSerieLote AND p.Articulo=s.Articulo AND s.Modulo='INV'
WHERE p.ID IS NOT NULL
GROUP BY p.ID,p.Mov,p.MovID,p.Empresa,p.FechaContable,p.EstatusCont,p.Cuenta,p.Debe,p.Haber,p.Origen
		,p.OrigenID,p.OrigenTipo,p.EstatusProd,p.ModuloID


IF @Debug=1
	SELECT '#ProdSerieLoteTBL',* FROM #ProdSerieLoteTBL --WHERE id=74531
	
INSERT INTO #ProdCont
SELECT p.ID, p.Empresa, p.Mov, p.MovID, p.FechaContable, p.EstatusCont, p.Cuenta
	,CASE
		WHEN p.EstatusProd='CONCLUIDO' OR p.EstatusProd IS NULL THEN p.Debe
		ELSE 0 END
	, CASE
		WHEN p.EstatusProd='CONCLUIDO' OR p.EstatusProd IS NULL THEN p.Haber
		ELSE 0 END
	, p.OrigenTipo
 	  ,p.ModuloID, p.Origen, p.OrigenID,p.EstatusProd, p.ModuloINV, p.ModuloIDINV
	  ,SUM(ISNULL(ROUND(p.DebeInv,2),0))
	  ,SUM(ISNULL(ROUND(p.HaberInv,2),0))
FROM #ProdSerieLoteTBL p
GROUP BY p.ID, p.Empresa, p.Mov, p.MovID, p.FechaContable, p.EstatusCont, p.Cuenta, p.Debe, p.Haber, p.OrigenTipo
 	  ,p.ModuloID, p.Origen, p.OrigenID,p.EstatusProd, p.ModuloINV, p.ModuloIDINV
HAVING SUM(ISNULL(ROUND(p.DebeInv,2),0))=p.Debe 
OR SUM(ISNULL(ROUND(p.HaberInv,2),0))=p.Haber
UNION ALL
SELECT t.ID,t.Empresa,t.Mov,t.MovID,t.FechaContable,t.EstatusCont,t.Cuenta,t.Debe,t.Haber,t.OrigenTipo
	  ,t.ModuloID,t.Origen,t.OrigenID,NULL,NULL,NULL,t.Debe,t.Haber
FROM #TransferenciasTbl t

IF @Debug=1
SELECT '#ProdCont', * FROM #ProdCont --WHERE ID=74531

--Se insertan los datos del detalle de los consumos por cada entrada de produccion
INSERT INTO DICOConsumosPP
SELECT @Estacion,i.ID,i.Mov,i.MovID,i.FechaEmision,i.Estatus
	,p.Origen,p.OrigenID,s.Articulo,p.ProdSerieLote,p.Cantidad
	  ,SUM(DISTINCT ISNULL(s.Cargo,0)) AS 'DebeInv'
	  ,SUM(DISTINCT ISNULL(s.Abono,0)) AS 'HaberInv'
FROM #ProdETbl p
JOIN ProdSerieLoteCosto s WITH(NOLOCK) ON p.ProdSerieLote=s.ProdSerieLote AND p.Articulo=s.Articulo AND s.Modulo='INV'
JOIN Inv i ON i.ID=s.ModuloID
GROUP BY i.ID,i.Mov,i.MovID,i.FechaEmision,i.Estatus,p.Origen,p.OrigenID,s.Articulo,p.Articulo,p.ProdSerieLote,p.Cantidad

IF @Debug=1
	SELECT 'DICOConsumosPP', * FROM DICOConsumosPP --WHERE Origen='Entrada´Produccion' and OrigenID='TEP2672'

--Se insertan los datos a mostrar en el tablero principal
INSERT INTO DICOInvContPP
SELECT @Estacion,p.ID,p.Empresa,p.Mov,p.MovID,p.FechaContable,p.EstatusCont,p.Cuenta,p.Debe,p.Haber,p.Origen,p.OrigenID,p.OrigenTipo,p.EstatusProd,p.ModuloID,p.ModuloInv,p.ModuloIDInv,
	   p.DebeInv,p.HaberInv,a.ModuloID AS 'ModuloIDAux',a.Modulo AS 'ModuloAux', a.Fecha AS 'FechaAux', a.Cargo,a.Abono
FROM #ProdCont p
JOIN #AuxU a ON a.ModuloID=ISNULL(p.ModuloIDInv,p.ModuloID) AND a.Modulo=p.ModuloINV

INSERT INTO DICOInvContPP
SELECT @Estacion,p.ID,ISNULL(p.Empresa,@Empresa),p.Mov,p.MovID,p.FechaContable,p.EstatusCont,p.Cuenta,p.Debe,p.Haber,p.Origen,p.OrigenID,p.OrigenTipo,p.EstatusProd,p.ModuloID,p.ModuloInv,p.ModuloIDInv,
	   p.DebeInv,p.HaberInv,a.ModuloID AS 'ModuloIDAux',a.Modulo AS 'ModuloAux', a.Fecha AS 'FechaAux', a.Cargo,a.Abono
FROM #AuxU a 
LEFT JOIN #ProdCont p  ON p.ModuloIDINV=a.ModuloID
WHERE p.ModuloIDINV IS NULL

INSERT INTO DICOInvContPP
SELECT @Estacion,p.ID,ISNULL(p.Empresa,@Empresa),p.Mov,p.MovID,p.FechaContable,p.EstatusCont,p.Cuenta,p.Debe,p.Haber,p.Origen,p.OrigenID,p.OrigenTipo,p.EstatusProd,p.ModuloID,p.ModuloInv,p.ModuloIDInv,
	   p.DebeInv,p.HaberInv,a.ModuloID AS 'ModuloIDAux',a.Modulo AS 'ModuloAux', a.Fecha AS 'FechaAux', a.Cargo,a.Abono
FROM  #ProdCont p
LEFT JOIN #AuxU a  ON p.ModuloIDINV=a.ModuloID
WHERE a.ModuloID IS NULL

IF @Debug=1
	SELECT * FROM DICOInvContPP WHERE Estacion=@Estacion

RETURN
END

--DROP TABLE #ProdETbl
--DROP TABLE #TransferenciasTbl
--DROP TABLE #ProdSerieLoteTBL
--DROP TABLE #ProdCont
--DROP TABLE #AuxU

