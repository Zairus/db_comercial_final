USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160509
-- Description:	Consumo de productos por temporada
-- =============================================
ALTER PROCEDURE [dbo].[_inv_rpt_consumoPorTemporada]
	@idsucursal AS INT = 0
	,@idalmacen AS INT = 0
	,@idproveedor AS INT = 0
	,@codarticulo1 AS VARCHAR(20) = ''
	,@codarticulo2 AS VARCHAR(20) = ''
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

IF @codarticulo2 = ''
BEGIN
	SELECT @codarticulo2 = MAX(codigo)
	FROM
		ew_articulos
END

SELECT
	[sucursal] = s.nombre
	,[almacen] = alm.nombre
	,[proveedor] = ISNULL(p.nombre, '-Sin Especificar-')
	,[articulo_codigo] = a.codigo
	,[articulo_nombre] = a.nombre
	,[salidas] = ISNULL((
		SELECT SUM(itm.cantidad) 
		FROM 
			ew_inv_transacciones_mov AS itm
			LEFT JOIN ew_inv_transacciones AS it
				ON it.idtran = itm.idtran
		WHERE
			itm.tipo = 2
			AND itm.idarticulo = a.idarticulo
			AND itm.idalmacen = alm.idalmacen
			AND it.fecha BETWEEN @fecha1 AND @fecha2
	), 0)
	,[vendidos] = ISNULL((
		SELECT SUM(
			CASE 
				WHEN vt.transaccion LIKE 'EFA%' THEN
					vtm.cantidad_facturada
				ELSE
					vtm.cantidad_devuelta * -1
			END
		) 
		FROM 
			ew_ven_transacciones_mov AS vtm
			LEFT JOIN ew_ven_transacciones AS vt
				ON vt.idtran = vtm.idtran
		WHERE
			vt.cancelado = 0
			AND (
				vt.transaccion LIKE 'EFA%'
				OR vt.transaccion LIKE 'EDE%'
			)
			AND vtm.idarticulo = a.idarticulo
			AND vt.idalmacen = alm.idalmacen
			AND vt.fecha BETWEEN @fecha1 AND @fecha2
	), 0)
	,[compras] = ISNULL((
		SELECT
			SUM(ctm.cantidad_facturada)
		FROM
			ew_com_transacciones_mov AS ctm
			LEFT JOIN ew_com_transacciones AS ct
				ON ct.idtran = ctm.idtran
		WHERE
			ct.cancelado = 0
			AND ct.transaccion LIKE 'CFA%'
			AND ctm.idarticulo = a.idarticulo
			AND ct.idalmacen = alm.idalmacen
			AND ct.fecha BETWEEN @fecha1 AND @fecha2
	), 0)
	,[ordenado] = ISNULL((
		SELECT
			SUM(com.cantidad_ordenada)
		FROM
			ew_com_ordenes_mov AS com
			LEFT JOIN ew_com_ordenes AS co
				ON co.idtran = com.idtran
		WHERE
			co.cancelado = 0
			AND co.transaccion LIKE 'COR%'
			AND com.idarticulo = a.idarticulo
			AND co.idalmacen = alm.idalmacen
			AND co.fecha BETWEEN @fecha1 AND @fecha2
	), 0)
	,[existencia] = aa.existencia
	,[comprometida] = [dbo].[fn_inv_existenciaComprometida](a.idarticulo, alm.idalmacen)
	,[disponible] = aa.existencia - [dbo].[fn_inv_existenciaComprometida](a.idarticulo, alm.idalmacen)
	,[costo_promedio] = aa.costo_promedio
	,[costo_total] = aa.costo_promedio * aa.existencia
INTO
	#_tmp_consumo
FROM
	ew_articulos AS a
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = (CASE WHEN @idsucursal = 0 THEN s.idsucursal ELSE @idsucursal END)
	LEFT JOIN ew_inv_almacenes AS alm
		ON (CASE WHEN @idalmacen <> 0 THEN alm.idalmacen ELSE alm.idsucursal END) = (CASE WHEN @idalmacen <> 0 THEN @idalmacen ELSE s.idsucursal END)
	LEFT JOIN ew_articulos_sucursales AS [as]
		ON [as].idarticulo = a.idarticulo
		AND [as].idsucursal = s.idsucursal
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = [as].idproveedor
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = a.idarticulo
		AND aa.idalmacen = alm.idalmacen
WHERE
	a.activo = 1
	AND a.idtipo = 0
	AND s.idsucursal = (CASE WHEN @idsucursal = 0 THEN s.idsucursal ELSE @idsucursal END)
	AND alm.idalmacen = (CASE WHEN @idalmacen = 0 THEN alm.idalmacen ELSE @idalmacen END)
	AND [as].idproveedor = (CASE WHEN @idproveedor = 0 THEN [as].idproveedor ELSE @idproveedor END)
	AND a.codigo BETWEEN @codarticulo1 AND @codarticulo2
ORDER BY
	s.idsucursal
	,alm.idalmacen
	,a.codigo

SELECT *
FROM
	#_tmp_consumo
WHERE
	salidas <> 0
	OR vendidos <> 0
	OR compras <> 0
	OR comprometida <> 0

DROP TABLE #_tmp_consumo
GO
