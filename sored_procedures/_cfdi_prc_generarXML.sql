USE db_comercial_final
GO
IF OBJECT_ID('_cfdi_prc_generarXML') IS NOT NULL
BEGIN
	DROP PROCEDURE _cfdi_prc_generarXML
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200106
-- Description:	Generar XML para descarga
-- =============================================
CREATE PROCEDURE [dbo].[_cfdi_prc_generarXML]
	@idtran AS INT
	, @ruta AS VARCHAR(1000) = NULL OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@ruta_temp AS VARCHAR(1000)
	, @cmd AS NVARCHAR(500)
	, @presentar AS BIT = 1
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

SELECT @ruta = @ruta_temp + @archivo_plantilla + '.xml'

IF @presentar = 1
BEGIN
	SELECT [ruta] = @ruta
END
GO
