USE db_comercial_final
GO
IF OBJECT_ID('ew_ct_analisis_reembolsos') IS NOT NULL
BEGIN
	DROP VIEW ew_ct_analisis_reembolsos
END
GO
CREATE VIEW [dbo].[ew_ct_analisis_reembolsos]
AS
SELECT
	[cuenta] = (SELECT TOP 1 cit.contabilidad4 FROM ew_cat_impuestos_tasas AS cit WHERE cit.contabilidad3 = pm.cuenta)
	,[cuenta_nombre] = (SELECT TOP 1 cc.nombre FROM ew_cat_impuestos_tasas AS cit LEFT JOIN ew_ct_cuentas AS cc ON cc.cuenta = cit.contabilidad4 WHERE cit.contabilidad3 = pm.cuenta)
	,[ejercicio] = YEAR(bt.fecha)
	,[periodo] = MONTH(bt.fecha)
	,[proveedor_codigo] = p.codigo
	,[proveedor_nombre] = p.nombre
	,[proveedor_rfc] = p.rfc
	,[importe] = pm.cargos
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_ban_transacciones AS bor
		ON bor.idtran = bt.idtran2
	LEFT JOIN ew_ban_transacciones_mov AS borm
		ON borm.idtran = bor.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = borm.idtran2
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = f.idproveedor
	LEFT JOIN ew_ct_poliza_mov AS pm
		ON pm.idtran2 = f.idtran
		AND pm.cuenta IN (
			SELECT cit1.contabilidad3 
			FROM ew_cat_impuestos_tasas AS cit1
		)

WHERE
	bt.transaccion = 'BDA1'
	AND bor.transaccion = 'BOR2'
	AND ISNULL(pm.cargos, 0) > 0

UNION ALL

SELECT
	[cuenta] = pm.cuenta
	,[cuenta_nombre] = cc.nombre
	,[ejercicio] = YEAR(bt.fecha)
	,[periodo] = MONTH(bt.fecha)
	,[proveedor_codigo] = p.codigo
	,[proveedor_nombre] = p.nombre
	,[proveedor_rfc] = p.rfc
	,[importe] = pm.abonos
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_ban_transacciones AS bor
		ON bor.idtran = bt.idtran2
	LEFT JOIN ew_ban_transacciones_mov AS borm
		ON borm.idtran = bor.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = borm.idtran2
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = f.idproveedor
	LEFT JOIN ew_ct_poliza_mov AS pm
		ON pm.idtran2 = f.idtran
		AND pm.cuenta IN (
			SELECT cit1.contabilidad3 
			FROM ew_cat_impuestos_tasas AS cit1
		)
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = pm.cuenta

WHERE
	bt.transaccion = 'BDA1'
	AND bor.transaccion = 'BOR2'
	AND ISNULL(pm.abonos, 0) > 0

UNION ALL

SELECT
	[cuenta] = pm.cuenta
	,[cuenta_nombre] = cc.nombre
	,[ejercicio] = YEAR(bt.fecha)
	,[periodo] = MONTH(bt.fecha)
	,[proveedor_codigo] = p.codigo
	,[proveedor_nombre] = p.nombre
	,[proveedor_rfc] = p.rfc
	,[importe] = pm.cargos * -1
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_ban_transacciones AS bor
		ON bor.idtran = bt.idtran2
	LEFT JOIN ew_ban_transacciones_mov AS borm
		ON borm.idtran = bor.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = borm.idtran2
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = f.idproveedor
	LEFT JOIN ew_ct_poliza_mov AS pm
		ON pm.idtran2 = f.idtran
		AND pm.cuenta IN (
			SELECT cit1.contabilidad3 
			FROM ew_cat_impuestos_tasas AS cit1
		)
	LEFT JOIN ew_ct_cuentas AS cc
		ON cc.cuenta = pm.cuenta

WHERE
	bt.transaccion = 'BDA1'
	AND bor.transaccion = 'BOR2'
	AND ISNULL(pm.cargos, 0) > 0

UNION ALL

SELECT
	[cuenta] = (SELECT TOP 1 cit.contabilidad4 FROM ew_cat_impuestos_tasas AS cit WHERE cit.contabilidad3 = pm.cuenta)
	,[cuenta_nombre] = (SELECT TOP 1 cc.nombre FROM ew_cat_impuestos_tasas AS cit LEFT JOIN ew_ct_cuentas AS cc ON cc.cuenta = cit.contabilidad4 WHERE cit.contabilidad3 = pm.cuenta)
	,[ejercicio] = YEAR(bt.fecha)
	,[periodo] = MONTH(bt.fecha)
	,[proveedor_codigo] = p.codigo
	,[proveedor_nombre] = p.nombre
	,[proveedor_rfc] = p.rfc
	,[importe] = pm.abonos * -1
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_ban_transacciones AS bor
		ON bor.idtran = bt.idtran2
	LEFT JOIN ew_ban_transacciones_mov AS borm
		ON borm.idtran = bor.idtran
	LEFT JOIN ew_cxp_transacciones AS f
		ON f.idtran = borm.idtran2
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = f.idproveedor
	LEFT JOIN ew_ct_poliza_mov AS pm
		ON pm.idtran2 = f.idtran
		AND pm.cuenta IN (
			SELECT cit1.contabilidad3 
			FROM ew_cat_impuestos_tasas AS cit1
		)

WHERE
	bt.transaccion = 'BDA1'
	AND bor.transaccion = 'BOR2'
	AND ISNULL(pm.abonos, 0) > 0
GO
