USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20150915
-- Description:	Cancelar factura de tickets
-- =============================================
ALTER PROCEDURE _ven_prc_facturaTicketsCancelar
	@idtran AS INT
	,@fecha AS SMALLDATETIME
	,@idu AS INT
AS

SET NOCOUNT ON

UPDATE ew_cxc_transacciones SET
	cancelado = 1
	,cancelado_fecha = @fecha
WHERE
	idtran = @idtran

UPDATE ew_ven_transacciones SET
	cancelado = 1
	,cancelado_fecha = @fecha
WHERE
	idtran = @idtran
GO
