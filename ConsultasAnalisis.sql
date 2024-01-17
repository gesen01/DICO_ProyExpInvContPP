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

CREATE TABLE #MovsINVPP(
	ID                  INT
   ,MovCont             VARCHAR(30)         NULL
   ,MovContID           VARCHAR(20)         NULL
   ,FechaContable       DATETIME            NULL
   ,Debe                FLOAT               NULL
   ,Haber               FLOAT               NULL
   ,OrigenTipo          VARCHAR(5)          NULL
   ,Origen              VARCHAR(30)         NULL
   ,OrigenID            VARCHAR(20)         NULL
   ,Cuenta              VARCHAR(30)         NULL
   ,OModuloID           VARCHAR(20)         NULL
)

--Se obtienen las polizas de cuardo a un rango de fechas contables que contengan en su origen una entrada de produccion
INSERT INTO #PolizasPRODE
	SELECT c.ID,c.Mov,c.MovID,c.FechaContable,c.Origen,c.OrigenID, cd.Cuenta, cd.Debe, cd.Haber
	FROM Cont AS c
	JOIN ContD AS cd ON cd.ID = c.ID AND cd.Cuenta='115-003-000'
	WHERE c.FechaContable BETWEEN '20230101' AND '20230228'
	AND c.Origen='Entrada Produccion'
	AND c.Estatus='CONCLUIDO'
	AND c.ID=67220

INSERT INTO #PolizasPRODE
	SELECT c.ID,c.Mov,c.MovID,c.FechaContable,c.Origen,c.OrigenID, cd.Cuenta, cd.Debe, cd.Haber
	FROM Cont AS c
	JOIN ContD AS cd ON cd.ID = c.ID AND cd.Cuenta='115-003-000'
	WHERE c.FechaContable BETWEEN '20230101' AND '20230228'
	AND c.Origen<>'Entrada Produccion'
	AND c.Estatus='CONCLUIDO'
	AND c.ID=67141

--Obtiene todas las entradas de produccion basado en las polizas seleccionadas
INSERT INTO #MovsPRODE
	SELECT PP.id, p.ID,pd.ProdSerieLote,SUM(pd.Cantidad*pd.Costo),p.Mov,p.MovID,p.FechaEmision
	FROM Prod AS p
	JOIN ProdD AS pd ON pd.ID = p.ID
	JOIN MovTipo AS mt ON mt.Mov = p.Mov AND mt.Clave IN ('PROD.E')
	JOIN #PolizasPRODE AS pp ON pp.Mov = p.Mov AND pp.MovID = p.MovID
	WHERE p.Estatus='CONCLUIDO'
	GROUP BY PP.id, p.ID,pd.ProdSerieLote,p.Mov,p.MovID,p.FechaEmision

--Obtiene los consumos 
INSERT INTO #MovsINVCM
	SELECT i.id, i.mov,i.MovID,i.FechaEmision,i.Almacen,SUM(id.Cantidad*id.Costo),id.ProdSerieLote
	FROM Inv AS i
	JOIN InvD AS id ON id.ID = i.ID
	JOIN MovTipo AS mt ON mt.Mov = i.Mov AND mt.Modulo='INV' AND mt.Clave='INV.CM'
	WHERE i.Estatus='CONCLUIDO' 
	AND id.ProdSerieLote='521'
	GROUP BY i.id, i.mov,i.MovID,i.FechaEmision,i.Almacen,id.ProdSerieLote

INSERT INTO #MovsINVPP
SELECT p.IDPoliza,pd.Poliza,pd.PolizaID,pd.FechaContable,pd.Cargo,pd.Abono,'INV',i.Mov,i.MovID,pd.Cuenta,i.ID
FROM #MovsPRODE p
JOIN #MovsINVCM i ON p.ProdSerieLote=i.ProdSerieLote
JOIN #PolizasPRODE pd ON pd.ID=p.IDPoliza 

INSERT INTO #MovsINVPP
SELECT p.ID,p.Poliza,p.PolizaID,p.FechaContable,p.Cargo,p.Abono
	    ,'INV',i.Mov,i.MovID,p.Cuenta,i.ID
FROM Inv i
JOIN #PolizasPRODE p ON p.Mov=i.Mov AND p.MovID=i.MovID
WHERE i.Estatus='CONCLUIDO'

INSERT INTO #MovsINVPP
SELECT p.IDPoliza,pd.Poliza,pd.PolizaID,pd.FechaContable,pd.Cargo,pd.Abono,'PROD',p.Mov,p.MovID,pd.Cuenta,p.ID
FROM #MovsPRODE p
JOIN #PolizasPRODE pd ON pd.ID=p.IDPoliza 

SELECT '#PolizasPRODE',* FROM #PolizasPRODE	
SELECT '#MovsPRODE',IDPoliza, ID, ProdSerieLote, Mov, MovID,TotalProdE FROM #MovsPRODE 
SELECT '#MovsINVCM', ProdSerieLote, TotalInvCM  FROM #MovsINVCM 
SELECT 'MovsINVPP',* FROM #MovsINVPP

DROP TABLE #PolizasPRODE

DROP TABLE #MovsPRODE

DROP TABLE #MovsINVCM

DROP TABLE #MovsINVPP


--SELECT *
--FROM AuxiliarU AS au
--WHERE au.Grupo='PP'
--AND au.Fecha BETWEEN '20230101' AND '20230228'
--AND au.Rama='INV'


--SELECT i.Origen,i.OrigenID
--FROM Inv AS i
--JOIN MovTipo AS mt ON mt.Mov = i.Mov AND mt.Modulo='INV' AND mt.Clave='INV.SM'


--WHERE p.ID=702

--SELECT *
--FROM MovTipo AS mt
--WHERE mt.Modulo='INV'

--SELECT ROW_NUMBER() OVER (PARTITION BY pslc.Articulo,pslc.ProdSerieLote ORDER BY pslc.ID),pslc.ProdSerieLote,pslc.Articulo,pslc.Modulo,pslc.ModuloID,pslc.Cargo,pslc.Abono
--FROM ProdSerieLoteCosto AS pslc
--WHERE pslc.Modulo='PROD'

--SELECT *
--FROM ProdSerieLoteCosto AS pslc
--WHERE pslc.ProdSerieLote='108'
--AND Articulo='STF00023'

--SELECT *
--FROM Cta AS c
--WHERE c.Descripcion LIKE 'Produccion%'

--SELECT *
--FROM Alm AS a
--WHERE a.Almacen='PP'


