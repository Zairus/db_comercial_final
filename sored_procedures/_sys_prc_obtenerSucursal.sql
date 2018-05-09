USE db_comercial_final
GO
ALTER PROCEDURE _sys_prc_obtenerSucursal
	@idtran AS INT
	,@idsucursal AS INT OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@cmd AS NVARCHAR(200)
	,@param AS NVARCHAR(100)
	,@stop AS BIT = 0

SELECT @param = N'@idtranIN INT, @idsucursalOUT INT OUTPUT'

DECLARE cur_sbusqueda CURSOR FOR
	SELECT
		[cmd] = 'SELECT @idsucursalOUT = idsucursal FROM dbo.' + [st].[name] + ' WHERE idtran = @idtranIN'
	FROM 
		sys.columns AS sc 
		LEFT JOIN sys.tables AS st
			ON [st].[object_id] = [sc].[object_id]
	WHERE 
		[sc].[name] = 'idsucursal'
		AND [sc].[object_id] IN (
			SELECT [sc1].[object_id] 
			FROM sys.columns AS sc1 
			WHERE [sc1].[name] = 'idtran'
		)
		AND [st].[name] IS NOT NULL

OPEN cur_sbusqueda

WHILE @@FETCH_STATUS = 0 OR @stop = 0
BEGIN
	FETCH NEXT FROM cur_sbusqueda INTO
		@cmd

	EXECUTE sp_executesql
		@cmd
		, @param
		, @idtranIN = @idtran
		, @idsucursalOUT = @idsucursal OUTPUT

	IF ISNULL(@idsucursal, 0) > 0
	BEGIN
		SELECT @stop = 1
	END
END

SELECT @idsucursal = ISNULL(@idsucursal, 0)

CLOSE cur_sbusqueda
DEALLOCATE cur_sbusqueda
GO
