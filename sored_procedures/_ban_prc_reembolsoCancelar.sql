USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20110518
-- Description:	Procesar solicitud de reembolso
-- =============================================
CREATE PROCEDURE [dbo].[_ban_prc_reembolsoCancelar]
	 @idtran AS INT
	,@fecha AS SMALLDATETIME
	,@idu AS SMALLINT
AS

SET NOCOUNT ON

UPDATE ct SET
	ct.caja_chica_aplicado = 0
FROM
	ew_ban_transacciones_mov AS btm
	LEFT JOIN ew_cxp_transacciones AS ct
		ON ct.idtran = btm.idtran2
WHERE
	btm.idtran = @idtran

UPDATE ew_ban_transacciones SET
	 cancelado = 1
	,cancelado_fecha = @fecha
WHERE
	idtran = @idtran
GO
