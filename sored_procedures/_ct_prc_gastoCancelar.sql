USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20091202
-- Description:	Cancelar factura de gasto
-- =============================================
ALTER PROCEDURE [dbo].[_ct_prc_gastoCancelar]
	@idtran AS INT
	, @cancelado_fecha AS SMALLDATETIME
	, @idu AS SMALLINT
AS

SET NOCOUNT ON

DECLARE
	@total AS DECIMAL(15,2)
	, @saldo AS DECIMAL(15,2)

SELECT
	@total = ct.total
	, @saldo = ct.saldo
	, @cancelado_fecha = ct.fecha
FROM 
	ew_cxp_transacciones AS ct
WHERE
	idtran = @idtran

IF @total <> @saldo
BEGIN
	RAISERROR('Error: No se puede cancelar un documento con aplicaciones de saldo.', 16, 1)
	RETURN
END

UPDATE ew_cxp_transacciones SET
	cancelado = 1
	, cancelado_fecha = @cancelado_fecha
WHERE
	idtran = @idtran

EXEC _ct_prc_transaccionCancelarContabilidad @idtran, 3, @cancelado_fecha, @idu
GO
