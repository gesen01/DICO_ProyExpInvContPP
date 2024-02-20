SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpDICOExpPP')
DROP PROCEDURE xpDICOExpPP
GO
--EXEC xpDICOExpPP 999,'TEP2','115-003-000','PP',2023,10,1
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

IF @Cuenta IS NULL
	SELECT @Cuenta=a.Cuenta
	FROM Alm AS a
	WHERE a.Almacen=@Almacen

IF @Almacen IS NULL
	SELECT @Almacen=a.Almacen
	FROM Alm AS a
	WHERE a.Cuenta=@Cuenta

INSERT INTO #AuxU
SELECT a.ModuloID,a.Empresa,a.Modulo,a.Fecha,SUM(ISNULL(a.Cargo,0)) AS 'Cargo', SUM(ISNULL(a.Abono,0)) AS 'Abono'
FROM AuxiliarU a WITH(NOLOCK)
WHERE Ejercicio=@Ejercicio
AND Periodo=@Periodo
AND Grupo=@Almacen
GROUP BY a.ModuloID,a.Empresa,a.Modulo,a.Fecha

IF @Debug=1
	SELECT '#AuxU',* FROM #AuxU

INSERT INTO #ProdETbl(ID,Mov,MovID,FechaContable,Origen,OrigenID,OrigenTipo,EstatusProd,Empresa,EstatusCont,Cuenta,ModuloID,clave,Cantidad,Costo,Articulo,ProdSerieLote,TotalProd,Debe,Haber)
	SELECT c.ID,c.Mov,c.MovID,c.FechaContable,c.Origen,c.OrigenID,c.OrigenTipo,p.Estatus AS 'EstatusProd',c.Empresa,c.Estatus, cd.Cuenta,m.ID AS 'ModuloID',mt.Clave
		   ,pd.Cantidad,pd.costo,pd.Articulo
		   ,pd.ProdSerieLote,pd.Cantidad*pd.Costo AS 'Total'
		  ,ISNULL(CASE WHEN c.Estatus='CANCELADO' THEN 0 ELSE cd.Debe END,0) AS 'Debe'
		  ,ISNULL(CASE WHEN c.Estatus='CANCELADO' THEN 0 ELSE cd.Haber END,0) AS 'Haber'
	FROM Cont AS c WITH(NOLOCK)
	JOIN ContD AS cd WITH(NOLOCK) ON cd.ID = c.ID AND cd.Cuenta=@Cuenta
	JOIN MovTipo mt ON mt.Mov=c.Origen AND mt.Modulo=c.OrigenTipo AND mt.Clave='PROD.E'
	LEFT JOIN Mov m ON c.OrigenTipo=m.Modulo AND c.Empresa=m.Empresa AND c.Origen=m.Mov AND c.OrigenID=m.MovID
	JOIN Prod p ON p.ID=m.ID
	JOIN ProdD pd ON pd.ID=m.ID
	WHERE YEAR(c.FechaContable)=@Ejercicio
	AND MONTH(c.FechaContable)=@Periodo
	AND c.Empresa=@Empresa
	AND pd.Costo IS NOT NULL
	--AND c.ID=73269

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
	SELECT '#ProdETbl', * FROM #ProdETbl WHERE id=73657

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
SELECT p.ID,p.Mov,p.MovID,p.Empresa,p.FechaContable,p.EstatusCont,p.Cuenta,p.Debe,p.Haber,p.Origen,p.OrigenID,p.OrigenTipo,p.EstatusProd,p.ModuloID,p.Articulo,p.ProdSerieLote,p.Cantidad,p.TotalProd
	  ,s.Modulo AS 'ModuloInv'
	  ,s.ModuloID AS 'ModuloIDInv'
	  ,SUM(ISNULL(s.Cargo,0)) AS 'DebeInv'
	  ,SUM(ISNULL(s.Abono,0)) AS 'HaberInv'
FROM #ProdETbl p
LEFT JOIN ProdSerieLoteCosto s WITH(NOLOCK) ON p.ProdSerieLote=s.ProdSerieLote AND p.Articulo=s.Articulo
GROUP BY p.ID,p.Mov,p.MovID,p.Empresa,p.FechaContable,p.EstatusCont,p.Cuenta,p.Debe,p.Haber,p.Origen
		,p.OrigenID,p.OrigenTipo,p.EstatusProd,p.ModuloID,p.Articulo,p.ProdSerieLote,p.Cantidad,p.TotalProd
		,s.Modulo,s.ModuloID

IF @Debug=1
	SELECT '#ProdSerieLoteTBL',* FROM #ProdSerieLoteTBL
	
INSERT INTO #ProdCont
SELECT p.ID, p.Empresa, p.Mov, p.MovID, p.FechaContable, p.EstatusCont, p.Cuenta, p.Debe, p.Haber, p.OrigenTipo
 	  ,p.ModuloID, p.Origen, p.OrigenID,p.EstatusProd, p.ModuloINV, p.ModuloIDINV
	  ,SUM(ISNULL(p.DebeInv,0))
	  ,SUM(ISNULL(p.HaberInv,0))
FROM #ProdSerieLoteTBL p
GROUP BY p.ID, p.Empresa, p.Mov, p.MovID, p.FechaContable, p.EstatusCont, p.Cuenta, p.Debe, p.Haber, p.OrigenTipo
 	  ,p.ModuloID, p.Origen, p.OrigenID,p.EstatusProd, p.ModuloINV, p.ModuloIDINV
HAVING SUM(ISNULL(p.DebeInv,0))=p.Debe 
OR SUM(ISNULL(p.HaberInv,0))=p.Haber
UNION ALL
SELECT t.ID,t.Empresa,t.Mov,t.MovID,t.FechaContable,t.EstatusCont,t.Cuenta,t.Debe,t.Haber,t.OrigenTipo
	  ,t.ModuloID,t.Origen,t.OrigenID,NULL,NULL,NULL,t.Debe,t.Haber
FROM #TransferenciasTbl t

IF @Debug=1
SELECT '#ProdCont', * FROM #ProdCont

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