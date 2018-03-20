USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180316
-- Description: Procesar cargo a acreedor
-- =============================================
ALTER PROCEDURE _cxp_prc_cargoProcesar
	@idtran AS INT
AS

SET NOCOUNT ON

EXEC _ct_prc_polizaAplicarDeConfiguracion @idtran, 'DDC1_A', @idtran
GO
