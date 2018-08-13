USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171115
-- Description:	Sella un Comprobante Fiscal Digital
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_sellarComprobante]
	 @idtran AS INT
	,@archivoXML AS VARCHAR(200)
AS

SET NOCOUNT ON

DECLARE 
	@idcertificado AS SMALLINT
	,@idtimbre AS INT
	,@restantes AS INT

DECLARE
	@msg AS VARCHAR(4000)

DECLARE 
	@rfc_emisor AS VARCHAR(13)
	,@rfc_receptor AS VARCHAR(13)
	,@cfd_total AS DECIMAL(17,6)
	,@QR_Base64 AS NVARCHAR(MAX)
	,@QR_code AS VARBINARY(MAX)

DECLARE
	@noCertificado AS VARCHAR(200)
	,@ruta AS VARCHAR(200)
	,@comprobante AS VARCHAR(MAX)
	,@cadena AS VARCHAR(MAX)
	,@tmp AS VARCHAR(200)
	,@xmlCFDi AS VARCHAR(MAX)
	,@idpac AS INT
	,@pac_codigo AS VARCHAR(50)

DECLARE
	@r AS BIT
	,@sello AS NVARCHAR(MAX)

DECLARE
	@pac_contrato AS VARCHAR(36)
	,@pac_usr AS VARCHAR(50)
	,@pac_pwd AS VARCHAR(50)
	,@pac_wsdl_url AS VARCHAR(200)
	,@pac_prueba AS BIT

DECLARE
	@codigo AS VARCHAR(10)
	,@mensaje AS VARCHAR(500)
	,@version AS VARCHAR(MAX)
	,@UUID AS VARCHAR(MAX)
	,@FechaTimbrado AS VARCHAR(MAX)
	,@selloCFD AS VARCHAR(MAX)
	,@noCertificadoSAT AS VARCHAR(MAX)
	,@selloSAT AS VARCHAR(MAX)
	,@xmlBase64 AS VARCHAR(MAX)
	,@cadena_original_timbrado AS VARCHAR(MAX)

	,@xmlSellado AS NVARCHAR(MAX)
	,@xmlSellado64 AS NVARCHAR (MAX)
	,@xmlTimbrado AS NVARCHAR(MAX)
	,@xmlTimbrado64 AS NVARCHAR (MAX)
	,@soapXml AS NVARCHAR(MAX)
	,@soapXmlResponse AS NVARCHAR(MAX)

DECLARE
	@bin_xml AS VARBINARY(MAX)
	,@str_xml AS VARCHAR(MAX)

DECLARE
	@xslt AS VARCHAR(1000)
	,@firma AS VARCHAR(MAX)

DECLARE
	@error_xml AS XML
	,@error_fatal AS BIT = 1

DECLARE
	@transaccion AS VARCHAR(5)
	
IF NOT EXISTS(SELECT idtran FROM ew_cfd_comprobantes WHERE idtran = @idtran)
BEGIN
	SELECT @msg = 'No existe el comprobante'

	GOTO ERROR_HANDLING
END

SELECT
	@transaccion = transaccion
FROM
	ew_sys_transacciones 
WHERE 
	idtran = @idtran

SELECT
	@rfc_emisor = c.rfc_emisor
	,@rfc_receptor = c.rfc_receptor
	,@cfd_total = cfd_total
FROM
	dbo.ew_cfd_comprobantes AS c
WHERE
	c.idtran = @idtran

SELECT @idtimbre = dbo.fn_cfd_getidtimbre()

IF @idtimbre = NULL OR @idtimbre = -1
BEGIN
	SELECT @msg = 'Error! No hay timbres disponibles. Consulte con el personal de soporte para mayor información.'

	GOTO ERROR_HANDLING
END

