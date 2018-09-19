USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180914
-- Description:	Lectura de XML individual
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_saldoLeerXML]
	@ruta AS VARCHAR(MAX)
AS

SET NOCOUNT ON

DECLARE
	@contenido AS VARCHAR(MAX)
	,@cxc_xml AS XML
	,@idcliente AS INT
	,@cliente_codigo AS VARCHAR(30)

DECLARE
	@valor AS VARCHAR(MAX)

	--/cfdi:Comprobante/
	,@Version AS VARCHAR(10)
	,@Fecha AS DATETIME
	,@Total AS DECIMAL(18,6)
	,@TipoDeComprobante AS VARCHAR(4)
	,@SubTotal AS DECIMAL(18,6)
	,@Serie AS VARCHAR(50)
	,@Sello AS VARCHAR(MAX)
	,@NoCertificado AS VARCHAR(100)
	,@Moneda AS VARCHAR(20)
	,@MetodoPago AS VARCHAR(100)
	,@LugarExpedicion AS VARCHAR(500)
	,@FormaPago AS VARCHAR(50)
	,@Folio AS VARCHAR(100)
	,@CondicionesDePago AS VARCHAR(500)
	,@Certificado AS VARCHAR(MAX)

	--/cfdi:Comprobante/cfdi:Emisor/
	,@EmisorRfc AS VARCHAR(20)
	,@EmisorRegimenFiscal AS VARCHAR(50)
	,@EmisorNombre AS VARCHAR(500)

	--/cfdi:Comprobante/cfdi:Receptor/
	,@ReceptorRfc AS VARCHAR(20)
	,@ReceptorNombre AS VARCHAR(500)
	,@ReceptorUsoCFDI AS VARCHAR(20)

	--/cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/
	,@ValorUnitario AS DECIMAL(18,6)
	,@NoIdentificacion AS VARCHAR(MAX)
	,@Importe AS DECIMAL(18,6)
	,@Descripcion AS VARCHAR(MAX)
	,@ClaveUnidad AS VARCHAR(200)
	,@ClaveProdServ AS VARCHAR(200)
	,@Cantidad AS DECIMAL(18,6)

	--/cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital/
	,@UUID AS VARCHAR(50)

SELECT @contenido = [dbEVOLUWARE].[dbo].[txt_read](@ruta)
SELECT @contenido = REPLACE(@contenido, 'encoding="utf-8"', '')

SELECT @cxc_xml = CONVERT(XML, @contenido)

;WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' AS cfdi)
SELECT @Version = @cxc_xml.value('(/cfdi:Comprobante/@Version)[1]', 'VARCHAR(MAX)')

IF @Version IS NULL
BEGIN
	;WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' AS cfdi)
	SELECT @Version = @cxc_xml.value('(/cfdi:Comprobante/@version)[1]', 'VARCHAR(MAX)')
END

IF @Version IS NULL
BEGIN
	PRINT 'No es un comprobante fiscal.'
	RETURN
END

IF @Version = '3.3'
BEGIN
	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@Fecha', @valor OUTPUT
	SELECT @Fecha = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@Total', @valor OUTPUT
	SELECT @Total = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@TipoDeComprobante', @valor OUTPUT
	SELECT @TipoDeComprobante = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@SubTotal', @valor OUTPUT
	SELECT @SubTotal = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@Serie', @valor OUTPUT
	SELECT @Serie = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@Sello', @valor OUTPUT
	SELECT @Sello = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@NoCertificado', @valor OUTPUT
	SELECT @NoCertificado = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@Moneda', @valor OUTPUT
	SELECT @Moneda = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@MetodoPago', @valor OUTPUT
	SELECT @MetodoPago = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@LugarExpedicion', @valor OUTPUT
	SELECT @LugarExpedicion = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@FormaPago', @valor OUTPUT
	SELECT @FormaPago = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@Folio', @valor OUTPUT
	SELECT @Folio = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@CondicionesDePago', @valor OUTPUT
	SELECT @CondicionesDePago = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@Certificado', @valor OUTPUT
	SELECT @Certificado = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/cfdi:Emisor/@Rfc', @valor OUTPUT
	SELECT @EmisorRfc = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/cfdi:Emisor/@RegimenFiscal', @valor OUTPUT
	SELECT @EmisorRegimenFiscal = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/cfdi:Emisor/@Nombre', @valor OUTPUT
	SELECT @EmisorNombre = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/cfdi:Receptor/@Rfc', @valor OUTPUT
	SELECT @ReceptorRfc = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/cfdi:Receptor/@Nombre', @valor OUTPUT
	SELECT @ReceptorNombre = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/cfdi:Receptor/@UsoCFDI', @valor OUTPUT
	SELECT @ReceptorUsoCFDI = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital/@UUID', @valor OUTPUT
	SELECT @UUID = @valor

	--;WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' AS cfdi)
	--SELECT @cxc_xml.query('/cfdi:Comprobante/cfdi:Conceptos')

	/*
	SELECT
		x.c.value('(/cfdi:Comprobante/@Version)[1]', 'VARCHAR(MAX)')
	FROM a a
	CROSS APPLY @cxc_xml.nodes('/cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto') x(c)
	*/
