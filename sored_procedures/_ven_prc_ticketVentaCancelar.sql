USE db_comercial_final
GO
IF OBJECT_ID('_ven_prc_ticketVentaCancelar') IS NOT NULL
BEGIN
	DROP PROCEDURE _ven_prc_ticketVentaCancelar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150723
-- Description:	Cancelar ticket de venta
-- =============================================
CREATE PROCEDURE [dbo].[_ven_prc_ticketVentaCancelar]
	@idtran AS INT
	, @fecha AS DATETIME
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@total AS DECIMAL(18,6)
	, @saldo AS DECIMAL(18,6)

SELECT
	@total = total
	, @saldo = saldo
FROM
	ew_cxc_transacciones
WHERE
	idtran = @idtran

IF @saldo <> @total
BEGIN
	RAISERROR('Error: No se puede cancelar documento con aplicaciones de saldo.', 16, 1)
	RETURN
END

--------------------------------------------------------------------
-- Reactivar Ordenes
--------------------------------------------------------------------
EXEC [dbo].[_ven_prc_facturaOrdenesReactivar] @idtran, @idu

UPDATE ew_ven_transacciones SET 
	cancelado = 1
	, cancelado_fecha = @fecha
WHERE
	idtran = @idtran

UPDATE ew_cxc_transacciones SET 
	cancelado = 1
	, cancelado_fecha = @fecha
WHERE
	idtran = @idtran

EXEC [dbo].[_ven_prc_ticketVentaSurtir] @idtran, 1

EXEC [dbo].[_ct_prc_transaccionCancelarContabilidad] @idtran, 3, @fecha, @idu
GO
