USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160119
-- Description:	Carga fiscal de articulo
-- =============================================
ALTER FUNCTION fn_ct_articuloCargaFactor
(
	@idarticulo AS INT
	,@idsucursal AS INT
)
RETURNS DECIMAL(18,6)
AS
BEGIN
	DECLARE
		@carga AS DECIMAL(18,6)
		,@porcentaje1 AS DECIMAL(18,6)

	SELECT @carga = 1
	
	SELECT
		@porcentaje1 = cit.tasa
	FROM
		ew_articulos_impuestos_tasas AS ait
		LEFT JOIN ew_cat_impuestos_tasas AS cit
			ON cit.idtasa = ait.idtasa
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = cit.idimpuesto
	WHERE
		ci.grupo = 'IVA'
		AND cit.tipo = 1
		AND ait.idarticulo = @idarticulo

	IF @porcentaje1 IS NULL
	BEGIN
		SELECT
			@porcentaje1 = ci.valor
		FROM
			ew_articulos AS a
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = a.idimpuesto1
		WHERE
			ci.grupo = 'IVA'
			AND a.idarticulo = @idarticulo
	END

	IF @porcentaje1 IS NULL
	BEGIN
		SELECT
			@porcentaje1 = ci.valor
		FROM 
			ew_sys_sucursales AS s
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = s.idimpuesto
		WHERE
			s.idsucursal = @idsucursal
	END

	SELECT @porcentaje1 = ISNULL(@porcentaje1, 0)

	SELECT @carga = @carga + @porcentaje1

	SELECT @porcentaje1 = NULL

	SELECT
		@porcentaje1 = cit.tasa
	FROM
		ew_articulos_impuestos_tasas AS ait
		LEFT JOIN ew_cat_impuestos_tasas AS cit
			ON cit.idtasa = ait.idtasa
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = cit.idimpuesto
	WHERE
		ci.grupo = 'IEPS'
		AND cit.tipo = 1
		AND ait.idarticulo = @idarticulo

	SELECT @porcentaje1 = ISNULL(@porcentaje1, 0)

	SELECT @carga = @carga + @porcentaje1

	SELECT @carga = ISNULL(@carga, 1)

	RETURN @carga
END
GO
