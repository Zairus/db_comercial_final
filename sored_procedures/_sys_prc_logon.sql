USE db_comercial_final
GO
IF OBJECT_ID('_sys_prc_logon') IS NOT NULL
BEGIN
	DROP PROCEDURE _sys_prc_logon
END
GO
-- =============================================
-- Author:		Laurence Saavedra
-- Create date: 20090801
-- Description:	Valida el ingreso de un usuario EVOLUWARE
--              Regresa un query con los menus y objetos a los que puede acceder el usuario
-- =============================================
CREATE PROCEDURE [dbo].[_sys_prc_logon]
	@usuario AS VARCHAR(20)
	, @password AS VARCHAR(20)
	, @version AS SMALLINT = 0
AS

SET NOCOUNT ON

DECLARE
	@user AS VARCHAR(20)
	, @idu AS SMALLINT
	, @version2 AS SMALLINT
	, @msg AS VARCHAR(200)
	, @idrol AS SMALLINT
	, @seguridad AS BIT
	, @cuenta AS VARCHAR(20)
	
SELECT
	@cuenta = sc.codigo
FROM 
	dbEVOLUWARE.dbo.ew_sys_cuentas_servicios AS scs
	LEFT JOIN dbEVOLUWARE.dbo.ew_sys_cuentas AS sc
		ON sc.cuenta_id = scs.cuenta_id
WHERE
	scs.objeto_inicio = DB_NAME()

SELECT 
	@idu = idu
	, @idrol = idrol
FROM
	evoluware_usuarios
WHERE
	usuario = @usuario

EXEC [dbEVOLUWARE].[dbo].[_sys_prc_auth] @cuenta, @usuario, @password

SELECT TOP 1 @version2 = [version] FROM licencia

IF @version < @version2 
BEGIN
	SELECT @msg = 'Versión de Ejecutable no permitida ' + CHAR(13) + 'Version Requerida ' + CONVERT(VARCHAR(4), @version2)

	RAISERROR(@msg, 16, 1)
	RETURN
END

-- Registrando la sesion
INSERT INTO ew_sys_sesiones (
	spid
	, usuario
) 
SELECT 
	[spid] = @@SPID
	, [usuario] = @idu 
WHERE 
	@idu IS NOT NULL
	
-- Tomando el criterio de seguridad segun el rol
SELECT 
	@seguridad = seguridad 
FROM 
	evoluware_roles 
WHERE 
	idrol = @idrol

SELECT @seguridad = ISNULL(@seguridad, 0)

SELECT 
	[o] = 'usuarios'
	, id = idu
	, * 
FROM 
	evoluware_usuarios 
WHERE 
	idu = @idu

SELECT 
	[o] = 'menus'
	, MM.*
FROM
	(
		SELECT
			[permiso] = (
				CASE 
					WHEN e.activo = 0 THEN 0 
					ELSE
						ISNULL((
							SELECT m.activo 
							FROM evoluware_roles_menus AS m 
							WHERE 
								m.idrol = @idrol 
								AND m.tipo = 'MNU' 
								AND m.codigo = e.codigo
						), 1) 
				END
			)
			, [menu] = CASE WHEN submenu=0 THEN (-1) ELSE menu END
			, [submenu] = e.submenu
			, [orden] = e.orden --(-1)
			, [tipo] = 'MNU'
			, [codigo] = e.codigo
			, [nombre] = e.nombre
			, [shortcut] = ''
			, [separador] = CONVERT(BIT,0)
			, [visible] = e.activo
			, [llave] = ''
			, [comando] = ''
			, [icono] = e.icono
			, [objeto] = 0
		FROM
			evoluware_menus AS e
		WHERE
			e.modelo = 1
			--AND e.activo = 1
			--AND e.menu BETWEEN 0 AND 10
			--AND e.submenu BETWEEN 0 AND 7

		UNION ALL

		SELECT 
			[permiso] = (
				CASE 
					WHEN a.tipo = 'CAT' AND a.orden = 0 THEN CONVERT(BIT, 1) 
					ELSE
						ISNULL((
							SELECT m.activo 
							FROM evoluware_roles_menus AS m 
							WHERE 
								idrol = @idrol 
								AND tipo = a.tipo
								AND codigo = a.codigo
						), @seguridad
					) 
				END
			)
			, [menu] = COALESCE(so.menu, a.menu)
			, [submenu] = COALESCE(so.submenu, a.submenu)
			, [orden] = COALESCE(so.orden, a.orden)
			, [tipo] = a.tipo
			, [codigo] = a.codigo
			, [nombre] = COALESCE(so.nombre, a.nombre)
			, [shortcut] = a.shortcut
			, [separador] = a.separador
			, [visible] = a.visible
			, [llave] = (
				CASE 
					WHEN a.tipo = 'CMD' THEN 
						ISNULL((SELECT TOP 1 b.valor FROM objetos_datos AS b WHERE b.objeto = a.objeto AND b.grupo = 'DATO' AND b.codigo = 'PARAMETERS'), '')
					ELSE
						ISNULL((SELECT TOP 1 b.sql_field FROM objetos_grids AS b WHERE b.objeto = a.objeto AND b.orden = 1), '')
				END
			)
			, [comando] = ISNULL((SELECT TOP 1 b.valor FROM objetos_datos AS b WHERE b.objeto = a.objeto AND b.grupo='DATO' AND b.codigo = 'EXECUTE'),'')
			, [icono] = a.icono
			, [objeto] = a.objeto
		FROM
			objetos AS a
			LEFT JOIN ew_sys_objetos AS so
				ON so.objeto = a.objeto
) AS MM
ORDER BY
	menu
	, orden
	, submenu
	, visible DESC
	, codigo
GO
