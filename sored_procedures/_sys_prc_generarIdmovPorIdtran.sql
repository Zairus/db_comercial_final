USE db_comercial_final
GO
ALTER PROCEDURE _sys_prc_generarIdmovPorIdtran
	@idtran AS INT
	, @tabla_nombre AS VARCHAR(500)
AS

SET NOCOUNT ON

DECLARE
	@sql AS NVARCHAR(MAX)
	, @tabla_codigo AS VARCHAR(20)

SELECT
	@tabla_codigo = tabla
FROM
	evoluware_tablas
WHERE
	nombre = @tabla_nombre
	
SELECT
	@sql = N'
DECLARE
	@idr AS INT
	, @idmov AS MONEY
	, @idtran AS INT = ' + LTRIM(RTRIM(STR(@idtran))) + '
	, @tabla AS VARCHAR(20) = ''' + @tabla_codigo + '''

DECLARE cur_genera_idmov CURSOR FOR
	SELECT idr
	FROM ' + @tabla_nombre + '
	WHERE
		idtran = @idtran
		AND ISNULL(idmov, 0) = 0

OPEN cur_genera_idmov

FETCH NEXT FROM cur_genera_idmov INTO
	@idr

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @idmov = dbo.NewIDMOV(@idtran, @tabla)

	INSERT INTO ew_sys_movimientos (idmov, tabla) VALUES(@idmov, @tabla)

	UPDATE ' + @tabla_nombre + ' SET idmov = @idmov WHERE idr = @idr

	FETCH NEXT FROM cur_genera_idmov INTO
		@idr
END

CLOSE cur_genera_idmov
DEALLOCATE cur_genera_idmov
'

EXEC sp_executesql @sql
GO
