USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20140807
-- Description:	Procesar egreso bancario
-- =============================================
ALTER PROCEDURE [dbo].[_ban_prc_egresoProcesar]
	@idtran AS INT
	, @ignorar_cancelado AS BIT = 0
AS

SET NOCOUNT ON

DECLARE
	@transaccion_referencia AS VARCHAR(4)
	, @pago_idtran AS INT
	, @pago_cancelado AS BIT
	, @fecha AS SMALLDATETIME
	, @idu AS INT

SELECT
	@transaccion_referencia = ISNULL(st.transaccion, '')
	, @pago_idtran = bt.idtran2
	, @pago_cancelado = ct.cancelado
	, @fecha = bt.fecha
	, @idu = bt.idu
FROM
	ew_ban_transacciones AS bt
	LEFT JOIN ew_sys_transacciones AS st
		ON st.idtran = bt.idtran2
	LEFT JOIN ew_cxp_transacciones AS ct
		ON ct.idtran = bt.idtran2
WHERE
	bt.idtran = @idtran

SELECT @ignorar_cancelado = 1

IF @transaccion_referencia = 'DDA3'
BEGIN
	IF @pago_cancelado = 0 OR @ignorar_cancelado = 0
	BEGIN
		EXEC _cxp_prc_aplicarTransaccion @pago_idtran, @fecha, @idu
	END

	EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion] @idtran, @transaccion_referencia, @idtran, NULL, 1, @fecha
END

IF @transaccion_referencia = 'DDA4'
BEGIN
	IF @pago_cancelado = 0 OR @ignorar_cancelado = 0
	BEGIN
		EXEC _cxp_prc_aplicarTransaccion @pago_idtran, @fecha, @idu
	END

	EXEC [dbo].[_ct_prc_polizaAplicarDeConfiguracion] @idtran, @transaccion_referencia, @pago_idtran, NULL, 1, @fecha

	INSERT INTO ew_sys_transacciones2
		(idtran, idestado, idu)
	VALUES
		(@pago_idtran, 5, @idu)
END

IF @transaccion_referencia = 'BOR2'
BEGIN
	EXEC _ct_prc_polizaAplicarDeConfiguracion @idtran, 'BDA1R', @idtran, NULL, 1, @fecha
END

IF @transaccion_referencia = ''
BEGIN
	EXEC _ct_prc_polizaAplicarDeConfiguracion @idtran, 'BDA1', @idtran, NULL, 1, @fecha
END
GO
