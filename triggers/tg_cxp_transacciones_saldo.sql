USE [db_refriequipos_datos]
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100426
-- Description:	No permitir cancelaciones con fecha anteiror a creación.
-- =============================================
ALTER TRIGGER [dbo].[tg_cxp_transacciones_saldo]
	ON [dbo].[ew_cxp_transacciones]
	FOR UPDATE
AS 

SET NOCOUNT ON

IF UPDATE(saldo)
BEGIN
	DECLARE
		@idtran AS INT

	DECLARE cur_saldoCXP CURSOR FOR
		SELECT idtran 
		FROM inserted
	
	OPEN cur_saldoCXP

	FETCH NEXT FROM cur_saldoCXP INTO
		@idtran

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC _cxp_prc_acumularSaldosPorFecha @idtran
		
		FETCH NEXT FROM cur_saldoCXP INTO
			@idtran
	END

	CLOSE cur_saldoCXP
	DEALLOCATE cur_saldoCXP
END
GO
EXEC sp_settriggerorder @triggername=N'[dbo].[tg_cxp_transacciones_saldo]', @order=N'Last', @stmttype=N'UPDATE'