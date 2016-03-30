USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160329
-- Description:	Generar documento PDF para descarga
-- =============================================
ALTER PROCEDURE _cfd_prc_generarPDF
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@transaccion AS VARCHAR(5)
	,@pdf_rs AS VARCHAR(4000)
	,@success AS BIT
	,@archivoPDF AS VARCHAR(4000)

SELECT
	@transaccion = transaccion
FROM
	ew_sys_transacciones
WHERE
	idtran = @idtran

SELECT
	@pdf_rs = (CASE WHEN @transaccion = 'EFA4' THEN REPLACE(p.PDF_RS, 'EFA1', 'EFA4') ELSE p.PDF_RS END)
FROM
	ew_cfd_parametros AS p

SELECT @pdf_rs = REPLACE(@pdf_rs, '{idtran}', RTRIM(CONVERT(VARCHAR(15),@idtran)))

SELECT @archivoPDF = REPLACE(archivoXML, '.xml', '.pdf') FROM ew_cfd_comprobantes_sello

SELECT @success = db_comercial.dbo.WEB_download(@pdf_rs, @archivoPDF, '', '')

SELECT [codigo] = @success, [ruta] = @archivoPDF
GO
