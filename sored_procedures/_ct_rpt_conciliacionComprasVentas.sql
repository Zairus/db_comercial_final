USE db_comercial_final
GO
IF OBJECT_ID('_ct_rpt_conciliacionComprasVentas') IS NOT NULL
BEGIN
	DROP PROCEDURE _ct_rpt_conciliacionComprasVentas
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200115
-- Description:	Conciliacion de compras y ventas facturadas y no facturadas
-- =============================================
CREATE PROCEDURE [dbo].[_ct_rpt_conciliacionComprasVentas]
	@fecha1 AS DATETIME = NULL
	, @fecha2 AS DATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = [db_comercial].[dbo].[_sys_fnc_fechaNormalizar](@fecha1, 'MES_ANT')
SELECT @fecha2 = [db_comercial].[dbo].[_sys_fnc_fechaNormalizar](@fecha2, 'DIA_COMPLETO')

SELECT
	[idr] = ROW_NUMBER() OVER (ORDER BY a.idtipo, a.codigo)
	, [articulo_codigo] = a.codigo
	, [articulo_nombre] = a.nombre
	, [articulo_tipo] = (
		CASE a.idtipo
			WHEN 1 THEN 'Concepto de Ingreso'
			WHEN 2 THEN 'Concepto de Gasto'
			ELSE 'Producto/Servicio'
		END
	)

	, [ven_factura_cantidad] = ISNULL((
		SELECT SUM(vtm.cantidad_facturada)
		FROM
			ew_ven_transacciones AS vt
			LEFT JOIN ew_ven_transacciones_mov As vtm
				ON vtm.idtran = vt.idtran
		WHERE
			vt.cancelado = 0
			AND vt.transaccion IN ('EFA1', 'EFA6')
			AND vt.fecha BETWEEN @fecha1 AND @fecha2
			AND vtm.idarticulo = a.idarticulo
	), 0)
	, [ven_factura_precio_unitario] = CONVERT(DECIMAL(18, 6), 0)
	, [ven_factura_importe] = ISNULL((
		SELECT SUM(vtm.importe)
		FROM
			ew_ven_transacciones AS vt
			LEFT JOIN ew_ven_transacciones_mov As vtm
				ON vtm.idtran = vt.idtran
		WHERE
			vt.cancelado = 0
			AND vt.transaccion IN ('EFA1', 'EFA6')
			AND vt.fecha BETWEEN @fecha1 AND @fecha2
			AND vtm.idarticulo = a.idarticulo
	), 0)

	, [ven_nota_cantidad] = ISNULL((
		SELECT SUM(vtm.cantidad_facturada)
		FROM
			ew_ven_transacciones AS vt
			LEFT JOIN ew_ven_transacciones_mov As vtm
				ON vtm.idtran = vt.idtran
		WHERE
			vt.cancelado = 0
			AND vt.transaccion IN ('EFA3')
			AND vt.fecha BETWEEN @fecha1 AND @fecha2
			AND vtm.idarticulo = a.idarticulo
	), 0)
	, [ven_nota_precio_unitario] = CONVERT(DECIMAL(18, 6), 0)
	, [ven_nota_importe] = ISNULL((
		SELECT SUM(vtm.importe)
		FROM
			ew_ven_transacciones AS vt
			LEFT JOIN ew_ven_transacciones_mov As vtm
				ON vtm.idtran = vt.idtran
		WHERE
			vt.cancelado = 0
			AND vt.transaccion IN ('EFA3')
			AND vt.fecha BETWEEN @fecha1 AND @fecha2
			AND vtm.idarticulo = a.idarticulo
	), 0)

	, [com_factura_cantidad] = ISNULL((
		SELECT SUM(ctm.cantidad_facturada)
		FROM
			ew_com_transacciones AS ct
			LEFT JOIN ew_com_transacciones_mov AS ctm
				ON ctm.idtran = ct.idtran
		WHERE
			ct.cancelado = 0
			AND ct.transaccion IN ('CFA1', 'CFA2')
			AND ct.fecha BETWEEN @fecha1 AND @fecha2
			AND ctm.idarticulo = a.idarticulo
	), 0)
	, [com_factura_precio_unitario] = CONVERT(DECIMAL(18, 6), 0)
	, [com_factura_importe] = ISNULL((
		SELECT SUM(ctm.importe)
		FROM
			ew_com_transacciones AS ct
			LEFT JOIN ew_com_transacciones_mov AS ctm
				ON ctm.idtran = ct.idtran
		WHERE
			ct.cancelado = 0
			AND ct.transaccion IN ('CFA1', 'CFA2')
			AND ct.fecha BETWEEN @fecha1 AND @fecha2
			AND ctm.idarticulo = a.idarticulo
	), 0)

	, [com_nota_cantidad] = ISNULL((
		SELECT SUM(ctm.cantidad_facturada)
		FROM
			ew_com_transacciones AS ct
			LEFT JOIN ew_com_transacciones_mov AS ctm
				ON ctm.idtran = ct.idtran
		WHERE
			ct.cancelado = 0
			AND ct.transaccion IN ('CDC1')
			AND ct.fecha BETWEEN @fecha1 AND @fecha2
			AND ctm.idarticulo = a.idarticulo
	), 0)
	, [com_nota_precio_unitario] = CONVERT(DECIMAL(18, 6), 0)
	, [com_nota_importe] = ISNULL((
		SELECT SUM(ctm.importe)
		FROM
			ew_com_transacciones AS ct
			LEFT JOIN ew_com_transacciones_mov AS ctm
				ON ctm.idtran = ct.idtran
		WHERE
			ct.cancelado = 0
			AND ct.transaccion IN ('CDC1')
			AND ct.fecha BETWEEN @fecha1 AND @fecha2
			AND ctm.idarticulo = a.idarticulo
	), 0)

	, [gasto_cuenta] = (CASE WHEN a.idtipo > 0 THEN a.contabilidad1 ELSE '' END)
	, [gasto_concpeto] = (CASE WHEN a.idtipo > 0 THEN a.nombre ELSE '' END)

	, [gasto_factura] = ISNULL((
		SELECT SUM(ctm.importe)
		FROM
			ew_cxp_transacciones AS ct
			LEFT JOIN ew_com_transacciones_mov AS ctm
				ON ctm.idtran = ct.idtran
		WHERE
			ct.cancelado = 0
			AND ct.comprobante_fiscal = 1
			AND ct.transaccion IN ('AFA1', 'AFA3')
			AND ct.fecha BETWEEN @fecha1 AND @fecha2
			AND ctm.idarticulo = a.idarticulo
	), 0)
	, [gasto_nota] = ISNULL((
		SELECT SUM(ctm.importe)
		FROM
			ew_cxp_transacciones AS ct
			LEFT JOIN ew_com_transacciones_mov AS ctm
				ON ctm.idtran = ct.idtran
		WHERE
			ct.cancelado = 0
			AND ct.comprobante_fiscal = 0
			AND ct.transaccion IN ('AFA1', 'AFA3')
			AND ct.fecha BETWEEN @fecha1 AND @fecha2
			AND ctm.idarticulo = a.idarticulo
	), 0)
