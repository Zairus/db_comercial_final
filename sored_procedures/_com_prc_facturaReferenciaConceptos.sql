USE db_comercial_final
GO
IF OBJECT_ID('_com_prc_facturaReferenciaDatos') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_prc_facturaReferenciaConceptos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190820
-- Description:	Datos para referencia en factura
-- =============================================
CREATE PROCEDURE [dbo].[_com_prc_facturaReferenciaConceptos]
	@idsucursal AS INT
	, @referencia AS VARCHAR(20)
AS

SET NOCOUNT ON

IF EXISTS (
	SELECT * 
	FROM 
		ew_com_transacciones
	WHERE 
		cancelado = 0 
		AND transaccion IN ('CDC1') 
		AND idsucursal = @idsucursal 
		AND folio = 'NC' + @referencia
)
BEGIN
	SELECT
		[referencia] = co.folio
		, [idtran2] = co.idtran
		, [idmov2] = com.idmov
		, [codarticulo] = a.codigo
		, [idarticulo] = com.idarticulo
		, [descripcion] = a.nombre
		, [idum] = com.idum
		, [maneja_lote] = a.lotes
		, [lote] = ''
		, [fecha_caducidad] = NULL
		, [cantidad_recibida] = com.cantidad_facturada
		, [cantidad_pen_Facturar] = com.cantidad_facturada
		, [cantidad_facturada] = com.cantidad_facturada
		, [costo_unitario] = com.costo_unitario
		, [descuento1] = com.descuento1
		, [descuento2] = com.descuento2
		, [descuento3] = com.descuento3
		, [gastos] = com.gastos
		, [comentario] = com.comentario
		, [idimpuesto2] = com.idimpuesto2
		, [idimpuesto2_valor] = (com.impuesto2 / com.importe)
		, [idimpuesto1] = com.idimpuesto1
		, [idimpuesto3] = a.idimpuesto3
		, [idimpuesto4] = a.idimpuesto4
		, [idimpuesto1_ret] = com.idimpuesto1_ret
		, [idimpuesto1_valor]= (
			CASE 
				WHEN com.impuesto1 = 0 THEN 0 
				ELSE com.idimpuesto1_valor 
			END
		)
		, [idimpuesto1_ret_valor] = com.idimpuesto1_ret_valor
		, [objidtran] = com.idtran
	FROM 
		ew_com_transacciones_mov AS com
		LEFT JOIN ew_com_transacciones AS co 
			ON co.idtran = com.idtran
		LEFT JOIN ew_articulos AS a 
			ON a.idarticulo = com.idarticulo
		LEFT JOIN ew_cat_impuestos AS imp1 
			ON imp1.idimpuesto = a.idimpuesto1
		LEFT JOIN ew_cat_impuestos AS imp2 
			ON imp2.idimpuesto = a.idimpuesto2
		LEFT JOIN ew_cat_impuestos AS imp3 
			ON imp3.idimpuesto = a.idimpuesto3
		LEFT JOIN ew_cat_impuestos AS imp4 
			ON imp4.idimpuesto = a.idimpuesto4
	WHERE
		co.transaccion = 'CDC1'
		AND co.idsucursal = @idsucursal
		AND co.folio = @referencia
END
	ELSE
BEGIN
	SELECT
		[referencia] = co.folio
		, [idtran2] = co.idtran
		, [idmov2] = com.idmov
		, [codarticulo] = a.codigo
		, [idarticulo] = com.idarticulo
		, [descripcion] = a.nombre
		, [idum] = com.idum
		, [maneja_lote] = a.lotes
		, [lote] = ''
		, [fecha_caducidad] = NULL
		, [cantidad_recibida] = com.cantidad_surtida
		, [cantidad_pen_Facturar] = (
			CASE 
				WHEN (com.cantidad_surtida - com.cantidad_facturada) <= 0 THEN (com.cantidad_autorizada - com.cantidad_facturada) 
				ELSE (com.cantidad_surtida - com.cantidad_facturada) 
			END
		)
		, [cantidad_facturada] = com.cantidad_surtida
		, [costo_unitario] = com.costo_unitario
		, [descuento1] = com.descuento1
		, [descuento2] = com.descuento2
		, [descuento3] = com.descuento3
		, [gastos] = com.gastos
		, [comentario] = com.comentario
		, [idimpuesto2] = com.idimpuesto2
		, [idimpuesto2_valor] = (com.impuesto2 / com.importe)
		, [idimpuesto1] = com.idimpuesto1
		, [idimpuesto3] = a.idimpuesto3
		, [idimpuesto4] = a.idimpuesto4
		, [idimpuesto1_ret] = com.idimpuesto1_ret
		, [idimpuesto1_valor]= (
			CASE 
				WHEN com.impuesto1 = 0 THEN 0 
				ELSE com.idimpuesto1_valor 
			END
		)
		, [idimpuesto1_ret_valor] = com.idimpuesto1_ret_valor
		, [objidtran] = com.idtran
	FROM 
		ew_com_ordenes_mov AS com
		LEFT JOIN ew_com_ordenes AS co 
			ON co.idtran = com.idtran
		LEFT JOIN ew_articulos AS a 
			ON a.idarticulo = com.idarticulo
		LEFT JOIN ew_cat_impuestos AS imp1 
			ON imp1.idimpuesto = a.idimpuesto1
		LEFT JOIN ew_cat_impuestos AS imp2 
			ON imp2.idimpuesto = a.idimpuesto2
		LEFT JOIN ew_cat_impuestos AS imp3 
			ON imp3.idimpuesto = a.idimpuesto3
		LEFT JOIN ew_cat_impuestos AS imp4 
			ON imp4.idimpuesto = a.idimpuesto4
	WHERE
		co.transaccion IN ('COR1', 'COR2')
		AND com.cantidad_facturada < (
			CASE 
				WHEN com.cantidad_autorizada > com.cantidad_facturada THEN com.cantidad_autorizada 
				ELSE com.cantidad_facturada 
			END
		)
		AND co.idsucursal = @idsucursal
		AND co.folio = @referencia
END
GO
