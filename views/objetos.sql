USE db_comercial_final
GO
IF OBJECT_ID('objetos') IS NOT NULL
BEGIN
	DROP VIEW objetos
END
GO
CREATE VIEW [dbo].[objetos]
AS
SELECT
	o.idr
	, o.objeto
	, o.codigo
	, [nombre] = o.nombre
	, o.tipo
	, o.orden
	, [menu] = o.menu
	, [submenu] = o.submenu
	, o.shortcut
	, o.visible
	, o.separador
	, o.icono
	, o.fecha_creacion
	, o.fecha_modificacion
	, [version] = o.[version]
	, o.comentario
FROM
	db_comercial.dbo.evoluware_objetos AS o
GO
