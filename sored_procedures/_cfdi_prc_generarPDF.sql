USE db_refriequipos_datos
GO
IF OBJECT_ID('_cfdi_prc_generarPDF') IS NOT NULL
BEGIN
	DROP PROCEDURE _cfdi_prc_generarPDF
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170814
-- Description:	Generar Archivo PDF
-- =============================================
CREATE PROCEDURE [dbo].[_cfdi_prc_generarPDF]
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
	, @ruta_temp AS VARCHAR(1000)
	, @cmd AS NVARCHAR(500)
	, @archivo_plantilla AS VARCHAR(200)

	, @directorio AS VARCHAR(150)
	, @cfd_emisor_rfc AS VARCHAR(13)
	, @cfd_folio AS INT
	, @cfd_serie AS VARCHAR(10)
	, @cfd_uuid AS VARCHAR(50)

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
	@cfd_emisor_rfc = c.rfc_emisor
	, @cfd_serie = c.cfd_serie
	, @cfd_folio = c.cfd_folio
	, @cfd_uuid = cct.cfdi_uuid
	, @directorio = cer.directorio
FROM
	ew_cfd_comprobantes AS c
	LEFT JOIN ew_cfd_folios AS f 
		ON f.idfolio = c.idfolio
	LEFT JOIN evoluware_certificados AS cer 
		ON cer.idcertificado = f.idcertificado
	LEFT JOIN ew_cfd_comprobantes_timbre AS cct
		ON cct.idtran = c.idtran
WHERE
	c.idtran = @idtran

SELECT 
	@ruta = REPLACE(archivoXML, '.xml', '')
FROM 
	ew_cfd_comprobantes_sello 
WHERE 
	idtran = @idtran

SELECT @ruta_temp = LEFT(@ruta, LEN(@ruta) - CHARINDEX('\', REVERSE(@ruta), 1) + 1)
SELECT @ruta_temp = LEFT(@ruta_temp, LEN(@ruta_temp) - 1)
SELECT @ruta_temp = LEFT(@ruta_temp, LEN(@ruta_temp) - CHARINDEX('\', REVERSE(@ruta_temp), 1) + 1)
SELECT @ruta_temp = @ruta_temp + 'TEMP\'

EXEC [dbEVOLUWARE].[dbo].[dir_create] @ruta_temp

SELECT @archivo_plantilla = [dbo].[_sys_fnc_parametroTexto]('CFDI_NOMBRE_ARCHIVO')
SELECT @archivo_plantilla = REPLACE(@archivo_plantilla, '{RFC}', @cfd_emisor_rfc)
SELECT @archivo_plantilla = REPLACE(@archivo_plantilla, '{SERIE}', @cfd_serie)
SELECT @archivo_plantilla = REPLACE(@archivo_plantilla, '{FOLIO}', dbo.fnRellenar(RTRIM(CONVERT(VARCHAR(10), @cfd_folio)), 5, '0'))
SELECT @archivo_plantilla = REPLACE(@archivo_plantilla, '{UUID}', @cfd_uuid)

SELECT @cmd = 'copy "' + @ruta + '.xml" "' + @ruta_temp + @archivo_plantilla + '.xml"'

EXEC master.dbo.xp_cmdshell @cmd, 'no_output'

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

SELECT @ruta = @ruta_temp + @archivo_plantilla + '.pdf'

SELECT @pdf_rs = REPLACE(@pdf_rs, '{idtran}', RTRIM(CONVERT(VARCHAR(15), @idtran)))

IF [dbEVOLUWARE].[dbo].[file_exists](@ruta) = 1
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
