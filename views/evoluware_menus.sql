USE [db_comercial_final]
GO
ALTER VIEW [dbo].[evoluware_menus]
AS
SELECT
	idr
	, modelo
	, menu
	, submenu
	, codigo
	, nombre
	, icono
	, activo
	, orden
FROM
	db_comercial.dbo.evoluware_menus AS evoluware_menus_1
GO
