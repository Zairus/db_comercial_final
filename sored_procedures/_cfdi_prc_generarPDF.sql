USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170814
-- Description:	Generar Archivo PDF
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_generarPDF]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@ruta AS VARCHAR(1000)
	,@PDF_rs AS VARCHAR(4000)
	,@transaccion AS VARCHAR(5)
	,@msg AS VARCHAR(200)
	,@success AS BIT

SELECT
	@transaccion = transaccion
FROM
	ew_sys_transacciones
WHERE
	idtran = @idtran

SELECT 
	@ruta = REPLACE(archivoXML, '.xml', '.pdf')
FROM 
	ew_cfd_comprobantes_sello 
WHERE 
	idtran = @idtran

SELECT TOP 1
	@PDF_rs = ISNULL((
		dbo.fn_sys_obtenerDato('DEFAULT', '?50')
		+ 'Pages/ReportViewer.aspx?/'
		+ od.valor
		+ '&rs:Command=Render'
		+ '&rc:Toolbar=true'
		+ '&rc:parameters=false'
		+ '&dsu:Conexion_servidor=' + dbo.fn_sys_obtenerDato('DEFAULT', '?52')
		+ '&dsp:Conexion_servidor=' + dbo.fn_sys_obtenerDato('DEFAULT', '?53')
		+ '&rs:format=PDF'
		+ '&ServidorSQL=Data Source=104.198.96.129,1093;Initial Catalog=' + DB_NAME()
		+ '&idtran={idtran}'
	), p.PDF_RS)
FROM
	ew_cfd_parametros AS p
	LEFT JOIN objetos AS o
		ON o.codigo = @transaccion
	LEFT JOIN objetos_datos AS od
		ON od.objeto = o.objeto
		AND od.codigo = 'REPORTERS'
	
IF NOT EXISTS(SELECT idtran FROM dbo.ew_cfd_comprobantes_timbre WHERE idtran = @idtran)
BEGIN
	SELECT @msg = '[2001] La transaccion no se encuentra timbrada'
	RAISERROR(@msg, 16, 1)

	RETURN
END

IF @ruta = ''
BEGIN
	SELECT
		@ruta = cer.directorio + c.rfc_emisor + '_' + c.cfd_serie + '-' + CONVERT(VARCHAR(10),c.cfd_folio) + '.pdf'
	FROM
		ew_cfd_comprobantes AS c
		LEFT JOIN ew_cfd_folios AS f 
			ON f.idfolio = c.idfolio
		LEFT JOIN evoluware_certificados AS cer 
			ON cer.idcertificado = f.idcertificado
	WHERE
		c.idtran = @idtran
END

SELECT @pdf_rs = REPLACE(@pdf_rs, '{idtran}', RTRIM(CONVERT(VARCHAR(15),@idtran)))

SELECT @success = db_comercial.dbo.WEB_download(@PDF_rs, @ruta, '', '')

IF @success != 1
BEGIN
	SELECT @msg = 'No se pudo generar el archivo PDF...'
	RAISERROR(@msg, 16, 1)
	RETURN
END

SELECT [ruta] = @ruta
GO
