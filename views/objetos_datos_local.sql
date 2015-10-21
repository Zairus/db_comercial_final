USE db_comercial_final
GO
ALTER VIEW [dbo].[objetos_datos_local]
AS
SELECT
	odl.objeto
	,odl.grupo
	,odl.codigo
	,odl.valor
	,odl.orden
FROM 
	ew_cat_objetos_datos AS odl
GO
