USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20190119
-- Description:	Cancelar factura de relacion
-- =============================================
ALTER PROCEDURE [dbo].[_ven_prc_facturaRelacionCancelar]
	@idtran AS INT
	, @idu INT
	, @cancelado_fecha DATETIME = NULL
AS

SET NOCOUNT ON

EXEC _cxc_prc_cancelarTransaccion @idtran, @cancelado_fecha, @idu
GO
