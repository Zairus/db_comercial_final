USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180310
-- Description:	Referencia de orden de venta a factura
-- =============================================
ALTER PROCEDURE _ven_prc_ordenReferenciaDocumento
	@referencia AS VARCHAR(15)
	,@idsucursal AS INT
AS

SET NOCOUNT ON

SELECT TOP 1
	[referencia] = @referencia
	,[idtran2] = ew_ven_ordenes.idtran
	,[idsucursal] = ew_ven_ordenes.idsucursal
	,[idalmacen] = ew_ven_ordenes.idalmacen
	,[codcliente] = c.codigo
	,[idcliente] = ew_ven_ordenes.idcliente
	,[cliente] = c.nombre
	,[telefono1] = cf.telefono1
	,[telefono2] = cf.telefono2
	,[idcontacto] = ew_ven_ordenes.idcontacto
	,[horario] = cc.horario
	,[contacto_telefono] = ''
	,[contacto_email] = ''
	,[comentario] = ew_ven_ordenes.comentario
	,[idmoneda] = ew_ven_ordenes.idmoneda
	,[tipocambio] = ew_ven_ordenes.tipocambio
	,[tipocambio_dof] = dbo.fn_ban_obtenerTC(ew_ven_ordenes.idmoneda, GETDATE())
	,[forma_moneda] = c.idmoneda
	,[forma_tipoCambio] = dbo.fn_ban_tipocambio (c.idmoneda,0)	
	,[idimpuesto1] = ew_ven_ordenes.idimpuesto1
	,[idimpuesto1_valor] = imp.valor
	,[idimpuesto1_cuenta] = imp.contabilidad
	,[idimpuesto1_ret] = ew_ven_ordenes.idimpuesto1_ret
	,[IVA] = (imp.valor/.01)
	,[idlista] = ew_ven_ordenes.idlista
	,[idmedioventa] = ew_ven_ordenes.idmedioventa
	,[dias_entrega] = ew_ven_ordenes.dias_entrega
	,[t_credito] = ct.credito
	,[credito] = CONVERT(TINYINT,ew_ven_ordenes.credito)
	,[credito_plazo] = ew_ven_ordenes.credito_plazo
	,[cliente_limite] = ct.credito_limite
	,[cliente_saldo] = csa.saldo
	,[cliente_credito] = (CASE WHEN ( (ISNULL(ct.credito_limite, 0) - ISNULL(csa.saldo, 0))) < 0 THEN 0 ELSE (ISNULL(ct.credito_limite, 0) - ISNULL(csa.saldo, 0)) END)
	,[idfacturacion] = ew_ven_ordenes.idfacturacion
	,[facturara]= cf.razon_social
	,cf.rfc
	,[direccion] = cf.calle
	,[colonia] = cf.colonia
	,[ciudad] = fac.ciudad
	,[estado] = fac.estado
	,[codigopostal] = cf.codpostal
	,[email] = cf.email
	,[idvendedor] = v.idvendedor
	,[vendedor] = v.nombre
	,total_ap = (total-impuesto1_ret)
	,cf.contabilidad
	,p.dias_pp1
	,p.dias_pp2
	,p.dias_pp3

	,c.cfd_iduso
	,idforma=CASE WHEN ew_ven_ordenes.credito=1 THEN (SELECT TOP 1 ISNULL(idforma,0) FROM ew_ban_formas_aplica WHERE codigo='99') ELSE c.idforma END
	,idmetodo=CASE WHEN ew_ven_ordenes.credito=1 THEN 2 ELSE 1 END
FROM 
	ew_ven_ordenes
	LEFT JOIN ew_clientes AS c ON c.idcliente = ew_ven_ordenes.idcliente
	LEFT JOIN ew_clientes_contactos AS cc ON cc.idcliente = ew_ven_ordenes.idcliente AND cc.idcontacto = ew_ven_ordenes.idcontacto 
	LEFT JOIN ew_clientes_terminos AS ct ON ct.idcliente = ew_ven_ordenes.idcliente
	LEFT JOIN ew_sys_sucursales AS s ON s.idsucursal = ew_ven_ordenes.idsucursal
	LEFT JOIN ew_cxc_saldos_actual AS csa ON csa.idcliente = ew_ven_ordenes.idcliente AND csa.idmoneda = ew_ven_ordenes.idmoneda
	LEFT JOIN ew_clientes_facturacion AS cf ON cf.idcliente = ew_ven_ordenes.idcliente AND cf.idfacturacion = ew_ven_ordenes.idfacturacion
	LEFT JOIN ew_clientes_ubicaciones AS cu ON cu.idcliente = ew_ven_ordenes.idcliente AND cu.idubicacion = ew_ven_ordenes.idubicacion
	LEFT JOIN ew_cat_impuestos imp ON imp.idimpuesto = ew_ven_ordenes.idimpuesto1
	LEFT JOIN ew_sys_ciudades fac ON fac.idciudad = cf.idciudad
	LEFT JOIN ew_ven_vendedores v ON v.idvendedor = ew_ven_ordenes.idvendedor
	LEFT JOIN ew_ven_politicas p ON p.idpolitica=ct.idpolitica
WHERE
	ew_ven_ordenes.cancelado = 0
	AND ew_ven_ordenes.transaccion = 'EOR1'
	AND ew_ven_ordenes.idsucursal = @idsucursal
	AND ew_ven_ordenes.folio IN (
		SELECT r.valor 
		FROM dbo._sys_fnc_separarMultilinea(@referencia, '	') AS r
	)
GO
