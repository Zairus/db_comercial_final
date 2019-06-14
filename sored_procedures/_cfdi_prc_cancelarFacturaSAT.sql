USE db_comercial_final
GO
IF OBJECT_ID('_cfdi_prc_cancelarFacturaSAT') IS NOT NULL
BEGIN
	DROP PROCEDURE _cfdi_prc_cancelarFacturaSAT
END
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20120601
-- Description:	Cancelar comprobante fiscal
-- =============================================
CREATE PROCEDURE [dbo].[_cfdi_prc_cancelarFacturaSAT]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idcertificado AS SMALLINT = 0
	, @xml_path AS NVARCHAR(MAX)
	, @xml_path_c AS NVARCHAR(MAX)

DECLARE
	@pac NVARCHAR (MAX)
	, @prueba BIT
	, @contrato NVARCHAR (MAX)
	, @usr NVARCHAR (MAX)
	, @pwd NVARCHAR (MAX)
	, @xml NVARCHAR (MAX)
	, @opciones NVARCHAR (MAX)
	, @xmlRespuesta NVARCHAR (MAX)
	, @fechaCancelacion NVARCHAR (MAX)
	, @mensaje NVARCHAR (MAX)
	, @idtimbre	INT

DECLARE
	@error_xml AS XML
	, @ruta AS VARCHAR(200)
	, @msg AS VARCHAR(4000)


-------------------------------------------------------------------------
-- Validamos que haya timbres disponibles para la cancelación ante el SAT
-------------------------------------------------------------------------
SELECT @idtimbre = dbo.fn_cfd_getidtimbre()

IF @idtimbre = NULL OR @idtimbre = -1
BEGIN
	RAISERROR('Error! No hay timbres disponibles para hacer la cancelación ante el SAT. Consulte con el personal de soporte para mayor información y después haga la Solicitud del acuse de cancelación dentro del sistema.', 16, 1)
	RETURN
END
	ELSE
BEGIN
	SELECT
		@idtran = c.idtran
		, @idcertificado = ec.idcertificado
		, @xml_path = ccs.archivoXML
	FROM 
		dbo.ew_cfd_comprobantes AS c
		LEFT JOIN dbo.ew_cfd_comprobantes_timbre AS ct 
			ON ct.idtran = c.idtran
		LEFT JOIN dbo.evoluware_certificados AS ec 
			ON ec.noCertificado = c.cfd_noCertificado
		LEFT JOIN dbo.ew_sys_transacciones AS t 
			ON t.idtran = c.idtran
		LEFT JOIN ew_cfd_comprobantes_sello AS ccs
			ON ccs.idtran = c.idtran
		LEFT JOIN ew_cxc_transacciones cxc
			ON c.idtran = cxc.idtran
	WHERE
		c.idtran = @idtran
		AND cxc.cancelado = 1
		AND LEN(ISNULL(ct.cfdi_UUID, '')) > 0
	ORDER BY
		t.idtran
	
	IF @@ROWCOUNT > 0
	BEGIN
		SELECT
			@pac = pac.codigo
			, @prueba = cc.prueba
			, @contrato = pac.contrato
			, @usr = cpc.usuario
			, @pwd = cpc.clave_acceso
			, @opciones = (
				'{'
				+ '"Cert_path": "' + REPLACE(cc.certificado, '\', '\\') + '"'
				+ ',"Key_path": "' + REPLACE(cc.firma, '\', '\\') + '"'
				+ ',"Key_pass": "'+ (SELECT CAST(dbo.fn_sys_desencripta([cc].[contraseña], '') as varbinary(max)) FOR XML PATH(''), BINARY BASE64) + '"'
				+ ',"Opciones": ["REGRESAR_CON_ERROR_307_XML"]'
				+ '}'
			)
		FROM 
			ew_cfd_certificados AS cc
			LEFT JOIN db_comercial.dbo.evoluware_pac AS pac
				ON pac.idpac = cc.idpac
			LEFT JOIN ew_cat_pac_credenciales AS cpc
				ON cpc.idpac = pac.idpac
		WHERE
			cc.idcertificado = @idcertificado

		BEGIN TRY
			SELECT @xml = [dbEVOLUWARE].[dbo].[txt_read](@xml_path)

			EXEC [dbEVOLUWARE].[dbo].[Cancelacion33]
				@pac
				, @prueba
				, @contrato
				, @usr
				, @pwd
				, @xml
				, @opciones
				, @xmlRespuesta OUTPUT
				, @fechaCancelacion OUTPUT
				, @mensaje OUTPUT

				IF NOT EXISTS (SELECT * FROM ew_cfd_comprobantes_cancelados WHERE idtran = @idtran)
				BEGIN
					INSERT INTO ew_cfd_comprobantes_cancelados (
						idtran
						, pac
						, acuse
					)
					VALUES (
						@idtran
						, @pac
						, @xmlRespuesta
					)
				END
					ELSE
				BEGIN
					UPDATE ew_cfd_comprobantes_cancelados SET
						acuse = @xmlRespuesta
					WHERE
						idtran = @idtran
				END

				IF @xmlRespuesta IS NULL OR @xmlRespuesta = ''
				BEGIN
					SELECT @mensaje = ISNULL(NULLIF(@mensaje, ''), 'Error: No se ha recibido respuesta del PAC, favor de solicitar cancelacion al SAT de nuevo.')
					GOTO ERROR_HANDLING
				END

				SELECT @xml_path_c = REPLACE(@xml_path, '.xml', '_Acuse.xml')
				SELECT @msg = [dbEVOLUWARE].[dbo].[txt_save](@xmlRespuesta, @xml_path_c)

				-------------------------------------------------------------------------
				-- LO CONTABILIZAMOS COMO CANCELADO EN ew_cfd_timbres
				-------------------------------------------------------------------------
				UPDATE ew_cfd_timbres SET 
					cancelados = cancelados + 1 
				WHERE 
					idtimbre = @idtimbre
		END TRY
		BEGIN CATCH
			SELECT @mensaje = CONVERT(VARCHAR(MAX), ERROR_MESSAGE())
			GOTO ERROR_HANDLING
		END CATCH
	END
END

RETURN
-------------------------------------------------------------------------
-- MANEJAR ERRORES
-------------------------------------------------------------------------
ERROR_HANDLING:

EXEC [dbo].[_cfdi_prc_errorXML] @idtran, @mensaje, @error_xml OUTPUT, 'cancelacion'

SELECT @ruta = 'F:\Clientes\_ErrorTimbrado\'

SELECT
	@ruta = (
		@ruta 
		+ 'Err_'
		+ DB_NAME()
		+ '_'
		+ CONVERT(VARCHAR(MAX), st.uuidtran)
		+ '_C.xml'
	)
FROM
	ew_sys_transacciones AS st
WHERE
	st.idtran = @idtran

SELECT @msg = [dbEVOLUWARE].[dbo].[txt_save](CONVERT(VARCHAR(MAX), @error_xml), @ruta)
GO
