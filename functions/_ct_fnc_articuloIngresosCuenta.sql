USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160224
-- Description:	Obtiene cuenta de ingresos para articulos dependiendo de IVA
-- =============================================
ALTER FUNCTION _ct_fnc_articuloIngresosCuenta
(
	@idarticulo AS INT
)
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE 
		@cuenta AS VARCHAR(20)

	SELECT
		@cuenta = (
			CASE
				WHEN cit.descripcion LIKE '%exen%' THEN '4100003000'
				ELSE
					CASE
						WHEN cit.tasa = 0 THEN '4100002000'
						ELSE '4100001000'
					END
			END
		)
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

	RETURN @cuenta
END
GO
