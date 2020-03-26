USE db_comercial_final
GO
IF OBJECT_ID('_xac_EDC3_cancelar') IS NOT NULL
BEGIN
	DROP PROCEDURE _xac_EDC3_cancelar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20200310
-- Description:	Cancelar nota de venta recibo provisional
-- =============================================
CREATE PROCEDURE [dbo].[_xac_EDC3_cancelar]
	@idtran AS INT
	, @idu AS INT
AS

SET NOCOUNT ON

DECLARE
	@cancelado_fecha AS DATETIME = GETDATE()

EXEC [dbo].[_cxc_prc_cancelarTransaccion]
	@idtran
	, @cancelado_fecha
	, @idu

UPDATE ew_ven_transacciones SET
	cancelado = 1
	, cancelado_fecha = @cancelado_fecha
WHERE
	idtran = @idtran

UPDATE ew_cxc_transacciones SET
	cancelado = 1
	, cancelado_fecha = @cancelado_fecha
WHERE
	idtran = @idtran

EXEC [dbo].[_ct_prc_transaccionCancelarContabilidad]
	@idtran = @idtran
	, @tipo = 3
	, @cancelado_fecha = @cancelado_fecha
	, @idu = @idu
GO
