USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20140806
-- Description:	Contabiliza una orden de pago aplicada en bancos
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_contabilizarDDA3]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@fecha AS SMALLDATETIME
	,@idtipo AS SMALLINT = 2
	,@idu AS INT
	,@poliza_idtran AS INT
	,@referencia AS VARCHAR(500)
	,@diferencia_cambiaria DECIMAL(18,6)

DECLARE
	@bancos_idtran AS INT

IF OBJECT_ID('tempdb.._tmp_poliza_mov') IS NOT NULL
BEGIN
	DROP TABLE #_tmp_poliza_mov
END

CREATE TABLE #_tmp_poliza_mov (
	id INT IDENTITY
	,idtran INT NOT NULL DEFAULT 0
	,idtran2 INT NOT NULL DEFAULT 0
	,estatus SMALLINT NOT NULL DEFAULT 0
	,consecutivo SMALLINT NOT NULL DEFAULT 0
	,idsucursal SMALLINT NOT NULL DEFAULT 0
	,cuenta VARCHAR(20) NOT NULL DEFAULT ''
	,tipomov SMALLINT NOT NULL DEFAULT 0
	,referencia VARCHAR(500) NOT NULL DEFAULT ''
	,cargos DECIMAL(18,6) NOT NULL DEFAULT 0
	,abonos DECIMAL(18,6) NOT NULL DEFAULT 0
	,importe DECIMAL(18,6) NOT NULL DEFAULT 0
	,moneda SMALLINT NOT NULL DEFAULT 0
	,tipocambio DECIMAL(18,6) NOT NULL DEFAULT 0
	,concepto VARCHAR(5000) NOT NULL DEFAULT ''
)

SELECT
	@bancos_idtran = idtran
FROM 
	ew_ban_transacciones 
WHERE idtran2 = @idtran

SELECT
	@fecha = bt.fecha
	,@idu = bt.idu
	,@referencia = bt.transaccion + ' - ' + bt.folio
FROM
	ew_ban_transacciones AS bt
WHERE
	bt.idtran = @bancos_idtran

EXEC _ct_prc_polizaCrear @idtran, @fecha, @idtipo, @idu, @poliza_idtran OUTPUT, @referencia

INSERT INTO #_tmp_poliza_mov (
	idtran
	,idtran2
	,estatus
	,consecutivo
	,idsucursal
	,cuenta
	,tipomov
	,referencia
	,cargos
	,abonos
	,importe
	,moneda
	,tipocambio
	,concepto
)

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @bancos_idtran
	,[estatus] = 0
	,[consecutivo] = 1
	,[idsucursal] = ct.idsucursal
	,[cuenta] = p.contabilidad
	,[tipomov] = 0
	,[referencia] = @referencia
	,[cargos] = (ct.total - ISNULL(SUM(ctm.importe), 0)) * (CASE WHEN ct.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END)
	,[abonos] = 0
	,[importe] = (ct.total - ISNULL(SUM(ctm.importe), 0)) * (CASE WHEN ct.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END)
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxp_transacciones AS ct
	LEFT JOIN ew_cxp_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = ct.idproveedor
	
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	ct.idtran = @idtran
GROUP BY
	ct.idsucursal
	,p.contabilidad
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
	,ct.idmoneda
	,ct.fecha
	,ct.total
HAVING
	(ct.total - ISNULL(SUM(ctm.importe), 0)) * (CASE WHEN ct.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END) <> 0

UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @bancos_idtran
	,[estatus] = 0
	,[consecutivo] = 2
	,[idsucursal] = pm.idsucursal
	,[cuenta] = pm.cuenta
	,[tipomov] = 0
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = ISNULL(SUM(pm.abonos * (ctm.importe2 / f.total)), 0)
	,[abonos] = 0
	,[importe] = ISNULL(SUM(pm.abonos * (ctm.importe2 / f.total)), 0)
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxp_transacciones_mov AS ctm
	LEFT JOIN ew_cxp_transacciones AS ct
		ON ct.idtran = ctm.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = ctm.idtran2
	
	LEFT JOIN ew_ct_poliza_mov AS pm
		ON pm.idtran2 = f.idtran
		AND pm.tipomov = 1
		AND LEFT(ISNULL(pm.cuenta, ''), 3) IN ('210','211')

	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	pm.cuenta IS NOT NULL
	AND ctm.idtran = @idtran
