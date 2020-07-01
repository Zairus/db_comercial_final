USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_productosMasVendidos') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_productosMasVendidos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200413
-- Description:	Productos mas vendidos
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_productosMasVendidos]
	@idsucursal AS INT = 0
	, @idalmacen AS INT = 0
	, @idcliente AS INT = 0
	, @fecha1 AS DATETIME = NULL
	, @fecha2 AS DATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = [db_comercial].[dbo].[_sys_fnc_fechaNormalizar](@fecha1, 'SEM_ANT')
SELECT @fecha2 = [db_comercial].[dbo].[_sys_fnc_fechaNormalizar](@fecha2, 'DIA_COMPLETO')

SELECT
	[articulo_codigo] = a.codigo
	, [articulo_nombre] = a.nombre
	, [unidad] = cum.nombre
	, [existencia] = ISNULL(aa.existencia, 0)
	, [cantidad] = SUM(vtm.cantidad_facturada)
	, [importe] = SUM(vtm.importe)
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_ven_transacciones_mov AS vtm
		ON vtm.idtran = vt.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_cat_unidadesMedida AS cum
		ON cum.idum = a.idum_venta
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = vt.idsucursal
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.idalmacen = vtm.idalmacen
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = vtm.idarticulo
		AND aa.idalmacen = vtm.idalmacen
WHERE
	vt.cancelado = 0
	AND vt.transaccion IN ('EFA1', 'EFA3', 'EFA6')
	AND vt.idsucursal = ISNULL(NULLIF(@idsucursal, 0), vt.idsucursal)
	AND vtm.idalmacen = ISNULL(NULLIF(@idalmacen, 0), vtm.idalmacen)
	AND vt.idcliente = ISNULL(NULLIF(@idcliente, 0), vt.idcliente)
	AND vt.fecha BETWEEN @fecha1 AND @fecha2
GROUP BY
	a.codigo
	, a.nombre
	, cum.nombre
	, ISNULL(aa.existencia, 0)
ORDER BY
	SUM(vtm.cantidad_facturada) DESC
GO
