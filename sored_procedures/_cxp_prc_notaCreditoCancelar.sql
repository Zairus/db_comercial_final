USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20171004
-- Description:	Cancelar nota de credito de proveedor
-- =============================================
ALTER PROCEDURE _cxp_prc_notaCreditoCancelar
	@idtran AS INT
	,@idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@fecha AS DATETIME

SELECT
	@fecha = fecha
FROM
	ew_cxp_transacciones AS ct
WHERE
	ct.idtran = @idtran

EXEC _cxp_prc_cancelarTransaccion @idtran, @fecha, @idu
EXEC _ct_prc_transaccionCancelarContabilidad @idtran, 3, @fecha, @idu
GO
