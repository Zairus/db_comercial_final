USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170622
-- Description:	Addenda Agnico
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_addendaAgnicoXML]
	@idtran AS INT
	,@addenda AS VARCHAR(MAX) OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@addenda_xml AS XML

SELECT
	@addenda_xml = g.XML
FROM (
	SELECT
		[Orden] = vt.no_orden
	FROM
		ew_ven_transacciones AS vt
	WHERE
		LEN(vt.no_orden) > 0
		AND vt.idtran = @idtran
	FOR XML PATH(''), TYPE
) AS g(XML)

SELECT @addenda = '<cfdi:Addenda>' + CONVERT(VARCHAR(MAX), @addenda_xml) + '</cfdi:Addenda>'
GO
