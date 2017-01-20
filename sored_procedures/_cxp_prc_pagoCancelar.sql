USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091203
-- Description:	Cancelar pago de acreedor
-- =============================================
ALTER PROCEDURE [dbo].[_cxp_prc_pagoCancelar]
	@idtran AS INT
	,@cancelado_fecha AS SMALLDATETIME
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

EXEC _cxp_prc_pagoRevocar @idtran, @idu, @cancelado_fecha

EXEC _cxp_prc_cancelarTransaccion @idtran, @cancelado_fecha, @idu

UPDATE ew_cxp_transacciones SET
	cancelado = 1
	,cancelado_fecha = @cancelado_fecha
WHERE
	idtran = @idtran

EXEC _ct_prc_transaccionAnularCT @idtran
GO
