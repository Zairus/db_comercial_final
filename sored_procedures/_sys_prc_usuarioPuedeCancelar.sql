USE db_comercial_final
GO
IF OBJECT_ID('_sys_prc_usuarioPuedeCancelar') IS NOT NULL
BEGIN
	DROP PROCEDURE _sys_prc_usuarioPuedeCancelar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200313
-- Description:	Validar si usuariop uede cancelar
-- =============================================
CREATE PROCEDURE [dbo].[_sys_prc_usuarioPuedeCancelar]
	@idu AS INT
	, @codigo AS VARCHAR(5)
AS

SET NOCOUNT ON

DECLARE
	@cancelar_permiso AS BIT
	, @error_mensaje AS VARCHAR(1000)

SELECT @cancelar_permiso = [dbo].[_sys_fnc_permisoUsuarioAccionObjeto](@idu, @codigo, 'cancelar')

IF @cancelar_permiso = 0
BEGIN
	SELECT
		@error_mensaje = (
			'Error: El usuario ' 
			+ u.nombre 
			+ ' no cuenta con permiso para cancelar '
			+ o.nombre
		)
	FROM
		evoluware_usuarios AS u
		LEFT JOIN objetos AS o
			ON o.codigo = @codigo
	WHERE
		u.idu = @idu

	RAISERROR(@error_mensaje, 16, 1)
	RETURN
END
GO
