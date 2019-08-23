USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_ticketVentaReferenciaDetalle') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_ticketVentaReferenciaDetalle
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151103
-- Description:	Detalle de referencia en ticket de venta
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_ticketVentaReferenciaDetalle]
	@referencia AS VARCHAR(20)
	, @idsucursal AS INT
AS

SET NOCOUNT ON

DECLARE
	@idturno AS INT
	, @pago_en_caja AS BIT
	, @idu AS INT = dbo._sys_fnc_usuario()
	, @idcuenta AS INT

SELECT @idturno = dbo.fn_sys_turnoActual(@idu)
SELECT @pago_en_caja = CONVERT(BIT, valor) FROM objetos_datos WHERE grupo = 'GLOBAL' AND codigo = 'PAGO_EN_CAJA'

IF @idu > 0 AND @idturno IS NULL AND @pago_en_caja = 0
BEGIN
	--RAISERROR('Error: El usuario no ha iniciado turno.', 16, 1)
	RETURN
END

SELECT
	[codarticulo] = a.codigo
	, [idarticulo] = vom.idarticulo
	, [descripcion] = a.nombre
	, [comentario] = vom.comentario
	, [idum] = a.idum_venta
	, [existencia] = aa.existencia
	, [cantidad_autorizada] = vom.cantidad_autorizada
	, [cantidad_ordenada] = vom.cantidad_autorizada
	, [cantidad_facturada] = vom.cantidad_autorizada
	, [precio_venta] = vom.precio_unitario
	, [idimpuesto1] = vom.idimpuesto1
	, [idimpuesto1_valor] = vom.idimpuesto1_valor
	, [descuento1] = vom.descuento1
	, [descuento2] = vom.descuento2
	, [descuento3] = vom.descuento3
	, [contabilidad] = an.contabilidad
	, [idtran2] = vom.idtran
	, [idmov2] = vom.idmov
	, [objidtran] = vom.idtran
FROM
	ew_ven_ordenes AS vo
	LEFT JOIN ew_ven_ordenes_mov AS vom
		ON vom.idtran = vo.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vom.idarticulo
	LEFT JOIN ew_articulos_almacenes AS aa
		ON aa.idarticulo = vom.idarticulo
		AND aa.idalmacen = ISNULL(NULLIF(vom.idalmacen, 0), vo.idalmacen)
	LEFT JOIN ew_articulos_niveles AS an
		ON an.codigo = a.nivel3
WHERE
	vo.transaccion = 'EOR1'
	AND vo.idsucursal = @idsucursal
	AND vo.folio = @referencia
GO
