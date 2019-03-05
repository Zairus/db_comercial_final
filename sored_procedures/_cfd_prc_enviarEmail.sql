USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20100101
-- Description:	Envia por correo un Comprobante Fiscal Digital
-- =============================================
ALTER PROCEDURE [dbo].[_cfd_prc_enviarEmail]
	@idtran AS INT
	, @email AS VARCHAR(200) = ''
	, @mensaje AS VARCHAR(4000) = ''
	, @urgente AS BIT = 1
AS

SET NOCOUNT ON

DECLARE
	@archivoXML AS VARCHAR(500)
	, @cadena AS VARCHAR(MAX)
	, @msg AS VARCHAR(200)

	, @XML_email AS BIT
	, @PDF_email AS BIT
	, @PDF_guardar AS BIT
	, @PDF_rs AS VARCHAR(4000)
	, @success AS BIT
	
	, @transaccion AS VARCHAR(5) = ''

	, @folio VARCHAR(20) = ''
	, @empresa VARCHAR(200) = ''
	, @receptor_nombre VARCHAR(200)=''

-- Obtener folio y empresa para anexarlo al ASUNTO del Correo
SELECT 
	@folio = folio 
FROM 
	ew_sys_transacciones 
WHERE 
	idtran = @idtran

SELECT 
	@empresa = (CASE WHEN c.nombre = '' THEN cf.razon_social ELSE c.nombre END)
FROM 
	ew_clientes_facturacion cf
	LEFT JOIN ew_clientes AS c 
		ON c.idcliente = cf.idcliente
WHERE 
	cf.idcliente = 0 
	AND cf.idfacturacion = 0

SELECT 
	@receptor_nombre = ISNULL(receptor_nombre, '') 
FROM 
	ew_cfd_comprobantes 
WHERE 
	idtran = @idtran

--Validamos que la transaccion se encuentre timbrada
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
SELECT 
	@transaccion = transaccion
FROM 
	ew_sys_transacciones 
WHERE 
	idtran = @idtran

----------------------------------------------------------------
-- Obtenemos los parametros generales
----------------------------------------------------------------
SELECT TOP 1
	@XML_email = p.XML_email
	, @PDF_guardar = p.PDF_guardar
	, @PDF_email = p.PDF_email
	, @PDF_rs = '' /*ISNULL((
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
	), p.PDF_RS)*/
FROM
	ew_cfd_parametros AS p
	--LEFT JOIN objetos AS o
		--ON o.codigo = @transaccion
	--LEFT JOIN objetos_datos AS od
		--ON od.objeto = o.objeto
		--AND od.codigo = 'REPORTERS'

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
	SELECT @cadena = ''
	EXEC [dbo].[_cfdi_prc_generarPDF] @idtran, @cadena OUTPUT
	SELECT @success = 1
END

----------------------------------------------------------------
-- Enviamos por correo electronico
----------------------------------------------------------------
IF (@email != '') AND (@XML_email = 1 OR @PDF_email = 1)
BEGIN
	SELECT @pdf_rs = ''

	IF @XML_email = 1
	BEGIN
		SELECT @pdf_rs = @archivoXML
	END

	IF @PDF_email = 1 
	BEGIN
		SELECT @pdf_rs = @pdf_rs + (CASE WHEN @pdf_rs = '' THEN '' ELSE ';' END) + @cadena
	END

	SELECT @cadena = 'Mensaje generado automaticamente por el servidor: ' + CONVERT(VARCHAR(20),GETDATE(),0) + '' + @mensaje
	
	DECLARE
		@idserver AS SMALLINT
		, @message_sender AS VARCHAR(200)
		, @message_subject AS VARCHAR(200)
		, @message_body AS VARCHAR(MAX)
		, @message_bodyHTML AS VARCHAR(200)
		, @message_cc AS VARCHAR(200)

	SELECT @idserver = CONVERT(SMALLINT, dbo.fn_sys_parametro('EMAIL_IDSERVER'))
	SELECT @message_subject = dbo.fn_sys_parametro('EMAIL_SUBJECT') + ' Folio ' + @folio + ' de ' + @empresa
	SELECT @message_bodyHTML = CONVERT(BIT, dbo.fn_sys_parametro('EMAIL_BODYHTML'))
	SELECT @message_cc = RTRIM(dbo.fn_sys_parametro('EMAIL_CC'))
	SELECT @message_cc = RTRIM(LTRIM(@message_cc))

	SELECT
		@message_body = '<!DOCTYPE html>'
			+ '<html>'
			+ '<body>'
			+ (
				'Estimado Cliente' + CASE WHEN @receptor_nombre = '' THEN ':' ELSE ' ' + @receptor_nombre + ':' END
				+ '<br>'
				+ '<br>'
				+ 'Adjunto se envía ' 
				+ o.nombre 
				+ ' ' 
				+ ct.folio 
				+ ', generado el día '
				+ CONVERT(VARCHAR(8), ct.fecha, 3)
				+ '<br>'
				+ '<br>'
				+ (
					CASE
						WHEN ct.tipo = 1 AND ct.vencimiento IS NOT NULL THEN
							(
								'Programación de pago: '
								+ CONVERT(VARCHAR(8), ct.vencimiento, 3)
								+ '<br>'
							)
						ELSE ''
					END
				)
				+ 'Total: $'
				+ CONVERT(VARCHAR(20), CONVERT(MONEY, ct.total), 1)
				+ ISNULL((
					CASE
						WHEN ct.tipo = 1 THEN
							(
								'<br>'
								+ '<br>'
								+ 'DATOS PARA PAGO: '
								+ '<br>'
								+ (
									SELECT TOP 1
										bb.nombre 
										+ ' ' 
										+ bc.no_cuenta 
										+ ' SUC ' 
										+ bc.sucursal 
										+ ' CLABE: ' 
										+ bc.clabe 
										+ ' ' 
										+ bm.codigo
									FROM 
										ew_ban_cuentas AS bc 
										LEFT JOIN ew_ban_bancos As bb
											ON bb.idbanco = bc.idbanco
										LEFT JOIN ew_ban_monedas AS bm
											ON bm.idmoneda = bc.idmoneda
									WHERE 
										bc.imprimir = 1
								)
							)
						ELSE ''
					END
				), '')
			)
	FROM
		ew_cxc_transacciones AS ct
		LEFT JOIN objetos AS o
			ON o.codigo = ct.transaccion
	WHERE
		ct.idtran = @idtran
		
	SELECT 
		@message_body = (
			ISNULL(@message_body, dbo.fn_sys_parametro('EMAIL_BODY'))
			+ ' '
			+ '<br>'
			+ '<br>'
			+ @mensaje
			+ '</body></html>'
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
		, @idtran
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
		DECLARE @id INT

		SELECT TOP 1 
			@id = ISNULL(idr, 0) 
		FROM 
			dbEVOLUWARE.dbo.ew_sys_email 
		WHERE 
			idtran = @idtran 
		ORDER BY 
			idr DESC

		IF @id > 0
		BEGIN
			EXEC dbEVOLUWARE.dbo._adm_prc_enviarEmail @id
		END
	END
END
GO
