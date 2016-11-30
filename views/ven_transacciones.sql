USE db_comercial_final
GO
ALTER VIEW [dbo].[ven_transacciones]
AS
SELECT
	vd.idtran
	, vd.idsucursal
	, vd.idalmacen
	, vd.transaccion
	, vd.idconcepto
	, vd.fecha
	, vd.folio
	, vd.idcliente
	, vd.idvendedor
	, vd.idmoneda
	, vd.subtotal
	, vd.impuesto1
	, vd.total
	, vd.cancelado
	, vd.comentario
FROM
	ew_ven_documentos AS vd

UNION ALL

SELECT
	vo.idtran
	, vo.idsucursal
	, vo.idalmacen
	, vo.transaccion
	, vo.idconcepto
	, vo.fecha
	, vo.folio
	, vo.idcliente
	, vo.idvendedor
	, vo.idmoneda
	, vo.subtotal
	, vo.impuesto1
	, vo.total
	, vo.cancelado
	, vo.comentario
FROM
	ew_ven_ordenes AS vo

UNION ALL

SELECT
	vt.idtran
	, vt.idsucursal
	, vt.idalmacen
	, vt.transaccion
	, vt.idconcepto
	, vt.fecha
	, vt.folio
	, vt.idcliente
	, vt.idvendedor
	, vt.idmoneda
	, vt.subtotal
	, vt.impuesto1
	, vt.total
	, vt.cancelado
	, vt.comentario
FROM
	ew_ven_transacciones AS vt
GO
