USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160128
-- Description:	Cargar datos de calculo de comisiones
-- =============================================
CREATE PROCEDURE _xac_EPR1_cargarDoc
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[transaccion] = vt.transaccion
	,[folio] = vt.folio
	,[fecha] = vt.fecha
	,[vendf1] = ''
	,[vendedor] = v.nombre
	,[idvendedor] = vt.idvendedor
	,[vendedor_nombre] = v.nombre
	,[cancelado] = vt.cancelado
	,[cancelado_fecha] = vt.cancelado_fecha
	,[idu] = vt.idu
	,[idr] = vt.idr
	,[idtran] = vt.idtran
	,[idmov] = vt.idmov
	,[spa] = ''
	,[subtotal] = vt.subtotal
	,[comentario] = vt.comentario
FROM
	ew_ven_documentos AS vt
	LEFT JOIN ew_ven_vendedores AS v
		ON v.idvendedor = vt.idvendedor
WHERE
	vt.idtran = @idtran

SELECT
	[consecutivo] = vdm.consecutivo
	,[fecha] = vt.fecha
	,[folio] = vt.folio
	,[cliente] = c.nombre + ' [' + c.codigo + ']'
	,[idarticulo] = vtm.idarticulo
	,[codarticulo] = a.codigo
	,[articulo] = a.nombre
	,[cantidad_surtida] = vdm.cantidad_surtida
	,[precio_unitario] = vdm.precio_unitario
	,[importe] = vdm.importe
	,[importe_pagado] = vdm.importe_pagado
	,[comision_porcentaje] = vdm.comision_porcentaje
	,[comision_importe_prev] = vdm.comision_importe_prev
	,[comision_pago_anterior] = vdm.comision_pago_anterior
	,[comision_importe] = vdm.comision_importe
	,[fecha_referencia] = vdm.fecha_referencia
	,[comentario] = vdm.comentario
	,[idtran2] = vtm.idtran
	,[idmov2] = vdm.idmov2
	,[idr] = vdm.idr
	,[idtran] = vdm.idtran
	,[idmov] = vdm.idmov
	,[spa] = ''
FROM
	ew_ven_documentos_mov AS vdm
	LEFT JOIN ew_ven_comisiones_datos1 AS vtm
		ON vtm.idmov = vdm.idmov2
	LEFT JOIN ew_ven_transacciones AS vt
		ON vt.idtran = vtm.idtran
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
WHERE
	vdm.idtran = @idtran
GO
