USE [db_comercial_final]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20180316
-- Description: Procesar cargo a acreedor
-- =============================================
ALTER PROCEDURE [dbo].[_cxp_prc_cargoProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

DECLARE
	@concepto_cuenta AS VARCHAR(50)

SELECT
	@concepto_cuenta = ISNULL(oc.contabilidad, '')
FROM
	ew_cxp_transacciones AS ct
	LEFT JOIN objetos AS o
		ON o.codigo = ct.transaccion
	LEFT JOIN objetos_conceptos AS oc
		ON oc.idconcepto = ct.idconcepto
		AND oc.objeto = o.objeto
WHERE
	ct.idtran = @idtran

IF LEN(@concepto_cuenta) > 0
BEGIN
	EXEC _ct_prc_polizaAplicarDeConfiguracion @idtran, 'DDC1_A', @idtran
END
GO
