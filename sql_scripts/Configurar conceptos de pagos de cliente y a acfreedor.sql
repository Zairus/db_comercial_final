USE db_comercial_final

DECLARE
	@idparametro AS INT
	,@idarticulo AS INT

IF NOT EXISTS (SELECT * FROM ew_articulos WHERE codigo = 'CXPP')
BEGIN
	SELECT 
		@idarticulo = MAX(idarticulo)
	FROM
		ew_articulos

	SELECT @idarticulo = ISNULL(@idarticulo, 0) + 1

	INSERT INTO ew_articulos (
		idarticulo
		,codigo
		,nombre
		,idtipo
	)
	SELECT
		[idarticulo] = @idarticulo
		,[codigo] = 'CXPP'
		,[nombre] = 'Pago a Proveedor/Acreedor'
		,[idtipo] = 2

	SELECT @idarticulo = NULL
END

IF NOT EXISTS (SELECT * FROM ew_articulos WHERE codigo = 'CXCP')
BEGIN
	SELECT 
		@idarticulo = MAX(idarticulo)
	FROM
		ew_articulos

	SELECT @idarticulo = ISNULL(@idarticulo, 0) + 1

	INSERT INTO ew_articulos (
		idarticulo
		,codigo
		,nombre
		,idtipo
	)
	SELECT
		[idarticulo] = @idarticulo
		,[codigo] = 'CXCP'
		,[nombre] = 'Pago de cliente'
		,[idtipo] = 1

	SELECT @idarticulo = NULL
END

IF NOT EXISTS (SELECT * FROM ew_sys_parametros WHERE codigo = 'CXP_CONCEPTOPAGO')
BEGIN
	SELECT
		@idparametro = MAX(idparametro)
	FROM
		ew_sys_parametros

	SELECT @idparametro = ISNULL(@idparametro, 0) + 1

	INSERT INTO ew_sys_parametros (
		idparametro
		, codigo
		, nombre
		, activo
		, valor
		, descripcion
	)
	SELECT
		[idparametro] = @idparametro
		, [codigo] = 'CXP_CONCEPTOPAGO'
		, [nombre] = 'CODIGO DE CONCEPTO PARA PAGO A ACREEDOR'
		, [activo] = 1
		, [valor] = 'CXPP'
		, [descripcion] = 'Codigo de concepto de egreso para pago a acreedor/proveedor'

	SELECT @idparametro = NULL
END
	ELSE
BEGIN
	UPDATE ew_sys_parametros SET
		comando = ''
	WHERE
		codigo = 'CXP_CONCEPTOPAGO'

	UPDATE ew_sys_parametros SET
		valor = 'CXPP'
	WHERE
		codigo = 'CXP_CONCEPTOPAGO'
END

IF NOT EXISTS (SELECT * FROM ew_sys_parametros WHERE codigo = 'CXC_CONCEPTOPAGO')
BEGIN
	SELECT
		@idparametro = MAX(idparametro)
	FROM
		ew_sys_parametros

	SELECT @idparametro = ISNULL(@idparametro, 0) + 1

	INSERT INTO ew_sys_parametros (
		idparametro
		, codigo
		, nombre
		, activo
		, valor
		, descripcion
	)
	SELECT
		[idparametro] = @idparametro
		, [codigo] = 'CXC_CONCEPTOPAGO'
		, [nombre] = 'CODIGO DE CONCEPTO PARA PAGO DE CLIENTE'
		, [activo] = 1
		, [valor] = 'CXCP'
		, [descripcion] = 'Codigo de concepto de ingreso para pago de cliente'

	SELECT @idparametro = NULL
END
	ELSE
BEGIN
	UPDATE ew_sys_parametros SET
		comando = ''
	WHERE
		codigo = 'CXC_CONCEPTOPAGO'

	UPDATE ew_sys_parametros SET
		valor = 'CXCP'
	WHERE
		codigo = 'CXC_CONCEPTOPAGO'
END

SELECT * FROM ew_sys_parametros WHERE codigo = 'CXP_CONCEPTOPAGO'
SELECT * FROM ew_sys_parametros WHERE codigo = 'CXC_CONCEPTOPAGO'

SELECT * FROM ew_articulos WHERE codigo = 'CXPP'
SELECT * FROM ew_articulos WHERE codigo = 'CXCP'
