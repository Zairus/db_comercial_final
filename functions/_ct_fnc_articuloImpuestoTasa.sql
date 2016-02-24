USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160224
-- Description:	Obtiene tasa de impuesto de un articulo
-- =============================================
ALTER FUNCTION _ct_fnc_articuloImpuestoTasa
(
	@codigo AS VARCHAR(10)
	,@tipo AS SMALLINT
	,@idarticulo AS INT
)
RETURNS DECIMAL(18,6)
AS
BEGIN
	DECLARE
		@tasa AS DECIMAL(18,6)

	SELECT
		@tasa = cit.tasa
	FROM 
		ew_articulos_impuestos_tasas AS ait
		LEFT JOIN ew_cat_impuestos_tasas AS cit
			ON cit.idtasa = ait.idtasa
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = cit.idimpuesto
	WHERE 
		ci.grupo = @codigo
		AND cit.tipo = @tipo
		AND ait.idarticulo = @idarticulo

	RETURN @tasa
END
GO