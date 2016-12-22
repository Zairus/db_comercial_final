USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20161210
-- Description:	Obtener ventas de consignacion para orden de compra
-- =============================================
ALTER PROCEDURE [dbo].[_com_prc_ordenarDeConsignacion]
	@idalmacen_consignacion AS INT
	,@idalmacen_ingreso AS INT
	,@fecha1 AS SMALLDATETIME
	,@fecha2 AS SMALLDATETIME
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00')
SELECT @fecha2 = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59')

SELECT
	[codarticulo] = a.codigo
	,[idarticulo] = vtm.idarticulo
	,[codigo_proveedor] = ''
	,[descripcion] = a.nombre
	,[idalmacen] = @idalmacen_ingreso
	,[idum] = vtm.idum
	,[existencia] = ISNULL(aa.existencia, 0)
	,[cantidad_ordenada] = vtm.cantidad_facturada
	,[cantidad_autorizada] = vtm.cantidad_facturada
	,[idimpuesto1] = vtm.idimpuesto1
	,[idimpuesto1_valor] = vtm.idimpuesto1_valor
	,[idimpuesto1_ret] = vtm.idimpuesto1_ret
	,[idimpuesto1_ret_valor] = vtm.idimpuesto1_ret_valor
	,[costo_unitario] = (vtm.costo / vtm.cantidad_facturada)
	,[idimpuesto2] = vtm.idimpuesto2
	,[idimpuesto2_valor] = vtm.idimpuesto2_valor
	,[consignacion] = 1
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = vtm.idtran
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.idalmacen = vt.idalmacen
	LEFT JOIN ew_inv_almacenes_tipos AS almt
		ON almt.idtipo = alm.tipo

	LEFT JOIN ew_articulos As a
		ON a.idarticulo = vtm.idarticulo
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = vtm.idarticulo
		AND aa.idalmacen = vt.idalmacen
WHERE
	vt.cancelado = 0
	AND vt.transaccion LIKE 'EFA%'
	AND almt.propio = 0
	AND vt.idalmacen = @idalmacen_consignacion
	AND vt.fecha BETWEEN @fecha1 AND @fecha2
GO
