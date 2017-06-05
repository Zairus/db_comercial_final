USE db_comercial_final
GO
-- =============================================
-- Author:		Paul Monge
-- Create date: 20100426
-- Description:	No permitir cancelaciones con fecha anteiror a creación.
-- =============================================
ALTER TRIGGER [dbo].[tg_cxc_transacciones_saldo]
	ON [dbo].[ew_cxc_transacciones]
	FOR UPDATE
AS 

SET NOCOUNT ON

IF UPDATE(saldo)
BEGIN
	DECLARE
		@idtran AS INT

	DECLARE cur_saldo CURSOR FOR
		SELECT idtran 
		FROM inserted
	
	OPEN cur_saldo

	FETCH NEXT FROM cur_saldo INTO
		@idtran

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC _cxc_prc_acumularSaldosPorFecha @idtran
		
		FETCH NEXT FROM cur_saldo INTO
			@idtran
	END

	CLOSE cur_saldo
	DEALLOCATE cur_saldo
END
GO
EXEC sp_settriggerorder @triggername=N'[dbo].[tg_cxc_transacciones_saldo]', @order=N'Last', @stmttype=N'UPDATE'
