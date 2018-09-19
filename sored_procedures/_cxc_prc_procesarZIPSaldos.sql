USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180831
-- Description:	Carga archivo ZIP con XML de clientes para saldos
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_procesarZIPSaldos]
	@contenido AS VARCHAR(MAX)
AS

SET NOCOUNT ON

DECLARE
	@path AS VARCHAR(MAX)
	,@path_dir AS VARCHAR(MAX)
	,@file_name AS VARCHAR(50) = CONVERT(VARCHAR(50), NEWID()) + '.zip'
	,@r AS BIT
	,@path_command AS NVARCHAR(1000)
	,@path_file AS VARCHAR(MAX)
	,@path_file_extracted AS VARCHAR(MAX)

DECLARE
	@files AS TABLE (
		id INT IDENTITY
		, [file_name] VARCHAR(200)
	)

SELECT
	@path = (
		'F:\Clientes\' 
		+ scsfs.direccion 
		+ '\'
		+ 'temp\'
		+ @file_name
	)
FROM
	dbEVOLUWARE.dbo.ew_sys_cuentas_servicios AS scs
	LEFT JOIN dbEVOLUWARE.dbo.ew_sys_cuentas_servicios AS scsfs
		ON scsfs.servicio_id = 3
		AND scsfs.cuenta_id = scs.cuenta_id
WHERE
	scs.servicio_id = 1
	AND scs.objeto_inicio = DB_NAME()

SELECT @r = [dbEVOLUWARE].[dbo].[base64_save](@contenido, @path)

SELECT @path_dir = REPLACE(@path, '.zip', '')

EXEC [dbEVOLUWARE].[dbo].[zip_extract] @path, @path_dir

SELECT @path_command = N'dir ' + CONVERT(NVARCHAR(1000), @path_dir) + N' /b'

INSERT INTO @files EXECUTE xp_cmdshell @path_command

DECLARE cur_leidos CURSOR FOR
	SELECT
		[file_name]
	FROM 
		@files 
	WHERE 
		[file_name] IS NOT NULL 
		AND [file_name] LIKE '%.xml'

OPEN cur_leidos

FETCH NEXT FROM cur_leidos INTO
	@path_file

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @path_file_extracted = @path_dir + '\' + @path_file

	EXEC _cxc_prc_saldoLeerXML @path_file_extracted

	FETCH NEXT FROM cur_leidos INTO
		@path_file
END

CLOSE cur_leidos
DEALLOCATE cur_leidos

EXEC _cxc_prc_migracionPendientesDeCaptura
GO