----------------------------------------------------------------
-- Obtenemos los datos de la FIEL y el CERTIFICADO
----------------------------------------------------------------
SELECT TOP 1 
	@idcertificado = f.idcertificado
	,@ruta = directorio
	,@tmp = RTRIM(rfc_emisor) + '_' + RTRIM(cfd_serie) + '-' + dbo.fnRellenar(RTRIM(CONVERT(VARCHAR(10),cfd_folio)),5,'0') + '.xml'
	,@idpac = fc.idpac
	,@pac_codigo = ep.codigo
	,@pac_contrato = ep.contrato
	,@pac_wsdl_url = ep.wsdl_url
	,@pac_usr = pc.usuario
	,@pac_pwd = pc.clave_acceso
	,@pac_prueba = fc.prueba

	,@xslt = fc.cadenaOriginal
	,@firma = db_comercial.dbo.EWCFD('LLAVE', fc.firma + ' ' + dbo.fn_sys_desencripta([fc].[contraseña], ''))
FROM	
	ew_cfd_comprobantes AS c 
	LEFT JOIN ew_cfd_folios AS f
		ON f.idfolio = c.idfolio
	LEFT JOIN ew_cfd_certificados AS fc
		ON fc.idcertificado = f.idcertificado
	LEFT JOIN db_comercial.dbo.evoluware_pac AS ep
		ON ep.idpac = fc.idpac
	LEFT JOIN ew_cat_pac_credenciales AS pc
		ON ep.idpac = pc.idpac
WHERE	
	c.idtran = @idtran
	
IF RIGHT(@ruta, 1) != '\' 
	SELECT @ruta = @ruta + '\'

IF @archivoXML = ''
	SELECT @archivoXML = @ruta + @tmp
	
SELECT @comprobante = ''
SELECT @cadena = ''
SELECT @sello = ''

IF @transaccion LIKE 'NFA%'
BEGIN
	-- NOMINA
	EXEC [dbo].[_cfdi_prc_generarCadenaXML33_NOM] @idtran, @comprobante OUTPUT
END
	ELSE
BEGIN
	-- VENTA
	EXEC [dbo].[_cfdi_prc_generarCadenaXML33_R2] @idtran, @comprobante OUTPUT
END

SELECT @xmlCFDi = @comprobante

