USE db_comercial_final
GO
-- SP: 	Envia un correo electrónico
-- 		Elaborado por Laurence Saavedra
-- 		Creado en Junio 2012
--		
-- EXEC _sys_prc_enviarEmail 1939, 'laurence@evoluware.com', ''
ALTER PROCEDURE [dbo].[_sys_prc_enviarEmail]
	@To AS VARCHAR(200) = ''
	, @CC AS VARCHAR(200) = ''
	, @subject AS VARCHAR(100) = ''
	, @body AS VARCHAR(4000) = ''
	, @File_Url AS VARCHAR(1000) = ''
	, @File_Name AS VARCHAR(100) = ''
	, @File_User AS VARCHAR(100) = ''
	, @File_Pass As VARCHAR(100) = ''
	, @idu AS INT = 0
AS

SET NOCOUNT ON

IF @File_Url != '' AND @File_Name = ''
BEGIN
	RAISERROR('Se requiere nombre del archivo a adjuntar.', 16, 1)
	RETURN
END

DECLARE
	@archivoXML AS VARCHAR(200)
	, @cadena AS VARCHAR(MAX)
	, @msg As VARCHAR(200)
	, @XML_email AS BIT
	, @PDF_email AS BIT
	, @PDF_guardar AS BIT
	, @PDF_rs AS VARCHAR(4000)
	, @success AS BIT	

DECLARE
	@idserver AS SMALLINT
	, @id AS INT

DECLARE
	@v AS VARCHAR(100)
	, @idtran AS INT

----------------------------------------------------------------
-- Generamos el archivo Attachment
----------------------------------------------------------------
BEGIN
	SELECT @File_Name = 'C:\Evoluware\Temp\' + @File_Name

	SELECT @success = [db_comercial].[dbo].[WEB_download](@File_Url, @File_Name, @File_User, @File_Pass)

	IF @success != 1
	BEGIN
		SELECT @msg = 'No se pudo adjuntar el Archivo.'

		RAISERROR(@msg, 16, 1)
		RETURN
	END
END

SELECT @v = valor FROM dbo._sys_fnc_separarMultilinea(@file_url, '&') WHERE valor LIKE '%idtran%'

IF @v IS NOT NULL
BEGIN
	SELECT @idtran = CONVERT(INT, valor) FROM dbo._sys_fnc_separarMultilinea(@v, '=') WHERE idr = 2
END

----------------------------------------------------------------
-- Enviamos por correo electronico
----------------------------------------------------------------

SELECT
	@idserver = crc.idserver
FROM
	ew_cat_roles_correo AS crc
	LEFT JOIN evoluware_usuarios AS u
		ON u.idrol = crc.idrol
	LEFT JOIN objetos AS o
		ON o.tipo = 'XAC'
		AND o.objeto > 0
		AND o.objeto = crc.objeto
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = @idtran
WHERE
	u.idu = @idu
	AND ISNULL(o.codigo, st.transaccion) = st.transaccion

IF @idserver IS NULL
BEGIN
	SELECT @idserver = ISNULL(CONVERT(SMALLINT, [dbo].[fn_sys_parametro]('EMAIL_IDSERVER')), 1)
END

SELECT @CC = ISNULL([dbo].[fn_sys_parametro]('EMAIL_CC'), '')

INSERT INTO [dbEVOLUWARE].[dbo].[ew_sys_email] (
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
	, [idtran] = 0
	, [idserver] = @idserver
	, [message_to] = @To
	, [message_subject] = @subject
	, [message_body] = @body
	, [message_bodyHTML] = 0
	, [message_attachment] = @File_Name
	, [urgente] = 1
	, [message_cc] = @CC

SELECT @id = SCOPE_IDENTITY()

IF @id > 0
BEGIN
	EXEC [dbEVOLUWARE].[dbo].[_adm_prc_enviarEmail] @id
END
GO
