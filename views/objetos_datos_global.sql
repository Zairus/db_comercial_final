USE db_comercial_final
GO
ALTER VIEW [dbo].[objetos_datos_global]
AS
SELECT
	odg.objeto
	,odg.grupo
	,odg.codigo
	,odg.valor
	,odg.orden
FROM 
	db_comercial.dbo.evoluware_objetos_datos AS odg
GO
