USE db_comercial_final
GO
IF EXISTS (SELECT * FROM sys.indexes WHERE [name] = 'IX_ew_ct_poliza_mov_abonos')
BEGIN
	DROP INDEX [IX_ew_ct_poliza_mov_abonos] ON [dbo].[ew_ct_poliza_mov]
END
GO
CREATE NONCLUSTERED INDEX [IX_ew_ct_poliza_mov_abonos]
	ON [dbo].[ew_ct_poliza_mov] ([abonos])
	INCLUDE ([idtran2], [cuenta])
GO

