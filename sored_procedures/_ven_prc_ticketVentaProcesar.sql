USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150624
-- Description:	Procesa ticket de venta
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_ticketVentaProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@credito AS BIT
	,@pago_total AS DECIMAL(18,6)
	,@total AS DECIMAL(18,6)
	,@idu AS INT
	,@idturno AS INT
	,@pago_en_caja AS BIT

SELECT
	@credito = ct.credito
	,@total = ct.total
	,@idu = idu
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran

SELECT
	@pago_total = (vtp.total + vtp.total2)
FROM
	ew_ven_transacciones_pagos AS vtp
WHERE
	vtp.idtran = @idtran

SELECT @idturno = dbo.fn_sys_turnoActual(@idu)
SELECT @pago_en_caja = CONVERT(BIT, valor) FROM objetos_datos WHERE grupo = 'GLOBAL' AND codigo = 'PAGO_EN_CAJA'

IF @idturno IS NULL AND @pago_en_caja = 0
bEGIN
	RAISERROR('Error: El usuario no ha iniciado turno.', 16, 1)
	RETURN
END

IF @credito = 0 AND @pago_total < @total AND @pago_en_caja = 0
BEGIN
	RAISERROR('Error: Ticket de contado debe ser pagado totalmente.', 16, 1)
	RETURN
END

IF @credito = 1 AND @pago_total >= @total
BEGIN
	UPDATE ew_cxc_transacciones SET
		credito = 0
	WHERE
		idtran = @idtran
END

--Surtir
EXEC [dbo].[_ven_prc_ticketVentaSurtir] @idtran

--Pagar
IF @pago_total > 0
BEGIN
	EXEC [dbo].[_ven_prc_ticketVentaPagos] @idtran, @idu
END

SELECT costo = ISNULL(SUM(costo),0) FROM ew_ven_transacciones_mov WHERE idtran = @idtran
GO
