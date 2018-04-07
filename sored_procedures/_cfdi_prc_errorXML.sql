USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180405
-- Description:	Generar Cadena XML por error de timbrado
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_errorXML]
	@idtran AS INT
	,@msg AS VARCHAR(MAX)
	,@error_xml AS XML OUTPUT
AS

SET NOCOUNT ON

SELECT
	@error_xml = g.XML
FROM (
	SELECT
		(
			SELECT
				DB_NAME() AS '@BaseDatos'
			FOR XML PATH('Empresa'), TYPE
		) AS '*'
		,(
			SELECT
				st.idtran AS '@Idtran'
				,st.folio AS '@Folio'
				,st.transaccion AS '@Transaccion'
			FOR XML PATH('Documento'), TYPE
		) AS '*'
		,(
			SELECT
				@msg AS '@Mensaje'
				,CONVERT(VARCHAR(19), GETDATE(), 126) AS '@FechaHora'
			FOR XML PATH('Error'), TYPE
		) AS '*'
	FROM
		ew_sys_transacciones AS st
	WHERE
		st.idtran = @idtran
	FOR XML PATH('Error'), TYPE
) AS g(XML)
GO
