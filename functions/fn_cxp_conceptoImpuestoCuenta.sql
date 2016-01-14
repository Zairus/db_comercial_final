USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160112
-- Description:	Obtener cuenta de impuesto de concepto
-- =============================================
ALTER FUNCTION fn_cxp_conceptoImpuestoCuenta
(
	@idarticulo AS INT
	,@grupo AS VARCHAR(10)
	,@tipo AS SMALLINT
	,@posicion AS SMALLINT
)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE
		@cuenta AS VARCHAR(50)

	SELECT
		@cuenta = (
			CASE @posicion
				WHEN 2 THEN cit.contabilidad2
				WHEN 3 THEN cit.contabilidad3
				WHEN 4 THEN cit.contabilidad4
				ELSE cit.contabilidad1
			END
		)
	FROM
		ew_articulos_impuestos_tasas AS ait
		LEFT JOIN ew_cat_impuestos_tasas AS cit
			ON cit.idtasa = ait.idtasa
		LEFT JOIN ew_cat_impuestos AS ci
			ON ci.idimpuesto = cit.idimpuesto
	WHERE
		ci.grupo = @grupo
		AND cit.tipo = @tipo
		AND ait.idarticulo = @idarticulo

	SELECT @cuenta = ISNULL(@cuenta, '')

	RETURN @cuenta
END
GO
