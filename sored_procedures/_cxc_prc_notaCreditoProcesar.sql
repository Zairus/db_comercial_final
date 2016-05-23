USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160523
-- Description:	Procesar nota de credito
-- =============================================
ALTER PROCEDURE _cxc_prc_notaCreditoProcesar
	@idtran AS INT
AS

SET NOCOUNT ON

EXEC [dbo].[_ct_prc_contabilizarBDC2] @idtran
GO
