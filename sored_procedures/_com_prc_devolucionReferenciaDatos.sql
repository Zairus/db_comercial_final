USE db_comercial_final
GO
IF OBJECT_ID('_com_prc_devolucionReferenciaDatos') IS NOT NULL
BEGIN
	DROP PROCEDURE _com_prc_devolucionReferenciaDatos
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20151009
-- Description:	Datos de referencia en devolucion de compra
-- =============================================
CREATE PROCEDURE [dbo].[_com_prc_devolucionReferenciaDatos]
	@idsucursal AS SMALLINT
	, @referencia AS VARCHAR(30)
	, @idmoneda AS SMALLINT
	, @idalmacen AS INT = 0
AS

SET NOCOUNT ON

SELECT
	[referencia] = co.folio
	, [idtran2] = com.idtran
	, [idmov2] = com.idmov
	, [objidtran] = com.idtran
	, [idarticulo] = com.idarticulo
	, [serie] = a.series
	, [codarticulo] = a.codigo
	, [descripcion] = a.nombre
	, [idalmacen] = ISNULL(NULLIF(@idalmacen, 0), co.idalmacen)
	, [idum] = a.idum_compra
	, [cantidad_ordenada] = com.cantidad_autorizada
	, [cantidad_recibida] = (com.cantidad_facturada - com.cantidad_devuelta)
	, [cantidad_devuelta] = 0

	, [costo_unitario] = (com.importe / com.cantidad_facturada)

	, [oc_idmoneda] = co.idmoneda
	, [oc_importe_moneda] = com.importe
	, [oc_tipocambio] = co.tipocambio
	, [oc_gastos] = com.gastos
	, [oc_cantidad_ordenada] = com.cantidad_facturada

	, [idimpuesto1] = com.idimpuesto1
	, [idimpuesto1_valor] = com.idimpuesto1_valor
	, [idimpuesto2] = com.idimpuesto2
	, [idimpuesto2_valor] = com.idimpuesto2_valor
FROM 
	ew_com_transacciones_mov AS com
	LEFT JOIN ew_cxp_transacciones AS ct
		ON ct.idtran = com.idtran
	LEFT JOIN ew_com_transacciones AS co
		ON co.idtran = com.idtran
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = com.idarticulo
WHERE
	(
		co.transaccion LIKE 'CFA%'
		OR co.transaccion LIKE 'CDC%'
	)
	AND (com.cantidad_facturada - com.cantidad_devuelta) > 0
	AND co.idsucursal = @idsucursal
	AND co.folio = @referencia
	AND co.idmoneda = @idmoneda
GO
