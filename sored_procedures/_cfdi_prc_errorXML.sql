USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180405
-- Description:	Generar Cadena XML por error de timbrado
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_errorXML]
	@idtran AS INT
	, @msg AS VARCHAR(MAX)
	, @error_xml AS XML OUTPUT
	, @tipo AS VARCHAR(50) = 'emision'
	, @pac_codigo AS VARCHAR(10) = ''
	, @soapRequest AS NVARCHAR(MAX) = ''
	, @soapResponse AS NVARCHAR(MAX) = ''
AS

SET NOCOUNT ON

DECLARE
	@version AS VARCHAR(10) = '1.3'
	, @err_codigo AS VARCHAR(50)
	, @msg_desc AS VARCHAR(MAX)

EXEC [db_comercial].[dbo].[CFDI_ErrorTimbrado] 
	@pac_codigo
	, @msg
	, @soapResponse
	, @err_codigo OUTPUT
	, @msg OUTPUT
	, @msg_desc OUTPUT

IF LEN(@msg_desc) = 0
BEGIN
	SELECT @msg_desc = 'No definido'
END

IF LEN(@soapRequest) = 0
BEGIN
	SELECT @soapRequest = NULL
END

IF LEN(@soapResponse) = 0
BEGIN
	SELECT @soapResponse = NULL
END

SELECT
	@error_xml = g.XML
FROM (
	SELECT
		@version AS '@Version'
		,@tipo AS '@Tipo'
		,(
			SELECT
				DB_NAME() AS '@BaseDatos'
			FOR XML PATH('Empresa'), TYPE
		) AS '*'
		,(
			SELECT
				st.idtran AS '@Idtran'
				, st.folio AS '@Folio'
				, st.transaccion AS '@Transaccion'
			FOR XML PATH('Documento'), TYPE
		) AS '*'
		,(
			SELECT
				@msg AS '@Mensaje'
				, @msg_desc AS '@MensajeDescripcion'
				, CONVERT(VARCHAR(19), GETDATE(), 126) AS '@FechaHora'
			FOR XML PATH('Error'), TYPE
		) AS '*'
		,(
			SELECT
				@soapRequest AS '@Request'
				,@soapResponse AS '@Response'
			FOR XML PATH('Soap'), TYPE
		) AS '*'
	FROM
		ew_sys_transacciones AS st
	WHERE
		st.idtran = @idtran
	FOR XML PATH('Error'), TYPE
) AS g(XML)
GO
