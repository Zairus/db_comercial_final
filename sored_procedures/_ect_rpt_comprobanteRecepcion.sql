USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160616
-- Description:	Reporte de comprobante recibido
-- =============================================
ALTER PROCEDURE _ect_rpt_comprobanteRecepcion
	@uuid AS VARCHAR(50)
AS

SET NOCOUNT ON

SELECT
	ccr.idcomprobante
	,ccr.ruta_archivo
	,ccr.fecha
	,ccr.serie
	,ccr.folio
	,ccr.LugarExpedicion
	,ccr.Moneda
	,ccr.NumCtaPago
	,ccr.TipoCambio
	,ccr.certificado
	,ccr.condicionesDePago
	,ccr.formaDePago
	,ccr.metodoDePago
	,ccr.noCertificado
	,ccr.sello
	,ccr.tipoDeComprobante
	,ccr.[version]
	,ccr.subTotal
	,ccr.total
	,ccr.Regimen
	,ccr.Emisor_nombre
	,ccr.Emisor_rfc
	,ccr.Emisor_calle
	,ccr.Emisor_noExterior
	,ccr.Emisor_noInterior
	,ccr.Emisor_codigoPostal
	,ccr.Emisor_colonia
	,ccr.Emisor_estado
	,ccr.Emisor_localidad
	,ccr.Emisor_municipio
	,ccr.Emisor_pais
	,ccr.Receptor_nombre
	,ccr.Receptor_rfc
	,ccr.Receptor_calle
	,ccr.Receptor_noExterior
	,ccr.Receptor_noInterior
	,ccr.Receptor_codigoPostal
	,ccr.Receptor_colonia
	,ccr.Receptor_estado
	,ccr.Receptor_localidad
	,ccr.Receptor_pais
	,ccr.Timbre_FechaTimbrado
	,ccr.Timbre_UUID
	,ccr.Timbre_noCertificadoSAT
	,ccr.Timbre_selloCFD
	,ccr.Timbre_selloSAT
	,ccr.Timbre_version

	,ccrm.noIdentificacion
	,ccrm.descripcion
	,ccrm.unidad
	,ccrm.cantidad
	,ccrm.importe
	,ccrm.valorUnitario
FROM 
	ew_cfd_comprobantes_recepcion AS ccr
	LEFT JOIN ew_cfd_comprobantes_recepcion_mov AS ccrm
		ON ccrm.idcomprobante = ccr.idcomprobante
WHERE 
	ccr.Timbre_UUID = @uuid
GO
