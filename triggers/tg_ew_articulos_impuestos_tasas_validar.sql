USE db_comercial_final
GO
IF OBJECT_ID('tg_ew_articulos_impuestos_tasas_validar') IS NOT NULL
BEGIN
	DROP TRIGGER tg_ew_articulos_impuestos_tasas_validar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200210
-- Description:	Validar que exista al menos un IVA trasladado
-- =============================================
CREATE TRIGGER [dbo].[tg_ew_articulos_impuestos_tasas_validar]
	ON [dbo].[ew_articulos_impuestos_tasas]
	FOR INSERT, DELETE
AS 

SET NOCOUNT ON

DECLARE
	@registros AS INT

SELECT
	@registros = COUNT(*)
FROM
	ew_articulos AS a
WHERE
	(
		SELECT COUNT(*)
		FROM 
			ew_articulos_impuestos_tasas AS ait
			LEFT JOIN ew_cat_impuestos_tasas AS cit
				ON cit.idtasa = ait.idtasa
			LEFT JOIN ew_cat_impuestos AS ci
				ON ci.idimpuesto = ci.idimpuesto
		WHERE
			ci.grupo = 'IVA'
			AND cit.tipo = 1
			AND ait.idarticulo = a.idarticulo
	) = 0
	AND (
		a.idarticulo IN (
			SELECT i.idarticulo 
			FROM 
				inserted AS i
		)
		OR a.idarticulo IN (
			SELECT d.idarticulo 
			FROM 
				deleted AS d
		)
	)

SELECT @registros = ISNULL(@registros, 0)

IF @registros > 0
BEGIN
	RAISERROR('Error: Es requerido definir al menos un "IVA Trasladado" en pestaña Control de Impuestos.', 16, 1)
	RETURN
END
GO
