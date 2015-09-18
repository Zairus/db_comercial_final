USE [db_comercial_final]
GO
-- SP: 	Genera una cadena XML partiendo de un Comprobante Fiscal Digital
-- 		Elaborado por Laurence Saavedra
-- 		Creado en Septiembre del 2010
--		Modificado en Junio del 2012
--
--		DECLARE @com VARCHAR(MAX);EXEC dbo._cfdi_prc_generarCadenaXML2 100253,@com OUTPUT;PRINT @com
ALTER PROCEDURE [dbo].[_cfdi_prc_cancelarFacturaSAT]
	 @idtran AS INT
AS

SET NOCOUNT ON

SET DATEFORMAT DMY
SET NOCOUNT ON

DECLARE 
	@uuid AS VARCHAR(50)
	,@transaccion AS VARCHAR(5)
	,@folio AS VARCHAR(20)
	,@idcertificado AS SMALLINT = 0
	,@idcertificado2 AS SMALLINT = 0

	,@rfcEmisor AS VARCHAR(MAX)
	,@cert AS VARBINARY(MAX)
	,@key AS VARBINARY(MAX)
	,@keyPass AS VARCHAR(MAX)
	,@opciones AS VARCHAR(MAX) = ''
	--===================================
	,@respuestaOk AS VARCHAR(MAX)
	,@codigo AS VARCHAR(10)
	,@mensaje As VARCHAR(500)
	,@rfc AS VARCHAR(MAX)
	--===================================
	,@comprobante AS VARCHAR(MAX)
	,@xmlBase64 AS VARCHAR(MAX)
	,@respuestaXml AS VARCHAR(MAX)
	,@cancelar AS BIT
	,@contrato AS VARCHAR(MAX)

SELECT 
	@idtran = c.idtran,
	@uuid = ct.cfdi_UUID,
	@transaccion = t.transaccion,
	@folio = t.folio,
	@idcertificado = ec.idcertificado,
	@rfcEmisor = c.rfc_emisor
FROM 
	dbo.ew_cfd_comprobantes AS c
	LEFT JOIN dbo.ew_cfd_comprobantes_timbre AS ct 
		ON ct.idtran=c.idtran
	LEFT JOIN dbo.ew_cfd_comprobantes_sello AS cs 
		ON cs.idtran=c.idtran
	LEFT JOIN dbo.evoluware_certificados ec 
		ON ec.noCertificado = c.cfd_noCertificado
	LEFT JOIN dbo.ew_sys_transacciones AS t 
		ON t.idtran=c.idtran
WHERE
	t.idestado = 255
	AND ct.cfdi_noCertificadoSAT IN (
		'00001000000203051706'
		,'20001000000100005761'
	)
	AND c.idtran NOT IN (SELECT idtran FROM dbo.ew_cfd_comprobantes_cancelados)
	AND ct.cfdi_UUID IS NOT NULL
	AND c.idtran = @idtran
ORDER BY
	t.idtran

IF @@ROWCOUNT > 0
BEGIN
	SELECT @cancelar = 1

	BEGIN TRY
		SELECT
			@cert = dbEVOLUWARE.dbo.BIN_ReadFile(ec.certificado)
			,@key = dbEVOLUWARE.dbo.BIN_ReadFile(ec.firma)
			,@keyPass = dbo.fn_sys_desencripta([contraseña], '')
		FROM
			dbo.evoluware_certificados AS ec
		WHERE
			idcertificado = @idcertificado
	END TRY
	BEGIN CATCH
		SELECT @cancelar = 0
		RAISERROR ('ERROR al obtener los certificados, no se cancelará en comprobante', 16, 2)
	END CATCH

	IF @cancelar = 1
	BEGIN
		BEGIN TRY
			EXECUTE [dbEVOLUWARE].[prodigia].[Cancelar] 
				'7965dd70-bc0a-11e2-9e96-0800200c9a66'				-- @wsContrato
				,'evoluware'										-- @wsUsuario
				,'B1234567890$'										-- @wsPassword
				,60													-- @wsTimeout
				,'https://www.pade.mx/PadeApp/TimbradoService?WSDL'	-- @wsUrl
				,@rfcEmisor											-- RFC del Emisor
				,@UUID												-- UUID
				,@cert
				,@key
				,@keyPass
				,@opciones											-- con Opciones
				--===================================
				,@respuestaOk OUTPUT
				,@rfc OUTPUT
				,@codigo OUTPUT
				,@mensaje OUTPUT
				,@comprobante OUTPUT
				,@xmlBase64 OUTPUT
				,@respuestaXml OUTPUT
			
			IF @codigo = '202'
			BEGIN
				EXECUTE [dbEVOLUWARE].[prodigia].[AcuseCancelacion] 
					'7965dd70-bc0a-11e2-9e96-0800200c9a66'
					,'evoluware'
					,'B1234567890$'
					,1
					,'https://www.pade.mx/PadeApp/TimbradoService?WSDL'
					,@uuid
					,@respuestaOk OUTPUT
					,@codigo OUTPUT
					,@mensaje OUTPUT
					,@contrato OUTPUT
					,@comprobante OUTPUT
					,@xmlBase64 OUTPUT
					,@respuestaXml OUTPUT
			END
			
			IF RTRIM(@comprobante) = ''
			BEGIN
				--SELECT @mensaje = '[' + ISNULL(@codigo, '0') + '] No se cancela el comprobante.' + ISNULL(@mensaje, '')
				--RAISERROR(@mensaje, 16, 1)
				SELECT @comprobante = '** NO CANCELADO EN SAT **'
			END
			
			INSERT INTO dbo.ew_cfd_comprobantes_cancelados
				(idtran, acuse)
			VALUES
				(@idtran, @comprobante)
		END TRY
		BEGIN CATCH
			RAISERROR (@mensaje, 16, 2)
		END CATCH
	END
END
GO
