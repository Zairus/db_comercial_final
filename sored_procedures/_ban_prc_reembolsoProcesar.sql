USE db_comercial_final
GO
IF OBJECT_ID('_ban_prc_reembolsoProcesar') IS NOT NULL
BEGIN 
	DROP PROCEDURE _ban_prc_reembolsoProcesar
END
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

UPDATE bt SET
	bt.importe = ISNULL((
		SELECT
			SUM(btm.importe)
		FROM
			ew_ban_transacciones_mov AS btm
		WHERE
			btm.idtran = bt.idtran
	), 0)
FROM
	ew_ban_transacciones AS bt
WHERE
	bt.idtran = @idtran
GO
