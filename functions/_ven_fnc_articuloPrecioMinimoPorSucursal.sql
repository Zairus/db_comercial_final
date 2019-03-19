USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190123
-- Description:	Devuelve el precio minimo de un articulo en la sucursal
--              de acuerdo a parametros de calculo de precios
-- =============================================
ALTER FUNCTION [dbo].[_ven_fnc_articuloPrecioMinimoPorSucursal]
(
	@idarticulo AS INT
	, @idsucursal AS INT
	, @costo_base AS DECIMAL(18, 6)
)
RETURNS DECIMAL(18, 6)
AS
BEGIN
	DECLARE
		@precio_minimo AS DECIMAL(18, 6)
		, @calculo AS INT
		, @margen_minimo AS DECIMAL(18,6)

	SELECT @calculo = CONVERT(INT, ISNULL(dbo.fn_sys_parametro('LISTAPRECIOS_CALCULO'), 0))
	SELECT @margen_minimo = CONVERT(DECIMAL(18,6), [dbo].[_sys_fnc_parametroTexto]('LISTAPRECIOS_MARGENMINIMO'))
	
	SELECT
		@precio_minimo = (
			CASE
				WHEN @calculo = 0 THEN
					@costo_base * (1 + (COALESCE(NULLIF(sa.margen_minimo, 0), @margen_minimo, 0)))
				ELSE
					@costo_base / (1 - (COALESCE(NULLIF(sa.margen_minimo, 0), @margen_minimo, 0)))
			END
		)
	FROM
		ew_articulos_sucursales AS sa
	WHERE
		sa.bajo_costo = 0
		AND sa.idarticulo = @idarticulo
		AND sa.idsucursal = @idsucursal

	SELECT @precio_minimo = ISNULL(@precio_minimo, 0)

	RETURN @precio_minimo
END
GO
