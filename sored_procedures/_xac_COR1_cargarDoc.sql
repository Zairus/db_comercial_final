USE db_comercial_final
GO
IF OBJECT_ID('_xac_COR1_cargarDoc') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_COR1_cargarDoc
END
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20170701
-- Description:	Procedimiento para desplegar la transaccion COR1 
-- =============================================
CREATE PROCEDURE [dbo].[_xac_COR1_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON

----------------------------------------------------
-- 1)  ew_com_ordenes
----------------------------------------------------
SELECT
	[transaccion] = ew_com_ordenes.transaccion
	, [idr] = ew_com_ordenes.idr
	, [idtran] = ew_com_ordenes.idtran
	, [doc_referencia] = cd.folio
	, [idsucursal] = ew_com_ordenes.idsucursal
	, [idalmacen] = ew_com_ordenes.idalmacen
	, [codproveedor] = p.codigo
	, [idproveedor] = ew_com_ordenes.idproveedor
	, [folio] = ew_com_ordenes.folio
	, [referencia] = ew_com_ordenes.referencia
	, [fecha] = ew_com_ordenes.fecha
	, [idu] = ew_com_ordenes.idu
	, [proveedor] = p.nombre
	, [rfc] = p.rfc
	, [telefono1] = p.telefono1
	, [telefono2] = p.telefono2
	, [telefono3] = p.telefono3
	, [idcontacto] = ew_com_ordenes.idcontacto
	, [contacto] = cc.nombre
	, [horario] = pc.horario
	, [contacto_telefono] = (
		CASE 
			WHEN RTRIM(dbo.fn_cat_contactoInformacion (pc.idcontacto,1,1)) = '' THEN p.telefono1 
			ELSE dbo.fn_cat_contactoInformacion (pc.idcontacto,1,1) 
		END
	)
	, [cel_contacto] = ''
	, [contacto_email] = (
		CASE 
			WHEN RTRIM(dbo.fn_cat_contactoInformacion (pc.idcontacto,4,1)) = '' THEN p.email 
			ELSE dbo.fn_cat_contactoInformacion (pc.idcontacto,4,1) END
	)
	, [idimpuesto1] = ew_com_ordenes.idimpuesto1
	, [idimpuesto1_ret] = ew_com_ordenes.idimpuesto1_ret
	, [iva] = (imp.valor / 0.01)
	, [dias_credito] = ew_com_ordenes.dias_credito
	, [dias_entrega] = ew_com_ordenes.dias_entrega
	, [proveedor_saldo] = ISNULL(csa.saldo, 0)
	, [proveedor_limite] = ISNULL(pt.credito_limite, 0)
	, [proveedor_credito] = (
		CASE 
			WHEN ((ISNULL(pt.credito_limite, 0) - ISNULL(csa.saldo, 0))) < 0 THEN 0 
			ELSE ((ISNULL(pt.credito_limite, 0) - ISNULL(csa.saldo, 0))) 
		END
	)
	, [idmoneda] = ew_com_ordenes.idmoneda
	, [tipocambio] = ew_com_ordenes.tipocambio
	, [subtotal] = ew_com_ordenes.subtotal
	, [gastos] = ew_com_ordenes.gastos
	, [gastos_criterio] = [dbo].[_sys_fnc_parametroTexto]('COM_CRITERIO_PRORRATEO')
	, [impuesto1] = ew_com_ordenes.impuesto1
	, [impuesto2] = ew_com_ordenes.impuesto2
	, [impuesto1_ret] = ew_com_ordenes.impuesto1_ret
	, [total] = ew_com_ordenes.total
	, [comentario] = ew_com_ordenes.comentario
	, [cancelado] = ew_com_ordenes.cancelado
	, [cancelado_fecha] = ew_com_ordenes.cancelado_fecha
	, [idrelacion] = 3
	, [entidad_codigo] = p.codigo
	, [entidad_nombre] = p.nombre
	, [identidad] = p.idproveedor
	, [factura_transaccion] = [dbo].[_sys_fnc_parametroTexto]('COM_TRANSACCIONFACTURA')
FROM 
	ew_com_ordenes
	LEFT JOIN ew_proveedores AS p 
		ON p.idproveedor = ew_com_ordenes.idproveedor
	LEFT JOIN ew_proveedores_contactos AS pc 
		ON pc.idproveedor = ew_com_ordenes.idproveedor
	LEFT JOIN ew_cat_contactos AS cc 
		ON cc.idcontacto = pc.idcontacto
	LEFT JOIN ew_proveedores_terminos AS pt 
		ON pt.idproveedor = p.idproveedor
	LEFT JOIN ew_cxp_saldos_actual AS csa 
		ON csa.idproveedor = ew_com_ordenes.idproveedor 
		AND csa.idmoneda = ew_com_ordenes.idmoneda
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = ew_com_ordenes.idsucursal
	LEFT JOIN ew_cat_impuestos AS imp 
		ON imp.idimpuesto = ew_com_ordenes.idimpuesto1
	LEFT JOIN ew_com_documentos AS cd 
		ON cd.idtran=ew_com_ordenes.idtran2
