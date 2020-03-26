USE db_comercial_final
GO
IF OBJECT_ID('_xac_EDC3_cargarDoc') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_EDC3_cargarDoc
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200310
-- Description:	Cargar nota de venta recibo provisional
-- =============================================
CREATE PROCEDURE [dbo].[_xac_EDC3_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON

--ew_cxc_transacciones
SELECT
	[transaccion] = vt.transaccion
	, [idsucursal] = vt.idsucursal
	, [idalmacen] = vt.idalmacen
	, [folio] = vt.folio
	, [fecha] = vt.fecha
	, [clientef1] = ''
	, [cliente] = c.codigo
	, [nombre] = c.nombre
	, [cancelado] = vt.cancelado
	, [cancelado_fecha] = vt.cancelado_fecha
	, [idu] = vt.idu
	--, [estado] = NULL
	, [idconcepto] = vt.idconcepto
	, [idr] = vt.idr
	, [idmov] = vt.idmov
	, [idtran] = vt.idtran
	, [sp1] = ''
	, [idcliente] = vt.idcliente
	, [idfacturacion] = vt.idfacturacion
	, [rfc] = c.rfc
	, [direccion] = c.calle
	, [noExterior] = c.noExterior
	, [colonia] = c.colonia
	, [ciudad] = ''
	, [codigo_postal] = c.codpostal
	, [telefono1] = c.telefono1
	, [idmoneda] = vt.idmoneda
	, [tipocambio] = vt.tipocambio
	, [vendf1] = ''
	, [idlista] = vt.idlista
	, [codigo_vendedor] = v.codigo
	, [idvendedor] = vt.idvendedor
	, [nombre_vendedor] = v.nombre
	, [artf1] = ''
	, [sp2] = ''
	, [subtotal] = vt.subtotal
	, [impuesto1] = vt.impuesto1
	, [impuesto2] = vt.impuesto2
	, [redondeo] = vt.redondeo
	, [total] = vt.total
	, [costo] = vt.costo
	, [comentario] = vt.comentario
	, [spa] = ''
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN vew_clientes AS c
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_ven_vendedores AS v
		ON v.idvendedor = vt.idvendedor
WHERE
	vt.idtran = @idtran

--ew_cxc_transacciones
SELECT
	[tipo] = ct.tipo
	, [idimpuesto1_valor] = ct.idimpuesto1_valor
	, [idimpuesto1] = ct.idimpuesto1
	, [credito] = ct.credito
	, [saldo] = ct.saldo
FROM 
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran

--ew_ven_transacciones_medico_ordenante
SELECT
	[codigo_medico_ordenante] = st.codigo
	, [nombre_medico_ordenante] = ISNULL(u.nombre, st.nombre)
	, [idtecnico_ordenante] = vtmo.idtecnico_ordenante
	, [tipo_ordenante] = vtmo.tipo_ordenante
FROM
	ew_ven_transacciones_medico_ordenante AS vtmo
	LEFT JOIN ew_ser_tecnicos AS st
		ON st.idtecnico = vtmo.idtecnico_ordenante
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = st.idu
WHERE
	vtmo.idtran = @idtran

--ew_ven_transacciones_medico_receptor
SELECT
	[codigo_medico_receptor] = st.codigo
	, [nombre_medico_recpetor] = ISNULL(u.nombre, st.nombre)
	, [idtecnico_receptor] = vtmr.idtecnico_receptor
	, [tipo_receptor] = vtmr.tipo_receptor
	, [sp2] = ''
FROM
	ew_ven_transacciones_medico_receptor AS vtmr
	LEFT JOIN ew_ser_tecnicos AS st
		ON st.idtecnico = vtmr.idtecnico_receptor
	LEFT JOIN evoluware_usuarios AS u
		ON u.idu = st.idu
WHERE
	vtmr.idtran = @idtran

--ew_ven_transacciones_mov
SELECT
	[codarticulo] = a.codigo
	, [idarticulo] = vtm.idarticulo
	, [descripcion] = a.nombre
	, [comentario] = vtm.comentario
	, [llave] = ''
	, [promocion] = 0
	, [inventariable] = a.inventariable
	, [idalmacen] = vtm.idalmacen
	, [idum] = a.idum_venta
	, [cantidad_ordenada] = vtm.cantidad_ordenada
	, [existencia] = 0
	, [existencia_v] = 0
	, [cantidad_autorizada] = vtm.cantidad_autorizada
	, [cantidad_facturada] = vtm.cantidad_facturada
	, [cantidad_surtida] = vtm.cantidad_surtida
	, [cantidad_devuelta] = vtm.cantidad_devuelta
	, [precio_venta] = vtm.precio_venta
	, [max_descuento1] = 0
	, [max_descuento2] = 0
	, [max_descuento3] = 0
	, [idimpuesto1] = vtm.idimpuesto1
	, [idimpuesto1_valor] = vtm.idimpuesto1_valor
	, [idimpuesto2] = vtm.idimpuesto2
	, [idimpuesto2_valor] = vtm.idimpuesto2_valor
	, [descuento1] = vtm.descuento1
	, [descuento2] = vtm.descuento2
	, [descuento3] = vtm.descuento3
	, [precio_desc] = (vtm.importe / vtm.cantidad_facturada)
	, [importe] = vtm.importe
	, [impuesto1] = vtm.impuesto1
	, [impuesto2] = vtm.impuesto2
	, [total] = vtm.total
	, [datos] = ''
	, [costo] = vtm.costo
	, [contabilidad] = ''
	, [sp3] = ''
	, [idr] = vtm.idr
	, [idmov] = vtm.idmov
	, [idtran] = vtm.idtran
	, [idtran2] = vtm.idtran2
	, [idmov2] = vtm.idmov2
	, [objidtran] = vtm.idtran2
	, [ingresos_cuenta] = ''
	, [idimpuesto1_cuenta] = ''
	, [idimpuesto2_cuenta] = ''
	, [idimpuesto1_ret_cuenta] = ''
	, [idimpuesto2_ret_cuenta] = ''
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_articulos As a
		ON a.idarticulo = vtm.idarticulo
WHERE
	vtm.idtran = @idtran

--ew_ven_transacciones_pagos
SELECT TOP 1
	[idforma] = vtp.idforma
	, [total] = vtp.total
	, [forma_referencia] = vtp.forma_referencia
	, [idforma2] = vtp.idforma2
	, [total2] = vtp.total2
	, [forma_referencia2] = vtp.forma_referencia2
	, [pago_total] = vtp.total + vtp.total2
	, [pago_cambio] = 0
	, [saldo] = ct.saldo
	, [forma1] = ''
	, [forma2] = ''
	, [idr] = vtp.idr
	, [idmov] = vtp.idmov
	, [idtran] = vtp.idtran
	, [spa] = ''
FROM
	ew_ven_transacciones_pagos AS vtp
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = vtp.idtran
WHERE
	vtp.idtran = @idtran
ORDER BY
	vtp.idr ASC

--ew_ven_transacciones_pagos2
SELECT
	[idforma] = vtp2.idforma
	, [reff1] = ''
	, [idtran2] = vtp2.idtran2
	, [forma_referencia] = vtp2.forma_referencia
	, [ref_moneda] = ''
	, [saldo_ref] = 0
	, [total_ap] = 0
	, [forma_moneda] = 0
	, [forma_tipocambio] = 1
	, [importe2] = vtp2.total
	, [total] = vtp2.total
	, [subtotal] = vtp2.subtotal
	, [impuesto] = vtp2.impuesto1
	, [idr] = vtp2.idr
	, [idtran] = vtp2.idtran
	, [idmov] = vtp2.idmov
	, [idmov2] = vtp2.idmov2
	, [comentario] = vtp2.comentario
	, [objidtran] = vtp2.idtran2
	, [saldo] = 0
	, [pagos] = 0
	, [poraplicar] = 0
	, [spa] = ''
FROM
	ew_ven_transacciones_pagos AS vtp2
WHERE
	vtp2.idtran = @idtran
GO
