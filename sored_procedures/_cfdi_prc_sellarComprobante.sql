USE db_comercial_final
GO
-- SP: 	Sella un Comprobante Fiscal Digital
-- 		Elaborado por Laurence Saavedra
-- 		Creado en Septiembre del 2010
--		
--
-- EXEC _cfdi_prc_sellarComprobante 100108,''
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
	SELECT	TOP 1 
		@idcertificado = f.idcertificado
		,@ruta = directorio
		,@tmp = RTRIM(rfc_emisor) + '_' + RTRIM(cfd_serie) + '-' + dbo.fnRellenar(RTRIM(CONVERT(VARCHAR(10),cfd_folio)),5,'0') + '.xml'
		,@idpac = fc.idpac
	FROM	
		ew_cfd_comprobantes c 
		LEFT JOIN ew_cfd_folios f
			ON f.idfolio = c.idfolio
		LEFT JOIN ew_cfd_certificados fc
			ON fc.idcertificado = f.idcertificado
	WHERE	
		c.idtran = @idtran
	
	IF RIGHT(@ruta,1) != '\' 
		SELECT @ruta = @ruta + '\'
	IF @archivoXML = ''
		SELECT @archivoXML = @ruta + @tmp
	
	---------------------------------------------------------------
	-- Generamos la cadena XML
	---------------------------------------------------------------
	SELECT @comprobante = '', @cadena = ''
	EXEC _cfdi_prc_generarCadenaXML @idtran, @comprobante OUTPUT

	----------------------------------------------------------------
	-- Sellamos y Creamos el archivo XML
	----------------------------------------------------------------
	SELECT @sello = ''

	BEGIN TRY
		EXEC db_comercial.dbo.CFDI_Sellar @idcertificado, @comprobante, @sello OUTPUT,@cadena OUTPUT, @noCertificado OUTPUT, @OutXML OUTPUT
	END TRY
	BEGIN CATCH
		SELECT @r = db_comercial.dbo.XML_GuardarArchivo(@comprobante,'c:\Evoluware\Temp\ERR - ' + LTRIM(RTRIM(STR(@idtran))) + '.xml')
		SELECT @msg = 'dbo.CFDI_Sellar: Ocurrió un error al generar el sello digital.'

		RAISERROR(@msg,16,1)
		RETURN	
	END CATCH

	----------------------------------------------------------------
	-- Guardamos la Cadena Original y el Sello en EW_CFD_COMPROBANTES_SELLO
	----------------------------------------------------------------
	BEGIN TRY
		UPDATE ew_cfd_comprobantes_sello SET 
			cadenaOriginal = @cadena
			,cfd_sello = @sello
			,archivoXML = @archivoXML
		WHERE
			idtran = @idtran

		IF @@ROWCOUNT = 0
		BEGIN
			INSERT INTO ew_cfd_comprobantes_sello 
				(idtran, cadenaOriginal, cfd_sello)
			SELECT
				idtran = @idtran
				,cadenaOriginal = @cadena
				,cfd_sello = @sello
		END

		UPDATE ew_cfd_comprobantes SET cfd_noCertificado = @noCertificado WHERE idtran = @idtran
	END TRY
	BEGIN CATCH
		SELECT @msg='Ocurrió un error al guardar la Cadena y el Sello en la Base de Datos.'

		RAISERROR(@msg,16,1)

		SELECT
			ERROR_NUMBER() AS [Error]
			,@msg AS [Mensaje]
			,'ew_cfd_comprobantes_sello' AS [Origen]
		RETURN
	END CATCH

	----------------------------------------------------------------
	-- Timbramos el Comprobante con el PAC
	----------------------------------------------------------------
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

		IF @idpac = 0
		BEGIN
			EXEC _cfdi_prc_timbrarSolucionFactible @idtran, @OutXML OUTPUT
		END
			
		IF @idpac = 1
		BEGIN
			IF @rfc_emisor IS NULL OR @rfc_emisor=''
			BEGIN
				RAISERROR('Error: RFC de emisor nulo.', 16, 1)
				RETURN
			END
				
			IF @rfc_receptor IS NULL OR @rfc_receptor=''
			BEGIN
				RAISERROR('Error: RFC de Receptor nulo.', 16, 1)
				RETURN
			END
			
			WHILE @pac_i < 5
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
				
				IF @respuestaOk = 'false'
				BEGIN
					SELECT @pac_i = 5
					SELECT @msg = @mensaje
				END

				IF @codigo = -1
				BEGIN
					SELECT @pac_i = 5
				END
					ELSE
				BEGIN
					SELECT @pac_i = @pac_i + 1
				END
			END
			
			IF @UUID IS NULL OR @UUID=''
			BEGIN
				IF @respuestaOk = 'false'
				BEGIN
					SELECT @msg = @mensaje
				END
					ELSE
				BEGIN
					SELECT @msg = 'Error, no se obtuvo UUID'
				END

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
					,cfdi_respuesta_mensaje
					,QRCode
				)
				VALUES (
					@idtran
					,@FechaTimbrado
					,@version
					,@UUID
					,@noCertificadoSAT
					,@selloSAT
					,@cadena_original_timbrado
					,@mensaje
					,@QR_code
				)
			END
		END

		IF @idpac NOT IN (0,1)
		BEGIN
			RAISERROR('Error: PAC Incorrecto.', 16, 1)
		END
	END TRY
	BEGIN CATCH
		SELECT @msg = ERROR_MESSAGE()

		RAISERROR(@msg, 16, 1)
		RETURN
	END CATCH

	----------------------------------------------------------------
	-- Guardamos el archivo XML
	----------------------------------------------------------------
	BEGIN TRY
		SELECT @bin_xml = [dbEVOLUWARE].[dbo].[CONV_Base64ToBin](@xmlBase64)
		SELECT @msg = [dbEVOLUWARE].[dbo].[BIN_WriteFile](@bin_xml, @archivoXML)

		------------ NUEVO POR VLADIMIR -------------------------------------------------------
		-- Actualizar tabla ew_cfd_timbres para sumar el timbre
		UPDATE ew_cfd_timbres SET usados = usados + 1 WHERE idtimbre = @idtimbre

		--Insertar en la tabla ew_cfd_timbres_mov para llevar detalle de las facturas timbradas
		INSERT INTO ew_cfd_timbres_mov(idtimbre, idtran) VALUES(@idtimbre, @idtran)
		---------------------------------------------------------------------------------------
		------------------------ Si se acabaron, deshabilitar ----------------------------------
		SELECT @restantes = restantes FROM ew_cfd_timbres WHERE idtimbre = @idtimbre
		
		IF @restantes <=0
			BEGIN
				UPDATE ew_cfd_timbres SET activo = 0 WHERE idtimbre=@idtimbre
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
