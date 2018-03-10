USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180310
-- Description:	Referencia de orden de venta a factura
-- =============================================
ALTER PROCEDURE _ven_prc_ordenReferenciaDetalle
	@referencia_encabezado AS VARCHAR(15)
	,@referencia_detalle AS VARCHAR(15)
	,@idsucursal AS INT
	,@idcliente AS INT
AS

SET NOCOUNT ON

SELECT
	[referencia] = doc.folio
	,[idtran2] = om.idtran
	,[idmov2] = om.idmov
	,[objidtran] = CONVERT (INT, om.idmov)
	,[consecutivo] = om.consecutivo
	,[codarticulo] = a.codigo
	,[idarticulo] = om.idarticulo
	,[descripcion] = a.nombre
	,[idum] = om.idum
	,[existencia] = ISNULL(aa.existencia, 0) --(Febrero 28, 2018)
	,precio_minimo= 0
	,[cantidad_porFacturar]= cantidad_porFacturar
	,[cantidad_porSurtir]= cantidad_porSurtir
	,[cantidad_ordenada] = om.cantidad_ordenada
	,[cantidad_autorizada] = om.cantidad_autorizada
	,[cantidad_recibida] = om.cantidad_porSurtir
	,[cantidad_facturada] =  om.cantidad_porFacturar
	,[cantidad_devuelta] = om.cantidad_devuelta
	,[idmoneda_m]=ISNULL(vlm.idmoneda,0)
	,[tipocambio_m]=ISNULL(dbo.fn_ban_tipocambio(vlm.idmoneda,0),1)
	,[precio_congelado]= ISNULL(vlm.precio_congelado,0)
	,[precio_unitario_m] = (om.precio_unitario/ISNULL(dbo.fn_ban_tipocambio(vlm.idmoneda,0),1))/(1/(ISNULL(dbo.fn_ban_tipocambio(doc.idmoneda,0),1)))
	,[precio_unitario] = om.precio_unitario
	,[descuento1] = om.descuento1
	,[descuento2] = om.descuento2
	,om.descuento_pp1
	,om.descuento_pp2
	,om.descuento_pp3
	,[comentario] = om.comentario
	,[serie]= a.series
	,a.inventariable
	,[idalmacen]=doc.idalmacen
	,cuenta_sublinea=subl.contabilidad
	
	,[idimpuesto1] = ISNULL([dbo].[_ct_fnc_articuloImpuestoId]('IVA', 1, a.idarticulo), a.idimpuesto1)
	,[idimpuesto1_valor] = ISNULL([dbo].[_ct_fnc_articuloImpuestoTasa]('IVA', 1, a.idarticulo), 0.16)
	,[idimpuesto1_cuenta] = ISNULL([dbo].[_ct_fnc_articuloImpuestoCuenta]('IVA', 1, a.idarticulo, 1), '2130001002')
	,[idimpuesto2] = ISNULL([dbo].[_ct_fnc_articuloImpuestoId]('IEPS', 1, a.idarticulo), a.idimpuesto2)
	,[idimpuesto2_valor] = ISNULL([dbo].[_ct_fnc_articuloImpuestoTasa]('IEPS', 1, a.idarticulo), 0.0)
	,[idimpuesto2_cuenta] = ISNULL([dbo].[_ct_fnc_articuloImpuestoCuenta]('IEPS', 1, a.idarticulo, 1), '')
	,[idimpuesto1_ret] = ISNULL([dbo].[_ct_fnc_articuloImpuestoId]('IVA', 2, a.idarticulo), a.idimpuesto1_ret)
	,[idimpuesto1_ret_valor] = ISNULL([dbo].[_ct_fnc_articuloImpuestoTasa]('IVA', 2, a.idarticulo), 0.0)
	,[idimpuesto1_ret_cuenta] = ISNULL([dbo].[_ct_fnc_articuloImpuestoCuenta]('IVA', 2, a.idarticulo, 1), '')
	,[idimpuesto2_ret] = ISNULL([dbo].[_ct_fnc_articuloImpuestoId]('ISR', 2, a.idarticulo), a.idimpuesto2_ret)
	,[idimpuesto2_ret_valor] = ISNULL([dbo].[_ct_fnc_articuloImpuestoTasa]('ISR', 2, a.idarticulo), 0.0)
	,[idimpuesto2_ret_cuenta] = ISNULL([dbo].[_ct_fnc_articuloImpuestoCuenta]('ISR', 2, a.idarticulo, 1), '')
	,[ingresos_cuenta] = ISNULL([dbo].[_ct_fnc_articuloIngresosCuenta](a.idarticulo), '4100001000')
	,om.objlevel
FROM 
	ew_ven_ordenes_mov AS om
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo =om.idarticulo
	LEFT JOIN ew_ven_ordenes AS doc 
		ON doc.idtran =  om.idtran
	LEFT JOIN ew_ven_listaprecios_mov AS vlm 
		ON vlm.idarticulo = a.idarticulo 
		AND vlm.idlista = doc.idlista 
	LEFT JOIN ew_articulos_niveles AS subl 
		ON subl.codigo=a.nivel3

	-- NUEVO POR VLADIMIR A SOLICITUD DE MARTIN (Febrero 28, 2018)
	-- QUE SE TRAIGA LA EXISTENCIA ACTUAL DEL ALMACEN EN VEZ DE LA EXISTENCIA QUE SE GUARD� AL
	-- MOMENTO DE HACER EL PEDIDO
	LEFT JOIN ew_articulos_almacenes AS aa 
		ON aa.idarticulo = a.idarticulo AND aa.idalmacen = doc.idalmacen
WHERE
	doc.transaccion = 'EOR1'
	AND doc.idsucursal = @idsucursal
	AND doc.folio IN (
		SELECT r.valor 
		FROM dbo._sys_fnc_separarMultilinea(
			(
				CASE 
					WHEN @referencia_encabezado = '' THEN @referencia_detalle
					ELSE @referencia_encabezado
				END
			), '	') AS r
	)
	AND doc.idcliente = @idcliente
	AND om.cantidad_porFacturar > 0
GO
