USE db_comercial_final
GO
ALTER PROCEDURE [dbo].[_ven_rpt_comisionCalculoConsulta]
	@idtran AS INT
AS

SET NOCOUNT ON

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
	,[idtran] = vtm.idtran
	,[objidtran] = vtm.idtran
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
