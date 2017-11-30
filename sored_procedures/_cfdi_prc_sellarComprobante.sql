USE db_comercial_final
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
	@pass AS VARBINARY(256)
	,@msg AS VARCHAR(4000)

DECLARE 
	@rfc_emisor AS VARCHAR(13)
	,@rfc_receptor AS VARCHAR(13)
	,@cfd_total AS DECIMAL(17,6)
	,@QR_Base64 AS NVARCHAR(MAX)
	,@QR_cadena AS NVARCHAR(122)
	,@QR_code AS VARBINARY(MAX)

DECLARE
	@noCertificado AS VARCHAR(200)
	,@ruta AS VARCHAR(200)
	,@comprobante AS VARCHAR(MAX)
	,@cadena AS VARCHAR(MAX)
	,@tmp AS VARCHAR(200)
	,@OutXML AS VARCHAR(MAX)
	,@idpac AS INT

DECLARE
	@r AS BIT
	,@sello AS NVARCHAR(MAX)

DECLARE
	@pac_contrato AS VARCHAR(36)
	,@pac_usuario AS VARCHAR(50)
	,@pac_clave_acceso AS VARCHAR(50)
	,@pac_wsdl_url AS VARCHAR(200)
	,@pac_prueba AS BIT

DECLARE
	@respuestaOk AS VARCHAR(MAX)
	,@codigo AS VARCHAR(10)
	,@mensaje AS VARCHAR(500)
	,@contrato AS VARCHAR(MAX)
	,@version AS VARCHAR(MAX)
	,@UUID AS VARCHAR(MAX)
	,@FechaTimbrado AS VARCHAR(MAX)
	,@selloCFD AS VARCHAR(MAX)
	,@noCertificadoSAT AS VARCHAR(MAX)
	,@selloSAT AS VARCHAR(MAX)
	,@xmlBase64 AS VARCHAR(MAX)
	,@respuestaXml AS VARCHAR(MAX)
	,@cadena_original_timbrado AS VARCHAR(MAX)

DECLARE
	@pac_i AS INT = 0

DECLARE
	@bin_xml AS VARBINARY(MAX)
	,@str_xml AS VARCHAR(MAX)

DECLARE
	@pac_usr AS VARCHAR(50)
	,@pac_pwd AS VARCHAR(50)

DECLARE
	@cfd_version AS VARCHAR(5) = [dbo].[_sys_fnc_parametroTexto]('CFDI_VERSION')
	,@xslt AS VARCHAR(1000)
	,@firma AS VARCHAR(MAX)
	
IF NOT EXISTS(SELECT idtran FROM ew_cfd_comprobantes WHERE idtran = @idtran)
IF @@ROWCOUNT = 0
BEGIN
	RAISERROR('No existe el comprobante',16,1)
	RETURN
END

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
	RAISERROR('Error! No hay timbres disponibles. Consulte con el personal de soporte para mayor información.',16,1)
	RETURN
END
	ELSE
