USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170814
-- Description:	Generar Archivo PDF
-- =============================================
ALTER PROCEDURE [dbo].[_cfdi_prc_generarPDF]
	@idtran AS INT
	, @ruta AS VARCHAR(1000) = NULL OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@PDF_rs AS VARCHAR(4000)
	, @transaccion AS VARCHAR(5)
	, @msg AS VARCHAR(200)
	, @success AS BIT
	, @presentar AS BIT = 1

IF @ruta IS NOT NULL
BEGIN
	SELECT @presentar = 0
END

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
		+ '&ServidorSQL=Data Source=erp.evoluware.com,1093;Initial Catalog=' + DB_NAME()
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
		@ruta = (
			cer.directorio 
			+ c.rfc_emisor 
			+ '_' 
			+ c.cfd_serie 
			+ '-' 
			+ CONVERT(VARCHAR(10),c.cfd_folio) 
			+ '.pdf'
		)
	FROM
		ew_cfd_comprobantes AS c
		LEFT JOIN ew_cfd_folios AS f 
			ON f.idfolio = c.idfolio
		LEFT JOIN evoluware_certificados AS cer 
			ON cer.idcertificado = f.idcertificado
	WHERE
		c.idtran = @idtran
END

SELECT @pdf_rs = REPLACE(@pdf_rs, '{idtran}', RTRIM(CONVERT(VARCHAR(15), @idtran)))

IF [dbEVOLUWARE].[dbo].[_sys_fnc_fileExists](@ruta) = 1
BEGIN
	SELECT @success = 1
END
	ELSE
BEGIN
	SELECT @success = [dbEVOLUWARE].[dbo].[web_download_v2](@PDF_rs, @ruta, '', '')
END

IF @success != 1
BEGIN
	SELECT @msg = 'No se pudo generar el archivo PDF...'
	RAISERROR(@msg, 16, 1)
	RETURN
END

IF @presentar = 1
BEGIN
	SELECT [ruta] = @ruta
END
GO
