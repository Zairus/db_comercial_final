USE db_comercial_final
GO
ALTER VIEW [dbo].[objetos_datos]
AS
SELECT
	odl.objeto
	,odl.grupo
	,odl.codigo
	,odl.valor
	,odl.orden
FROM 
	ew_cat_objetos_datos AS odl

UNION ALL

SELECT
	odg.objeto
	,odg.grupo
	,odg.codigo
	,odg.valor
	,odg.orden
FROM 
	db_comercial.dbo.evoluware_objetos_datos AS odg
WHERE
	odg.grupo NOT IN (
		SELECT
			odl.grupo
		FROM
			ew_cat_objetos_datos AS odl
		WHERE
			odl.objeto = odg.objeto
	)
GO