BEGIN
	----------------------------------------------------------------
	-- Obtenemos los datos de la FIEL y el CERTIFICADO
	----------------------------------------------------------------
	SELECT TOP 1 
		@idcertificado = f.idcertificado
		,@ruta = directorio
		,@tmp = RTRIM(rfc_emisor) + '_' + RTRIM(cfd_serie) + '-' + dbo.fnRellenar(RTRIM(CONVERT(VARCHAR(10),cfd_folio)),5,'0') + '.xml'
		,@idpac = fc.idpac
		,@pac_usr = fc.pac_usr
		,@pac_pwd = fc.pac_pwd

		,@xslt = fc.cadenaOriginal
		,@firma = db_comercial.dbo.EWCFD('LLAVE', fc.firma + ' ' + dbo.fn_sys_desencripta([fc].[contraseña], ''))
	FROM	
		ew_cfd_comprobantes AS c 
		LEFT JOIN ew_cfd_folios AS f
			ON f.idfolio = c.idfolio
		LEFT JOIN ew_cfd_certificados AS fc
			ON fc.idcertificado = f.idcertificado
	WHERE	
		c.idtran = @idtran
	
	IF RIGHT(@ruta,1) != '\' 
		SELECT @ruta = @ruta + '\'
	IF @archivoXML = ''
		SELECT @archivoXML = @ruta + @tmp
	
	SELECT @comprobante = ''
	SELECT @cadena = ''
	SELECT @sello = ''

	--##############################################################
	--SELECT @cfd_version = '3.3'

	IF @cfd_version = '3.2'
	BEGIN
		EXEC [dbo].[_cfdi_prc_generarCadenaXML] @idtran, @comprobante OUTPUT

		BEGIN TRY
			EXEC db_comercial.dbo.CFDI_Sellar @idcertificado, @comprobante, @sello OUTPUT, @cadena OUTPUT, @noCertificado OUTPUT, @OutXML OUTPUT
		END TRY
		BEGIN CATCH
			SELECT @r = db_comercial.dbo.XML_GuardarArchivo(@comprobante,'c:\Evoluware\Temp\ERR - ' + LTRIM(RTRIM(STR(@idtran))) + '.xml')
			SELECT @msg = 'dbo.CFDI_Sellar: Ocurrió un error al generar el sello digital.'

			RAISERROR(@msg,16,1)
			RETURN	
		END CATCH
	END
		ELSE
	BEGIN
		EXEC [dbo].[_cfdi_prc_generarCadenaXML33_R2] @idtran, @comprobante OUTPUT
		SELECT @OutXML = @comprobante
	END

	SELECT @msg = [dbEVOLUWARE].[dbo].[TXT_WriteFile](@OutXML, REPLACE(@archivoXML, '.xml', '_debug.xml'))

	BEGIN TRY
		SELECT
			@pac_contrato = contrato
			,@pac_usuario = usuario
			,@pac_clave_acceso = clave_acceso
			,@pac_wsdl_url = wsdl_url
			,@pac_prueba = ISNULL((SELECT prueba FROM evoluware_certificados WHERE idcertificado = @idcertificado), 1)
		FROM
			db_comercial.dbo.evoluware_pac
		WHERE
			idpac = @idpac

		IF @rfc_emisor IS NULL OR LTRIM(RTRIM(@rfc_emisor)) = ''
		BEGIN
			RAISERROR('Error: RFC de emisor nulo.', 16, 1)
			RETURN
		END
		
		IF @rfc_receptor IS NULL OR LTRIM(RTRIM(@rfc_receptor)) = ''
		BEGIN
			RAISERROR('Error: RFC de Receptor nulo.', 16, 1)
			RETURN
		END
		
		IF @cfd_version = '3.2'
		BEGIN
			IF @idpac = 1
			BEGIN
				IF @pac_prueba = 1
				BEGIN
					EXECUTE [dbEVOLUWARE].[prodigia].[TimbradoPruebas]
						@pac_contrato
						,@pac_usuario
						,@pac_clave_acceso
						,120
						,@pac_wsdl_url
						,@OutXML
						,'' --Opciones
					
						,@respuestaOk OUTPUT
						,@codigo OUTPUT
						,@mensaje OUTPUT
						,@contrato OUTPUT
						,@version OUTPUT
						,@UUID OUTPUT
						,@FechaTimbrado OUTPUT
						,@selloCFD OUTPUT
						,@noCertificadoSAT OUTPUT
						,@selloSAT OUTPUT
						,@comprobante OUTPUT
						,@xmlBase64 OUTPUT
						,@respuestaXml OUTPUT
				END
					ELSE
				BEGIN
					EXECUTE [dbEVOLUWARE].[prodigia].[Timbrado]
						@pac_contrato
						,@pac_usuario
						,@pac_clave_acceso
						,120
						,@pac_wsdl_url
						,@OutXML
						,'' --Opciones
					
						,@respuestaOk OUTPUT
						,@codigo OUTPUT
						,@mensaje OUTPUT
						,@contrato OUTPUT
						,@version OUTPUT
						,@UUID OUTPUT
						,@FechaTimbrado OUTPUT
						,@selloCFD OUTPUT
						,@noCertificadoSAT OUTPUT
						,@selloSAT OUTPUT
						,@comprobante OUTPUT
						,@xmlBase64 OUTPUT
						,@respuestaXml OUTPUT
				END
			END
		
			IF @idpac = 2
			BEGIN
				SELECT @codigo = 0

				IF @pac_prueba = 1
				BEGIN
					EXEC [dbEVOLUWARE].[dbo].[SWTimbradoPruebaEX]
						@OutXML
						, @OutXML OUTPUT
						, @mensaje OUTPUT
						, @UUID OUTPUT
						, @fechaTimbrado OUTPUT
						, @selloCFD OUTPUT
						, @noCertificadoSAT OUTPUT
						, @selloSAT OUTPUT
						, @xmlBase64 OUTPUT
				END
					ELSE
				BEGIN
					EXEC [dbEVOLUWARE].[dbo].[SWTimbradoEX]
						@OutXML
						, @pac_usr
						, @pac_pwd
						, @OutXML OUTPUT
						, @mensaje OUTPUT
						, @UUID OUTPUT
						, @fechaTimbrado OUTPUT
						, @selloCFD OUTPUT
						, @noCertificadoSAT OUTPUT
						, @selloSAT OUTPUT
						, @xmlBase64 OUTPUT
				END
			END

			IF @UUID IS NULL OR LTRIM(RTRIM(@UUID)) = ''
			BEGIN
				SELECT @msg = 'Error, no se obtuvo UUID. ' + @mensaje

				RAISERROR(@msg, 16, 1)
				RETURN
			END
		
			SELECT
				@QR_cadena = (
					'?re=' + @rfc_emisor + 
					'&rr=' + @rfc_receptor + 
					'&tt=' + dbo.fnRellenar(CONVERT(DECIMAL(17,6), @cfd_total), 17, '0') + 
					'&id=' + @UUID
				)
			
			SELECT @QR_code = dbEVOLUWARE.dbo.QR_Codificar(@QR_cadena)
			SELECT @msg = [dbEVOLUWARE].[dbo].[BIN_WriteFile](@QR_code, REPLACE(@archivoXML, '.xml', '.png'))

			SELECT
				@cadena_original_timbrado = (
					'||1.0|'
					+ @UUID + '|'
					+ @FechaTimbrado + '|'
					+ @selloSAT + '|'
					+ @noCertificadoSAT + '||'
				)
		END
			ELSE
		BEGIN
			DECLARE
				@pac_codigo AS VARCHAR(50) = 'PRODIGIA'

			IF @idpac = 2
				SELECT @pac_codigo = 'SW'

			SELECT @codigo = 0

			EXEC [dbEVOLUWARE].[dbo].[Timbrado33]
				@pac_codigo
				, @pac_prueba
				, @pac_contrato
				, @pac_usuario
				, @pac_clave_acceso
				, @OutXML
				, '' --Opciones
				, @xslt
				, @firma
				, @OutXML OUTPUT
				, @respuestaXml OUTPUT
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

			SELECT @mensaje = ISNULL(@mensaje, '')
			SELECT @xmlBase64 = [dbEVOLUWARE].[dbo].[CONV_StringToBase64](@respuestaXml)
			
			SELECT @msg = @mensaje

			SELECT @QR_code = [dbEVOLUWARE].[dbo].[CONV_Base64ToBin](@QR_Base64)

			IF @uuid IS NULL OR LEN(@UUID) = 0
			BEGIN
				RAISERROR(@msg, 16, 1)
			END
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
			RAISERROR('Error: PAC Incorrecto.', 16, 1)
		END
	END TRY
	BEGIN CATCH
		SELECT @msg = ERROR_MESSAGE()

		RAISERROR(@msg, 16, 1)
		RETURN
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

		------------ NUEVO POR VLADIMIR -------------------------------------------------------
		-- Actualizar tabla ew_cfd_timbres para sumar el timbre
		UPDATE ew_cfd_timbres SET usados = usados + 1 WHERE idtimbre = @idtimbre

		--Insertar en la tabla ew_cfd_timbres_mov para llevar detalle de las facturas timbradas
		IF NOT EXISTS (SELECT * FROM ew_cfd_timbres_mov WHERE idtimbre = @idtimbre)
		BEGIN
			INSERT INTO ew_cfd_timbres_mov (idtimbre, idtran) 
			VALUES (@idtimbre, @idtran)
		END

		---------------------------------------------------------------------------------------
		------------------------ Si se acabaron, deshabilitar ----------------------------------
		SELECT @restantes = restantes FROM ew_cfd_timbres WHERE idtimbre = @idtimbre
		
		IF @restantes <= 0
		BEGIN
			UPDATE ew_cfd_timbres SET activo = 0 WHERE idtimbre = @idtimbre
		END
		---------------------------------------------------------------------------------------
	END TRY
	BEGIN CATCH
		SELECT @msg = ERROR_MESSAGE()
		
		RAISERROR(@msg, 16, 1)
		RETURN
	END CATCH
END
GO
