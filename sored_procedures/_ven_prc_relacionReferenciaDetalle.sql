USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_relacionReferenciaDetalle') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_relacionReferenciaDetalle
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180310
-- Description:	Referencia de orden de venta a factura
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_relacionReferenciaDetalle]
	@referencia_encabezado AS VARCHAR(15)
	, @referencia_detalle AS VARCHAR(15)
	, @idsucursal AS INT
	, @idcliente AS INT
AS

SET NOCOUNT ON

SELECT
	[referencia] = doc.folio
	, [idtran2] = doc.idtran
	, [idmov2] = om.idmov
	, [objidtran] = doc.idtran --CONVERT (INT, om.idmov)
	, [consecutivo] = om.consecutivo
	, [codarticulo] = a.codigo
	, [idarticulo] = om.idarticulo
	, [descripcion] = a.nombre
	, [idum] = om.idum
	, [existencia] = ISNULL(aa.existencia, 0)
	, [precio_minimo] = 0
	, [cantidad_porFacturar]= om.cantidad_facturada
	, [cantidad_porSurtir]= om.cantidad_facturada
	, [cantidad_ordenada] = om.cantidad_ordenada
	, [cantidad_autorizada] = om.cantidad_facturada
	, [cantidad_recibida] = om.cantidad_facturada
	, [cantidad_facturada] =  om.cantidad_facturada
	, [cantidad_devuelta] = om.cantidad_devuelta
	, [idmoneda_m] = ISNULL(vlm.idmoneda,0)
	, [tipocambio_m] = ISNULL(dbo.fn_ban_tipocambio(vlm.idmoneda, 0), 1)
	, [precio_congelado]= om.precio_unitario
	, [precio_unitario_m] = om.precio_unitario
	, [precio_unitario] = ISNULL(
		NULLIF(om.precio_unitario, 0)
		, (
			om.importe 
			/ ISNULL(NULLIF(om.cantidad_facturada, 0), 1)
		)
	)
	, [descuento1] = om.descuento1
	, [descuento2] = om.descuento2
	, [descuento_pp1] = om.descuento_pp1
	, [descuento_pp2] = om.descuento_pp2
	, [descuento_pp3] = om.descuento_pp3
	, [comentario] = om.comentario
	, [serie]= a.series
	, [lotes] = a.lotes
	, [inventariable] = a.inventariable
	, [idalmacen] = doc.idalmacen
	, [cuenta_sublinea] = subl.contabilidad
	
	, [idimpuesto1] = om.idimpuesto1
	, [idimpuesto1_valor] = om.idimpuesto1_valor
	, [idimpuesto1_cuenta] = ISNULL([dbo].[_ct_fnc_articuloImpuestoCuenta]('IVA', 1, a.idarticulo, 1, doc.idsucursal), '2130001002')
	, [idimpuesto2] = om.idimpuesto2
	, [idimpuesto2_valor] = om.idimpuesto2_valor
	, [idimpuesto2_cuenta] = ISNULL([dbo].[_ct_fnc_articuloImpuestoCuenta]('IEPS', 1, a.idarticulo, 1, doc.idsucursal), '')
	, [idimpuesto1_ret] = om.idimpuesto1_ret
	, [idimpuesto1_ret_valor] = om.idimpuesto1_ret_valor
	, [idimpuesto1_ret_cuenta] = ISNULL([dbo].[_ct_fnc_articuloImpuestoCuenta]('IVA', 2, a.idarticulo, 1, doc.idsucursal), '')
	, [idimpuesto2_ret] = om.idimpuesto2_ret
	, [idimpuesto2_ret_valor] = om.idimpuesto2_ret_valor
	, [idimpuesto2_ret_cuenta] = ISNULL([dbo].[_ct_fnc_articuloImpuestoCuenta]('ISR', 2, a.idarticulo, 1, doc.idsucursal), '')
	, [ingresos_cuenta] = ISNULL([dbo].[_ct_fnc_articuloIngresosCuenta](a.idarticulo, doc.idsucursal), '4100001000')
 
	, [importe] = om.importe
	, [impuesto1] = om.impuesto1
	, [impuesto2] = om.impuesto2
	, [impuesto1_ret] = om.impuesto1_ret
	, [impuesto2_ret] = om.impuesto2_ret

	, [objlevel] = om.objlevel
FROM 
	ew_ven_transacciones AS doc 
	LEFT JOIN ew_cxc_transacciones_rel AS ctr
		ON doc.transaccion = 'EFA4'
		AND ctr.idtran = doc.idtran
	LEFT JOIN ew_ven_transacciones_mov AS om
		ON om.idtran = ISNULL(ctr.idtran2, doc.idtran)
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = om.idarticulo
	--LEFT JOIN ew_ven_transacciones AS doc 
		--ON doc.idtran = om.idtran
	LEFT JOIN ew_ven_listaprecios_mov AS vlm 
		ON vlm.idarticulo = a.idarticulo 
		AND vlm.idlista = doc.idlista 
	LEFT JOIN ew_articulos_niveles AS subl 
		ON subl.codigo = a.nivel3
	LEFT JOIN ew_articulos_almacenes AS aa 
		ON aa.idarticulo = a.idarticulo 
		AND aa.idalmacen = doc.idalmacen
WHERE
	doc.idcliente = @idcliente
	AND doc.transaccion LIKE 'EFA%'
	AND doc.idsucursal = @idsucursal
	AND doc.folio IN (
		SELECT r.valor 
		FROM dbo._sys_fnc_separarMultilinea (
			(
				CASE 
					WHEN @referencia_encabezado = '' THEN @referencia_detalle
					ELSE @referencia_encabezado
				END
			), '	') AS r
	)
GO
