USE db_comercial_final
GO
IF EXISTS (SELECT * FROM sys.indexes WHERE [name] = 'IX_ew_ban_transacciones_idr')
BEGIN
	DROP INDEX [IX_ew_ban_transacciones_idr] ON [dbo].[ew_ban_transacciones]
END
GO
CREATE NONCLUSTERED INDEX [IX_ew_ban_transacciones_idr]
	ON [dbo].[ew_ban_transacciones] ([idr])
	INCLUDE ([idtran],[transaccion],[folio])
GO
