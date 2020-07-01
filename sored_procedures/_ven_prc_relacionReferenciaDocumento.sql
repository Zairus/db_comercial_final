USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_relacionReferenciaDocumento') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_relacionReferenciaDocumento
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180310
-- Description:	Referencia de orden de venta a factura
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_relacionReferenciaDocumento]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT TOP 1
	[referencia] = vt.folio
	, [idtran2] = vt.idtran
	, [idsucursal] = vt.idsucursal
	, [idalmacen] = vt.idalmacen
	, [codcliente] = c.codigo
	, [idcliente] = vt.idcliente
	, [cliente] = c.nombre
	, [telefono1] = cf.telefono1
	, [telefono2] = cf.telefono2
	, [idcontacto] = vt.idcontacto
	, [horario] = cc.horario
	, [contacto_telefono] = ''
	, [contacto_email] = ''
	, [comentario] = vt.comentario
	, [idmoneda] = vt.idmoneda
	, [tipocambio] = vt.tipocambio
	, [tipocambio_dof] = dbo.fn_ban_obtenerTC(vt.idmoneda, GETDATE())
	, [forma_moneda] = vt.idmoneda
	, [forma_tipoCambio] = dbo.fn_ban_tipocambio (c.idmoneda, 0)	
	, [idimpuesto1] = ctran.idimpuesto1
	, [idimpuesto1_valor] = ctran.idimpuesto1_valor
	, [idimpuesto1_cuenta] = imp.contabilidad
	, [idimpuesto1_ret] = ctran.idimpuesto1_ret
	, [IVA] = (imp.valor / 0.01)
	, [idlista] = vt.idlista
	, [idmedioventa] = vt.idmedioventa
	, [dias_entrega] = 0
	, [t_credito] = ctran.credito
	, [credito] = CONVERT(INT, vt.credito)
	, [credito_plazo] = vt.credito_plazo
	, [cliente_limite] = ct.credito_limite
	, [cliente_saldo] = csa.saldo
	, [cliente_credito] = (
		CASE 
			WHEN ((ISNULL(ct.credito_limite, 0) - ISNULL(csa.saldo, 0))) < 0 THEN 0 
			ELSE (ISNULL(ct.credito_limite, 0) - ISNULL(csa.saldo, 0)) 
		END
	)
	, [idfacturacion] = vt.idfacturacion
	, [facturara]= cf.razon_social
	, [rfc] = cf.rfc
	, [direccion] = cf.calle
	, [colonia] = cf.colonia
	, [ciudad] = fac.ciudad
	, [estado] = fac.estado
	, [codigopostal] = cf.codpostal
	, [email] = cf.email
	, [idvendedor] = vt.idvendedor
	, [vendedor] = v.nombre
	, [total_ap] = (vt.total - vt.impuesto1_ret)
	, [contabilidad] = cf.contabilidad
	, [dias_pp1] = p.dias_pp1
	, [dias_pp2] = p.dias_pp2
	, [dias_pp3] = p.dias_pp3

	, [cfd_iduso] = ctran.cfd_iduso
	, [idforma] = ISNULL(
		NULLIF(vt.idforma, 0)
		, (
			CASE 
				WHEN ctran.credito = 1 THEN (
					SELECT TOP 1 
						bfa.idforma 
					FROM 
						ew_ban_formas_aplica AS bfa 
					WHERE 
						bfa.codigo = '99'
				)
				ELSE 0 
			END
		)
	)
	, [idmetodo] = (
		CASE 
			WHEN ctran.credito = 1 THEN 2 
			ELSE 1 
		END
	)

	, [saldoAfavor] = (
		SELECT 
			ISNULL(SUM(ct.saldo), 0) 
		FROM 
			ew_cxc_transacciones AS ct
		WHERE
			ct.cancelado = 0 
			AND ct.tipo = 2 
			AND ct.saldo > 0 
			AND ct.idcliente = vt.idcliente
	)
	, [cliente_notif] = dbo.fn_sys_parametro('CFDI_NOTIFICAR_AUTOMATICO')
FROM 
	ew_ven_transacciones AS vt
	LEFT JOIN ew_cxc_transacciones AS ctran
		ON ctran.idtran = vt.idtran
	LEFT JOIN ew_clientes AS c 
		ON c.idcliente = vt.idcliente
	LEFT JOIN ew_clientes_contactos AS cc 
		ON cc.idcliente = vt.idcliente 
		AND cc.idcontacto = vt.idcontacto 
	LEFT JOIN ew_clientes_terminos AS ct 
		ON ct.idcliente = vt.idcliente
	LEFT JOIN ew_sys_sucursales AS s 
		ON s.idsucursal = vt.idsucursal
	LEFT JOIN ew_cxc_saldos_actual AS csa 
		ON csa.idcliente = vt.idcliente 
		AND csa.idmoneda = vt.idmoneda
	LEFT JOIN ew_clientes_facturacion AS cf 
		ON cf.idcliente = vt.idcliente 
		AND cf.idfacturacion = vt.idfacturacion
	LEFT JOIN ew_clientes_ubicaciones AS cu 
		ON cu.idcliente = vt.idcliente 
		AND cu.idubicacion = 0 --vt.idubicacion
	LEFT JOIN ew_cat_impuestos AS imp 
		ON imp.idimpuesto = 1 --vt.idimpuesto1
	LEFT JOIN ew_sys_ciudades AS fac 
		ON fac.idciudad = cf.idciudad
	LEFT JOIN ew_ven_vendedores AS v 
		ON v.idvendedor = vt.idvendedor
	LEFT JOIN ew_ven_politicas AS p 
		ON p.idpolitica = ct.idpolitica
WHERE
	vt.cancelado = 0
	AND vt.idtran = @idtran
GO
