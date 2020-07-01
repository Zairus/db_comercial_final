USE db_comercial_final
GO
IF EXISTS (SELECT * FROM sys.indexes WHERE [name] = 'IX_ew_cxc_transacciones_transaccion_cancelado')
BEGIN
	DROP INDEX [IX_ew_cxc_transacciones_transaccion_cancelado] ON [dbo].[ew_cxc_transacciones]
END
GO
CREATE NONCLUSTERED INDEX [IX_ew_cxc_transacciones_transaccion_cancelado]
	ON [dbo].[ew_cxc_transacciones] (
		[transaccion]
		, [cancelado]
	)
INCLUDE (
	[idtran]
	, [idmov]
	, [fecha]
	, [folio]
	, [idcliente]
	, [total]
)
GO
