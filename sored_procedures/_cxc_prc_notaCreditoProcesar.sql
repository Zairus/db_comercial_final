USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20160523
-- Description:	Procesar nota de credito
-- =============================================
ALTER PROCEDURE [dbo].[_cxc_prc_notaCreditoProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@idtran2 AS INT
	,@idconcepto AS INT

SELECT
	@idtran2 = idtran2
	,@idconcepto = idconcepto
FROM
	ew_cxc_transacciones
WHERE
	idtran = @idtran

IF @idconcepto = 0
BEGIN
	RAISERROR('Error: Debe indicar un concepto para la nota de credito.', 16, 1)
	RETURN
END

EXEC _ct_prc_polizaAplicarDeConfiguracion @idtran, 'BDC2', @idtran, NULL
GO
