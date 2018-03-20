USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170629
-- Description:	Procesar cargo a proveedor
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_abonoProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

EXEC _ct_prc_polizaAplicarDeConfiguracion @idtran, 'FDC1_A', @idtran
GO