BEGIN TRY
	IF @rfc_emisor IS NULL OR LTRIM(RTRIM(@rfc_emisor)) = ''
	BEGIN
		SELECT @msg = 'Error: RFC de emisor nulo.'
		GOTO ERROR_HANDLING
	END
		
	IF @rfc_receptor IS NULL OR LTRIM(RTRIM(@rfc_receptor)) = ''
	BEGIN
		SELECT @msg = 'Error: RFC de Receptor nulo.'
		GOTO ERROR_HANDLING
	END
	
	IF @idpac = 2
	BEGIN
		SELECT @pac_codigo = 'SW'
	END

	SELECT @codigo = 0
	
	EXEC [dbEVOLUWARE].[dbo].[Timbrado33]
		@pac_codigo
		, @pac_prueba
		, @pac_contrato
		, @pac_usr
		, @pac_pwd
		, @xmlCFDi
		, '' --Opciones
		, @xslt
		, @firma
		, @xmlSellado OUTPUT -- XMLSellado
		, @xmlSellado64 OUTPUT -- XMLSellado64
		, @xmlTimbrado OUTPUT --XMLTimbrado
		, @xmlTimbrado64 OUTPUT --XMLTimbrado64
		, @cadena OUTPUT
		, @cadena_original_timbrado OUTPUT
		, @FechaTimbrado OUTPUT
		, @noCertificado OUTPUT
		, @noCertificadoSAT OUTPUT
		, @QR_Base64 OUTPUT
		, @selloCFD OUTPUT
		, @selloSAT OUTPUT
		, @UUID OUTPUT
		, @mensaje OUTPUT
		, @soapXml OUTPUT
		, @soapXmlResponse OUTPUT

	SELECT @mensaje = ISNULL(@mensaje, '')
	SELECT @xmlBase64 = @xmlTimbrado64
	
	SELECT @QR_code = [dbEVOLUWARE].[dbo].[CONV_Base64ToBin](@QR_Base64)
	SELECT @bin_xml = [dbEVOLUWARE].[dbo].[CONV_Base64ToBin](@xmlSellado64)
	SELECT @r = [dbEVOLUWARE].[dbo].[bin_save](@bin_xml, REPLACE(@archivoXML, '.xml', '_debug.xml'))
	SELECT @bin_xml = NULL
	SELECT @error_fatal = 0
	SELECT @msg = @mensaje
	
	IF @uuid IS NULL OR LEN(@UUID) = 0
	BEGIN
		GOTO ERROR_HANDLING
	END

	IF EXISTS(SELECT idtran FROM ew_cfd_comprobantes_timbre WHERE idtran = @idtran)
	BEGIN
		UPDATE ew_cfd_comprobantes_timbre SET
			cfdi_FechaTimbrado = @FechaTimbrado
			,cfdi_versionTFD = @version
			,cfdi_UUID = @UUID
			,cfdi_noCertificadoSAT = @noCertificadoSAT
			,cfdi_selloDigital = @selloSAT
			,cfdi_cadenaOriginal = @cadena_original_timbrado
			,cfdi_respuesta_codigo = @codigo
			,cfdi_respuesta_mensaje = @mensaje
			,QRCode = @QR_code
			,cfdi_prueba = @pac_prueba
		WHERE
			idtran = @idtran
	END
		ELSE
	BEGIN
		INSERT INTO ew_cfd_comprobantes_timbre (
			idtran
			,cfdi_FechaTimbrado
			,cfdi_versionTFD
			,cfdi_UUID
			,cfdi_noCertificadoSAT
			,cfdi_selloDigital
			,cfdi_cadenaOriginal
			,cfdi_respuesta_codigo
			,cfdi_respuesta_mensaje
			,QRCode
			,cfdi_prueba
		)
		VALUES (
			@idtran
			,@FechaTimbrado
			,@version
			,@UUID
			,@noCertificadoSAT
			,@selloSAT
			,@cadena_original_timbrado
			,@codigo
			,@mensaje
			,@QR_code
			,@pac_prueba
		)
	END

	IF @idpac NOT IN (1,2)
	BEGIN
		SELECT @msg = 'Error: PAC Incorrecto.'
		GOTO ERROR_HANDLING
	END
END TRY
BEGIN CATCH
	SELECT @error_fatal = 0
	SELECT @msg = ERROR_MESSAGE()
	GOTO ERROR_HANDLING
END CATCH

UPDATE ew_cfd_comprobantes_sello SET 
	cadenaOriginal = @cadena
	,cfd_sello = @sello
	,archivoXML = @archivoXML
WHERE
	idtran = @idtran

IF @@ROWCOUNT = 0
BEGIN
	INSERT INTO ew_cfd_comprobantes_sello (
		idtran
		, cadenaOriginal
		, cfd_sello
	)
	SELECT
		idtran = @idtran
		,cadenaOriginal = @cadena
		,cfd_sello = @sello
END

UPDATE ew_cfd_comprobantes SET cfd_noCertificado = @noCertificado WHERE idtran = @idtran

