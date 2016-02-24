USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160224
-- Description:	Obtiene id de impuesto de un articulo
-- =============================================
ALTER FUNCTION _ct_fnc_articuloImpuestoId
(
	@codigo AS VARCHAR(10)
	,@tipo AS SMALLINT
	,@idarticulo AS INT
)
RETURNS INT
AS
BEGIN
	DECLARE
		@idimpuesto AS INT

	SELECT
		@idimpuesto = cit.idimpuesto
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

	RETURN @idimpuesto
END
GO
