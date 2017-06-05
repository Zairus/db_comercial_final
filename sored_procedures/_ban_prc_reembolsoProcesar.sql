USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110518
-- Description:	Procesar solicitud de reembolso
-- =============================================
CREATE PROCEDURE [dbo].[_ban_prc_reembolsoProcesar]
	@idtran AS INT
AS

SET NOCOUNT ON

UPDATE ct SET
	ct.caja_chica_aplicado = 1
FROM
	ew_ban_transacciones_mov AS btm
	LEFT JOIN ew_cxp_transacciones AS ct
		ON ct.idtran = btm.idtran2
WHERE
	btm.idtran = @idtran
GO
