USE db_comercial_final
GO
IF OBJECT_ID('_ban_prc_bdt2_contabilizar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ban_prc_bdt2_contabilizar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190430
-- Description:	Aplicar contabilidad de integracion de deposito
-- =============================================
CREATE PROCEDURE [dbo].[_ban_prc_bdt2_contabilizar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idr AS INT = 0
	, @pago_idtran AS INT
	, @pago_transaccion AS VARCHAR(5)
	, @pago_fecha AS DATETIME

WHILE EXISTS(SELECT * FROM ew_ban_documentos_mov AS bdm WHERE bdm.idtran = @idtran AND bdm.idr > @idr)
BEGIN
	SELECT @idr = MIN(bdm.idr)
	FROM
		ew_ban_documentos_mov AS bdm
	WHERE
		bdm.idtran = @idtran
		AND bdm.idr > @idr

	SELECT
		@pago_idtran = bdm.idtran2
		, @pago_transaccion = st.transaccion
		, @pago_fecha = st.fecha
	FROM
		ew_ban_documentos_mov AS bdm
		LEFT JOIN ew_sys_transacciones AS st
			ON st.idtran = bdm.idtran2
	WHERE
		bdm.idr = @idr
		
	IF @pago_transaccion = 'BDC2'
	BEGIN
		EXEC _ct_prc_polizaAplicarDeConfiguracion @pago_idtran, @pago_transaccion, @pago_idtran, NULL, 1, @pago_fecha
	END
END

EXEC _ct_prc_polizaAplicarDeConfiguracion @idtran, 'BDT2', @idtran, NULL, 1
GO
