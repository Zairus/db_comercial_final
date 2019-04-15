USE db_comercial_final
GO
IF EXISTS (SELECT * FROM sys.indexes WHERE [name] = 'IX_ew_cxp_transacciones_transaccion_cancelado')
BEGIN
	DROP INDEX [IX_ew_cxp_transacciones_transaccion_cancelado] ON [dbo].[ew_cxp_transacciones]
END
GO
CREATE NONCLUSTERED INDEX [IX_ew_cxp_transacciones_transaccion_cancelado]
	ON [dbo].[ew_cxp_transacciones] ([transaccion],[cancelado])
	INCLUDE ([idtran],[fecha],[folio],[idmoneda],[idcuenta],[total])
GO
