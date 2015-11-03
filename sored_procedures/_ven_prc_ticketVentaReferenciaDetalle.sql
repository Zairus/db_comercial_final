USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151103
-- Description:	Detalle de referencia en ticket de venta
-- =============================================
ALTER PROCEDURE _ven_prc_ticketVentaReferenciaDetalle
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[codarticulo] = a.codigo
	,[idarticulo] = vdm.idarticulo
	,[descripcion] = a.nombre
	,[comentario] = vdm.comentario
	,[idum] = a.idum_venta
	,[existencia] = aa.existencia
	,[cantidad_autorizada] = vdm.cantidad_solicitada
	,[cantidad_ordenada] = vdm.cantidad_solicitada
	,[cantidad_facturada] = vdm.cantidad_solicitada
	,[precio_venta] = vdm.precio_unitario
	,[idimpuesto1] = vdm.idimpuesto1
	,[idimpuesto1_valor] = vdm.idimpuesto1_valor
	,[descuento1] = vdm.descuento1
	,[descuento2] = vdm.descuento2
	,[descuento3] = vdm.descuento3
	,[contabilidad] = an.contabilidad
FROM
	ew_ven_documentos_mov AS vdm
	LEFT JOIN ew_ven_documentos AS vd
		ON vd.idtran = vdm.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vdm.idarticulo
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = vdm.idarticulo
		AND aa.idalmacen = vd.idalmacen
	LEFT JOIN ew_articulos_niveles AS an
		ON an.codigo = a.nivel3
WHERE
	vdm.idtran = @idtran
GO
