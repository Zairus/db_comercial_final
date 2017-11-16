USE db_comercial_final

DECLARE
	@idum AS INT

SELECT @idum = MAX(idum) FROM ew_cat_unidadesMedida

SELECT @idum = ISNULL(@idum, 0) + 1

IF NOT EXISTS (SELECT * FROM ew_cat_unidadesMedida WHERE sat_unidad_clave  = 'ACT')
BEGIN
	INSERT INTO ew_cat_unidadesMedida (
		idum
		,idub
		,codigo
		,nombre
		,factor
		,peso
		,volumen
		,comentario
		,sat_unidad_clave
	)
	SELECT
		[idum] = @idum
		,[idub] = 0
		,[codigo] = 'ACT'
		,[nombre] = 'Accion'
		,[factor] = 1
		,[peso] = 1
		,[volumen] = 1
		,[comentario] = ''
		,[sat_unidad_clave] = 'ACT'

	UPDATE ew_articulos SET
		idum_almacen = @idum
		,idum_compra = @idum
		,idum_venta = @idum
	WHERE
		codigo IN ('CXCP', 'CXPP')
END

SELECT * FROM ew_cat_unidadesMedida WHERE sat_unidad_clave  = 'ACT'

SELECT * FROM ew_articulos WHERE codigo IN ('CXCP', 'CXPP')
