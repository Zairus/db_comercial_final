USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20140807
-- Description:	Procesar egreso bancario
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_egresoProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@transaccion_referencia AS VARCHAR(4)
	,@pago_idtran AS INT
	,@fecha AS SMALLDATETIME
	,@idu AS INT

SELECT
	@transaccion_referencia = ISNULL(st.transaccion, '')
	,@pago_idtran = bt.idtran2
	,@fecha = bt.fecha
	,@idu = bt.idu
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = bt.idtran2
WHERE
	bt.idtran = @idtran

IF @transaccion_referencia = 'DDA3'
BEGIN
	EXEC _cxp_prc_aplicarTransaccion @pago_idtran, @fecha, @idu

	EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion] @idtran, @transaccion_referencia
END

IF @transaccion_referencia = 'DDA4'
BEGIN
	EXEC _cxp_prc_aplicarTransaccion @pago_idtran, @fecha, @idu

	EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion] @pago_idtran

	INSERT INTO ew_sys_transacciones2
		(idtran, idestado, idu)
	VALUES
		(@pago_idtran, 5, @idu)
END

IF @transaccion_referencia = 'BOR2'
BEGIN
	EXEC _ct_prc_polizaAplicarDeConfiguracion @idtran, 'BDA1R'
END
GO
