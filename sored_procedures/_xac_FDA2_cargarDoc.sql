USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160523
-- Description:	Cargar nota de credito
-- =============================================
ALTER PROCEDURE _xac_FDA2_cargarDoc
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	[transaccion] = ct.transaccion
	,[idsucursal] = ct.idsucursal
	,[cliente_codigo] = c.codigo
	,[idcliente] = ct.idcliente
	,[referencia] = ISNULL(st.folio, '')
	,[idtran2] = ct.idtran2
	,[idconcepto] = ct.idconcepto
	,[concepto_nombre] = con.nombre
	,[concepto_cuenta] = oc.contabilidad
	,[fecha] = ct.fecha
	,[folio] = ct.folio
	,[estado] = e.nombre
	,[idu] = ct.idu
	,[tipo] = ct.tipo
	,[idr] = ct.idr
	,[idtran] = ct.idtran
	,[idmov] = ct.idmov
	,[cliente_nombre] = c.nombre
	,[cliente_rfc] = cfa.rfc
	,[cliente_direccion] = cfa.calle
	,[cliente_ciudad] = cfa.ciudad
	,[cliente_estado] = cfa.estado
	,[cliente_cp] = cfa.codpostal
	,[cliente_email] = cfa.email
	,[idmoneda] = ct.idmoneda
	,[tipocambio] = ct.tipocambio
	,[spa] = ''
	,[doc_subtotal] = ct2.subtotal
	,[doc_impuesto1] = ct2.impuesto1
	,[doc_impuesto2] = ct2.impuesto2
	,[doc_impuesto3] = ct2.impuesto3
	,[doc_impuesto4] = ct2.impuesto4
	,[doc_impuesto1_ret] = ct2.impuesto1_ret
	,[doc_impuesto2_ret] = ct2.impuesto2_ret
	,[doc_total] = ct2.total
	,[subtotal] = ct.subtotal
	,[impuesto1] = ct.impuesto1
	,[impuesto2] = ct.impuesto2
	,[impuesto3] = ct.impuesto3
	,[impuesto4] = ct.impuesto4
	,[impuesto1_ret] = ct.impuesto1_ret
	,[impuesto2_ret] = ct.impuesto2_ret
	,[total] = ct.total
	,[saldo] = ct.saldo
	,[comentario] = ct.comentario
FROM
	ew_cxc_transacciones AS ct
	LEFT JOIN ew_clientes AS c
		ON c.idcliente = ct.idcliente
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN db_comercial.dbo.evoluware_objetos_conceptos AS oc
		ON oc.objeto = o.objeto
		AND oc.idconcepto = ct.idconcepto
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = ct.idtran2
	LEFT JOIN conceptos AS con
		ON con.idconcepto = ct.idconcepto

	LEFT JOIN ew_sys_transacciones AS st1
		ON st1.idtran = ct.idtran
	LEFT JOIN estados AS e
		ON e.idestado =  st1.idestado

	LEFT JOIN ew_cxc_transacciones AS ct2
		ON ct2.idtran = ct.idtran2

	CROSS APPLY (
		SELECT TOP 1 
			cfa.rfc
			, cfa.calle 
			, cd.ciudad
			, cd.estado
			, cfa.codpostal
			, cfa.email
		FROM 
			ew_clientes_facturacion AS cfa 
			LEFT JOIN ew_sys_ciudades As cd
				ON cd.idciudad = cfa.idciudad
		WHERE 
			cfa.idcliente = c.idcliente
	) AS cfa
WHERE
	ct.idtran = @idtran

SELECT
	[consecutivo] = ctm.consecutivo
	,[idtran2] = ctm.idtran2
	,[ref_folio] = f.folio
	,[ref_fecha] = f.fecha
	,[idmoneda] = f.idmoneda
	,[tipocambio] = ctm.tipocambio
	,[r_subtotal] = f.subtotal
	,[r_impuesto1] = f.impuesto1
	,[r_impuesto2] = f.impuesto2
	,[r_impuesto3] = f.impuesto3
	,[r_impuesto4] = f.impuesto4
	,[r_impuesto1_ret] = f.impuesto1_ret
	,[r_impuesto2_ret] = f.impuesto2_ret
	,[r_total] = f.total
	,[r_saldo] = f.saldo
	,[importe] = ctm.importe
	,[importe2] = ctm.importe2
	,[saldo] = f.saldo - ctm.importe2
	,[subtotal] = ctm.subtotal
	,[impuesto1] = ctm.impuesto1
	,[impuesto2] = ctm.impuesto2
	,[impuesto3] = ctm.impuesto3
	,[impuesto4] = ctm.impuesto4
	,[impuesto1_ret] = ctm.impuesto1_ret
	,[impuesto2_ret] = ctm.impuesto2_ret
	,[idu] = ctm.idu
	,[comentario] = ctm.comentario
FROM
	ew_cxc_transacciones_mov AS ctm
	LEFT JOIN ew_cxc_transacciones AS f
		ON f.idtran = ctm.idtran2
WHERE
	ctm.idtran = @idtran

SELECT
	[objidtran] = c.objidtran
	,[idtran2] = c.idtran2
	,[consecutivo] = c.consecutivo
	,[fecha] = c.fecha
	,[tipo_nombre] = c.tipo_nombre
	,[folio] = c.folio
	,[referencia] = c.referencia
	,[cuenta] = c.cuenta
	,[cuenta_nombre] = c.cuenta_nombre
	,[cargos] = c.cargos
	,[abonos] = c.abonos
	,[concepto] = c.concepto
FROM
	contabilidad AS c
WHERE
	c.idtran2 = @idtran

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
GO
