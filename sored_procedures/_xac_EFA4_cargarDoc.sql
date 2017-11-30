USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160123
-- Description:	Cargar factura de notas de venta
-- =============================================
ALTER PROCEDURE [dbo].[_xac_EFA4_cargarDoc]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@codcliente_o AS VARCHAR(30)
	,@idcliente_o AS INT
	,@nombre_o AS VARCHAR(200)
	,@fecha_fact AS SMALLDATETIME

IF (SELECT COUNT(*) FROM (SELECT DISTINCT ct.idcliente FROM ew_cxc_transacciones_rel AS ctr LEFT JOIN ew_cxc_transacciones AS ct ON ct.idtran = ctr.idtran2 WHERE ctr.idtran = @idtran) AS d) > 1
BEGIN
	SELECT @codcliente_o = 'Todos'
	SELECT @idcliente_o = 0
	SELECT @nombre_o = 'Notas de todos los clientes'
END
	ELSE
BEGIN
	SELECT TOP 1
		@codcliente_o = c.codigo
		,@idcliente_o = c.idcliente
		,@nombre_o = c.nombre
	FROM
		ew_cxc_transacciones_rel AS ctr
		LEFT JOIN ew_cxc_transacciones AS ct
			ON ct.idtran = ctr.idtran2
		LEFT JOIN ew_clientes AS c
			ON c.idcliente = ct.idcliente
	WHERE
		ctr.idtran = @idtran
END

SELECT TOP 1
	@fecha_fact = ct.fecha
FROM
	ew_cxc_transacciones_rel AS ctr
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = ctr.idtran2
WHERE
	ctr.idtran = @idtran

SELECT
	[transaccion] = vt.transaccion
	,[idsucursal] = vt.idsucursal
	,[idalmacen] = vt.idalmacen
	,[codclientef1] = ''
	,[codcliente] = c.codigo
	,[idcliente] = vt.idcliente
	,[cliente] = c.nombre
	,[folio] = vt.folio
	,[fecha] = vt.fecha
	,[idu] = vt.idu
	,[xestado] = e.nombre
	,[cancelado] = vt.cancelado
	,[cancelado_fecha] = (CASE WHEN vt.cancelado = 0 THEN NULL ELSE vt.cancelado_fecha END)
	,[UUID] = cct.cfdi_UUID
	,[idr] = vt.idr
	,[idtran] = vt.idtran
	,[idmov] = vt.idmov
	,[spa] = ''
	,[subtotal] = vt.subtotal
	,[impuesto1] = vt.impuesto1
	,[impuesto2] = vt.impuesto2
	,[total] = vt.total
	,[comentario] = vt.comentario

	,[sys_cuenta] = dbo.fn_sys_obtenerDato('GLOBAL', 'EVOLUWARE_CUENTA')
	,[cliente_notif] = dbo._sys_fnc_parametroActivo('CFDI_NOTIFICAR_AUTOMATICO')
FROM
	ew_ven_transacciones AS vt
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_sys_Transacciones As st
		ON st.idtran = vt.idtran
	LEFT JOIN estados AS e
		ON e.idestado = st.idestado
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = vt.idtran
WHERE
	vt.idtran = @idtran
	
SELECT
	[transaccion] = ct.transaccion
	,[idsucursal] = ct.idsucursal
	,[tipo] = ct.tipo
	,[codcliente] = c.codigo
	,[idcliente] = ct.idcliente
	,[cliente] = c.nombre
	,[folio] = ct.folio
	,[fecha] = ct.fecha
	,[idu] = ct.idu
	,[cancelado] = ct.cancelado
	,[cancelado_fecha] = ct.cancelado_fecha
	,[idr] = ct.idr
	,[idtran] = ct.idtran
	,[idmov] = ct.idmov
	,[facturara] = cfa.razon_social
	,[rfc] = cfa.rfc
	,[direccion] = cfa.direccion1
	,[colonia] = cfa.colonia
	,[ciudad] = cd.ciudad
	,[estado] = cd.estado
	,[codigopostal] = cfa.codpostal
	,[idfacturacion] = ct.idfacturacion
	,[email] = cfa.email
	,[telefono1] = cfa.telefono1
	,[metodoDePago] = RTRIM(c.cfd_metodoDePago) + ' ' + RTRIM(c.cfd_NumCtaPago)
	
	,[codcliente_o] = @codcliente_o
	,[idcliente_o] = @idcliente_o
	,[nombre_o] = @nombre_o
	,[fecha_fact] = ISNULL(@fecha_fact, ct.fecha)
	,[fecha_fact1] = ISNULL(@fecha_fact, ct.fecha)
	,[formas] = ''
	,[spa] = ''

	,[subtotal] = ct.subtotal
	,[impuesto1] = ct.impuesto1
	,[impuesto2] = ct.impuesto2
	,[total] = ct.total
	,[comentario] = ct.comentario
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN ew_clientes_facturacion AS cfa
		ON cfa.idcliente = ct.idcliente
		AND cfa.idfacturacion = ct.idfacturacion
	LEFT JOIN ew_sys_ciudades AS cd
		ON cd.idciudad = cfa.idciudad
WHERE
	ct.idtran = @idtran

SELECT
	[referencia] = ct.idtran
	,[idtran2] = ctr.idtran2
	,[r_fecha] = ct.fecha
	,[r_folio] = ct.folio
	,[r_cliente] = c.nombre
	,[r_importe] = ct.subtotal
	,[r_impuesto1] = ct.impuesto1
	,[r_impuesto2] = ct.impuesto2
	,[r_total] = ct.total
	,[saldo] = ctr.saldo
	,[comentario] = ctr.comentario
	,[idr] = ctr.idr
	,[idtran] = ctr.idtran
	,[idmov] = ctr.idmov
	,[objidtran] = ctr.idtran2
	,[spa] = ''
FROM
	ew_cxc_transacciones_rel AS ctr
	LEFT JOIN ew_cxc_transacciones AS ct
		ON ct.idtran = ctr.idtran2
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
WHERE
	ctr.idtran = @idtran

SELECT
	[codarticulo] = a.codigo
	,[descripcion] = a.nombre
	,[cantidad_facturada] = vtm.cantidad_facturada
	,[precio_unitario] = vtm.precio_unitario
	,[importe] = vtm.importe
	,[impuesto1] = vtm.impuesto1
	,[impuesto2] = vtm.impuesto2
	,[total] = vtm.total
	,[comentario] = vtm.comentario
	,[spa] = ''
FROM
	ew_ven_transacciones_mov AS vtm
	LEFT JOIN ew_articulos AS a
		ON a.idarticulo = vtm.idarticulo
WHERE
	vtm.idtran = @idtran

SELECT
	[fechahora] = b.fechahora
	,[codigo] = b.codigo
	,[nombre] = b.nombre
	,[usuario_nombre] = b.usuario_nombre
	,[host] = b.host
	,[comentario] = b.comentario
FROM
	bitacora AS b
WHERE
	b.idtran = @idtran

/*
SELECT
	[cmd] = ',[' + oc.codigo + '] = '''''
FROM 
	objetos AS o
	LEFT JOIN objetos_grids AS og
		ON og.objeto = o.objeto
	LEFT JOIN objetos_columnas AS oc
		ON oc.objeto = o.objeto
		AND oc.grid = og.codigo
WHERE 
	o.objeto = 1384
	AND og.[tables] LIKE '%bitacora%'
ORDER BY
	og.orden
	,oc.orden
*/
GO
