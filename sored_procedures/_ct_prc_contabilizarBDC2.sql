USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20140916
-- Description:	Contabiliza un pago de cliente
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_contabilizarBDC2]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@fecha AS SMALLDATETIME
	,@idtipo AS SMALLINT = 1
	,@idu AS INT
	,@poliza_idtran AS INT
	,@referencia AS VARCHAR(500)
	,@diferencia_cambiaria DECIMAL(18,6)

IF OBJECT_ID('tempdb.._tmp_poliza_mov') IS NOT NULL
BEGIN
	DROP TABLE #_tmp_poliza_mov
END

CREATE TABLE #_tmp_poliza_mov (
	id INT IDENTITY
	,idtran INT NOT NULL DEFAULT(0)
	,idtran2 INT NOT NULL DEFAULT(0)
	,estatus SMALLINT NOT NULL DEFAULT(0)
	,consecutivo SMALLINT NOT NULL DEFAULT(0)
	,idsucursal SMALLINT NOT NULL DEFAULT(0)
	,cuenta VARCHAR(20) NOT NULL DEFAULT('')
	,tipomov SMALLINT NOT NULL DEFAULT(0)
	,referencia VARCHAR(500) NOT NULL DEFAULT('')
	,cargos DECIMAL(18,6) NOT NULL DEFAULT(0)
	,abonos DECIMAL(18,6) NOT NULL DEFAULT(0)
	,importe DECIMAL(18,6) NOT NULL DEFAULT(0)
	,moneda SMALLINT NOT NULL DEFAULT(0)
	,tipocambio DECIMAL(18,6) NOT NULL DEFAULT(0)
	,concepto VARCHAR(5000) NOT NULL DEFAULT('')
)

SELECT
	@fecha = bt.fecha
	,@idu = bt.idu
	,@referencia = bt.transaccion + ' - ' + bt.folio
FROM
	ew_ban_transacciones AS bt
WHERE
	bt.idtran = @idtran

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
	,[idtran2] = @idtran
	,[estatus] = 0
	,[consecutivo] = 1
	,[idsucursal] = bt.idsucursal
	,[cuenta] = bc.contabilidad1
	,[tipomov] = 0
	,[referencia] = (bt.transaccion + ' - ' + bt.folio)
	,[cargos] = (bt.importe * (CASE bt.idmoneda WHEN 0 THEN 1 ELSE bt.tipocambio END))
	,[abonos] = 0
	,[importe] = (bt.importe * (CASE bt.idmoneda WHEN 0 THEN 1 ELSE bt.tipocambio END))
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
	bt.idtran = @idtran

UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @idtran
	,[estatus] = 0
	,[consecutivo] = 2
	,[idsucursal] = ct.idsucursal
	,[cuenta] = pm.cuenta
	,[tipomov] = 1
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = 0
	,[abonos] =SUM((ctm.importe2 / f.total) * pm.cargos) --SUM(((ctm.importe / (CASE WHEN f.idmoneda = ct.idmoneda THEN 1 ELSE ctm.tipocambio END)) / f.total) * pm.cargos)
	,[importe] = SUM((ctm.importe2 / f.total) * pm.cargos)
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cxc_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN ew_ct_poliza_mov AS pm
		ON pm.cuenta LIKE '1130%'
		AND pm.idtran2 = f.idtran
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	ct.idtran = @idtran
	AND pm.cuenta IS NOT NULL
GROUP BY
	ct.idsucursal
	,pm.cuenta
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
	
UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @idtran
	,[estatus] = 0
	,[consecutivo] = 3
	,[idsucursal] = ct.idsucursal
	,[cuenta] = ci.contabilidad
	,[tipomov] = 0
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = SUM((CASE WHEN f.idmoneda = 0 THEN f.impuesto1 ELSE (f.impuesto1 * f.tipocambio) END) * (ctm.importe2 / f.total))
	,[abonos] = 0
	,[importe] = SUM((CASE WHEN f.idmoneda = 0 THEN f.impuesto1 ELSE (f.impuesto1 * f.tipocambio) END) * (ctm.importe2 / f.total))
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cxc_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN ew_cat_impuestos AS ci
		ON ci.idimpuesto = ct.idimpuesto1
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	ct.idtran = @idtran
	AND (
		(SELECT COUNT(*) FROM ew_ct_poliza_mov AS pm WHERE pm.idtran2 = f.idtran) = 0
	)
