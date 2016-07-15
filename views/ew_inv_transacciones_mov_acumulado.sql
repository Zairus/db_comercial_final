USE db_comercial_final
GO
CREATE VIEW [dbo].[ew_inv_transacciones_mov_acumulado]
AS
SELECT
	[id] = ROW_NUMBER() OVER (ORDER BY itm.idalmacen, itm.idarticulo, itm.idr)
	,[almacen] = alm.nombre
	,[codigo] = a.codigo
	,[nombre] = a.nombre
	,[fecha_t] = CONVERT(DATETIME, CONVERT(VARCHAR(8), it.fecha, 3) + ' ' + CONVERT(VARCHAR(8), it.fechahora, 8))
	,[fecha] = it.fecha
	,[movimiento] = it.transaccion
	,[folio] = it.folio

	,[entradas] = (CASE WHEN itm.tipo = 1 THEN itm.cantidad ELSE 0 END)
	,[salidas] = (CASE WHEN itm.tipo = 2 THEN itm.cantidad ELSE 0 END)
	,[existencia] = SUM(CASE WHEN itm.tipo = 1 THEN itm.cantidad ELSE itm.cantidad * -1 END) OVER (PARTITION BY itm.idalmacen, itm.idarticulo ORDER BY itm.idalmacen, itm.idarticulo, itm.idr)

	,[cargos] = (CASE WHEN itm.tipo = 1 THEN itm.costo ELSE 0 END)
	,[abonos] = (CASE WHEN itm.tipo = 2 THEN itm.costo ELSE 0 END)
	,[saldo] = SUM(CASE WHEN itm.tipo = 1 THEN itm.costo ELSE itm.costo * -1 END) OVER (PARTITION BY itm.idalmacen, itm.idarticulo ORDER BY itm.idalmacen, itm.idarticulo, itm.idr)

	,itm.tipo

	,itm.idalmacen
	,itm.idarticulo
	,itm.idtran
	,itm.idr
FROM
	ew_inv_transacciones_mov AS itm
	LEFT JOIN ew_inv_almacenes AS alm
		ON alm.idalmacen = itm.idalmacen
	LEFT JOIN ew_inv_transacciones AS it
		ON it.idtran = itm.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo= itm.idarticulo
WHERE
	itm.tipo IN (1,2)
GO