----------------------------------------------------------------
-- Guardamos el archivo XML
----------------------------------------------------------------
BEGIN TRY
	SELECT @bin_xml = [dbEVOLUWARE].[dbo].[CONV_Base64ToBin](@xmlBase64)
	SELECT @msg = [dbEVOLUWARE].[dbo].[BIN_WriteFile](@bin_xml, @archivoXML)
	SELECT @str_xml = [dbEVOLUWARE].[dbo].[CONV_Base64ToString](@xmlBase64)

	IF EXISTS (SELECT * FROM ew_cfd_comprobantes_xml WHERE uuid = @UUID)
	BEGIN
		DELETE FROM ew_cfd_comprobantes_xml WHERE uuid = @UUID
	END
	
	IF @transaccion NOT IN ('NFA1')
	BEGIN
		INSERT INTO ew_cfd_comprobantes_xml (
			uuid
			,xml_base64
			,xml_cfdi
		)
		VALUES (
			@UUID
			,@xmlBase64
			,@str_xml
		)
	END

	------------ NUEVO POR VLADIMIR -------------------------------------------------------
	-- Actualizar tabla ew_cfd_timbres para sumar el timbre
	IF EXISTS(SELECT * FROM ew_cfd_comprobantes_timbre) AND (ISNULL(@UUID,'') <>'')
		BEGIN
			UPDATE ew_cfd_timbres SET usados = usados + 1 WHERE idtimbre = @idtimbre

			--Insertar en la tabla ew_cfd_timbres_mov para llevar detalle de las facturas timbradas
			IF NOT EXISTS (SELECT * FROM ew_cfd_timbres_mov WHERE idtimbre = @idtimbre)
			BEGIN
				INSERT INTO ew_cfd_timbres_mov (idtimbre, idtran) 
				VALUES (@idtimbre, @idtran)
			END

			------------------------ Si se acabaron, deshabilitar ----------------------------------
			SELECT @restantes = restantes FROM ew_cfd_timbres WHERE idtimbre = @idtimbre
		
			IF @restantes <= 0
			BEGIN
				UPDATE ew_cfd_timbres SET activo = 0 WHERE idtimbre = @idtimbre
			END
			---------------------------------------------------------------------------------------
		END
	---------------------------------------------------------------------------------------
END TRY
BEGIN CATCH
	SELECT @error_fatal = 0
	SELECT @msg = ERROR_MESSAGE()
	GOTO ERROR_HANDLING
END CATCH

RETURN

ERROR_HANDLING:

SELECT @soapXml = ISNULL(@soapXml, '')
SELECT @soapXmlResponse = ISNULL(@soapXmlResponse, '')

SELECT @soapXml = [dbEVOLUWARE].[dbo].[conv_to_base64](CAST(@soapXml AS NTEXT))
SELECT @soapXmlResponse = [dbEVOLUWARE].[dbo].[conv_to_base64](CAST(@soapXmlResponse AS NTEXT))

EXEC [dbo].[_cfdi_prc_errorXML] @idtran, @msg, @error_xml OUTPUT, 'emision', @pac_codigo, @soapXml, @soapXmlResponse

SELECT @ruta = 'F:\Clientes\_ErrorTimbrado\'

SELECT
	@ruta = (
		@ruta 
		+ 'Err_'
		+ DB_NAME()
		+ '_'
		+ CONVERT(VARCHAR(MAX), st.uuidtran)
		+ '.xml'
	)
FROM
	ew_sys_transacciones AS st
WHERE
	st.idtran = @idtran

SELECT @mensaje = @msg
SELECT @msg = [dbEVOLUWARE].[dbo].[txt_save](CONVERT(VARCHAR(MAX), @error_xml), @ruta)

DECLARE
	@err_codigo AS VARCHAR(50)
	,@err_mensaje AS VARCHAR(MAX)
	,@err_descripcion AS VARCHAR(MAX)

EXEC [db_comercial].[dbo].[CFDI_ErrorTimbrado] 
	@pac_codigo
	, @mensaje
	, @soapXmlResponse
	, @err_codigo OUTPUT
	, @err_mensaje OUTPUT
	, @err_descripcion OUTPUT

IF @error_fatal = 0
BEGIN
	SELECT @mensaje = (
		'[' + @err_codigo + ']'
		+ CHAR(13)
		+ '------------------------'
		+ CHAR(13)
		+ @mensaje
	)
END

RAISERROR(@mensaje, 16, 1)
RETURN
GO
