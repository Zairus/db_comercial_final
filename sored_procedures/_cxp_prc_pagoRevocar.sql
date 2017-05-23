USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091203
-- Description:	Revocar autorizaci�n a pago de acreedor
-- =============================================
ALTER PROCEDURE [dbo].[_cxp_prc_pagoRevocar]
	@idtran AS BIGINT
	,@idu AS SMALLINT
	,@cancelado_fecha AS SMALLDATETIME
AS

SET NOCOUNT ON

DECLARE
	@egreso_idtran AS INT

SELECT
	@egreso_idtran = bt.idtran
FROM 
	ew_ban_transacciones AS bt
WHERE
	bt.cancelado = 0
	AND bt.idtran2 = @idtran

IF @egreso_idtran IS NULL
BEGIN
	RAISERROR('Error: No se pudo obtener registro de egreso.', 16, 1)
	RETURN
END

EXEC _ban_prc_cancelarTransaccion @egreso_idtran, @cancelado_fecha, @idu

INSERT INTO ew_sys_transacciones2
	(idtran, idestado, idu)
VALUES
	(@idtran, 0, @idu)
GO