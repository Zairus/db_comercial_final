USE db_comercial_final

IF NOT EXISTS (SELECT * FROM ew_sys_parametros WHERE codigo = 'CXP_GASTOSRELACIONADOS')
BEGIN 
	DECLARE
		@idparametro AS INT

	SELECT 
		@idparametro = MAX(idparametro)
	FROM
		ew_sys_parametros

	SELECT @idparametro = ISNULL(@idparametro, 0) + 1

	INSERT INTO ew_sys_parametros (
		idparametro
		,codigo
		,nombre
		,activo
		,valor
	)
	SELECT
		[idparametro] = @idparametro
		,[codigo] = 'CXP_GASTOSRELACIONADOS'
		,[nombre] = 'Usar solo conceptos de gasto relacionados en el catalogo de proveedores'
		,[activo] = 0
		,[valor] = '0'
END

SELECT * FROM ew_sys_parametros WHERE codigo = 'CXP_GASTOSRELACIONADOS'