INTO
	#_tmp_conciliacion_cv
FROM
	ew_articulos AS a
WHERE
	a.activo = 1
	AND a.idtipo IN (0, 2)
ORDER BY
	a.idtipo
	, a.codigo

UPDATE #_tmp_conciliacion_cv SET
	ven_factura_precio_unitario = ven_factura_importe / ven_factura_cantidad
WHERE
	ABS(ven_factura_cantidad) <> 0

UPDATE #_tmp_conciliacion_cv SET
	ven_nota_precio_unitario = ven_nota_importe / ven_nota_cantidad
WHERE
	ABS(ven_nota_cantidad) <> 0

UPDATE #_tmp_conciliacion_cv SET
	com_factura_precio_unitario = com_factura_importe / com_factura_cantidad
WHERE
	ABS(com_factura_cantidad) <> 0

UPDATE #_tmp_conciliacion_cv SET
	com_nota_precio_unitario = com_nota_importe / com_nota_cantidad
WHERE
	ABS(com_nota_cantidad) <> 0

SELECT * 
FROM 
	#_tmp_conciliacion_cv 
WHERE
	ven_factura_importe > 0
	OR ven_nota_importe > 0
	OR com_factura_importe > 0
	OR com_nota_importe > 0
	OR gasto_factura > 0
	OR gasto_nota > 0
ORDER BY 
	idr

DROP TABLE #_tmp_conciliacion_cv
GO
