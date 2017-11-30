USE db_comercial_final
GO
ALTER TRIGGER [dbo].[tg_ew_sys_parametros_u]
	ON [dbo].[ew_sys_parametros]
	INSTEAD OF UPDATE
AS

SET NOCOUNT ON

DECLARE
	@idparametro AS INT

IF NOT EXISTS (
	SELECT * 
	FROM 
		ew_sys_parametros_local AS pl 
	WHERE 
		pl.codigo IN (
			SELECT i.codigo
			FROM inserted AS i
		)
)
BEGIN
	SELECT 
		@idparametro = MAX(idparametro) 
	FROM 
		ew_sys_parametros_local

	SELECT @idparametro = ISNULL(@idparametro, 0) + 1

	INSERT INTO ew_sys_parametros_local (
		idparametro
		,codigo
		,nombre
		,descripcion
		,activo
		,valor
		,comando
	)
	SELECT
		[idparametro] = @idparametro
		,codigo
		,nombre
		,descripcion
		,activo
		,valor
		,comando
	FROM
		inserted
END
	ELSE
BEGIN
	UPDATE pl SET
		pl.activo = i.activo
		,pl.valor = i.valor
		,pl.comando = i.comando
	FROM
		inserted AS i
		LEFT JOIN ew_sys_parametros_local AS pl
			ON pl.codigo = i.codigo
END
GO
