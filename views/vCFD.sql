USE db_comercial_final
GO
ALTER VIEW [dbo].[vCFD]
AS
SELECT
	c.idr
	, c.idtran
	, c.idsucursal
	, [version] = c.cfd_version
	, [folio] = c.cfd_folio
	, [serie] = c.cfd_serie
	, [fecha] = c.cfd_fecha
	, [noAprobacion] = c.xcfd_noAprobacion
	, c.xcfd_anoAprobacion AS añoAprobacion
	, [formaDePago] = c.cfd_formaDePago
	, [condicionesDePago] = c.cdf_condicionesDePago
	, [metodoDePago] = ISNULL((
		SELECT TOP 1 '[' + bf.codigo + '] ' + bf.nombre 
		FROM 
			ew_ban_formas AS bf 
		WHERE
			bf.codigo = c.cfd_metodoDePago
	), ISNULL(
		dbo.fn_ban_formasDePagoTexto(c.cfd_metodoDePago)
		, c.cfd_metodoDePago)
	)
	,[NumCtaPago]=c.cfd_NumCtaPago
	, [tipoDeComprobante] = c.cfd_tipoDeComprobante
	, [subtotal] = c.cfd_subTotal
	, [descuento] = c.xcfd_descuento
	, [motivoDescuento] = c.cfd_motivoDescuento
	, [total] = c.cfd_total
	, [ivaTrasladoTasa] = ISNULL(ivat.cfd_tasa, 0)
	, [ivaTrasladoImporte] = ISNULL(ivat.cfd_importe, 0)
	
	, [iepsTrasladoTasa] = ISNULL((
		SELECT
			SUM(iepst.cfd_importe)
		FROM 
			dbo.ew_cfd_comprobantes_impuesto AS iepst
		WHERE
			iepst.idtran = c.idtran
			AND iepst.idtipo = 1
			AND iepst.cfd_impuesto = 'IEPS'
	), 0) / c.cfd_subTotal
	, [iepsTrasladoImporte] = ISNULL((
		SELECT
			SUM(iepst.cfd_importe)
		FROM 
			dbo.ew_cfd_comprobantes_impuesto AS iepst
		WHERE
			iepst.idtran = c.idtran
			AND iepst.idtipo = 1
			AND iepst.cfd_impuesto = 'IEPS'
	), 0)

	, [ivaRetenidoTasa] = ISNULL(ivar.cfd_tasa, 0)
	, [IvaRetenidoImporte] = ISNULL(ivar.cfd_importe, 0)
	, [isrRetenidoTasa] = ISNULL(isrr.cfd_tasa, 0)
	, [IsrRetenidoImporte] = ISNULL(isrr.cfd_importe, 0)
	, [emisorRfc] = c.rfc_emisor
	, [emisorNombre] = ce.cfd_nombre
	, [emisorDomicilio_Calle] = ced.cfd_calle
	, [emisorDomicilio_NoExterior] = ced.cfd_noExterior
	, [emisorDomicilio_NoInterior] = ced.cfd_noInterior
	, [emisorDomicilio_Colonia] = ced.cfd_colonia
	, [emisorDomicilio_Localidad] = ced.cfd_localidad
	, [emisorDomicilio_Referencia] = ced.cfd_referencia
	, [emisorDomicilio_Municipio] = ced.cfd_municipio
	, [emisorDomicilio_Estado] = ced.cfd_estado
	, [emisorDomicilio_Pais] = ced.cfd_pais
	, [emisorDomicilio_CodigoPostal] = ced.cfd_codigoPostal
	, [emisorExpedidoEn_Calle] = cee.cfd_calle
	, [emisorExpedidoEn_NoExterior] = cee.cfd_noExterior
	, [emisorExpedidoEn_NoInterior] = cee.cfd_noInterior
	, [emisorExpedidoEn_Colonia] = cee.cfd_colonia
	, [emisorExpedidoEn_Localidad] = cee.cfd_localidad
	, [emisorTelefono1] = cfe.telefono1
	, [emisorTelefono2] = cfe.telefono2
	, [emisorExpedidoEn_Referencia] = cee.cfd_referencia
	, [emisorExpedidoEn_Municipio] = cee.cfd_municipio
	, [emisorExpedidoEn_Estado] = cee.cfd_estado
	, [emisorExpedidoEn_Pais] = cee.cfd_pais
	, [emisorExpedidoEn_CodigoPostal] = cee.cfd_codigoPostal
	, [receptor_rfc] = c.rfc_receptor
	, [receptor_nombre] = cfr.razon_social
	, [receptorDomicilio_Calle] = crd.cfd_calle
	, [receptorDomicilio_NoExterior] = crd.cfd_noExterior
	, [receptorDomicilio_NoInterior] = crd.cfd_noInterior
	, [receptorDomicilio_Colonia] = crd.cfd_colonia
	, [receptorDomicilio_Localidad] = crd.cfd_localidad
	, [receptorDomicilio_Referencia] = crd.cfd_referencia
	, [telefono1] = cfr.telefono1
	, [telefono2] = cfr.telefono2
	, [receptorDomicilio_Municipio] = crd.cfd_municipio
	, [receptorDomicilio_Estado] = crd.cfd_estado
	, [receptorDomicilio_Pais] = crd.cfd_pais
	, [receptorDomicilio_CodigoPostal] = crd.cfd_codigoPostal
	, [noCertificado] = c.cfd_noCertificado
	, [certificado] = cs.cfd_certificado
	, [sello] = cs.cfd_sello
	, [cadenaOriginal] = cs.cadenaOriginal
	, [cantidad_letra] = dbo.fnNum2Letra(c.cfd_total, vt.idmoneda)
