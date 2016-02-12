USE db_comercial_final

DECLARE
	@idparametro AS INT

IF NOT EXISTS (SELECT * FROM ew_sys_parametros WHERE codigo = 'LISTAPRECIOS_MARGENMINIMO')
BEGIN
	SELECT @idparametro = MAX(idparametro) FROM ew_sys_parametros

	SELECT @idparametro = ISNULL(@idparametro, 0) + 1

	INSERT INTO ew_sys_parametros (
		idparametro
		,codigo
		,nombre
		,activo
		,valor
		,descripcion
	)
	VALUES (
		@idparametro
		,'LISTAPRECIOS_MARGENMINIMO'
		,'Margen mínimo deseado para venta sobre costo'
		,1
		,0.20
		,'Representa el margen mínimo sobre el costo a obtener con una venta'
	)
END

SELECT * FROM ew_sys_parametros WHERE codigo = 'LISTAPRECIOS_MARGENMINIMO'