WHERE  
	ew_com_ordenes.idtran = @idtran 

----------------------------------------------------
-- 2)  ew_com_ordenes_mov
----------------------------------------------------
SELECT
	[consecutivo] = ew_com_ordenes_mov.consecutivo
	, [codarticulo] = a.codigo
	, [idarticulo] = ew_com_ordenes_mov.idarticulo
	, [codigo_proveedor]=ISNULL(ew_com_ordenes_mov.codigo_proveedor,'')
	, [descripcion] = a.nombre
	, [marca]=ISNULL(m.nombre,'-NO DEFINIDA-')
	, [idalmacen] = ew_com_ordenes_mov.idalmacen
	, [idum] = ew_com_ordenes_mov.idum
	, [existencia] = ew_com_ordenes_mov.existencia
	, [cantidad_cotizada] = ew_com_ordenes_mov.cantidad_cotizada
	, [cantidad_ordenada] = ew_com_ordenes_mov.cantidad_ordenada
	, [cantidad_autorizada] = ew_com_ordenes_mov.cantidad_autorizada
	, [cantidad_surtida] = ew_com_ordenes_mov.cantidad_surtida
	, [cantidad_devuelta] = ew_com_ordenes_mov.cantidad_devuelta
	, [cantidad_facturada] = ew_com_ordenes_mov.cantidad_facturada
	, [costo_unitario] = ew_com_ordenes_mov.costo_unitario
	, [descuento1] = ew_com_ordenes_mov.descuento1
	, [descuento2] = ew_com_ordenes_mov.descuento2
	, [descuento3] = ew_com_ordenes_mov.descuento3
	, [importe] = ew_com_ordenes_mov.importe
	, [gastos] = ew_com_ordenes_mov.gastos
	, [impuesto1] = ew_com_ordenes_mov.impuesto1
	, [impuesto2] = ew_com_ordenes_mov.impuesto2
	, [impuesto1_ret] = ew_com_ordenes_mov.impuesto1_ret
	, [total] = ew_com_ordenes_mov.total
	, [comentario] = ew_com_ordenes_mov.comentario
	, [idr] = ew_com_ordenes_mov.idr
	, [idtran] = ew_com_ordenes_mov.idtran
	, [idmov] = ew_com_ordenes_mov.idmov
	, [idmov2] = ew_com_ordenes_mov.idmov2
	, [objidtran]= CONVERT(int,idmov2)
	, [idimpuesto1] = ew_com_ordenes_mov.idimpuesto1
	, [idimpuesto1_valor] = ew_com_ordenes_mov.idimpuesto1_valor
	, [idimpuesto2] = ew_com_ordenes_mov.idimpuesto2
	, [idimpuesto2_valor] = ew_com_ordenes_mov.idimpuesto2_valor
	, [idimpuesto1_ret] = ew_com_ordenes_mov.idimpuesto1_ret
	, [idimpuesto1_ret_valor] = ew_com_ordenes_mov.idimpuesto1_ret_valor
	, [consignacion] = ew_com_ordenes_mov.consignacion
FROM 
	ew_com_ordenes_mov
	LEFT JOIN ew_com_ordenes AS ord 
		ON ord.idtran = ew_com_ordenes_mov.idtran
	LEFT JOIN ew_sys_sucursales AS suc 
		ON suc.idsucursal = ord.idsucursal
	LEFT JOIN ew_articulos AS a 
		ON a.idarticulo = ew_com_ordenes_mov.idarticulo
	LEFT JOIN ew_cat_impuestos AS imp 
		ON imp.idimpuesto = a.idimpuesto1
	LEFT JOIN ew_cat_impuestos AS imp2 
		ON imp2.idimpuesto = suc.idimpuesto
	LEFT JOIN EW_CAT_IMPUESTOS AS IMP3 
		ON IMP3.IDIMPUESTO = ord.idimpuesto1
	LEFT JOIN ew_articulos_proveedores AS ap 
		ON ap.idproveedor = ord.idproveedor 
		AND ap.idarticulo = ew_com_ordenes_mov.idarticulo 
	LEFT JOIN ew_cat_marcas AS m 
		ON m.idmarca=a.idmarca
WHERE  
	ew_com_ordenes_mov.idtran = @idtran 

----------------------------------------------------
-- 3)  traking
----------------------------------------------------
SELECT
	*
FROM
	[dbo].[fn_sys_tracking](@idtran)
WHERE
	objidtran > 0

----------------------------------------------------
-- 4)  bitacora
----------------------------------------------------
SELECT
	fechahora
	, codigo
	, nombre
	, usuario_nombre
	, host
	, comentario
FROM 
	bitacora
WHERE  
	bitacora.idtran = @idtran 
ORDER BY 
	fechahora
GO
