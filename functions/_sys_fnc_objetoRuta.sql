USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20181226
-- Description:	Ruta de acceso a objeto
-- =============================================
ALTER FUNCTION [dbo].[_sys_fnc_objetoRuta]
(
	@objeto AS INT
)
RETURNS VARCHAR(1000)
AS
BEGIN
	DECLARE
		@ruta AS VARCHAR(1000)

	SELECT
		@ruta = (
			ms.nombre
			+ '/'
			+ m.nombre
			+ '/'
			+ ro.nombre
		)
	FROM 
		objetos AS ro 
		LEFT JOIN evoluware_menus AS ms 
			ON ms.menu = ro.menu 
			AND ms.submenu = 0
		LEFT JOIN evoluware_menus AS m
			ON m.menu = ro.menu 
			AND m.submenu = ro.submenu
	WHERE 
		ro.objeto = @objeto

	SELECT @ruta = ISNULL(@ruta, '')

	RETURN @ruta
END
GO
