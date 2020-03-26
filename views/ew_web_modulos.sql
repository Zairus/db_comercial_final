USE db_comercial_final
GO
IF OBJECT_ID('ew_web_modulos') IS NOT NULL
BEGIN
	DROP VIEW ew_web_modulos
END
GO
CREATE VIEW [dbo].[ew_web_modulos]
AS
SELECT
	wm.codigo
	, wm.titulo
	, wm.descripcion
	, wm.tipo
	, wm.ruta
	, [orden] = m.idr
FROM 
	[dbo].[_sys_fnc_separarMultilinea]('', '|') AS m
	LEFT JOIN db_comercial.dbo.evoluware_web_modulos AS wm
		ON wm.codigo = m.valor
GO
