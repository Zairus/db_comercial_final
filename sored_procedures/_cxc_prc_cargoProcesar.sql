USE db_comercial_final
GO
IF OBJECT_ID('_cxc_prc_cargoProcesar') IS NOT NULL
BEGIN
	DROP PROCEDURE _cxc_prc_cargoProcesar
END
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20170629
-- Description:	Procesar cargo a proveedor
-- =============================================
CREATE PROCEDURE [dbo].[_cxc_prc_cargoProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

EXEC [dbo].[_xac_FDC1_procesar] @idtran
GO
