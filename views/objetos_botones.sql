USE [db_comercial_final]
GO
ALTER VIEW [dbo].[objetos_botones]
AS
SELECT
	idr
	, objeto
	, codigo
	, caption
	, [enabled]
	, visible
	, orden
	, command
	, commandedit
	, [when]
	, [password]
	, [procedure]
	, procedure2
	, error
	, [default]
	, tooltip
FROM
	db_comercial.dbo.evoluware_objetos_botones
GO
