USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160211
-- Description:	Consulta de ventas y su utilidad
-- =============================================
ALTER PROCEDURE _ven_rpt_ventasPreciosAnalisis
	@codvendedor AS VARCHAR(20) = ''
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, ISNULL(@fecha2, GETDATE()) + ' 23:59')

SELECT
	[vendedor] = ISNULL(v.nombre, '-Sin especificar-')
	,vt.fecha
	,vt.folio
	,a.codigo
	,a.nombre
	,[precio_lista] = vlm.precio1
	,[precio_minimo] = (
		s.costo_base 
		*(
			1
			+(
				CASE
					WHEN s.margen_minimo > 0 THEN s.margen_minimo
					ELSE (SELECT CONVERT(DECIMAL(18,6), sp.valor) FROM ew_sys_parametros AS sp WHERE sp.codigo = 'LISTAPRECIOS_MARGENMINIMO')
				END
			)
		)
	)
	,[precio_venta] = (vtm.importe / vtm.cantidad_facturada)
	,[precio_diferencial] = (
		(vtm.importe / vtm.cantidad_facturada)
		-(
			s.costo_base 
			*(
				1
				+(
					CASE
						WHEN s.margen_minimo > 0 THEN s.margen_minimo
						ELSE (SELECT CONVERT(DECIMAL(18,6), sp.valor) FROM ew_sys_parametros AS sp WHERE sp.codigo = 'LISTAPRECIOS_MARGENMINIMO')
					END
				)
			)
		)
	)
	,[costo_unitario] = (vtm.costo / vtm.cantidad_facturada)
	,[utilidad] = (
		(vtm.importe / vtm.cantidad_facturada)
		-(vtm.costo / vtm.cantidad_facturada)
	)
	,[margen] = (
		CASE
			WHEN vtm.costo = 0 THEN 1.0
			ELSE (
				(vtm.importe / vtm.cantidad_facturada)
				-(vtm.costo / vtm.cantidad_facturada)
			)
			/(vtm.costo / vtm.cantidad_facturada)
		END
	)

	,vt.idtran
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_ven_vendedores AS v
		ON v.idvendedor = vt.idvendedor
	LEFT JOIN ew_ven_transacciones_mov As vtm
		ON vtm.idtran = vt.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_ven_listaprecios_mov AS vlm
		ON vlm.idlista = vt.idlista
		AND vlm.idarticulo = a.idarticulo
	LEFT JOIN ew_articulos_sucursales AS s
		ON s.idsucursal = vt.idsucursal
		AND s.idarticulo = vtm.idarticulo
WHERE
	vt.cancelado = 0
	AND vt.transaccion LIKE 'EFA%'
	AND vtm.cantidad_facturada > 0
	AND v.codigo = (CASE WHEN @codvendedor = '' THEN v.codigo ELSE @codvendedor END)
	AND vt.fecha BETWEEN @fecha1 AND @fecha2
ORDER BY
	vt.idvendedor
	,vt.fecha
GO
