USE db_comercial_final
GO
IF OBJECT_ID('_cxc_prc_enviarEmailCXC') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxc_prc_enviarEmailCXC
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20191223
-- Description:	Enviar ant de saldos por correo.
-- =============================================
CREATE PROCEDURE [dbo].[_cxc_prc_enviarEmailCXC]
	@idmoneda INT
	, @idsucursal INT
	, @idcliente INT
	, @idu SMALLINT
	, @idvendedor SMALLINT
	, @email AS VARCHAR(200) = ''
	, @mensaje AS VARCHAR(4000) = ''
	, @urgente AS BIT = 1
	, @fecha AS VARCHAR(10) = NULL
AS

SET NOCOUNT ON

SELECT @fecha = ISNULL(@fecha,(CONVERT(VARCHAR(10), GETDATE(), 103)))

DECLARE
	@archivoPDF AS VARCHAR(500)
	, @cadena AS VARCHAR(MAX)
	, @msg AS VARCHAR(200)

	, @XML_email AS BIT
	, @PDF_email AS BIT
	, @PDF_guardar AS BIT
	, @PDF_rs AS VARCHAR(4000)
	, @success AS BIT
	
	, @transaccion AS VARCHAR(5) = ''

	, @folio VARCHAR(20) = ''
	, @codcliente VARCHAR(30) = ''
	, @empresa VARCHAR(200) = ''
	, @receptor_nombre VARCHAR(200)=''

	, @idserver AS SMALLINT
	, @message_sender AS VARCHAR(200)
	, @message_subject AS VARCHAR(200)
	, @message_body AS VARCHAR(MAX)
	, @message_bodyHTML AS VARCHAR(200)
	, @message_cc AS VARCHAR(200)

	, @id INT

DECLARE
	@uid AS VARCHAR(36)

SELECT @empresa = razon_social FROM ew_clientes_facturacion WHERE idcliente=0 AND idfacturacion=0
SELECT @receptor_nombre=ISNULL(nombre,''), @codcliente=ISNULL(codigo,'') FROM ew_clientes WHERE idcliente=@idcliente

SELECT @uid = NEWID()

SELECT TOP 1
	@XML_email = 0
	, @PDF_guardar = 1
	, @PDF_email = 1
	, @PDF_rs = ISNULL((
		dbo.fn_sys_obtenerDato('DEFAULT', '?50')
		+ 'Pages/ReportViewer.aspx?/'
		+ od.valor
		+ '&rs:Command=Render'
		+ '&idmoneda=' + CONVERT(VARCHAR(5),@idmoneda) -- {idmoneda}
		+ '&idsucursal=' + CONVERT(VARCHAR(5),@idsucursal) -- {idsucursal}
		+ '&idcliente=' + CONVERT(VARCHAR(5),@idcliente) -- {idcliente}
		+ '&idu=' + CONVERT(VARCHAR(5),@idu) --{5}
		+ '&idvendedor=' + CONVERT(VARCHAR(5),@idvendedor) --{idvendedor}
		+ '&detallado=1' -- SIEMPRE DETALLADO
		+ '&fecha=' + CONVERT(VARCHAR(10),@fecha)
		+ '&rc:Toolbar=true'
		+ '&rc:parameters=false'
		+ '&dsu:Conexion_servidor=' + dbo.fn_sys_obtenerDato('DEFAULT', '?52')
		+ '&dsp:Conexion_servidor=' + dbo.fn_sys_obtenerDato('DEFAULT', '?53')
		+ '&rs:format=PDF'
--		+ '&ServidorSQL=Data Source=erp.evoluware.com,1093;Initial Catalog=' + DB_NAME()
		+ '&ServidorSQL=Data Source=erp.evoluware.com,1093;Initial Catalog=' + DB_NAME()
	), '')
FROM
	objetos AS o LEFT JOIN objetos_datos AS od
		ON od.objeto = o.objeto AND od.codigo = 'REPORTERS'
WHERE
	o.codigo = 'AUX25'

----------------------------------------------------------------
-- Generamos el archivo PDF
----------------------------------------------------------------
IF @PDF_guardar = 1
BEGIN
	SELECT @archivoPDF = 'C:\Evoluware\Temp\AntiguedadDeSaldosCliente' + LTRIM(RTRIM(@codcliente)) + '-' + @uid + '.pdf'

	SELECT @cadena = 'C:\EVOLUWARE\Temp\' + RIGHT(@archivoPDF, PATINDEX('%\%', REVERSE(@archivoPDF)) - 1)
	
	SELECT @success = [dbEVOLUWARE].[dbo].[WEB_download_v2](@PDF_rs, @archivoPDF, '', '')

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

	IF @PDF_email = 1
	BEGIN
		SELECT @pdf_rs = @archivoPDF
	END
	
	SELECT @cadena = 'Mensaje generado automaticamente por el servidor: ' + CONVERT(VARCHAR(20),GETDATE(),0) + '' + @mensaje

	SELECT @idserver = CONVERT(SMALLINT, dbo.fn_sys_parametro('EMAIL_IDSERVER'))

	SELECT @message_subject = 'Antiguedad de Saldos para el cliente ' + @receptor_nombre

	SELECT @message_bodyHTML = CONVERT(BIT, dbo.fn_sys_parametro('EMAIL_BODYHTML'))
	SELECT @message_cc = RTRIM(dbo.fn_sys_parametro('EMAIL_CC'))
	SELECT @message_cc = RTRIM(LTRIM(@message_cc))
	
	SELECT
		@message_body = (
			'Estimado Cliente' + CASE WHEN @receptor_nombre = '' THEN ':' ELSE ' ' + @receptor_nombre + ':' END
			+ CHAR(13) + CHAR(10)
			+ CHAR(13) + CHAR(10)
			+ 'Adjunto se envia ' 
			+ 'INFORME DE ANTIGUEDAD DE SALDOS' 
			+ ' ' 
			+ 'generado el dia '
			+ CONVERT(VARCHAR(8), GETDATE(), 3)
		)

	SELECT 
		@message_body = (
			ISNULL(@message_body,'')
			+ ' '
			+ CHAR(13)+CHAR(10)
			+ CHAR(13)+CHAR(10)
			+ @mensaje
		)

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
		, 0
		, @idserver
		, @email
		, @message_subject
		, @message_body
		, @message_bodyHTML
		, @pdf_rs
		, @urgente
		, @message_cc
	)

	IF @urgente = 1
	BEGIN
		SELECT @id = SCOPE_IDENTITY()

		IF @id > 0
		BEGIN
			EXEC dbEVOLUWARE.dbo._adm_prc_enviarEmail @id
		END
	END
END
GO