GROUP BY
	ct.idsucursal
	,ci.contabilidad
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
HAVING
	SUM(CASE WHEN f.idmoneda = 0 THEN f.impuesto1 ELSE (f.impuesto1 * f.tipocambio) END) <> 0

UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @idtran
	,[estatus] = 0
	,[consecutivo] = 4
	,[idsucursal] = ct.idsucursal
	,[cuenta] = pm.cuenta
	,[tipomov] = 0
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = SUM((ctm.importe2 / f.total) * ISNULL(pm.abonos, 0))
	,[abonos] = 0
	,[importe] = SUM((ctm.importe2 / f.total) * ISNULL(pm.abonos, 0))
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cxc_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN ew_ct_poliza_mov AS pm
		ON pm.idtran2 = f.idtran
		AND pm.cuenta IN (SELECT cit.contabilidad1 FROM ew_cat_impuestos_tasas AS cit)
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	ct.idtran = @idtran
	AND pm.cuenta IS NOT NULL
GROUP BY
	ct.idsucursal
	,pm.cuenta
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
HAVING
	SUM((ctm.importe2 / f.total) * ISNULL(pm.abonos, 0)) > 0

UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @idtran
	,[estatus] = 0
	,[consecutivo] = 5
	,[idsucursal] = ct.idsucursal
	,[cuenta] = (SELECT TOP 1 cit.contabilidad2 FROM ew_cat_impuestos_tasas AS cit WHERE cit.contabilidad1 = pm.cuenta)
	,[tipomov] = 0
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = 0
	,[abonos] = SUM((ctm.importe2 / f.total) * ISNULL(pm.abonos, 0))
	,[importe] = SUM((ctm.importe2 / f.total) * ISNULL(pm.abonos, 0))
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cxc_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN ew_ct_poliza_mov AS pm
		ON pm.idtran2 = f.idtran
		AND pm.cuenta IN (SELECT cit.contabilidad1 FROM ew_cat_impuestos_tasas AS cit)
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	ct.idtran = @idtran
	AND pm.cuenta IS NOT NULL
GROUP BY
	ct.idsucursal
	,pm.cuenta
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
HAVING
	SUM((ctm.importe2 / f.total) * ISNULL(pm.abonos, 0)) > 0
	
UNION ALL

SELECT
	[idtran] = @poliza_idtran
	,[idtran2] = @idtran
	,[estatus] = 0
	,[consecutivo] = 6
	,[idsucursal] = ct.idsucursal
	,[cuenta] = '1130001000'
	,[tipomov] = 1
	,[referencia] = (ct.transaccion + ' - ' + ct.folio)
	,[cargos] = 0
	,[abonos] = SUM(ctm.importe2 * (CASE WHEN f.idmoneda = 0 THEN 1.00 ELSE f.tipocambio END))
	,[importe] = SUM(ctm.importe2 * (CASE WHEN f.idmoneda = 0 THEN 1.00 ELSE f.tipocambio END))
	,[moneda] = 0
	,[tipocambio] = 1
	,[concepto] = (o.nombre + ' - ' + ct.folio)
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_cxc_transacciones_mov AS ctm
		ON ctm.idtran = ct.idtran
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
WHERE
	(SELECT COUNT(*) FROM ew_ct_poliza_mov AS pm WHERE pm.idtran2 = ctm.idtran2) = 0
	AND ct.idtran = @idtran
GROUP BY
	ct.idsucursal
	,(ct.transaccion + ' - ' + ct.folio)
	,(o.nombre + ' - ' + ct.folio)
HAVING
	ISNULL(SUM(ctm.importe2 * (CASE WHEN f.idmoneda = 0 THEN 1.00 ELSE f.tipocambio END)),0) <> 0

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
	,[idtran2] = @idtran
	,[estatus] = 0
	,[consecutivo] = 7
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
	bt.idtran = @idtran
	AND ABS(@diferencia_cambiaria) > 0.01

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

EXEC _ct_prc_polizaValidarDualidad @idtran
GO
