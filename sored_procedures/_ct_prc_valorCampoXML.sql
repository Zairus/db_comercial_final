USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180914
-- Description:	Regresa valor de campo
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_valorCampoXML]
	@contenido_xml AS XML
	, @ruta_campo AS VARCHAR(500)
	, @valor AS VARCHAR(MAX) OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@command AS NVARCHAR(MAX)
	,@param AS NVARCHAR(500)

SELECT @param = N'@value_out VARCHAR(MAX) OUTPUT'

SELECT
	@command = (
		'DECLARE @cont_xml AS XML = ''' + REPLACE(CONVERT(VARCHAR(MAX), @contenido_xml), '''', '''''') + ''''
		+ CHAR(13)
		+ ';WITH XMLNAMESPACES (''http://www.sat.gob.mx/cfd/3'' AS cfdi, ''http://www.sat.gob.mx/TimbreFiscalDigital'' AS tfd) '
		+ CHAR(13)
		+ 'SELECT @value_out = @cont_xml.value(''(' + @ruta_campo + ')[1]'', ''VARCHAR(MAX)'')'
	)

EXEC sp_executesql @command, @param, @value_out = @valor OUTPUT
GO
