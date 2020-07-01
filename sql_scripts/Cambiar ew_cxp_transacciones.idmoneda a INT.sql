USE db_comercial_final
GO
IF EXISTS (SELECT * FROM sys.indexes WHERE [name] = 'IX_ew_cxp_transacciones_transaccion_cancelado')
BEGIN
	DROP INDEX [IX_ew_cxp_transacciones_transaccion_cancelado] ON [dbo].[ew_cxp_transacciones]
END
GO

ALTER TABLE ew_cxp_transacciones DROP CONSTRAINT DF_ew_cxp_transacciones_idmoneda
GO

ALTER TABLE ew_cxp_transacciones ALTER COLUMN idmoneda INT NOT NULL
GO

ALTER TABLE ew_cxp_transacciones ADD CONSTRAINT DF_ew_cxp_transacciones_idmoneda DEFAULT 0 FOR idmoneda
GO

CREATE NONCLUSTERED INDEX [IX_ew_cxp_transacciones_transaccion_cancelado]
	ON [dbo].[ew_cxp_transacciones] ([transaccion],[cancelado])
	INCLUDE ([idtran],[fecha],[folio],[idmoneda],[idcuenta],[total])
GO