FROM
	dbo.ew_cfd_comprobantes AS c 
	LEFT JOIN dbo.ew_cfd_comprobantes_sello AS cs 
		ON cs.idtran = c.idtran 

	LEFT OUTER JOIN dbo.ew_cfd_comprobantes_impuesto AS ivat 
		ON ivat.idtran = c.idtran AND ivat.idtipo = 1 AND ivat.cfd_impuesto = 'IVA'
	LEFT OUTER JOIN dbo.ew_cfd_comprobantes_impuesto AS ivar 
		ON ivar.idtran = c.idtran AND ivar.idtipo = 2 AND ivar.cfd_impuesto = 'IVA'
	LEFT OUTER JOIN dbo.ew_cfd_comprobantes_impuesto AS isrr 
		ON isrr.idtran = c.idtran AND isrr.idtipo = 2 AND isrr.cfd_impuesto = 'ISR' 
	LEFT OUTER JOIN dbo.ew_cfd_rfc AS ce ON ce.cfd_rfc = c.rfc_emisor
	LEFT OUTER JOIN dbo.ew_cfd_comprobantes_ubicacion AS ced 
		ON ced.idtran = c.idtran AND ced.idtipo = 1 AND ced.ubicacion = 'domicilioFiscal' 
	LEFT OUTER JOIN dbo.ew_cfd_comprobantes_ubicacion AS cee 
		ON cee.idtran = c.idtran AND cee.idtipo = 1 AND cee.ubicacion = 'expedidoEn' 
	LEFT OUTER JOIN dbo.ew_cfd_rfc AS cr ON cr.cfd_rfc = c.rfc_receptor 
	LEFT OUTER JOIN dbo.ew_cfd_comprobantes_ubicacion AS crd 
		ON crd.idtran = c.idtran AND crd.idtipo = 2 AND crd.ubicacion = 'domicilio' 
	LEFT OUTER JOIN dbo.vew_clientes AS cfe 
		ON cfe.rfc = c.rfc_emisor 
	LEFT OUTER JOIN dbo.ew_cxc_transacciones AS vt 
		ON vt.idtran = c.idtran 
	LEFT OUTER JOIN dbo.vew_clientes AS cfr 
		ON cfr.idcliente = vt.idcliente
GO
