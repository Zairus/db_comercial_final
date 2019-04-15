USE db_comercial_final
GO
IF OBJECT_ID('_cxc_prc_devolucionDineroCancelar') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxc_prc_devolucionDineroCancelar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190408
-- Description:	Cancelar devolucion de dinero a cliente
-- =============================================
CREATE PROCEDURE _cxc_prc_devolucionDineroCancelar
	@idtran AS INT
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@cancelado_fecha AS SMALLDATETIME

SELECT
	@cancelado_fecha = ct.fecha
FROM
	ew_cxc_transacciones AS ct
WHERE
	ct.idtran = @idtran

EXEC _cxc_prc_cancelarTransaccion @idtran, @cancelado_fecha, @idu

EXEC _ban_prc_cancelarTransaccion @idtran, @cancelado_fecha, @idu, 0, 0
GO
