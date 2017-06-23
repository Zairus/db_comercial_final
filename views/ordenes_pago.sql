USE db_comercial_final
GO
ALTER VIEW [dbo].[ordenes_pago]
AS
SELECT
	[idtran2] = a.idtran
	, [idmov2] = a.idmov
	, [transaccion] = a.transaccion
	, [fecha] = a.fecha
	, [idsucursal] = a.idsucursal
	, [folio] = a.folio
	, [referencia] = a.referencia
	, [idconcepto] = a.idconcepto
	, [concepto_nombre] = c.nombre
	, [concepto_cuenta] = c.contabilidad
	, [Expr1] = a.referencia
	, [idrelacion] = 3
	, [identidad] = a.idproveedor
	, [entidad_codigo] = p.codigo
	, [entidad_nombre] = p.nombre
	, [entidad_registro] = p.rfc
	, [entidad_cuenta] = p.contabilidad
	, [idmoneda] = a.idmoneda
	, [importe] = a.total
	, [idimpuesto_monto] = (a.impuesto1 + a.impuesto2 - a.impuesto1_ret - a.impuesto2_ret)
	, [idimpuesto] = a.idimpuesto1
	, [impuesto_tasa] = i.valor
	, [impuesto_cuenta] = i.contabilidad
	, [impuesto_cuenta2] = i.contabilidad2
FROM
	dbo.ew_cxp_transacciones AS a
	LEFT OUTER JOIN dbo.ew_proveedores AS p 
		ON p.idproveedor = a.idproveedor 
	LEFT OUTER JOIN dbo.conceptos AS c 
		ON c.idconcepto = a.idconcepto 
	LEFT OUTER JOIN dbo.ew_cat_impuestos AS i 
		ON i.idimpuesto = a.idimpuesto1
WHERE
	a.tipo = 2
	AND a.transaccion IN ('DDA3')

UNION ALL

SELECT
	[idtran2] = bt.idtran
	, [dimov2] = bt.idmov
	, [transaccion] = bt.transaccion
	, [fecha] = bt.fecha
	, [idsucursal] = bt.idsucursal
	, [folio] = bt.folio
	, [referencia] = bt.referencia
	, [idconcepto] = a.idarticulo
	, [concepto_nombre] = a.nombre
	, [concepto_cuenta] = ''

	, [Expr1] = bt.referencia
	, [idrelacion] = 7
	, [identidad] = bt.idu
	, [entidad_codigo] = u.usuario
	, [entidad_nombre] = u.nombre
	, [entidad_registro] = ''
	, [entidad_cuenta] = ''
	, [idmoneda] = bt.idmoneda
	, [importe] = bt.importe
	, [idimpuesto_monto] = ISNULL((
		SELECT
			SUM(ct.impuesto1)
		FROM 
			ew_ban_transacciones_mov AS btm
			LEFT JOIN ew_cxp_transacciones AS ct
				ON ct.idtran = btm.idtran2
		WHERE 
			btm.idtran = bt.idtran
	), 0)
	, [idimpuesto] = 0
	, [impuesto_tasa] = 0
	, [impuesto_cuenta] = ''
	, [impuesto_cuenta2] = ''
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_articulos AS a
		ON a.codigo = 'CXPP'
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = bt.idu
WHERE
	bt.transaccion IN ('BOR2')
	AND bt.idtran NOT IN (
		SELECT bt.idtran2
		FROM
			ew_ban_transacciones AS bt
		WHERE
			bt.cancelado = 0
			AND bt.transaccion = 'BDA1'
	)

UNION ALL

SELECT
	[idtran2] = a.idtran
	, [idmov2] = a.idmov
	, [transaccion] = a.transaccion
	, [fecha] = a.fecha
	, [idsucursal] = a.idsucursal
	, [folio] = a.folio
	, [referencia] = a.referencia
	, [idconcepto] = a.idconcepto
	, [concepto_nombre] = c.nombre
	, [concepto_cuenta] = c.contabilidad
	, [Expr1] = a.referencia
	, [idrelacion] = 4
	, [identidad] = a.idcliente
	, [entidad_codigo] = p.codigo
	, [entidad_nombre] = p.nombre
	, [entidad_registro] = pf.rfc
	, [entidad_cuenta] = pf.contabilidad
	, [idmoneda] = a.idmoneda
	, [importe] = a.total
	, [idimpuesto_monto] = a.impuesto1
	, [idimpuesto] = a.idimpuesto1
	, [impuesto_tasa] = i.valor
	, [impuesto_cuenta] = i.contabilidad
	, [impuesto_cuenta2] = i.contabilidad2
FROM
	dbo.ew_cxc_transacciones AS a 
	LEFT OUTER JOIN dbo.ew_clientes p 
		ON p.idcliente = a.idcliente 
	LEFT OUTER JOIN dbo.ew_clientes_facturacion pf 
		ON pf.idcliente = a.idcliente 
		AND pf.idfacturacion = a.idfacturacion 
	LEFT OUTER JOIN dbo.conceptos AS c 
		ON c.idconcepto = a.idconcepto 
	LEFT OUTER JOIN dbo.ew_cat_impuestos AS i 
		ON i.idimpuesto = a.idimpuesto1
WHERE
	a.tipo = 1
	AND a.transaccion IN ('FOR1')

GO