END
	ELSE
BEGIN
	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@fecha', @valor OUTPUT
	SELECT @Fecha = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/cfdi:Receptor/@rfc', @valor OUTPUT
	SELECT @ReceptorRfc = @valor

	SELECT @Moneda = 'MXN'

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/cfdi:Receptor/@nombre', @valor OUTPUT
	SELECT @ReceptorNombre = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@total', @valor OUTPUT
	SELECT @Total = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/@subTotal', @valor OUTPUT
	SELECT @SubTotal = @valor

	EXEC _ct_prc_valorCampoXML @cxc_xml, '/cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital/@UUID', @valor OUTPUT
	SELECT @UUID = @valor
END

SELECT
	@idcliente = c.idcliente
	,@cliente_codigo = c.codigo
FROM
	vew_clientes AS c
WHERE
	c.rfc = @ReceptorRfc

IF @idcliente IS NULL
BEGIN
	SELECT @idcliente = MAX(idcliente) FROM ew_clientes
	SELECT @idcliente = ISNULL(@idcliente, 0) + 1

	INSERT INTO ew_clientes (
		idcliente
		, codigo
		, nombre
		, nombre_corto
		, idforma
		, cfd_iduso
	)
	SELECT
		[idcliente] = @idcliente
		, [codigo] = @ReceptorRfc
		, [nombre] = @ReceptorNombre
		, [nombre_corto] = LEFT(@ReceptorNombre, 5)
		, [idforma] = 1
		, [cfd_iduso] = 3

	INSERT INTO ew_clientes_facturacion (
		idcliente
		, razon_social
		, rfc
		, email
	)
	SELECT
		[idcliente] = @idcliente
		, [razon_social] = @ReceptorNombre
		, [rfc] = @ReceptorRfc
		, [email] = dbo._sys_fnc_parametroTexto('EMAIL_CUENTA')

	SELECT @cliente_codigo = @ReceptorRfc
END

INSERT INTO ew_cxc_migracion (
	folio
	, fecha
	, idcliente
	, codcliente
	, vencimiento
	, idmoneda
	, saldo
	, importe
	, impuesto1
	, impuesto2
	, idsucursal
	, UUID
	, idtran
	, cfdi_xml
)
SELECT
	[folio] = (
		CASE
			WHEN LEN(ISNULL(@Serie, '') + ISNULL(@Folio, '')) = 0 THEN
				RIGHT(REPLACE(CONVERT(VARCHAR(50), NEWID()), '-', ''), 10)
			ELSE
				ISNULL(@Serie, '') + ISNULL(@Folio, '')
		END
	)
	, [fecha] = @Fecha
	, [idcliente] = @idcliente
	, [codcliente] = @cliente_codigo
	, [vencimiento] = @Fecha
	, [idmoneda] = (
		SELECT bm.idmoneda 
		FROM ew_ban_monedas AS bm 
		WHERE bm.codigo = @Moneda
	)
	, [saldo] = 0
	, [importe] = @SubTotal
	, [impuesto1] = @Total - @Subtotal
	, [impuesto2] = 0
	, [idsucursal] = 1
	, [UUID] = @UUID
	, [idtran] = 0
	, [cfdi_xml] = @cxc_xml
WHERE
	(
		SELECT COUNT(*) 
		FROM ew_cxc_migracion AS cm 
		WHERE REPLACE(cm.UUID, '-', '') = REPLACE(@UUID, '-', '')
	) = 0

UPDATE cm SET
	cm.cfdi_xml = @cxc_xml
FROM
	ew_cxc_migracion AS cm
WHERE
	REPLACE(cm.UUID, '-', '') = REPLACE(@UUID, '-', '')

