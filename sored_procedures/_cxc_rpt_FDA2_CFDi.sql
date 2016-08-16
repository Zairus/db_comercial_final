USE db_comercial_final
GO
-- =============================================
-- Author:		Fernanda Corona
-- Create date: 2011 Julio
-- Description:	Reporte WEB Nota de Crédito Electronica
-- Ejemplo : EXEC _CXC_rpt_FDA2_CFDi 25063
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_rpt_FDA2_CFDi]
	@idtran AS INT
AS

SET NOCOUNT ON

SELECT
	folio=d.serie+dbo.fnRellenar(d.folio,5,0)
	,d.fecha
	,d.formaDePago
	,emisor=d.emisorNombre
	,d.emisorRfc
	,dir_emisor= d.emisorDomicilio_Calle + ' ' + d.emisorDomicilio_NoExterior + ' - ' +
				d.emisorDomicilio_NoInterior + ' C.P '+ d.emisorDomicilio_CodigoPostal + ' Col.' +
				d.emisorDomicilio_Colonia
	,local_emi= d.emisorDomicilio_Localidad + ', ' + d.emisorDomicilio_Estado + ' , '+ d.emisorDomicilio_Pais
	,tel_emi= d.emisorTelefono1 + ' ' + d.emisorTelefono2
	,d.noAprobacion
	,d.añoAprobacion
	,d.noCertificado

	,receptor=d.receptor_nombre
	,d.receptor_rfc
	,dir_receptor= d.receptorDomicilio_Calle + ' ' + d.receptorDomicilio_NoExterior + ' - ' +
				d.receptorDomicilio_NoInterior + ' C.P '+ d.receptorDomicilio_CodigoPostal + ' Col.' +
				d.receptorDomicilio_Colonia
	,local_receptor= d.receptorDomicilio_Localidad + ', ' + d.receptorDomicilio_Estado + ' , '+ d.receptorDomicilio_Pais
	,tel_receptor=d.telefono1 + ' ' + d.telefono2
	,m.orden
	,m.cantidad
	,m.unidad
	,m.codigo
	,m.descripcion
	,comentario_detalle = ''
	,m.valorUnitario
	,m.importe
	,d.subtotal
	
	,d.ivaTrasladoTasa
	,d.ivaTrasladoImporte
	,d.IvaRetenidoImporte
	
	,d.iepsTrasladoTasa
	,d.iepsTrasladoImporte

	,d.total
--	,total_letra=dbo.fnNum2Letra(d.total, d.idmoneda)
	,total_letra=d.cantidad_letra
	,comentario_doc=doc.comentario
	,d.sello
------------------------------------
-- Inicia Cambios para CFDI	
------------------------------------
	--,d.cadenaOriginal	
	,[cadenaOriginal]=cfdi.cfdi_cadenaOriginal
	,[FechaTimbrado]=cfdi.cfdi_FechaTimbrado
	,[UUID]=cfdi.cfdi_UUID
	,[noCertificadoSAT]=cfdi.cfdi_noCertificadoSAT
	,[selloDigitalSAT]=cfdi.cfdi_selloDigital
	,[QRCode]=cfdi.QRCode

	,[RegimenFiscal]=(SELECT TOP 1 regimenfiscal FROM ew_cfd_parametros)
	,[LugarExpedicion]=ISNULL(cd.ciudad,'MEXICO') + ', ' + ISNULL(cd.estado,'')	

------------------------------------
-- Finaliza Cambios para CFDI	
------------------------------------
	
FROM 
	vCFD d
	LEFT JOIN vCFDMov m ON m.idtran = d.idtran
	LEFT JOIN ew_cxc_transacciones doc ON doc.idtran=d.idtran
	LEFT JOIN ew_clientes_facturacion sss ON sss.idcliente=0 AND sss.idfacturacion=doc.idsucursal
-- Cambios CFDI
	LEFT JOIN ew_cfd_comprobantes_timbre cfdi ON cfdi.idtran=d.idtran
	LEFT JOIN ew_sys_ciudades cd ON cd.idciudad=sss.idciudad
WHERE
	RIGHT(m.orden,1)='0'
	AND d.idtran=@idtran
order by 
	m.orden
GO
