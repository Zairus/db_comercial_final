USE db_comercial_final
GO
-- SP: 	Envia por correo un Comprobante Fiscal Digital
-- 		Elaborado por Laurence Saavedra
-- 		Creado en Noviembre del 2010
--		LAUSAA 201508 - ignora al no estar timbrado
--		
-- EXEC _cfd_prc_enviarEmail 100021, 'laurence@evoluware.com', 'gruposd'
ALTER PROCEDURE [dbo].[_cfd_prc_enviarEmail]
	@idtran AS INT
	,@email AS VARCHAR(200) = ''
	,@mensaje AS VARCHAR(4000) = ''
	,@urgente AS BIT = 1
AS

SET NOCOUNT ON

DECLARE
	@archivoXML AS VARCHAR(500)
	,@cadena AS VARCHAR(MAX)
	,@msg AS VARCHAR(200)

	,@XML_email AS BIT
	,@PDF_email AS BIT
	,@PDF_guardar AS BIT
	,@PDF_rs AS VARCHAR(4000)
	,@success AS BIT
	
	,@transaccion AS VARCHAR(5) = ''

--Validamos que la transaccion no se encuentre timbrada
IF NOT EXISTS(SELECT idtran FROM dbo.ew_cfd_comprobantes_timbre WHERE idtran = @idtran)
BEGIN
	IF @urgente = 1
	BEGIN
		SELECT @msg = '[2001] La transaccion no se encuentra timbrada'
		RAISERROR(@msg, 16, 1)
	END

	RETURN
END

----------------------------------------------------------------------
-- Porque siempre agarra los parametros de la EFA1 para generar el PDF
-- Tuve que agregar 2 campos más
-- 1 para la ruta de la EDE1 y otro para la ruta de la FDA2
----------------------------------------------------------------------
SELECT @transaccion = transaccion
FROM ew_sys_transacciones 
WHERE idtran = @idtran

----------------------------------------------------------------
-- Obtenemos los parametros generales
----------------------------------------------------------------
SELECT TOP 1
	@XML_email = p.XML_email
	,@PDF_guardar = p.PDF_guardar
	,@PDF_email = p.PDF_email
	,@PDF_rs = (
				CASE WHEN @transaccion = 'EFA1' THEN p.PDF_RS ELSE
					CASE WHEN @transaccion = 'EDE1' THEN p.PDF_RS1 ELSE
						CASE WHEN @transaccion = 'FDA2' THEN p.PDF_RS2 ELSE
							CASE WHEN @transaccion = 'EFA4' THEN p.PDF_RS3 ELSE
								CASE WHEN @transaccion = 'EFA6' THEN p.PDF_RS ELSE ''
								END
							END
						END
					END
				END
	)
FROM
	ew_cfd_parametros AS p

SELECT 
	@archivoXML = ISNULL(archivoXML, '')
FROM
	ew_cfd_comprobantes_sello AS s
WHERE
	idtran = @idtran

IF @archivoXML = ''
BEGIN
	SELECT
		@archivoXML = cer.directorio + c.rfc_emisor + '_' + c.cfd_serie + '-' + CONVERT(VARCHAR(10),c.cfd_folio) + '.xml'
		, @XML_email = 0
	FROM
		ew_cfd_comprobantes AS c
		LEFT JOIN ew_cfd_folios AS f 
			ON f.idfolio = c.idfolio
		LEFT JOIN evoluware_certificados AS cer 
			ON cer.idcertificado = f.idcertificado
	WHERE
		c.idtran = @idtran
END

IF @archivoXML IS NULL
BEGIN
	SELECT @archivoXML = 'C:\Evoluware\Temp\Documento_' + RTRIM(CONVERT(VARCHAR(10),@idtran)) + '.xml', @XML_email = 0
END

----------------------------------------------------------------
-- Generamos el archivo PDF
----------------------------------------------------------------
IF @PDF_guardar = 1
BEGIN
	SELECT @pdf_rs = REPLACE(@pdf_rs,'{idtran}',RTRIM(CONVERT(VARCHAR(15),@idtran)))
	
	SELECT @cadena = 'C:\EVOLUWARE\Temp\' + RIGHT(@archivoXML,PATINDEX('%\%',REVERSE(@archivoXML))-1) + '.pdf'
	
	SELECT @success = db_comercial.dbo.WEB_download(@PDF_rs,@cadena, '', '')

	IF @success != 1
	BEGIN
		SELECT @msg = 'No se pudo generar el archivo PDF...'
		RAISERROR(@msg, 16, 1)
		RETURN
	END
END

----------------------------------------------------------------
-- Enviamos por correo electronico
----------------------------------------------------------------
IF (@email != '') AND (@XML_email = 1 OR @PDF_email = 1)
BEGIN
	SELECT @pdf_rs = ''

	IF @XML_email = 1 SELECT @pdf_rs = @archivoXML
	IF @PDF_email = 1 SELECT @pdf_rs = @pdf_rs + (CASE WHEN @pdf_rs='' THEN '' ELSE ';' END) + @cadena

	SELECT @cadena = 'Mensaje generado automaticamente por el servidor: ' + CONVERT(VARCHAR(20),GETDATE(),0) + '' + @mensaje

	DECLARE
		@idserver AS SMALLINT
		,@message_sender AS VARCHAR(200)
		,@message_subject AS VARCHAR(200)
		,@message_body AS VARCHAR(MAX)
		,@message_bodyHTML AS VARCHAR(200)
		,@message_cc AS VARCHAR(200)

	SELECT @idserver = CONVERT(SMALLINT, dbo.fn_sys_parametro('EMAIL_IDSERVER'))
	SELECT @message_subject = dbo.fn_sys_parametro('EMAIL_SUBJECT')
	SELECT @message_body = dbo.fn_sys_parametro('EMAIL_BODY') + ' ' + CHAR(13) + CHAR(10) + @mensaje
	SELECT @message_bodyHTML = CONVERT(BIT, dbo.fn_sys_parametro('EMAIL_BODYHTML'))
	SELECT @message_cc = RTRIM(dbo.fn_sys_parametro('EMAIL_CC'))
	SELECT @message_cc = RTRIM(LTRIM(@message_cc))
	
	INSERT INTO dbEVOLUWARE.dbo.ew_sys_email (
		db
		, idtran
		, idserver
		, message_to
		, message_subject
		, message_body
		, message_bodyHTML
		, message_attachment
		, urgente
		, message_cc
	)
	VALUES (
		DB_NAME()
		, @idtran
		, @idserver
		, @email
		, @message_subject
		, @message_body
		, @message_bodyHTML
		, @pdf_rs,@urgente
		, @message_cc
	)

	IF @urgente = 1
	BEGIN
		DECLARE @id INT

		SELECT TOP 1 @id = ISNULL(idr,0) 
		FROM dbEVOLUWARE.dbo.ew_sys_email 
		WHERE idtran = @idtran 
		ORDER BY idr DESC

		IF @id > 0
		BEGIN
			EXEC dbEVOLUWARE.dbo._adm_prc_enviarEmail @id
		END
	END
END
GO
