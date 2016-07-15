USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160712
-- Description:	Kardex con saldos acumulados
-- =============================================
ALTER PROCEDURE [dbo].[_inv_rpt_kardexAcumulado]
	@idsucursal AS INT = 0
	,@idalmacen AS INT = 0
	,@idarticulo AS INT = 0
	,@fecha1 AS SMALLDATETIME = NULL
	,@fecha2 AS SMALLDATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha1 = CONVERT(VARCHAR(8), ISNULL(@fecha1, DATEADD(DAY, -30, GETDATE())), 3) + ' 00:00'
SELECT @fecha2 = CONVERT(VARCHAR(8), ISNULL(@fecha2, GETDATE()), 3) + ' 23:59'

SELECT
	[sucursal] = s.nombre
	,[almacen] = alm.nombre
	,[codarticulo] = a.codigo
	,[nombre] = a.nombre + ' [' + a.codigo + ']'
	,[movimiento] = ISNULL(orel.nombre, o.nombre)
	,[transaccion] = ISNULL(orel.codigo, o.codigo)
	,[fecha] = it.fecha
	,[folio] = ISNULL(strel.folio, it.folio)
	,[referencia] = ISNULL(c.codigo, ISNULL(p.codigo, ''))
	,[entradas] = itma.entradas
	,[salidas] = itma.salidas
	,[existencia] = itma.existencia
	,[existencia_act] = aa.existencia
	,[cargos] = itma.cargos
	,[abonos] = itma.abonos
	,[saldo] = itma.saldo

	,itma.idtran
	,[objidtran] = ISNULL(strel.idtran, itma.idtran)
FROM
	[dbo].[ew_inv_transacciones_mov_acumulado] AS itma
	LEFT JOIN ew_inv_transacciones AS it
		ON it.idtran = itma.idtran
	LEFT JOIN ew_sys_sucursales AS s
		ON s.idsucursal = it.idsucursal
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.idalmacen = itma.idalmacen
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = itma.idarticulo
	LEFT JOIN objetos AS o
		ON o.codigo = it.transaccion
	LEFT JOIN ew_sys_transacciones AS strel
		ON strel.idtran = it.idtran2
	LEFT JOIN objetos AS orel
		ON orel.codigo = strel.transaccion
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = it.idtran2
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_com_transacciones AS ct
		ON ct.idtran = it.idtran2
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = ct.idproveedor
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = itma.idarticulo
		AND aa.idalmacen = itma.idalmacen
WHERE
	itma.idalmacen = (CASE WHEN @idalmacen = 0 THEN itma.idalmacen ELSE @idalmacen END)
	AND alm.idsucursal = (CASE WHEN @idsucursal = 0 THEN alm.idsucursal ELSE @idsucursal END)
	AND itma.idarticulo = (CASE WHEN @idarticulo = 0 THEN itma.idarticulo ELSE @idarticulo END)
	AND itma.fecha BETWEEN @fecha1 AND @fecha2
ORDER BY
	itma.idalmacen
	,itma.idarticulo
	,itma.idr
GO
