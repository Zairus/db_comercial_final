USE db_comercial_final
GO
ALTER VIEW [dbo].[ven_movtosDetallado]
AS
SELECT
	idtran
	, idarticulo
	, idalmacen
	, cantidad_solicitada
	, cantidad_autorizada
	, cantidad_surtida
	, [pendiente] = (cantidad_autorizada - cantidad_surtida)
	, precio_unitario
	, impuesto1
	, importe, total
FROM
	ew_ven_documentos_mov

UNION ALL

SELECT
	idtran
	, idarticulo
	, idalmacen
	, cantidad_ordenada
	, cantidad_autorizada
	, cantidad_surtida
	, [pendiente] = (cantidad_autorizada - cantidad_surtida)
	, precio_unitario
	, impuesto1
	, importe, total
FROM
	ew_ven_ordenes_mov

UNION ALL

SELECT
	idtran
	, idarticulo
	, idalmacen
	, cantidad_facturada
	, cantidad_autorizada
	, cantidad_surtida
	, [pendiente] = (cantidad_autorizada - cantidad_surtida)
	, precio_unitario
	, impuesto1
	, importe
	, total
FROM
	ew_ven_transacciones_mov
GO
