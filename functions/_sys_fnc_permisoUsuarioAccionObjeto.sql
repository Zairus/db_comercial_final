USE db_comercial_final
GO
IF OBJECT_ID('_sys_fnc_permisoUsuarioAccionObjeto') IS NOT NULL
BEGIN
	DROP FUNCTION _sys_fnc_permisoUsuarioAccionObjeto
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200313
-- Description:	Obtener permiso para accion de objeto por usuario
-- =============================================
CREATE FUNCTION [dbo].[_sys_fnc_permisoUsuarioAccionObjeto]
(
	@idu AS INT
	, @codigo AS VARCHAR(5)
	, @accion AS VARCHAR(10)
)
RETURNS BIT
AS
BEGIN
	DECLARE
		@cancelar_permiso AS BIT

	SELECT 
		@cancelar_permiso = (
			CASE LOWER(@accion)
				WHEN 'activo' THEN rm.activo
				WHEN 'consultar' THEN rm.consultar
				WHEN 'nuevo' THEN rm.nuevo
				WHEN 'modificar' THEN rm.modificar
				WHEN 'cancelar' THEN rm.cancelar
				WHEN 'imprimir' THEN rm.imprimir
				WHEN 'exportar' THEN rm.exportar
				WHEN 'acciones' THEN rm.acciones
				WHEN 'autorizar' THEN rm.autorizar
			END
		)
	FROM 
		evoluware_usuarios AS u 
		LEFT JOIN evoluware_roles_menus AS rm
			ON rm.idrol = u.idrol
	WHERE 
		u.idu = @idu
		AND ISNULL(rm.codigo, '') = @codigo
	
	SELECT 
		@cancelar_permiso = ISNULL(@cancelar_permiso, CONVERT(BIT, r.seguridad))
	FROM 
		evoluware_usuarios AS u 
		LEFT JOIN evoluware_roles AS r
			ON r.idrol = u.idrol
	WHERE 
		u.idu = @idu

	RETURN @cancelar_permiso
END
GO
