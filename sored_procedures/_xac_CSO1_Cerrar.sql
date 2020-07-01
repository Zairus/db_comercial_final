USE db_comercial_final
GO
IF OBJECT_ID('_xac_CSO1_Cerrar') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_CSO1_Cerrar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091008
-- Description:	Cerrar requisición de compras
-- =============================================
CREATE PROCEDURE [dbo].[_xac_CSO1_Cerrar]
	@idtran AS INT
	, @idu AS INT
	, @password AS VARCHAR(20)
	, @comentario AS VARCHAR(4000) = ''
AS

SET NOCOUNT ON

DECLARE
	@msg AS VARCHAR(1000)
	, @cont AS INT

-- Comprobando la seguridad del usuario
SELECT
	@cont = COUNT(*)
FROM 
	ew_usuarios
WHERE
	idu = @idu
	AND [password] = @password

IF @cont = 0
BEGIN
	SELECT @msg = 'Contraseña incorrecta.'

	RAISERROR(@msg, 16, 1)
	RETURN
END

-- Registrando el cambio de estado a cerrada
INSERT INTO ew_sys_transacciones2 (
	idtran
	, idestado
	, idu
	, comentario
)
SELECT
	[idtran] = @idtran
	, [idestado] = 251
	, [idu] = @idu
	, [comentario] = @comentario

IF @@ERROR != 0 OR @@ROWCOUNT = 0
BEGIN
	SELECT @msg='No se logró cambiar el estado de la transaccion.'

	RAISERROR(@msg, 16, 1)
	RETURN
END
GO