GROUP BY
	pm.idsucursal
	,pm.cuenta
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
HAVING
	ISNULL(SUM(pm.abonos * (ctm.importe2 / f.total)), 0) <> 0

UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @bancos_idtran
	,[estatus] = 0
	,[consecutivo] = 3
	,[idsucursal] = ct.idsucursal
	,[cuenta] = p.contabilidad
	,[tipomov] = 0
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = SUM(ctm.importe2 * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE f.tipocambio END))
	,[abonos] = 0
	,[importe] = SUM(ctm.importe2 * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE f.tipocambio END))
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxp_transacciones_mov AS ctm
	LEFT JOIN ew_cxp_transacciones AS ct
		ON ct.idtran = ctm.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = ct.idproveedor
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	ctm.idtran = @idtran
	AND (SELECT COUNT(*) FROM ew_ct_poliza_mov AS pm WHERE pm.idtran2 = f.idtran) = 0
GROUP BY
	ct.idsucursal
	,p.contabilidad
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)

UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @bancos_idtran
	,[estatus] = 0
	,[consecutivo] = 4
	,[idsucursal] = bt.idsucursal
	,[cuenta] = bc.contabilidad1
	,[tipomov] = 0
	,[referencia] = (bt.transaccion + ' - ' + bt.folio)
	,[cargos] = 0
	,[abonos] = (CASE WHEN bc.idmoneda = 0 THEN bt.importe ELSE bt.importe * ISNULL(dbo.fn_ban_obtenerTC(bc.idmoneda, bt.fecha), bm.tipocambio3) END)
	,[importe] = (CASE WHEN bc.idmoneda = 0 THEN bt.importe ELSE bt.importe * ISNULL(dbo.fn_ban_obtenerTC(bc.idmoneda, bt.fecha), bm.tipocambio3) END)
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + bt.folio)
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = bt.idcuenta
	LEFT JOIN ew_ban_monedas AS bm
		ON bm.idmoneda = bc.idmoneda

	LEFT JOIN objetos AS o
		ON o.codigo = bt.transaccion
WHERE
	bt.idtran = @bancos_idtran
	
INSERT INTO #_tmp_poliza_mov (
	idtran
	,idtran2
	,estatus
	,consecutivo
	,idsucursal
	,cuenta
	,tipomov
	,referencia
	,cargos
	,abonos
	,importe
	,moneda
	,tipocambio
	,concepto
)

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @bancos_idtran
	,[estatus] = 0
	,[consecutivo] = 5
	,[idsucursal] = ct.idsucursal
	,[cuenta] = ci.contabilidad4
	,[tipomov] = 0
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = (ct.impuesto1 - SUM(ctm.importe - ctm.impuesto2 - ((ctm.importe - ctm.impuesto2) / (1 + (ct.impuesto1 / ct.subtotal))))) * (CASE WHEN ct.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END)
	,[abonos] = 0
	,[importe] = (ct.impuesto1 - SUM(ctm.importe - ctm.impuesto2 - ((ctm.importe - ctm.impuesto2) / (1 + (ct.impuesto1 / ct.subtotal))))) * (CASE WHEN ct.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END)
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxp_transacciones AS ct
	LEFT JOIN ew_cxp_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = ct.idimpuesto1
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	ct.idtran = @idtran
GROUP BY
	ct.idsucursal
	,ci.contabilidad4
	,ct.idmoneda
	,ct.fecha
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
	,ct.impuesto1
HAVING
	ABS(ct.impuesto1 - SUM(ctm.importe - ctm.impuesto2 - ((ctm.importe - ctm.impuesto2) / (1 + (ct.impuesto1 / ct.subtotal))))) * (CASE WHEN ct.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END) > 0.01

UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @bancos_idtran
	,[estatus] = 0
	,[consecutivo] = 6
	,[idsucursal] = f.idsucursal
	,[cuenta] = (SELECT TOP 1 cit.contabilidad4 FROM ew_cat_impuestos_tasas AS cit WHERE cit.contabilidad3 = pm.cuenta)
	,[tipomov] = 0
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = SUM((pm.cargos * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END)) * (ctm.importe / f.total))
	,[abonos] = 0
	,[importe] = SUM((pm.cargos * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END)) * (ctm.importe / f.total))
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxp_transacciones_mov AS ctm
	LEFT JOIN ew_cxp_transacciones AS ct
		ON ct.idtran = ctm.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN ew_ct_poliza_mov AS pm
		ON pm.idtran2 = f.idtran
		AND pm.cuenta IN (SELECT cit.contabilidad3 FROM ew_cat_impuestos_tasas AS cit)
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	ctm.idtran = @idtran
GROUP BY
	f.idsucursal
	,pm.cuenta
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
HAVING
	SUM((pm.cargos * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END)) * (ctm.importe / f.total)) <> 0

UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @bancos_idtran
	,[estatus] = 0
	,[consecutivo] = 6
	,[idsucursal] = ct.idsucursal
	,[cuenta] = ci.contabilidad4
	,[tipomov] = 0
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = SUM(ctm.impuesto1 * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE f.tipocambio END))
	,[abonos] = 0
	,[importe] = SUM(ctm.impuesto1 * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE f.tipocambio END))
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxp_transacciones_mov AS ctm
	LEFT JOIN ew_cxp_transacciones AS ct
		ON ct.idtran = ctm.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = f.idimpuesto1
WHERE
	ctm.idtran = @idtran
	AND (SELECT COUNT(*) FROM ew_ct_poliza_mov AS pm WHERE pm.idtran2 = f.idtran) = 0
GROUP BY
	ct.idsucursal
	,ci.contabilidad4
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
HAVING
	ABS(SUM(ctm.impuesto1 * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE f.tipocambio END))) > 0.01

UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @bancos_idtran
	,[estatus] = 0
	,[consecutivo] = 7
	,[idsucursal] = ct.idsucursal
	,[cuenta] = ci.contabilidad3
	,[tipomov] = 1
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = 0
	,[abonos] = (ct.impuesto1 - SUM(ctm.importe - ctm.impuesto2 - ((ctm.importe - ctm.impuesto2) / (1 + (ct.impuesto1 / ct.subtotal))))) * (CASE WHEN ct.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END)
	,[importe] = (ct.impuesto1 - SUM(ctm.importe - ctm.impuesto2 - ((ctm.importe - ctm.impuesto2) / (1 + (ct.impuesto1 / ct.subtotal))))) * (CASE WHEN ct.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END)
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxp_transacciones AS ct
	LEFT JOIN ew_cxp_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = ct.idimpuesto1
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	ct.idtran = @idtran
GROUP BY
	ct.idsucursal
	,ci.contabilidad3
	,ct.idmoneda
	,ct.fecha
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
	,ct.impuesto1
HAVING
	ABS(ct.impuesto1 - SUM(ctm.importe - ctm.impuesto2 - ((ctm.importe - ctm.impuesto2) / (1 + (ct.impuesto1 / ct.subtotal))))) * (CASE WHEN ct.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END) > 0.01

UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @bancos_idtran
	,[estatus] = 0
	,[consecutivo] = 8
	,[idsucursal] = f.idsucursal
	,[cuenta] = pm.cuenta
	,[tipomov] = 1
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = 0
	,[abonos] = SUM((pm.cargos * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END)) * (ctm.importe / f.total))
	,[importe] = SUM((pm.cargos * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END)) * (ctm.importe / f.total))
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxp_transacciones_mov AS ctm
	LEFT JOIN ew_cxp_transacciones AS ct
		ON ct.idtran = ctm.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN ew_ct_poliza_mov AS pm
		ON pm.idtran2 = f.idtran
		AND pm.cuenta IN (SELECT cit.contabilidad3 FROM ew_cat_impuestos_tasas AS cit)
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	ctm.idtran = @idtran
GROUP BY
	f.idsucursal
	,pm.cuenta
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
HAVING
	SUM((pm.cargos * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE dbo.fn_ban_obtenerTC(ct.idmoneda, ct.fecha) END)) * (ctm.importe / f.total)) <> 0

UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @bancos_idtran
	,[estatus] = 0
	,[consecutivo] = 8
	,[idsucursal] = ct.idsucursal
	,[cuenta] = ci.contabilidad3
	,[tipomov] = 1
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = 0
	,[abonos] = SUM(ctm.impuesto1 * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE f.tipocambio END))
	,[importe] = SUM(ctm.impuesto1 * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE f.tipocambio END))
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxp_transacciones_mov AS ctm
	LEFT JOIN ew_cxp_transacciones AS ct
		ON ct.idtran = ctm.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = f.idimpuesto1
WHERE
	ctm.idtran = @idtran
	AND (SELECT COUNT(*) FROM ew_ct_poliza_mov AS pm WHERE pm.idtran2 = f.idtran) = 0
GROUP BY
	ct.idsucursal
	,ci.contabilidad3
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
HAVING
	ABS(SUM(ctm.impuesto1 * (CASE WHEN f.idmoneda = 0 THEN 1 ELSE f.tipocambio END))) > 0.01

SELECT @diferencia_cambiaria = SUM(cargos - abonos)
FROM
	#_tmp_poliza_mov

SELECT @diferencia_cambiaria = ISNULL(@diferencia_cambiaria, 0)

INSERT INTO #_tmp_poliza_mov (
	idtran
	,idtran2
	,estatus
	,consecutivo
	,idsucursal
	,cuenta
	,tipomov
	,referencia
	,cargos
	,abonos
	,importe
	,moneda
	,tipocambio
	,concepto
)

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @bancos_idtran
	,[estatus] = 0
	,[consecutivo] = 10
	,[idsucursal] = bt.idsucursal
	,[cuenta] = (CASE WHEN @diferencia_cambiaria < 0 THEN '5400006003' ELSE '4300003000' END)
	,[tipomov] = (CASE WHEN @diferencia_cambiaria < 0 THEN 0 ELSE 1 END)
	,[referencia] = (bt.transaccion + ' - ' + bt.folio)
	,[cargos] = (CASE WHEN @diferencia_cambiaria < 0 THEN ABS(@diferencia_cambiaria) ELSE 0 END)
	,[abonos] = (CASE WHEN @diferencia_cambiaria > 0 THEN ABS(@diferencia_cambiaria) ELSE 0 END)
	,[importe] = ABS(@diferencia_cambiaria)
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + bt.folio)
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_ban_cuentas AS bc
		ON bc.idcuenta = bt.idcuenta

	LEFT JOIN objetos AS o
		ON o.codigo = bt.transaccion
WHERE
	bt.idtran = @bancos_idtran
	AND ABS(@diferencia_cambiaria) > 0.001
		
INSERT INTO ew_ct_poliza_mov (
	[idtran]
	,[idtran2]
	,[estatus]
	,[consecutivo]
	,[idsucursal]
	,[cuenta]
	,[tipomov]
	,[referencia]
	,[cargos]
	,[abonos]
	,[importe]
	,[moneda]
	,[tipocambio]
	,[concepto]
)
SELECT
	[idtran]
	,[idtran2]
	,[estatus]
	,[consecutivo]
	,[idsucursal]
	,[cuenta]
	,[tipomov]
	,[referencia]
	,[cargos]
	,[abonos]
	,[importe]
	,[moneda]
	,[tipocambio]
	,[concepto]
FROM
	#_tmp_poliza_mov
	
DROP TABLE #_tmp_poliza_mov

EXEC _ct_prc_polizaValidarDualidad @poliza_idtran
GO