USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20161210
-- Description:	Consulta de ventas de consignacion
-- =============================================
ALTER PROCEDURE _ven_rpt_ventasDeProductosConsignacion
	@idalmacen AS INT
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT
	[sucursal] = s.nombre
	,[almacen] = alm.nombre
	,[movimiento] = o.nombre
	,[folio] = vt.folio
	,[cliente] = c.nombre

	,[codarticulo] = a.codigo
	,[descripcion] = a.nombre

	,[cantidad] = vtm.cantidad_facturada
	,[precio_venta] = vtm.precio_venta
	,[importe] = vtm.importe
	,[impuesto1] = vtm.impuesto1
	,[impuesto2] = vtm.impuesto2
	,[impuesto3] = vtm.impuesto3
	,[impuesto4] = vtm.impuesto4
	,[total] = vtm.total

	,[idtran] = vt.idtran
	,[objidtran] = vt.idtran
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = vtm.idtran
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.idalmacen = vt.idalmacen
	LEFT JOIN ew_inv_almacenes_tipos AS almt
		ON almt.idtipo = alm.tipo
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = alm.idsucursal
	LEFT JOIN objetos AS o
		ON o.codigo = vt.transaccion
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente

	LEFT JOIN ew_articulos As a
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = vtm.idarticulo
		AND aa.idalmacen = vt.idalmacen
WHERE
	vt.cancelado = 0
	AND vt.transaccion LIKE 'EFA%'
	AND almt.propio = 0
	AND vt.idalmacen = (CASE WHEN @idalmacen = 0 THEN vt.idalmacen ELSE @idalmacen END)
	AND vt.fecha BETWEEN @fecha1 AND @fecha2
GO
