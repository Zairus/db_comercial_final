USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20181220
-- Description:	Aplica el estado de cancelacion a una transaccion
-- =============================================
ALTER PROCEDURE [dbo].[_sys_prc_transaccionCancelacionEstado]
	@idtran AS INT
	, @idu AS INT
	, @fecha AS DATETIME = NULL
AS

SET NOCOUNT ON

DECLARE
	@idestado AS INT = 255

UPDATE ew_sys_transacciones SET
	cancelado = 1
WHERE
	cancelado = 0
	AND idtran = @idtran

SELECT @fecha = ISNULL(@fecha, GETDATE())

EXEC _sys_prc_transaccionEstado @idtran, @idestado, @idu, @fecha
GO
