SELECT * INTO #AuxU FROM AuxiliarU WHERE 
Fecha BETWEEN '01/07/2023' AND '31/07/2023'
AND Grupo='PP' order by id asc

--SELECT * FROM Axu

SELECT c.ID, c.Empresa, c.Mov, c.MovID, c.FechaContable, c.Estatus, d.Cuenta,d.Renglon, 'Debe'=SUM(ISNULL(CASE WHEN c.Estatus='CANCELADO' THEN 0 ELSE d.Debe END,0)),'Haber'=SUM(ISNULL(CASE WHEN c.Estatus='CANCELADO' THEN 0 ELSE d.Haber END,0)), c.OrigenTipo,c.Origen, c.OrigenID
INTO #CONT 
FROM Cont c 
JOIN ContD d On c.ID=d.ID 
WHERE c.FechaContable BETWEEN '01/07/2023' AND '31/07/2023'
AND d.Cuenta='115-003-000'-- and isnull(Debe,0)>0 
--AND c.ID=73223
GROUP BY  c.ID, c.Empresa, c.Mov, c.MovID, c.FechaContable, c.Estatus, d.Cuenta, d.Debe, d.Haber, c.OrigenTipo,c.Origen, c.OrigenID,d.Renglon
 --order by c.id asc

 SELECT '#Cont', * FROM #CONT WHERE ID=74371


 SELECT c.*, m.Clave, 'IDModulo'=M1.ID 
 into #CONT2
 FROM #Cont c 
 JOIN MovTipo  m On c.Origen=m.Mov AND c.OrigenTipo = m.Modulo 
 left join Mov M1 oN c.OrigenTipo = M1.modulo AND c.Empresa=m1.Empresa AND c.Origen=m1.Mov AND c.OrigenID=m1.MovID
-- WHERE Clave='PROD.E'

SELECT '#Cont2',* FROM #CONT2 WHERE ID=74371

 SELECT c.*
 INTO #CONTPROD
 FROM #CONT2 c 
 WHERE Clave='PROD.E'

 SELECT '#ContProd',* FROM #CONTPROD WHERE ID=74371


 SELECT c.*, 'MovProd'= p.Mov, 'MovIDProd'=p.MovID, 'EstatusProd'= p.Estatus, d.Articulo, d.ProdSerieLote, d.Cantidad, d.Costo, 'Total'= d.Cantidad * d.Costo
 INTO #PROD 
 FROM #CONTPROD c 
 JOIN Prod p On c.IDModulo=p.ID AND c.Origen=p.Mov AND c.OrigenID=p.MovID
 JOIN ProdD d On p.ID = d.ID 

 SELECT '#PROD',* FROM #PROD where ID=74371

 --SELECT ID, Empresa, Mov, MovID, FechaContable, Estatus, Cuenta, Debe, Haber, OrigenTipo, IDModulo,Origen, OrigenID, 'Estatus'=NULL,OrigenTipo , IDModulo, Debe, Haber FROm #CONT2  WHERE Clave<>'PROD.E'

 SELECt DISTINCT p.ID, p.Empresa, p.Mov, p.MovID, p.FechaContable, p.Estatus, p.Cuenta, p.Debe, p.Haber, p.OrigenTipo, p.IDmodulo, p.MovProd, p.MovIDProd, p.EstatusProd, p.Articulo, p.ProdSerieLote, p.Costo, P.Total , 'ModuloINV'= pslc.Modulo, 'ModuloIDINV'= pslc.ModuloID, 'DebeInv'=SUM(ISNULL(Abono,0)), 'HaberInv'=SUM(ISNULL(Cargo,0))
 INTO #ProdInv 
  FROM #PROD p LEFT JOIN ProdSerieLoteCosto pslc ON p.Articulo=pslc.Articulo AND p.ProdSerieLote = pslc.ProdSerieLote 
 WHERE 1=1 -- pslc.Modulo<>'PROD'
 GROUP BY  p.ID, p.Empresa, p.Mov, p.MovID, p.FechaContable, p.Estatus, p.Cuenta, p.Debe, p.Haber, p.OrigenTipo, p.IDmodulo, p.MovProd, p.MovIDProd, p.EstatusProd, p.Articulo, p.ProdSerieLote, p.Costo, P.Total , pslc.Modulo, pslc.ModuloID

 SELECT '#ProdInv', * FROM #ProdInv WHERE ID=74371

 SELECT DISTINCT p.ID, p.Empresa, p.Mov, p.MovID, p.FechaContable, p.Estatus, p.Cuenta, p.Debe, p.Haber, p.OrigenTipo, p.IDmodulo, p.MovProd, p.MovIDProd, p.EstatusProd, p.ModuloINV, p.ModuloIDINV,'DebeInv'=SUM(ISNULL(DebeInv,0)), 'HaberInv'=SUM(ISNULL(HaberInv,0))
 into #ProdInv2
  FROM #ProdInv p --LEFT JOIN INvD d ON p.ModuloIDINV = d.ID AND p.ProdSerieLote = d.ProdSerieLote AND p.Articulo=d.Producto
  GROUP BY p.ID, p.Empresa, p.Mov, p.MovID, p.FechaContable, p.Estatus, p.Cuenta, p.Debe, p.Haber, p.OrigenTipo, p.IDmodulo, p.MovProd, p.MovIDProd, p.EstatusProd,  p.ModuloINV, p.ModuloIDINV

  SELECT '#ProdInv2', * FROM #ProdInv WHERE ID=74371

  SELECT * FROM
  #ProdInv2
	WHERE ROUND(Debe,2)=ROUND(DebeInv,2) OR ROUND(Haber,2)=ROUND(HaberInv,2)
UNION ALL
 SELECT ID, Empresa, Mov, MovID, FechaContable, Estatus, Cuenta, Debe, Haber, OrigenTipo, IDModulo,Origen, OrigenID, 'Estatus'=NULL,OrigenTipo , IDModulo, Debe, Haber FROm #CONT2  WHERE Clave<>'PROD.E'

 SELECT  Empresa, mODULO, ModuloId, Fecha, 'Cargo'=SUM(ISNULL(Cargo,0)), 'Abono'=SUM(ISNULL(Abono,0))  FROM #AuxU 
  GROUP BY Empresa, mODULO, ModuloId, Fecha

 DROP TABLE #CONT
  DROP TABLE #CONT2 
    DROP TABLE #PROD 
	DROP TABLE #CONTPROD
	DROP TABLE #AuxU
	DROP TABLE #ProdInv2
	DROp TABLE #ProdInv