IF NOT EXISTS (
	SELECT * 
	FROM ew_cfd_comprobantes_timbre 
	WHERE REPLACE(cfdi_UUID, '-', '') = REPLACE(@UUID, '-', '')
)
BEGIN
	INSERT INTO ew_cfd_comprobantes (
		idtran
		,idsucursal
		,idestado
		,idfolio
		,cfd_version
		,cfd_fecha
		,cfd_folio
		,cfd_serie
		,cfd_noCertificado
		,cfd_formaDePago
		,cdf_condicionesDePago
		,cfd_subTotal
		,cfd_total
		,cfd_metodoDePago
		,cfd_tipoDeComprobante
		,rfc_emisor
		,rfc_receptor
		,receptor_nombre
		,xcfd_noAprobacion
		,xcfd_anoAprobacion
		,cfd_Moneda
		,cfd_TipoCambio
		,comentario
		,idtran2
		,cfd_NumCtaPago
		,cfd_uso
	)

	SELECT
		[idtran] = cm.idtran
		,[idsucursal] = cm.idsucursal
		,[idestado] = 0
		,[idfolio] = 0
		,[cfd_version] = @Version
		,[cfd_fecha] = @Fecha
		,[cfd_folio] = ISNULL(@folio, '')
		,[cfd_serie] = ISNULL(@Serie, '')
		,[cfd_noCertificado] = @NoCertificado
		,[cfd_formaDePago] = @MetodoPago
		,[cdf_condicionesDePago] = ISNULL(@CondicionesDePago, '')
		,[cfd_subTotal] = @SubTotal
		,[cfd_total] = @Total
		,[cfd_metodoDePago] = @MetodoPago
		,[cfd_tipoDeComprobante] = @TipoDeComprobante
		,[rfc_emisor] = @EmisorRfc
		,[rfc_receptor] = @ReceptorRfc
		,[receptor_nombre] = @ReceptorNombre
		,[xcfd_noAprobacion] = 0
		,[xcfd_anoAprobacion] = 0
		,[cfd_Moneda] = @Moneda
		,[cfd_TipoCambio] = 1
		,[comentario] = 'Importado'
		,[idtran2] = 0
		,[cfd_NumCtaPago] = ''
		,[cfd_uso] = @ReceptorUsoCFDI
	FROM
		ew_cxc_migracion AS cm
	WHERE
		LEN(ISNULL(@UUID, '')) > 0
		AND REPLACE(cm.UUID, '-', '') = REPLACE(@UUID, '-', '')
		AND cm.idtran > 0

	INSERT INTO ew_cfd_comprobantes_timbre (
		idtran
		,cfdi_FechaTimbrado
		,cfdi_versionTFD
		,cfdi_UUID
		,cfdi_noCertificadoSAT
		,cfdi_selloDigital
		,cfdi_cadenaOriginal
		,QRCode
		,cfdi_fechaCancelacion
		,cfdi_respuesta_codigo
		,cfdi_respuesta_mensaje
		,cfdi_prueba
	)

	SELECT
		[idtran] = cm.idtran
		,[cfdi_FechaTimbrado] = @Fecha
		,[cfdi_versionTFD] = '1.1'
		,[cfdi_UUID] = @UUID
		,[cfdi_noCertificadoSAT] = ''
		,[cfdi_selloDigital] = ''
		,[cfdi_cadenaOriginal] = ''
		,[QRCode] = ''
		,[cfdi_fechaCancelacion] = ''
		,[cfdi_respuesta_codigo] = ''
		,[cfdi_respuesta_mensaje] = ''
		,[cfdi_prueba] = 0
	FROM
		ew_cxc_migracion AS cm
	WHERE
		LEN(ISNULL(@UUID, '')) > 0
		AND REPLACE(cm.UUID, '-', '') = REPLACE(@UUID, '-', '')
		AND cm.idtran > 0

	INSERT INTO ew_cfd_comprobantes_xml (
		uuid
		,xml_base64
		,xml_cfdi
		,xml_modificado
	)

	SELECT
		[uuid] = @UUID
		,[xml_base64] = [dbEVOLUWARE].[dbo].[conv_to_base64](CONVERT(VARCHAR(MAX), cm.cfdi_xml))
		,[xml_cfdi] = cm.cfdi_xml
		,[xml_modificado] = NULL
	FROM
		ew_cxc_migracion AS cm
	WHERE
		LEN(ISNULL(@UUID, '')) > 0
		AND REPLACE(cm.UUID, '-', '') = REPLACE(@UUID, '-', '')
		AND cm.idtran > 0
END

/*
SELECT 
	[Version] = @Version
	, [Fecha] = @Fecha
	, [Total] = @Total
	, [TipoDeComprobante] = @TipoDeComprobante
	, [SubTotal] = @SubTotal
	, [Serie] = @Serie
	, [Sello] = @Sello
	, [NoCertificado] = @NoCertificado
	, [Moneda] = @Moneda
	, [MetodoPago] = @MetodoPago
	, [LugarExpedicion] = @LugarExpedicion
	, [FormaPago] = @FormaPago
	, [Folio] = @Folio
	, [CondicionesDePago] = @CondicionesDePago
	, [Certificado] = @Certificado

	, [EmisorRfc] = @EmisorRfc
	, [EmisorRegimenFiscal] = @EmisorRegimenFiscal
	, [EmisorNombre] = @EmisorNombre

	, [ReceptorRfc] = @ReceptorRfc
	, [ReceptorNombre] = @ReceptorNombre
	, [ReceptorUsoCFDI] = @ReceptorUsoCFDI

	, [UUID] = @UUID
*/

/*
/cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/
/cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/
/cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado/
Importe
TipoFactor
TasaOCuota
Impuesto
Base

/cfdi:Comprobante/cfdi:Impuestos/
TotalImpuestosTrasladados

/cfdi:Comprobante/cfdi:Impuestos/cfdi:Traslados/
/cfdi:Comprobante/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado/
Importe
TipoFactor
TasaOCuota
Impuesto

/cfdi:Comprobante/cfdi:Complemento/
/cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital/
Version
SelloSAT
NoCertificadoSAT
SelloCFD
RfcProvCertif
FechaTimbrado
UUID
*/
GO
