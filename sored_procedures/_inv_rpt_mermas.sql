USE db_comercial_final
GO
IF OBJECT_ID('_inv_rpt_mermas') IS NOT NULL
BEGIN
	DROP PROCEDURE _inv_rpt_mermas
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200414
-- Description:	Consulta de mermas
-- =============================================
CREATE PROCEDURE [dbo].[_inv_rpt_mermas]
	@idproveedor AS INT = 0
	, @fecha1 AS DATETIME = NULL
	, @fecha2 AS DATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = [db_comercial].[dbo].[_sys_fnc_fechaNormalizar](@fecha1, 'MES_ANT')
SELECT @fecha2 = [db_comercial].[dbo].[_sys_fnc_fechaNormalizar](@fecha2, 'DIA_COMPLETO')

SELECT
	[articulo_codigo] = a.codigo
	, [articulo_nombre] = a.nombre
	-- Total de traspasos entradas al almacen mermas
	, [cantidad_merma] = ISNULL((
		SELECT
			SUM(itm.cantidad)
		FROM
			ew_inv_transacciones_mov AS itm
			LEFT JOIN ew_inv_almacenes AS alm
				ON alm.idalmacen = itm.idalmacen
			LEFT JOIN ew_inv_transacciones AS it
				ON it.idtran = itm.idtran
		WHERE
			itm.idarticulo = a.idarticulo
			AND itm.tipo = 1
			AND alm.tipo = 3
			AND it.fecha BETWEEN @fecha1 AND @fecha2
	), 0)
	, [costo_promedio] = CONVERT(DECIMAL(18, 6), 0)
	, [costo_total] = ISNULL((
		SELECT
			SUM(itm.costo)
		FROM
			ew_inv_transacciones_mov AS itm
			LEFT JOIN ew_inv_almacenes AS alm
				ON alm.idalmacen = itm.idalmacen
		WHERE
			itm.idarticulo = a.idarticulo
			AND itm.tipo = 1
			AND alm.tipo = 3
	), 0)
	--Total en dinero por artículo de las NC Devolución de 
	--Proveedor hechas en Almacén de Merma.
	, [total_recuperado_compras] = ISNULL((
		SELECT
			SUM(devm.importe)
		FROM
			ew_com_transacciones AS dev
			LEFT JOIN ew_com_transacciones_mov AS devm
				ON devm.idtran = dev.idtran
		WHERE
			dev.cancelado = 0
			AND dev.transaccion = 'CDE2'
			AND dev.fecha BETWEEN @fecha1 AND @fecha2
			AND dev.idproveedor = ISNULL(NULLIF(@idproveedor, 0), dev.idproveedor)
			AND ISNULL(devm.idarticulo, 0) = a.idarticulo
	), 0)
	, [total_recuperado_ventas] = ISNULL((
		SELECT
			SUM(vtm.importe)
		FROM
			ew_ven_transacciones AS ven
			LEFT JOIN ew_ven_transacciones_mov AS vtm
				ON vtm.idtran = ven.idtran
			LEFT JOIN ew_inv_almacenes AS alm
				ON alm.idalmacen = vtm.idalmacen
		WHERE
			ven.cancelado = 0
			AND ven.transaccion IN ('EFA1', 'EFA6', 'EFA3')
			AND ven.fecha BETWEEN @fecha1 AND @fecha2
			AND ISNULL(vtm.idarticulo, 0) = a.idarticulo
			AND alm.tipo = 3
	), 0)
	, [total_recuperado] = CONVERT(DECIMAL(18, 6), 0)
	, [porcentaje_recuperado] = CONVERT(DECIMAL(18, 6), 0)
INTO
	#_tmp_rpt_mermas
FROM
	ew_articulos AS a
WHERE
	a.activo = 1
	AND a.inventariable = 1
	AND a.idtipo = 0

UPDATE #_tmp_rpt_mermas SET
	costo_promedio = costo_total / cantidad_merma
WHERE
	ABS(cantidad_merma) > 0

UPDATE #_tmp_rpt_mermas SET
	total_recuperado = total_recuperado_compras + total_recuperado_ventas

UPDATE #_tmp_rpt_mermas SET
	porcentaje_recuperado = total_recuperado / costo_total
WHERE
	ABS(total_recuperado) > 0

DELETE FROM #_tmp_rpt_mermas
WHERE
	cantidad_merma = 0
	AND costo_promedio = 0
	AND costo_total = 0
	AND total_recuperado = 0
	AND porcentaje_recuperado = 0

SELECT * FROM #_tmp_rpt_mermas

DROP TABLE #_tmp_rpt_mermas
GO