USE db_comercial_final
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 201011XX
-- Description:	Enviar acuse de cancelacion
-- =============================================
ALTER PROCEDURE [dbo].[_cfd_prc_enviarEmailAcuse]
	@idtran AS INT
	,@email AS VARCHAR(200) = ''
	,@asunto AS VARCHAR(500) = ''
	,@urgente AS BIT = 1
AS

SET NOCOUNT ON

DECLARE
	@cadena AS VARCHAR(MAX)
	, @xml_path_c AS NVARCHAR(MAX)
	, @transaccion AS VARCHAR(5) = ''
	, @folio AS VARCHAR(15) = ''
	, @idcliente AS SMALLINT = 0
	, @razon_social AS VARCHAR(200) = ''

DECLARE
	@idserver AS SMALLINT
	, @message_sender AS VARCHAR(200)
	, @message_subject AS VARCHAR(500) = @asunto
	, @message_body AS VARCHAR(4000) = ''
	, @message_bodyHTML AS BIT = 0
	, @message_cc AS VARCHAR(500)
	, @msg AS VARCHAR(4000)

DECLARE
	@id AS INT
	, @exists AS INT = 0
	, @PDF_rs AS VARCHAR(4000)
	, @success AS BIT

SELECT 
	@cadena = acuse 
FROM 
	dbo.ew_cfd_comprobantes_cancelados 
WHERE 
	idtran = @idtran

IF @@ROWCOUNT = 0 OR @cadena NOT LIKE '<?xml%'
BEGIN
	RAISERROR ('No se encontró acuse de cancelación.',16,1)
	RETURN
END

----------------------------------------------------------------------
-- Obtenemos el acuse de cancelacion
----------------------------------------------------------------------
SELECT 
	@transaccion = st.transaccion 
	, @folio = st.folio 
	, @idcliente = ct.idcliente
	, @razon_social = cfa.razon_social
	, @xml_path_c = ccs.archivoXML
	, @message_subject = (
		'Ha recibido acuse de cancelacion CFDI de ' 
		+ (
			CASE 
				WHEN ISNULL(e.nombre, '') = '' THEN ISNULL(e.razon_social, '') 
				ELSE ISNULL(e.nombre, '') 
			END
		)
	)
	, @PDF_rs = (
		dbo.fn_sys_obtenerDato('DEFAULT', '?50')
		+ 'Pages/ReportViewer.aspx?/'
		+ 'Modelo/Cobranza/CXC_CFDI33_CANC'
		+ '&rs:Command=Render'
		+ '&rc:Toolbar=true'
		+ '&rc:parameters=false'
		+ '&dsu:Conexion_servidor=' + dbo.fn_sys_obtenerDato('DEFAULT', '?52')
		+ '&dsp:Conexion_servidor=' + dbo.fn_sys_obtenerDato('DEFAULT', '?53')
		+ '&rs:format=PDF'
		+ '&ServidorSQL=Data Source=104.198.96.129,1093;Initial Catalog=' + DB_NAME()
		+ '&idtran='
		+ LTRIM(RTRIM(STR(st.idtran)))
	)
FROM 
	dbo.ew_sys_transacciones AS st
	LEFT JOIN dbo.ew_cxc_transacciones AS ct
		ON ct.idtran = st.idtran
	LEFT JOIN ew_clientes_facturacion AS cfa
		ON cfa.idcliente = ct.idcliente 
		AND cfa.idfacturacion = 0
	LEFT JOIN ew_cfd_comprobantes_sello AS ccs
		ON ccs.idtran = st.idtran
	LEFT JOIN vew_clientes AS e
		ON e.idcliente = 0
WHERE
	st.idtran = @idtran

SELECT @xml_path_c = REPLACE(@xml_path_c, '.xml', '_Acuse.xml')
SELECT @idserver = CONVERT(SMALLINT, dbo.fn_sys_parametro('EMAIL_IDSERVER'))

SELECT @exists = [dbEVOLUWARE].[dbo].[_sys_fnc_fileExists](@xml_path_c)

IF @exists = 0
BEGIN
	SELECT @msg = [dbEVOLUWARE].[dbo].[txt_save](@cadena, @xml_path_c)
END

SELECT @success = [db_comercial].[dbo].[WEB_download](@PDF_rs, REPLACE(@xml_path_c, '.xml', '.pdf'), '', '')

IF @success = 1
BEGIN
	SELECT
		@xml_path_c = (
			@xml_path_c
			+ ';'
			+ REPLACE(@xml_path_c, '.xml', '.pdf')
		)
END

SELECT
	@message_body = (
		'Estimado Cliente ' + ISNULL(@razon_social, '') + ': 

** La siguiente factura ha sido cancelada: FOLIO ' + @folio + ' **

FAVOR DE NO RESPONDER A ESTE CORREO.

Adjunto encontrara el acuse de cancelación con el cual se confirma la cancelación en el SAT.
'
	)

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
SELECT
	[db] = DB_NAME()
	, [idtran] = @idtran
	, [idserver] = @idserver
	, [message_to] = @email
	, [message_subject] = @message_subject
	, [message_body] = @message_body
	, [message_bodyHTML] = @message_bodyHTML
	, [message_attachment] = @xml_path_c
	, [urgente] = @urgente
	, [message_cc] = @message_cc

IF @urgente = 1
BEGIN
	SELECT TOP 1 
		@id = ISNULL(idr,0) 
	FROM 
		[dbEVOLUWARE].[dbo].[ew_sys_email]
	WHERE 
		idtran = @idtran 
	ORDER BY 
		idr DESC

	IF @id > 0
	BEGIN
		EXEC [dbEVOLUWARE].[dbo].[_adm_prc_enviarEmail] @id
	END
END
GO
