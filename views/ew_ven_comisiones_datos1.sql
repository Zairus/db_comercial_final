USE db_comercial_final
GO
ALTER VIEW [dbo].[ew_ven_comisiones_datos1]
AS
SELECT
	vt.idtran
	,vtm.idmov
	,vt.transaccion
	,vt.fecha
	,[fecha_ult_pago] = (
		SELECT MAX(ct1.fecha)
		FROM
			ew_cxc_transacciones_mov AS ctm1
			LEFT JOIN ew_cxc_transacciones AS ct1
				ON ct1.idtran = ctm1.idtran
		WHERE
			ct1.cancelado = 0
			AND ct1.tipo <> ct.tipo
			AND ctm1.idtran2 = vt.idtran
	)
	,vt.folio
	,[tipo] = ct.tipo
	,vt.idcliente
	,[idvendedor] = v.idvendedor
	,vtm.idarticulo
	,[precio_unitario] = vtm.importe / vtm.cantidad_facturada
	,vtm.cantidad_facturada
	,vtm.cantidad_devuelta
	,[cantidad] = vtm.cantidad_facturada - vtm.cantidad_devuelta
	,vtm.importe
	,[importe_base] = (vtm.importe / vtm.cantidad_facturada) * (vtm.cantidad_facturada - vtm.cantidad_devuelta)
	,a.comision_nivel
	,[comision] = (
		CASE a.comision_nivel
			WHEN 1 THEN v.comision1
			WHEN 2 THEN v.comision2
			WHEN 3 THEN v.comision3
			ELSE v.comision
		END
	)
	,[pago_proporcion] = (
		ISNULL((
			SELECT SUM(ctm1.subtotal)
			FROM 
				ew_cxc_transacciones_mov AS ctm1
				LEFT JOIN ew_cxc_transacciones AS ct1
					ON ct1.idtran = ctm1.idtran
				LEFT JOIN ew_ban_transacciones AS bt
					ON bt.idtran = ct1.idtran
			WHERE
				bt.idr IS NOT NULL
				AND ct1.tipo <> ct.tipo
				AND ctm1.idtran2 = vt.idtran
		), 0) 
		/ vt.subtotal
	)
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = vtm.idtran
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = vt.idtran
	LEFT JOIN ew_clientes_terminos AS ctr
		ON ctr.idcliente = ct.idcliente
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_ven_vendedores AS v
		ON v.idvendedor = (CASE WHEN vt.idvendedor = 0 THEN ctr.idvendedor ELSE vt.idvendedor END)
WHERE
	vt.cancelado = 0
	AND vt.transaccion LIKE 'EFA%'
GO
