USE db_comercial_final
GO
IF OBJECT_ID('_xac_AFA1_cargarDoc') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_AFA1_cargarDoc
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190530
-- Description:	Cargar datos para factura de gasto
-- =============================================
CREATE PROCEDURE [dbo].[_xac_AFA1_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON

----------------------------------------------------
-- 1) ew_cxp_transacciones
----------------------------------------------------
SELECT
	[transaccion] = ct.transaccion
	, [idsucursal] = ct.idsucursal
	, [tipo] = ct.tipo
	, [afectasaldo] = 1
	, [codacreef1] = ''
	, [codacreedor] = p.codigo
	, [idproveedor] = ct.idproveedor
	, [folio] = ct.folio
	, [fecha] = ct.fecha
	, [idcomprobante] = ct.idcomprobante
	, [Timbre_UUID] = ISNULL(cco.Timbre_UUID, '-No Asignado-')
	, [cancelado] = ct.cancelado
	, [cancelado_fecha] = ct.cancelado_fecha
	, [idu] = ct.idu
	, [caja_chica] = ct.caja_chica
	, [comprobante_fiscal] = ct.comprobante_fiscal
	, [idconcepto] = ct.idconcepto
	, [concepto_cuenta] = ISNULL(oc.contabilidad, '')
	, [idr] = ct.idr
	, [idtran] = ct.idtran
	, [tipo_cargo] = ct.tipo_cargo
	, [spa1] = ''
	, [acreedor] = p.nombre
	, [credito] = ct.credito
	, [credito_dias] = ct.credito_dias
	, [acreedor_saldo] = csa.saldo
	, [acreedor_limite] = pt.credito_limite
	, [acreedor_credito] = pt.credito
	, [acreedor_cuenta] = p.contabilidad
	, [idimpuesto1] = ct.idimpuesto1
	, [idimpuesto2] = ct.idimpuesto2
	, [iva] = ct.idimpuesto1_valor
	, [idmoneda] = ct.idmoneda
	, [tipocambio] = ct.tipocambio
	, [idimpuesto1_valor] = ct.idimpuesto1_valor
	, [tipocambio_dof] = ct.tipocambio_dof
	, [spa2] = ''
	, [subtotal] = ct.subtotal
	, [impuesto1] = ct.impuesto1
	, [impuesto2] = ct.impuesto2
	, [impuesto1_ret] = ct.impuesto1_ret
	, [impuesto2_ret] = ct.impuesto2_ret
	, [total] = ct.total
	, [saldo] = ct.saldo
	, [Comentario] = ct.comentario
FROM
	ew_cxp_transacciones AS ct
	LEFT JOIN ew_proveedores AS p
		ON p.idproveedor = ct.idproveedor
	LEFT JOIN ew_cxp_saldos_actual AS csa 
		ON csa.idproveedor = ct.idproveedor 
		AND csa.idmoneda = ct.idmoneda
	LEFT JOIN ew_proveedores_terminos AS pt 
		ON pt.idproveedor = ct.idproveedor
	LEFT JOIN conceptos AS c 
		ON c. idconcepto = ct.idconcepto
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN objetos_conceptos AS oc
		ON oc.objeto = o.objeto
		AND oc.idconcepto = ct.idconcepto
	LEFT JOIN ew_cfd_comprobantes_recepcion AS cco
		ON cco.idcomprobante = ct.idcomprobante
WHERE
	ct.idtran = @idtran

----------------------------------------------------
-- 2) ew_com_transacciones_mov
----------------------------------------------------
SELECT
	[codarticulo] = a.codigo
	, [idarticulo] = ctm.idarticulo
	, [descripcion] = a.nombre
	, [comentario] = ctm.comentario
	, [cantidad_facturada] = ctm.cantidad_facturada
	, [costo_unitario] = ctm.costo_unitario
	, [costo_unitario2] = ctm.costo_unitario2
	, [descuento1] = ctm.descuento1
	, [descuento2] = ctm.descuento2
	, [descuento3] = ctm.descuento3
	, [importe] = ctm.importe
	, [cuenta] = a.contabilidad1
	, [idimpuesto1] = ctm.idimpuesto1
	, [idimpuesto1_valor] = ctm.idimpuesto1_valor
	, [idimpuesto2] = ctm.idimpuesto2
	, [idimpuesto2_valor] = ctm.idimpuesto2_valor
	, [idimpuesto1_ret] = ctm.idimpuesto1_ret
	, [idimpuesto1_ret_valor] = ctm.idimpuesto1_ret_valor
	, [idimpuesto2_ret] = ctm.idimpuesto2_ret
	, [idimpuesto2_ret_valor] = ctm.idimpuesto2_ret_valor
	, [impuesto1] = ctm.impuesto1
	, [impuesto2] = ctm.impuesto2
	, [impuesto1_ret] = ctm.impuesto1_ret
	, [impuesto2_ret] = ctm.impuesto2_ret
	, [idimpuesto1_cuenta] = dbo.fn_cxp_conceptoImpuestoCuenta(ctm.idarticulo, 'IVA', 1, 3)
	, [idimpuesto2_cuenta] = dbo.fn_cxp_conceptoImpuestoCuenta(ctm.idarticulo, 'IEPS', 1, 3)
	, [idimpuesto1_ret_cuenta] = dbo.fn_cxp_conceptoImpuestoCuenta(ctm.idarticulo, 'IVA', 2, 3)
	, [idimpuesto2_ret_cuenta] = dbo.fn_cxp_conceptoImpuestoCuenta(ctm.idarticulo, 'ISR', 2, 3)
	, [total] = ctm.total
	, [idr] = ctm.idr
	, [idtran] = ctm.idtran
	, [spa3] = ''
FROM
	ew_com_transacciones_mov AS ctm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = ctm.idarticulo
WHERE
	ctm.idtran = @idtran

----------------------------------------------------
-- 3) contabilidad
----------------------------------------------------
EXEC [dbo].[_xac_CONTABILIDAD_cargarDoc] @idtran

----------------------------------------------------
-- 4) bitacora
----------------------------------------------------
EXEC [dbo].[_xac_BITACORA_cargarDoc] @idtran
GO
