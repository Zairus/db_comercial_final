USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150720
-- Description:	Cambiar estado de transaccion
-- =============================================
ALTER PROCEDURE [dbo].[_sys_prc_transaccionEstado]
	@idtran AS INT
	, @idestado AS INT
	, @idu AS INT
	, @fecha AS DATETIME = NULL
AS

SET NOCOUNT ON

SELECT @fecha = ISNULL(@fecha, GETDATE())

IF (
	SELECT COUNT(*)
	FROM ew_sys_transacciones2
	WHERE
		idtran = @idtran
		AND idestado = @idestado
		AND idu = @idu
		AND fechahora = @fecha
) = 0
BEGIN
	INSERT INTO ew_sys_transacciones2 (
		idtran
		, idestado
		, idu
		, fechahora
	)
	SELECT
		[idtran] = @idtran
		, [idestado] = @idestado
		, [idu] = @idu
		, [fechahora] = @fecha
END
GO
