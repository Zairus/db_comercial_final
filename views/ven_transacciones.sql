USE db_comercial_final
GO
ALTER VIEW [dbo].[ven_transacciones]
AS
SELECT     idtran, idsucursal, idalmacen, transaccion, idconcepto, fecha, folio, idcliente, idvendedor, idmoneda, subtotal, impuesto1, total, cancelado, comentario
FROM
	ew_ven_documentos

UNION ALL

SELECT
	idtran, idsucursal, idalmacen, transaccion, idconcepto, fecha, folio, idcliente, idvendedor, idmoneda, subtotal, impuesto1, total, cancelado, comentario
FROM
	ew_ven_ordenes

UNION ALL

SELECT     idtran, idsucursal, idalmacen, transaccion, idconcepto, fecha, folio, idcliente, idvendedor, idmoneda, subtotal, impuesto1, total, cancelado, comentario
FROM
	ew_ven_transacciones

UNION ALL

SELECT     idtran, idsucursal, idalmacen, transaccion, idconcepto, fecha, folio, cl.idcliente, idvendedor = 0, idmoneda, subtotal = 0, impuesto = 0, total, cancelado, ew_inv_transacciones.comentario
FROM
	ew_inv_transacciones
	LEFT JOIN ew_clientes cl 
		ON cl.idcliente = dbo.FN_VEN_SURTIRIDCLIENTE(ew_inv_transacciones.idtran)
--WHERE     transaccion IN ('ERE1', 'EDE2')
GO
