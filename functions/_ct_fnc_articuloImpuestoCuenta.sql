USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160224
-- Description:	Obtiene cuenta de impuesto de un articulo
-- =============================================
ALTER FUNCTION _ct_fnc_articuloImpuestoCuenta
(
	@codigo AS VARCHAR(10)
	,@tipo AS SMALLINT
	,@idarticulo AS INT
	,@cuenta_tipo AS SMALLINT
)
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE
		@cuenta AS VARCHAR(20)

	SELECT
		@cuenta = (
			CASE @cuenta_tipo
				WHEN 1 THEN cit.contabilidad1
				WHEN 2 THEN cit.contabilidad2
				WHEN 3 THEN cit.contabilidad3
				ELSE cit.contabilidad4
			END
		)
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

	RETURN @cuenta
END
GO