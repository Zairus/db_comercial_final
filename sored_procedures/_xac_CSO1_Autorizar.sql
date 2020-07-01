USE db_comercial_final
GO
IF OBJECT_ID('_xac_CSO1_Autorizar') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_CSO1_Autorizar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200414
-- Description:	Autorizar requisición de compras
-- =============================================
GO
CREATE PROCEDURE [dbo].[_xac_CSO1_Autorizar]
	@idtran AS INT
	, @idu AS INT
	, @password AS VARCHAR(20)
	, @comentario AS VARCHAR(4000) = ''
AS

SET NOCOUNT ON

DECLARE
	@msg AS VARCHAR(1000)
	, @cont AS SMALLINT

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

-- Registrando el cambio de estado en la transaccion de Elaborado a Solicitado
INSERT INTO ew_sys_transacciones2 (
	idtran
	, idestado
	, idu
	, comentario
)
SELECT
	[idtran] = @idtran
	, [idestado] = 3
	, [idu] = @idu
	, [comentario] = @comentario

IF @@ERROR != 0 OR @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'No se logró cambiar el estado de la transaccion.'

	RAISERROR(@msg, 16, 1)
	RETURN
END
GO
