USE [db_comercial_final]
GO
-- SP: 	Valida el ingreso de un usuario EVOLUWARE
--		Regresa un query con los menus y objetos a los que puede acceder el usuario
-- 		Elaborado por Laurence Saavedra
-- 		Agosto del 2009
--		Modificado en Octubre del 2009
--		EXEC _sys_prc_logon 'SUPERVISOR','admin',2056
--      Modificado 2015-03 LAUSAA : 7 Submenus
ALTER PROCEDURE [dbo].[_sys_prc_logon]
	@usuario AS VARCHAR(20)
	,@password AS VARCHAR(20)
	,@version AS SMALLINT = 0
AS

SET NOCOUNT ON

DECLARE
	@user AS VARCHAR(20)
	,@pass AS VARCHAR(20)
	,@idu AS SMALLINT
	,@activo AS BIT
	,@version2 AS SMALLINT
	,@msg AS VARCHAR(200)
	,@idrol AS SMALLINT
	,@seguridad AS BIT
	
SELECT 
	@idu = idu
	, @pass = [password]
	, @activo = activo
	, @idrol = idrol
FROM
	evoluware_usuarios
WHERE
	usuario = @usuario

IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'El usuario ' + @usuario + ' no se encuentra registrado.'

	RAISERROR(@msg, 16, 1)
	RETURN
END	

IF @pass != @password 
BEGIN	
	SELECT @msg = 'La contraseña es incorrecta.'

	RAISERROR(@msg, 16, 1)
	RETURN
END	

IF @activo = 0
BEGIN	
	SELECT @msg = 'El usuario se encuentra inactivo.'

	RAISERROR(@msg, 16, 1)
	RETURN
END	

SELECT TOP 1 @version2 = [version] FROM licencia

IF @version < @version2 
BEGIN
	SELECT @msg = 'Versión de Ejecutable no permitida ' + CHAR(13) + 'Version Requerida ' + CONVERT(VARCHAR(4), @version2)
	RAISERROR(@msg, 16, 1)
	RETURN
END

-- Registrando la sesion
INSERT INTO ew_sys_sesiones (spid, usuario) VALUES (@@SPID, @idu)

-- Tomando el criterio de seguridad segun el rol
SELECT 
	@seguridad = seguridad 
FROM 
	evoluware_roles 
WHERE idrol = @idrol

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
			AND e.activo = 1
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
			, [menu] = a.menu
			, [submenu] = a.submenu
			, [orden] = a.orden
			, [tipo] = a.tipo
			, [codigo] = a.codigo
			, [nombre] = a.nombre
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
) AS MM
ORDER BY
	menu
	, orden
	, submenu
	, visible DESC
	, codigo
GO
